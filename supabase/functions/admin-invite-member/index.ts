import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return json(405, { error: "Method not allowed." });

  const authorization = request.headers.get("Authorization") ?? "";
  const token = authorization.replace(/^Bearer\s+/i, "");
  if (!token || token === authorization) return json(401, { error: "Sign-in required." });

  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) return json(500, { error: "Server is not configured." });

  const service = createClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: caller, error: callerError } = await service.auth.getUser(token);
  if (callerError || !caller.user) return json(401, { error: "Sign-in required." });

  const { data: allowed, error: allowlistError } = await service
    .from("admin_allowlist")
    .select("user_id")
    .eq("user_id", caller.user.id)
    .maybeSingle();
  if (allowlistError) return json(500, { error: "Could not verify admin access." });
  if (!allowed) return json(403, { error: "Administrator access required." });

  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return json(400, { error: "Invalid request body." });
  }
  if (typeof payload !== "object" || payload === null) {
    return json(400, { error: "Invalid request body." });
  }
  const body = payload as Record<string, unknown>;
  const displayName = typeof body.displayName === "string" ? body.displayName.trim() : "";
  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  if (displayName.length < 2 || displayName.length > 100 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return json(400, { error: "Enter a valid name and email address." });
  }

  const { data: invite, error: inviteError } = await service.auth.admin.inviteUserByEmail(email, {
    data: { full_name: displayName },
    redirectTo: "com.christiangolfers.capetown://login-callback",
  });
  if (inviteError) {
    return json(400, { error: inviteError.message });
  }
  return json(200, { invited: true, userId: invite.user.id });
});
