import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};
const projectUrl = Deno.env.get("SUPABASE_URL") ?? "";
const publicKeys = JSON.parse(Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") ?? "{}");
const publishableKey = publicKeys.default ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";
const secretKeys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}");
const serviceKey = secretKeys.default ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const service = createClient(projectUrl, serviceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function html(status: number, source: string) {
  const config = JSON.stringify({ projectUrl, publishableKey }).replaceAll("<", "\\u003c");
  const page = source.replace("__CONFIG__", config);
  return new Response(page, {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "public, max-age=300",
      "Content-Security-Policy": `default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src ${projectUrl}; form-action 'none'; base-uri 'none'; frame-ancestors 'none'`,
      "X-Content-Type-Options": "nosniff",
      "Referrer-Policy": "no-referrer",
    },
  });
}

const style = `
  :root{color-scheme:dark;--bg:#0b1220;--panel:#111c2d;--line:#27364a;--ink:#f4f7f3;--muted:#a7b3c0;--green:#16a36a;--lime:#c7e84a}
  *{box-sizing:border-box}body{margin:0;background:radial-gradient(ellipse at 20% 0%,#183d32 0,transparent 35%),var(--bg);color:var(--ink);font:16px/1.6 system-ui,-apple-system,Segoe UI,sans-serif}
  main{width:min(760px,100% - 32px);margin:32px auto 60px}.brand{color:var(--lime);font-size:13px;font-weight:800;letter-spacing:.12em;text-transform:uppercase}
  h1{font-size:clamp(30px,6vw,46px);line-height:1.1;margin:10px 0 12px}h2{font-size:20px;margin:26px 0 6px}p,li{color:var(--muted)}a{color:var(--lime)}.panel{background:var(--panel);border:1px solid var(--line);border-radius:18px;padding:22px;margin:18px 0}
  label{display:block;font-weight:700;margin:14px 0 5px}input,textarea{width:100%;border:1px solid var(--line);border-radius:10px;padding:12px;background:#0b1220;color:var(--ink);font:inherit}button{background:var(--lime);color:#13210d;border:0;border-radius:12px;padding:12px 18px;font-weight:800;font:inherit;cursor:pointer;margin-top:16px}button:disabled{opacity:.6;cursor:wait}.status{min-height:28px;color:var(--lime)}.trap{position:absolute;left:-10000px;width:1px;height:1px;overflow:hidden}
  nav{display:flex;gap:18px;flex-wrap:wrap;margin:18px 0}small{color:var(--muted)}
`;

