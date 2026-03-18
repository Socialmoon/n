import "@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(status: number, payload: Record<string, unknown>) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function normalizeMobile(value: string): string {
  const digits = value.replace(/[^0-9]/g, "");
  if (digits.length > 10) {
    return digits.slice(-10);
  }
  return digits;
}

function toE164(value: string): string | null {
  const digits = value.replace(/[^0-9]/g, "");
  if (digits.length === 10) {
    return `+91${digits}`;
  }
  if (digits.length >= 11 && digits.length <= 15) {
    return `+${digits}`;
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { success: false, error: "Method not allowed" });
  }

  const accountSid = Deno.env.get("TWILIO_ACCOUNT_SID") ?? "";
  const authToken = Deno.env.get("TWILIO_AUTH_TOKEN") ?? "";
  const verifyServiceSid = Deno.env.get("TWILIO_VERIFY_SERVICE_SID") ?? "";

  if (!accountSid || !authToken || !verifyServiceSid) {
    return jsonResponse(500, {
      success: false,
      error: "Twilio OTP service is not configured on server",
    });
  }

  let body: { mobileNumber?: string; otp?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { success: false, error: "Invalid JSON payload" });
  }

  const normalized = normalizeMobile(body.mobileNumber ?? "");
  const otp = (body.otp ?? "").trim();

  if (normalized.length !== 10) {
    return jsonResponse(400, {
      success: false,
      error: "Enter a valid 10 digit mobile number.",
    });
  }

  if (otp.length !== 6) {
    return jsonResponse(400, {
      success: false,
      error: "Enter the 6 digit OTP.",
    });
  }

  const to = toE164(normalized);
  if (!to) {
    return jsonResponse(400, {
      success: false,
      error: "Unable to format phone number for OTP verification.",
    });
  }

  const authHeader = `Basic ${btoa(`${accountSid}:${authToken}`)}`;

  const twilioResponse = await fetch(
    `https://verify.twilio.com/v2/Services/${verifyServiceSid}/VerificationCheck`,
    {
      method: "POST",
      headers: {
        Authorization: authHeader,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        To: to,
        Code: otp,
      }),
    },
  );

  const twilioText = await twilioResponse.text();
  if (!twilioResponse.ok) {
    return jsonResponse(502, {
      success: false,
      error: "OTP verification failed. Please retry.",
      details: twilioText,
    });
  }

  let decoded: Record<string, unknown> = {};
  try {
    decoded = JSON.parse(twilioText) as Record<string, unknown>;
  } catch {
    return jsonResponse(502, {
      success: false,
      error: "Unexpected verification response from OTP provider.",
    });
  }

  const status = String(decoded.status ?? "").toLowerCase();
  if (status !== "approved") {
    return jsonResponse(400, {
      success: false,
      error: "Invalid OTP.",
    });
  }

  return jsonResponse(200, {
    success: true,
    message: "OTP verified",
  });
});
