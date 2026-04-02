declare const Deno: {
  serve(handler: (req: Request) => Response | Promise<Response>): void;
  env: {
    get(name: string): string | undefined;
  };
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const OTP_SLOT_MS = 5 * 60 * 1000;
const ROLLOVER_GRACE_MS = 60 * 1000;
const VERIFY_WINDOW_MS = 10 * 60 * 1000;
const VERIFY_LOCK_MS = 10 * 60 * 1000;
const VERIFY_MAX_ATTEMPTS = 8;

type VerifyState = {
  count: number;
  windowStartedAt: number;
  lockedUntil: number;
};

const verifyAttempts = new Map<string, VerifyState>();

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

  let body: { email?: string; otp?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { success: false, error: "Invalid JSON payload" });
  }

  const email = (body.email ?? "").trim();
  const otp = (body.otp ?? "").trim();
  const normalizedEmail = email.toLowerCase();

  if (!isValidEmail(email)) {
    return jsonResponse(400, { success: false, error: "Invalid email address" });
  }

  if (!/^\d{6}$/.test(otp)) {
    return jsonResponse(400, { success: false, error: "OTP must be 6 digits" });
  }

  const otpSecret = Deno.env.get("EMAIL_OTP_SECRET") ?? "";
  if (!otpSecret) {
    return jsonResponse(500, {
      success: false,
      error: "Email OTP verification is not configured on server",
    });
  }

  const now = Date.now();
  const state = verifyAttempts.get(normalizedEmail);
  if (state != null) {
    if (state.lockedUntil > now) {
      const retryAfterSeconds = Math.ceil((state.lockedUntil - now) / 1000);
      return jsonResponse(429, {
        success: false,
        error: `Too many failed attempts. Retry after ${retryAfterSeconds}s.`,
      });
    }

    if (now - state.windowStartedAt > VERIFY_WINDOW_MS) {
      verifyAttempts.delete(normalizedEmail);
    }
  }

  const currentOtp = await computeOtp(email, otpSecret, 0);
  const allowPrevious = (Date.now() % OTP_SLOT_MS) < ROLLOVER_GRACE_MS;
  const previousOtp = allowPrevious
    ? await computeOtp(email, otpSecret, -1)
    : null;

  if (otp !== currentOtp && otp !== previousOtp) {
    const existing = verifyAttempts.get(normalizedEmail);
    if (existing == null) {
      verifyAttempts.set(normalizedEmail, {
        count: 1,
        windowStartedAt: now,
        lockedUntil: 0,
      });
    } else {
      const nextCount = existing.count + 1;
      const lockUntil = nextCount >= VERIFY_MAX_ATTEMPTS ? now + VERIFY_LOCK_MS : 0;
      verifyAttempts.set(normalizedEmail, {
        count: nextCount,
        windowStartedAt: existing.windowStartedAt,
        lockedUntil: lockUntil,
      });
    }

    return jsonResponse(400, {
      success: false,
      error: "Invalid or expired OTP",
    });
  }

  verifyAttempts.delete(normalizedEmail);

  return jsonResponse(200, {
    success: true,
    message: "OTP verified",
  });
});