function page(title: string, content: string) {
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="index,follow"><title>${title} · Christian Golfers Cape Town</title><style>${style}</style></head><body><main><div class="brand">Christian Golfers Cape Town</div>${content}<nav><a href="?view=privacy">Privacy policy</a><a href="?view=delete">Request account deletion</a><a href="?view=contact">Privacy contact</a></nav><small>Christian Golfers Cape Town · Updated 29 October 2026</small></main></body></html>`;
}

const privacyPage = page("Privacy policy", `
  <h1>Privacy policy</h1><p>Last updated 29 October 2026</p>
  <p>This policy explains how the Christian Golfers Cape Town app handles information when you use the app. The app is operated under the name Christian Golfers Cape Town. Privacy questions can be submitted using the <a href="?view=contact">privacy contact form</a>.</p>
  <section class="panel"><h2>Information we handle</h2><ul>
    <li>Account details: email address, display name, sign-in provider, and profile photo if supplied by you or your Google account.</li>
    <li>Golfer profile: Handicap Index and its source, visitor classification, and distance-unit preference.</li>
    <li>Golf activity: selected course and tee, round participants and host, hole-by-hole strokes, putts, penalties, sand shots, fairway results, green-in-regulation values, and completed-round results.</li>
    <li>Fellowship features: profile details, friend requests, and content you choose to post or share with signed-in members.</li>
    <li>Privacy requests: the contact email and message you submit, kept until the request is closed.</li>
  </ul><p>The Android app does not request device location, contacts, camera, microphone, or advertising identifiers. Course coordinates are course data and are not a record of your device's location.</p></section>
  <section class="panel"><h2>How information is used and shared</h2><p>Information is used to authenticate accounts, display profiles and fellowship features, run golf rounds, calculate handicap-adjusted results, and maintain league standings. Players in a round can see the round's participants and scorecards. Allowlisted league owners and captains can view members, rounds, scores, and standings to administer the league.</p><p>Supabase provides the app's authentication, database, and server functions. Google processes sign-in if you choose Google sign-in. The app does not include advertising or in-app analytics SDKs.</p></section>
  <section class="panel"><h2>Storage, security, and retention</h2><p>Account and golf data are stored in the Christian Golfers Cape Town Supabase project. Row-level security restricts ordinary golfer access; privileged league and account operations require server-side administrator checks. No internet service can guarantee absolute security.</p><p>We retain account-linked data while your account is active. You can delete your account from Profile in the app. Account deletion removes the auth account and linked profile, friendships, round memberships, scores, results, and rounds hosted by that account. Removing a hosted round also removes that round's other players' associated round records. Privacy request details are erased when an administrator closes the request.</p></section>
  <section class="panel"><h2>Your choices</h2><p>You may use email and password sign-in without a Google account. You can edit profile details in the app, sign out from Profile, submit a privacy question, or request deletion of your account.</p><p>For an in-app request, open <strong>Profile → Delete account</strong>. If you no longer have the app, use the external <a href="?view=delete">account deletion request form</a>. External requests are reviewed by a league administrator, who may verify control of the email address before deleting the account. This verification protects golfers from deletion requests submitted by someone else.</p></section>
  <section class="panel"><h2>Children and changes</h2><p>The app is intended for adult golfers and is not designed for children under 13. We may update this policy when the app's data practices change; the current version will remain available at this address.</p></section>
`);

function requestPage(kind: "privacy_question" | "account_deletion") {
  const deletion = kind === "account_deletion";
  const title = deletion ? "Request account deletion" : "Privacy contact";
  const detail = deletion
    ? "Submit the email address on your account. An allowlisted league administrator will verify the request before processing it. For immediate deletion while signed in, use Profile → Delete account in the app. Deletion removes your profile and linked golf records; rounds you hosted and the associated round records for other players will also be removed."
    : "Send a privacy question about Christian Golfers Cape Town. Include an email address so the league administrator can respond. Your request details are removed when the request is closed.";
  return page(title, `<h1>${title}</h1><p>${detail}</p><section class="panel"><form id="request-form"><label for="email">Email address</label><input id="email" type="email" autocomplete="email" maxlength="254" required><label for="message">${deletion ? "Optional note" : "Your question"}</label><textarea id="message" rows="5" maxlength="2000" ${deletion ? "" : "required"}></textarea><div class="trap"><label>Leave this field empty<input id="website" tabindex="-1" autocomplete="off"></label></div><label><input id="ack" type="checkbox" required> ${deletion ? "I understand the account and linked golf records will be permanently deleted after the request is verified." : "I agree that my email and message can be used to respond to this privacy question."}</label><button id="send" type="submit">${deletion ? "Submit deletion request" : "Send privacy question"}</button><p id="status" class="status" role="status" aria-live="polite"></p></form></section><script>const cfg=__CONFIG__;const form=document.getElementById("request-form");form.addEventListener("submit",async(e)=>{e.preventDefault();const button=document.getElementById("send"),status=document.getElementById("status");button.disabled=true;status.textContent="Sending…";try{const response=await fetch(cfg.projectUrl+"/functions/v1/account-center",{method:"POST",headers:{"Content-Type":"application/json","apikey":cfg.publishableKey},body:JSON.stringify({action:"submit-request",requestType:"${kind}",email:document.getElementById("email").value.trim(),message:document.getElementById("message").value.trim(),website:document.getElementById("website").value})});const payload=await response.json();if(!response.ok)throw new Error(payload.error||"Request could not be submitted.");form.reset();status.textContent="Request received. Keep the reference below for your records: "+payload.reference;}catch(error){status.textContent=error.message||"Unable to submit. Please try again later.";}finally{button.disabled=false;}});</script>`);
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const url = new URL(request.url);
  if (request.method === "GET") {
    const view = url.searchParams.get("view") ?? "privacy";
    if (view === "privacy") return html(200, privacyPage);
    if (view === "delete") return html(200, requestPage("account_deletion"));
    if (view === "contact") return html(200, requestPage("privacy_question"));
    return json(404, { error: "Page not found." });
  }
  if (request.method !== "POST") return json(405, { error: "Method not allowed." });

  let body: Record<string, unknown>;
  try {
    const parsed: unknown = await request.json();
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      return json(400, { error: "Invalid request body." });
    }
    body = parsed as Record<string, unknown>;
  } catch {
    return json(400, { error: "Invalid request body." });
  }

  if (body.action === "submit-request") {
    if (typeof body.website === "string" && body.website.length > 0) {
      return json(200, { reference: "received" });
    }
    const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
    const requestType = body.requestType;
    const message = typeof body.message === "string" ? body.message.trim() : "";
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254 ||
        (requestType !== "privacy_question" && requestType !== "account_deletion") ||
        message.length > 2000 || (requestType === "privacy_question" && message.length < 5)) {
      return json(400, { error: "Enter a valid email address and request." });
    }
    const { data: existing, error: lookupError } = await service
      .from("privacy_requests").select("id").eq("requester_email", email)
      .neq("status", "completed").limit(1);
    if (lookupError) return json(503, { error: "The request inbox is unavailable. Try again later." });
    if (existing?.length) return json(409, { error: "An open request already exists for this email. Please wait for it to be reviewed." });
    const { data: saved, error: saveError } = await service
      .from("privacy_requests")
      .insert({ request_type: requestType, requester_email: email, message })
      .select("id").single();
    if (saveError || !saved) return json(503, { error: "The request could not be saved. Try again later." });
    return json(201, { reference: saved.id });
  }

  const authorization = request.headers.get("Authorization") ?? "";
  const token = authorization.replace(/^Bearer\s+/i, "");
  if (!token || token === authorization) return json(401, { error: "Sign-in required." });
  const { data: caller, error: callerError } = await service.auth.getUser(token);
  if (callerError || !caller.user) return json(401, { error: "Sign-in required." });

  if (body.action === "delete-account") {
    const email = (caller.user.email ?? "").toLowerCase();
    const { error: deleteError } = await service.auth.admin.deleteUser(caller.user.id);
    if (deleteError) return json(500, { error: "Your account could not be deleted. Please submit an account deletion request." });
    if (email) await service.from("privacy_requests").delete().eq("requester_email", email);
    return json(200, { deleted: true });
  }

  if (body.action === "admin-delete-request") {
    const { data: allowed, error: allowlistError } = await service.from("admin_allowlist")
      .select("user_id").eq("user_id", caller.user.id).maybeSingle();
    if (allowlistError) return json(500, { error: "Could not verify administrator access." });
    if (!allowed) return json(403, { error: "Administrator access required." });
    const requestId = typeof body.requestId === "string" ? body.requestId : "";
    const { data: deletionRequest, error: requestError } = await service.from("privacy_requests")
      .select("id,request_type,requester_email,status").eq("id", requestId).maybeSingle();
    if (requestError || !deletionRequest || deletionRequest.request_type !== "account_deletion" || deletionRequest.status === "completed") {
      return json(404, { error: "Open account deletion request not found." });
    }
    const email = String(deletionRequest.requester_email).toLowerCase();
    const { data: profile } = await service.from("profiles").select("id").eq("email", email).maybeSingle();
    if (!profile) {
      await service.from("privacy_requests").update({ status: "completed", requester_email: "[removed]", message: "", closed_at: new Date().toISOString(), processed_by: caller.user.id }).eq("id", requestId);
      return json(200, { deleted: false, accountFound: false });
    }
    const { error: deleteError } = await service.auth.admin.deleteUser(profile.id);
    if (deleteError) return json(500, { error: "The verified account could not be deleted." });
    await service.from("privacy_requests").delete().eq("requester_email", email).neq("id", requestId);
    await service.from("privacy_requests").update({ status: "completed", requester_email: "[removed]", message: "", closed_at: new Date().toISOString(), processed_by: caller.user.id }).eq("id", requestId);
    return json(200, { deleted: true, accountFound: true });
  }
  return json(400, { error: "Unsupported action." });
});
