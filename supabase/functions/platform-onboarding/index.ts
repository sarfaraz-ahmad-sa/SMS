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
const strongPassword = (value: string) => value.length >= 10 &&
  /[A-Z]/.test(value) && /[a-z]/.test(value) && /[0-9]/.test(value) &&
  /[^A-Za-z0-9]/.test(value);
const plans = new Set(["trial", "starter", "standard", "pro", "enterprise", "custom"]);

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed." }, 405);

  let createdAuthUserId = "";
  try {
    const url = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const authorization = request.headers.get("Authorization") ?? "";
    if (!url || !anonKey || !serviceKey || !authorization.startsWith("Bearer ")) {
      throw new RequestError("Authentication is required.", 401);
    }

    const callerClient = createClient(url, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
    const { data: authData, error: authError } = await callerClient.auth.getUser();
    if (authError || !authData.user) throw new RequestError("Your session is invalid.", 401);

    const { data: operator, error: operatorError } = await admin
      .from("tenant_members")
      .select("tenant_id")
      .eq("user_id", authData.user.id)
      .eq("is_active", true)
      .eq("status", "active")
      .contains("roles", ["superAdmin"])
      .limit(1)
      .maybeSingle();
    if (operatorError || !operator) {
      throw new RequestError("Only a platform Super Admin can create schools.", 403);
    }

    const body = await request.json() as Record<string, unknown>;
    const action = text(body.action);
    if (action !== "createSchool") throw new RequestError("Unsupported onboarding action.");

    const schoolName = text(body.schoolName);
    const schoolCode = text(body.schoolCode).toUpperCase();
    const ownerName = text(body.ownerName);
    const ownerEmail = text(body.ownerEmail).toLowerCase();
    const campusName = text(body.campusName) || "Main Campus";
    const campusCode = text(body.campusCode).toUpperCase() || "MAIN";
    const academicYearName = text(body.academicYearName);
    const academicYearStart = text(body.academicYearStart);
    const academicYearEnd = text(body.academicYearEnd);
    const timezone = text(body.timezone) || "Asia/Karachi";
    const currency = text(body.currency).toUpperCase() || "PKR";
    const plan = text(body.plan) || "trial";
    const setupMethod = text(body.setupMethod) || "emailLink";
    const temporaryPassword = text(body.temporaryPassword);
    const trialDays = Math.max(1, Math.min(90, Number(body.trialDays) || 30));

    if (schoolName.length < 2 || schoolName.length > 160) {
      throw new RequestError("Enter a valid school name.");
    }
    if (!/^[A-Z0-9_-]{2,32}$/.test(schoolCode)) {
      throw new RequestError("School code must use 2-32 letters, numbers, hyphens or underscores.");
    }
    if (ownerName.length < 2 || ownerName.length > 120 ||
      !/^\S+@\S+\.\S+$/.test(ownerEmail)) {
      throw new RequestError("Enter valid owner details.");
    }
    if (!plans.has(plan)) throw new RequestError("Select a valid plan.");
    if (!["emailLink", "temporaryPassword"].includes(setupMethod)) {
      throw new RequestError("Select a valid account setup method.");
    }
    if (setupMethod === "temporaryPassword" && !strongPassword(temporaryPassword)) {
      throw new RequestError("Temporary password does not meet the security requirements.");
    }
    const startsAt = new Date(`${academicYearStart}T00:00:00Z`);
    const endsAt = new Date(`${academicYearEnd}T00:00:00Z`);
    if (!academicYearName || Number.isNaN(startsAt.valueOf()) ||
      Number.isNaN(endsAt.valueOf()) || endsAt <= startsAt) {
      throw new RequestError("Enter a valid academic year and date range.");
    }

    const { data: duplicate } = await admin.from("tenants")
      .select("id").eq("code", schoolCode).maybeSingle();
    if (duplicate) throw new RequestError("This school code is already in use.", 409);

    const existing = await findUserByEmail(admin, ownerEmail);
    let owner = existing;
    let invitationSent = false;
    if (!owner) {
      if (setupMethod === "emailLink") {
        const { data, error } = await admin.auth.admin.inviteUserByEmail(ownerEmail, {
          data: { display_name: ownerName },
        });
        if (error) throw error;
        owner = data.user;
        invitationSent = true;
      } else {
        const { data, error } = await admin.auth.admin.createUser({
          email: ownerEmail,
          password: temporaryPassword,
          email_confirm: true,
          user_metadata: { display_name: ownerName },
        });
        if (error) throw error;
        owner = data.user;
      }
      createdAuthUserId = owner?.id ?? "";
    }
    if (!owner) throw new RequestError("Owner account could not be created.", 500);

    const tenantId = crypto.randomUUID();
    const campusId = "main-campus";
    const academicYearId = `year-${academicYearName.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "")}`;
    const periodEnd = new Date(Date.now() + trialDays * 86_400_000);
    const graceEnd = new Date(periodEnd.getTime() + 7 * 86_400_000);
    const subscription = {
      tier: plan,
      status: plan === "trial" ? "trialing" : "active",
      active: true,
      current_period_end: periodEnd.toISOString(),
      trial_ends_at: plan === "trial" ? periodEnd.toISOString() : null,
      grace_period_ends_at: graceEnd.toISOString(),
      cancel_at_period_end: false,
      enabled_features: [],
      limits: {},
    };

    const { data: provisioned, error: provisionError } = await admin.rpc(
      "provision_school_tenant",
      {
        p_tenant_id: tenantId,
        p_school_name: schoolName,
        p_school_code: schoolCode,
        p_timezone: timezone,
        p_currency: currency,
        p_subscription: subscription,
        p_owner_user_id: owner.id,
        p_owner_email: ownerEmail,
        p_owner_name: ownerName,
        p_owner_must_change_password: setupMethod === "temporaryPassword" && !existing,
        p_campus_id: campusId,
        p_campus_code: campusCode,
        p_campus_name: campusName,
        p_academic_year_id: academicYearId,
        p_academic_year_name: academicYearName,
        p_academic_year_start: academicYearStart,
        p_academic_year_end: academicYearEnd,
        p_actor_user_id: authData.user.id,
      },
    );
    if (provisionError) throw provisionError;

    return json({
      ...provisioned,
      ownerEmail,
      accountCreated: !existing,
      existingOwnerAccount: Boolean(existing),
      invitationSent,
      requiresPasswordChange: setupMethod === "temporaryPassword" && !existing,
    }, 201);
  } catch (error) {
    if (createdAuthUserId) {
      try {
        const url = Deno.env.get("SUPABASE_URL") ?? "";
        const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
        if (url && serviceKey) {
          await createClient(url, serviceKey, { auth: { persistSession: false } })
            .auth.admin.deleteUser(createdAuthUserId);
        }
      } catch (_) {
        // The original onboarding error remains the actionable response.
      }
    }
    const status = error instanceof RequestError ? error.status : 500;
    const message = error instanceof RequestError
      ? error.message
      : "School onboarding could not be completed.";
    console.error("platform-onboarding", {
      status,
      message: error instanceof Error ? error.message : String(error),
    });
    return json({ error: message }, status);
  }
});

async function findUserByEmail(admin: ReturnType<typeof createClient>, email: string) {
  for (let page = 1; page <= 10; page++) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 200 });
    if (error) throw error;
    const found = data.users.find((user) => user.email?.toLowerCase() === email);
    if (found) return found;
    if (data.users.length < 200) return null;
  }
  throw new RequestError("Owner lookup exceeded the supported account directory size.", 503);
}
