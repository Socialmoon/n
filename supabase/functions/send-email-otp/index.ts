import "@supabase/functions-js/edge-runtime.d.ts";
/// <reference path="./smtp-url-module.d.ts" />
import { SmtpClient } from "https://deno.land/x/smtp/mod.ts";

declare const Deno: {
  serve(handler: (req: Request) => Response | Promise<Response>): void;
  env: {
    get(name: string): string | undefined;
  };
  writeAll?: (
    writer: { write(p: Uint8Array): Promise<number> },
    data: Uint8Array,
  ) => Promise<void>;
};

// Compatibility shim for smtp module on newer edge runtime.
if (typeof Deno.writeAll !== "function") {
  Deno.writeAll = async (
    writer: { write(p: Uint8Array): Promise<number> },
    data: Uint8Array,
  ): Promise<void> => {
    let offset = 0;
    while (offset < data.length) {
      const chunk = data.subarray(offset);
      const written = await writer.write(chunk);
      if (written <= 0) {
        throw new Error("Failed to write SMTP payload");
      }
      offset += written;
    }
  };
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const RESEND_COOLDOWN_MS = 60 * 1000;
const OTP_SLOT_MS = 5 * 60 * 1000;
const lastOtpSentAt = new Map<string, number>();

function jsonResponse(status: number, payload: Record<string, unknown>) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function isValidEmail(email: string): boolean {
  return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(email.trim());
}

async function computeOtp(email: string, secret: string, slotOffset = 0): Promise<string> {
  const slot = Math.floor(Date.now() / OTP_SLOT_MS) + slotOffset;
  const encoder = new TextEncoder();
  const keyData = encoder.encode(secret);
  const messageData = encoder.encode(`${email.toLowerCase().trim()}|${slot}`);

  const key = await crypto.subtle.importKey(
    "raw",
    keyData,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, messageData);
  const bytes = new Uint8Array(signature);

  let value = 0;
  for (let i = 0; i < 4; i += 1) {
    value = (value << 8) | bytes[i];
  }
  const normalized = Math.abs(value) % 1000000;
  return normalized.toString().padStart(6, "0");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { success: false, error: "Method not allowed" });
  }

  let body: { email?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { success: false, error: "Invalid JSON payload" });
  }

  const email = (body.email ?? "").trim();
  if (!isValidEmail(email)) {
    return jsonResponse(400, { success: false, error: "Invalid email address" });
  }

  const smtpUser = Deno.env.get("GMAIL_SMTP_USER") ?? "";
  const smtpPass = Deno.env.get("GMAIL_SMTP_APP_PASSWORD") ?? "";
  const otpSecret = Deno.env.get("EMAIL_OTP_SECRET") ?? "";

  if (!smtpUser || !smtpPass || !otpSecret) {
    return jsonResponse(500, {
      success: false,
      error: "Email OTP service is not configured on server",
    });
  }

  const now = Date.now();
  const normalizedEmail = email.toLowerCase();
  const previousSendAt = lastOtpSentAt.get(normalizedEmail);
  if (previousSendAt != null && now - previousSendAt < RESEND_COOLDOWN_MS) {
    const retryAfterSeconds = Math.ceil((RESEND_COOLDOWN_MS - (now - previousSendAt)) / 1000);
    return jsonResponse(429, {
      success: false,
      error: `OTP already sent. Please wait ${retryAfterSeconds}s before requesting again.`,
    });
  }

  const otp = await computeOtp(email, otpSecret);
  const client = new SmtpClient();

  try {
    await client.connectTLS({
      hostname: "smtp.gmail.com",
      port: 465,
      username: smtpUser,
      password: smtpPass,
    });

    await client.send({
      from: smtpUser,
      to: email,
      subject: "Apne Saathi Support | OTP Verification",
      content:
        `Hello,\n\n` +
        `Your Apne Saathi verification OTP is: ${otp}\n` +
        `This OTP is valid for 5 minutes.\n\n` +
        `If you did not request this, please ignore this email.\n\n` +
        `Regards,\nApne Saathi Support`,
      html: `
        <div style="font-family:Arial,sans-serif;background:#f5f8fb;padding:18px;">
          <div style="max-width:560px;margin:0 auto;background:#ffffff;border:1px solid #d9e2ea;border-radius:12px;overflow:hidden;">
            <div style="background:linear-gradient(135deg,#10394b,#2f7982);padding:14px 16px;color:#ffffff;">
              <h2 style="margin:0;font-size:18px;">Apne Saathi Support</h2>
              <p style="margin:4px 0 0;font-size:12px;opacity:0.92;">Secure OTP Verification</p>
            </div>
            <div style="padding:16px;color:#1f2d36;">
              <p style="margin:0 0 10px;">Hello,</p>
              <p style="margin:0 0 12px;">Use the OTP below to verify your login:</p>
              <div style="display:inline-block;padding:10px 14px;border:1px dashed #b7c5cf;border-radius:8px;background:#f7fbfd;font-size:24px;font-weight:700;letter-spacing:4px;">${otp}</div>
              <p style="margin:12px 0 0;font-size:13px;color:#4a5e6c;">This OTP is valid for <strong>5 minutes</strong>.</p>
              <p style="margin:10px 0 0;font-size:12px;color:#6b7d88;">If you did not request this OTP, you can safely ignore this email.</p>
            </div>
          </div>
        </div>
      `,
    });

    await client.close();
    lastOtpSentAt.set(normalizedEmail, now);

    return jsonResponse(200, {
      success: true,
      message: "OTP sent successfully",
    });
  } catch (error) {
    try {
      await client.close();
    } catch (_) {
      // Ignore close failures after send error.
    }

    return jsonResponse(502, {
      success: false,
      error: "Failed to send OTP email",
      details: String(error),
    });
  }
});
