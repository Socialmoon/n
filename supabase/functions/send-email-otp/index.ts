// @ts-ignore: Resolved by Supabase Edge/Deno runtime during function execution.
import "@supabase/functions-js/edge-runtime.d.ts";
/// <reference path="./smtp-url-module.d.ts" />
// @ts-ignore: Remote Deno URL import is valid at runtime; local declaration file provides types.
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

type OtpPurpose =
  | "login_verification"
  | "registration"
  | "device_binding"
  | "profile_update";

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

function normalizePurpose(rawPurpose: string | undefined): OtpPurpose {
  if (rawPurpose === "registration") {
    return "registration";
  }
  if (rawPurpose === "device_binding") {
    return "device_binding";
  }
  if (rawPurpose === "profile_update") {
    return "profile_update";
  }
  return "login_verification";
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function buildOtpTemplate(
  otp: string,
  purpose: OtpPurpose,
  memberName?: string,
): { subject: string; content: string; html: string } {
  const cleanName = (memberName ?? "").trim();
  const greetingName = cleanName.length > 0 ? cleanName : "Member";

  const labels = {
    login_verification: {
      subject: "Apne Saathi security code",
      heading: "Login verification",
      line: "Use this code to verify your sign-in request.",
    },
    registration: {
      subject: "Apne Saathi security code",
      heading: "Registration verification",
      line: "Use this code to complete your new account registration.",
    },
    device_binding: {
      subject: "Apne Saathi security code",
      heading: "New device verification",
      line: "Use this code to approve login from a new device.",
    },
    profile_update: {
      subject: "Apne Saathi security code",
      heading: "Profile update verification",
      line: "Use this code to confirm your email update request.",
    },
  } as const;

  const selected = labels[purpose];
  const safeName = escapeHtml(greetingName);
  const safeLine = escapeHtml(selected.line);

  const content =
    `Hello ${greetingName},\n\n` +
    `${selected.line}\n` +
    `Code: ${otp}\n` +
    `Valid for 5 minutes.\n\n` +
    `If you did not request this, you can ignore this email.\n\n` +
    `Apne Saathi`;

  const html = `
    <div style="font-family:Arial,sans-serif;background:#ffffff;padding:16px;color:#1f2d36;">
      <p style="margin:0 0 10px;">Hello ${safeName},</p>
      <p style="margin:0 0 12px;">${safeLine}</p>
      <div style="display:inline-block;padding:12px 16px;border:1px solid #d6dbe1;border-radius:8px;background:#f8fafc;font-size:28px;font-weight:700;letter-spacing:3px;">${otp}</div>
      <p style="margin:12px 0 0;font-size:13px;color:#4a5e6c;">Valid for 5 minutes.</p>
      <p style="margin:8px 0 0;font-size:12px;color:#6b7d88;">If you did not request this, ignore this email.</p>
      <p style="margin:14px 0 0;font-size:12px;color:#6b7d88;">Apne Saathi</p>
    </div>
  `;

  return {
    subject: selected.subject,
    content,
    html,
  };
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

  let body: { email?: string; purpose?: string; memberName?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { success: false, error: "Invalid JSON payload" });
  }

  const email = (body.email ?? "").trim();
  const purpose = normalizePurpose(body.purpose);
  const memberName = (body.memberName ?? "").trim();
  if (!isValidEmail(email)) {
    return jsonResponse(400, { success: false, error: "Invalid email address" });
  }

  const smtpUser = Deno.env.get("GMAIL_SMTP_USER") ?? "apnesaathiheadquarter@gmail.com";
  const smtpFromName = Deno.env.get("EMAIL_FROM_NAME") ?? "Apne Saathi";
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
  const template = buildOtpTemplate(otp, purpose, memberName);
  const client = new SmtpClient();

  try {
    await client.connectTLS({
      hostname: "smtp.gmail.com",
      port: 465,
      username: smtpUser,
      password: smtpPass,
    });

    await client.send({
      from: `${smtpFromName} <${smtpUser}>`,
      to: email,
      subject: template.subject,
      content: template.content,
      html: template.html,
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
