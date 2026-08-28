import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, "Content-Type": "application/json" },
});

class RequestError extends Error {
  constructor(message: string, readonly status = 400) { super(message); }
}

const text = (value: unknown) => typeof value === "string" ? value.trim() : "";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed." }, 405);

  try {
    const url = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!url || !serviceKey) throw new RequestError("Service is unavailable.", 503);

    const body = await request.json() as Record<string, unknown>;
    const schoolCode = text(body.schoolCode).toUpperCase();
    const name = text(body.name);
    const rollNumber = text(body.rollNumber);
    const className = text(body.className);
    const email = text(body.email).toLowerCase();
    const phone = text(body.phone);

    if (!/^[A-Z0-9_-]{2,32}$/.test(schoolCode)) {
      throw new RequestError("Enter a valid school code.");
    }
    if (name.length < 2 || name.length > 120 || rollNumber.length > 64 ||
      className.length > 120 || phone.length < 7 || phone.length > 32) {
      throw new RequestError("Review the submitted details and try again.");
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254) {
      throw new RequestError("Enter a valid email address.");
    }

    const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
    const { data: tenant, error: tenantError } = await admin.from("tenants")
      .select("id").eq("code", schoolCode).eq("is_active", true).maybeSingle();
    if (tenantError) throw tenantError;
    if (!tenant) throw new RequestError("The school code was not recognized.", 404);

    const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const { count, error: countError } = await admin.from("access_requests")
      .select("id", { count: "exact", head: true })
      .eq("tenant_id", tenant.id).eq("email", email).gte("created_at", since);
    if (countError) throw countError;
    if ((count ?? 0) >= 3) {
      throw new RequestError("Too many requests. Please contact the school office.", 429);
    }

    const { data: created, error: insertError } = await admin.from("access_requests")
      .insert({
        tenant_id: tenant.id,
        school_code: schoolCode,
        full_name: name,
        roll_or_employee_id: rollNumber,
        class_or_department: className,
        email,
        phone,
      })
      .select("id").single();
    if (insertError) throw insertError;
    return json({ requestId: created.id }, 201);
  } catch (error) {
    if (error instanceof RequestError) return json({ error: error.message }, error.status);
    console.error("request-school-access failed", error);
    return json({ error: "Request could not be submitted." }, 500);
  }
});
