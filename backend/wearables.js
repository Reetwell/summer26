// ============================================================================
// Build Your Body — wearables OAuth (Cloudflare Worker module). READY TO WIRE.
// Frontend shows "Coming soon" until WEARABLES_ENABLED=true in index.html and
// these routes are mounted in worker.js. Tokens live server-side only.
//
// SETUP (per provider):
//  1. Register a developer app:
//       Oura   → https://cloud.ouraring.com/oauth/applications
//       Whoop  → https://developer.whoop.com
//       Fitbit → https://dev.fitbit.com/apps
//  2. Redirect URI = https://<your-worker>/wearable/<provider>/callback
//  3. Add secrets to the Worker:  OURA_ID/OURA_SECRET, WHOOP_ID/WHOOP_SECRET,
//     FITBIT_ID/FITBIT_SECRET  (wrangler secret put …)
//  4. Store tokens in Supabase (table wearable_tokens: user_id, provider,
//     access_token, refresh_token, expires_at) or the REMINDERS KV.
//
// Apple Watch (HealthKit) & Garmin need the native app / partner approval —
// not handled here (see BUSINESS.md §7).
// ============================================================================

const PROVIDERS = {
  oura: {
    auth: 'https://cloud.ouraring.com/oauth/authorize',
    token: 'https://api.ouraring.com/oauth/token',
    scope: 'daily',
    // Oura returns a 1–100 daily readiness score directly — maps to ours as-is.
    readiness: async (token) => {
      const r = await fetch('https://api.ouraring.com/v2/usercollection/daily_readiness?start_date=' + isoDaysAgo(1),
        { headers: { Authorization: 'Bearer ' + token } });
      const d = await r.json();
      const row = (d.data || []).slice(-1)[0];
      return row ? { score: row.score, source: 'oura' } : null;
    }
  },
  whoop: {
    auth: 'https://api.prod.whoop.com/oauth/oauth2/auth',
    token: 'https://api.prod.whoop.com/oauth/oauth2/token',
    scope: 'read:recovery read:sleep offline',
    readiness: async (token) => {
      const r = await fetch('https://api.prod.whoop.com/developer/v1/recovery?limit=1',
        { headers: { Authorization: 'Bearer ' + token } });
      const d = await r.json();
      const rec = (d.records || [])[0];
      return rec ? { score: Math.round(rec.score.recovery_score), source: 'whoop' } : null;
    }
  },
  fitbit: {
    auth: 'https://www.fitbit.com/oauth2/authorize',
    token: 'https://api.fitbit.com/oauth2/token',
    scope: 'sleep heartrate activity',
    // Fitbit has no single readiness number — derive a rough one from sleep score.
    readiness: async (token) => {
      const r = await fetch('https://api.fitbit.com/1.2/user/-/sleep/date/' + isoDaysAgo(1) + '.json',
        { headers: { Authorization: 'Bearer ' + token } });
      const d = await r.json();
      const eff = ((d.sleep || [])[0] || {}).efficiency;
      return eff ? { score: eff, source: 'fitbit' } : null;
    }
  }
};

function isoDaysAgo(n){ const d = new Date(); d.setDate(d.getDate() - n); return d.toISOString().slice(0, 10); }
function cfg(env, provider){ const P = provider.toUpperCase(); return { id: env[P + '_ID'], secret: env[P + '_SECRET'] }; }

// Mount these in worker.js fetch() before the fallback:
//   if (path.startsWith('/wearable/')) return wearables(request, env, path);
export async function wearables(request, env, path){
  const url = new URL(request.url);
  const [, , provider, action] = path.split('/');   // /wearable/<provider>/<action>
  const P = PROVIDERS[provider];
  if(!P) return json({ error: 'unknown_provider' }, 400);
  const { id, secret } = cfg(env, provider);
  if(!id || !secret) return json({ error: 'not_configured' }, 503);
  const redirect = url.origin + '/wearable/' + provider + '/callback';

  if(action === 'start'){
    const state = url.searchParams.get('user') || '';
    const auth = P.auth + '?response_type=code&client_id=' + encodeURIComponent(id) +
      '&redirect_uri=' + encodeURIComponent(redirect) + '&scope=' + encodeURIComponent(P.scope) +
      '&state=' + encodeURIComponent(state);
    return Response.redirect(auth, 302);
  }

  if(action === 'callback'){
    const code = url.searchParams.get('code'); const state = url.searchParams.get('state') || '';
    const body = new URLSearchParams({ grant_type: 'authorization_code', code, redirect_uri: redirect, client_id: id, client_secret: secret });
    const tok = await (await fetch(P.token, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body })).json();
    // TODO: persist tok.access_token / tok.refresh_token / expires_in for `state` (user) in Supabase or KV.
    return Response.redirect(url.origin + '/connected.html?provider=' + provider, 302);   // bounce back to the app
  }

  if(action === 'sync'){
    // TODO: look up the stored token for the user, refresh if expired.
    const token = url.searchParams.get('token');   // placeholder until token store is wired
    const out = token ? await P.readiness(token) : null;
    return json(out || { error: 'no_data' }, out ? 200 : 404);
  }

  return json({ error: 'unknown_action' }, 400);
}

function json(o, status = 200){ return new Response(JSON.stringify(o), { status, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }); }
