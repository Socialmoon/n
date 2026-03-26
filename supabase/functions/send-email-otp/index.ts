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
  const slot = Math.floor(Date.now() / 600000) + slotOffset;
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
      subject: "Police Network OTP Verification",
      content: `Your OTP is ${otp}. It is valid for 10 minutes.`,
      html: `<p>Your OTP is <strong>${otp}</strong>.</p><p>It is valid for 10 minutes.</p>`,
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
