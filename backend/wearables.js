// ============================================================================
// Build Your Body — wearables OAuth (Cloudflare Worker module).
//
// Mount in worker.js fetch() before the 404 fallback:
//   import { wearables } from './wearables.js';
//   ...
//   if (url.pathname.startsWith('/wearable/')) return wearables(request, env, url.pathname);
//
// Routes
//   GET  /wearable/<provider>/start?user=<supabase-user-id>
//        → redirects to provider OAuth consent screen
//   GET  /wearable/<provider>/callback?code=...&state=<user-id>
//        → exchanges code, persists tokens to Supabase, redirects to app
//   POST /wearable/<provider>/sync
//        Authorization: Bearer <supabase-access-token>
//        → validates JWT, reads stored tokens, refreshes if needed,
//          returns { score, source } readiness object
//   POST /wearable/<provider>/disconnect
//        Authorization: Bearer <supabase-access-token>
//        → deletes stored tokens for this user/provider
//
// Required CF bindings (Worker → Settings → Variables and Secrets):
//   Secrets: OURA_ID, OURA_SECRET
//            WHOOP_ID, WHOOP_SECRET
//            FITBIT_ID, FITBIT_SECRET
//            SUPABASE_SERVICE_ROLE_KEY
//   Vars:    SUPABASE_URL  (https://owqyrgufwvqgbrpdpskx.supabase.co)
//
// Redirect URIs to register in each provider's dev portal
// (replace <subdomain> with your workers.dev subdomain):
//   https://summerbody-reminders.<subdomain>.workers.dev/wearable/oura/callback
//   https://summerbody-reminders.<subdomain>.workers.dev/wearable/whoop/callback
//   https://summerbody-reminders.<subdomain>.workers.dev/wearable/fitbit/callback
//
// Supabase table required: run backend/wearable-tokens.sql before enabling.
// Apple Watch / Garmin / HealthKit need the native app — not handled here.
// ============================================================================

const APP_URL = 'https://reetwell.github.io/summer26/';

const PROVIDERS = {
  oura: {
    auth:      'https://cloud.ouraring.com/oauth/authorize',
    token:     'https://api.ouraring.com/oauth/token',
    scope:     'daily',
    basicAuth: false,
    // Oura returns a 1–100 daily readiness score directly.
    readiness: async (accessToken) => {
      const r = await fetch(
        'https://api.ouraring.com/v2/usercollection/daily_readiness?start_date=' + isoDaysAgo(1),
        { headers: { Authorization: 'Bearer ' + accessToken } }
      );
      if (!r.ok) return null;
      const d = await r.json();
      const row = (d.data || []).slice(-1)[0];
      return row ? { score: row.score, source: 'oura' } : null;
    },
    // RFC 7009 token revocation (form-encoded token + client creds). Best-effort.
    revoke: async (accessToken, { id, secret }) => {
      await fetch('https://api.ouraring.com/oauth/revoke', {
        method:  'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body:    new URLSearchParams({ token: accessToken, client_id: id, client_secret: secret }),
      });
    },
  },
  whoop: {
    auth:      'https://api.prod.whoop.com/oauth/oauth2/auth',
    token:     'https://api.prod.whoop.com/oauth/oauth2/token',
    scope:     'read:recovery read:sleep offline',
    basicAuth: false,
    readiness: async (accessToken) => {
      const r = await fetch(
        'https://api.prod.whoop.com/developer/v1/recovery?limit=1',
        { headers: { Authorization: 'Bearer ' + accessToken } }
      );
      if (!r.ok) return null;
      const d = await r.json();
      const rec = (d.records || [])[0];
      return rec ? { score: Math.round(rec.score.recovery_score), source: 'whoop' } : null;
    },
    // WHOOP revokes the caller's grant via the user-access endpoint (Bearer auth). Best-effort.
    revoke: async (accessToken) => {
      await fetch('https://api.prod.whoop.com/developer/v1/user/access', {
        method:  'DELETE',
        headers: { Authorization: 'Bearer ' + accessToken },
      });
    },
  },
  fitbit: {
    auth:      'https://www.fitbit.com/oauth2/authorize',
    token:     'https://api.fitbit.com/oauth2/token',
    scope:     'sleep heartrate activity',
    basicAuth: true,  // Fitbit requires Authorization: Basic base64(id:secret) — body creds rejected
    // Fitbit has no readiness score; derive one from previous night's sleep efficiency (0–100).
    readiness: async (accessToken) => {
      const r = await fetch(
        'https://api.fitbit.com/1.2/user/-/sleep/date/' + isoDaysAgo(1) + '.json',
        { headers: { Authorization: 'Bearer ' + accessToken } }
      );
      if (!r.ok) return null;
      const d = await r.json();
      const eff = ((d.sleep || [])[0] || {}).efficiency;
      return eff != null ? { score: eff, source: 'fitbit' } : null;
    },
    // Fitbit revoke: Basic-auth client creds + form token. Best-effort.
    revoke: async (accessToken, { id, secret }) => {
      await fetch('https://api.fitbit.com/oauth2/revoke', {
        method:  'POST',
        headers: {
          'Content-Type':  'application/x-www-form-urlencoded',
          'Authorization': 'Basic ' + btoa(id + ':' + secret),
        },
        body: new URLSearchParams({ token: accessToken }),
      });
    },
  },
};

function isoDaysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString().slice(0, 10);
}

function providerCreds(env, provider) {
  const P = provider.toUpperCase();
  return { id: env[P + '_ID'], secret: env[P + '_SECRET'] };
}

export async function wearables(request, env, pathname) {
  const url      = new URL(request.url);
  const parts    = pathname.split('/');   // ['', 'wearable', provider, action]
  const provider = parts[2] || '';
  const action   = parts[3] || '';

  const P = PROVIDERS[provider];
  if (!P) return wjson({ error: 'unknown_provider' }, 400);

  const { id, secret } = providerCreds(env, provider);
  if (!id || !secret) return wjson({ error: 'not_configured' }, 503);

  const callbackUrl = url.origin + '/wearable/' + provider + '/callback';

  // ── GET /wearable/<provider>/start?user=<uuid> ──────────────────────────
  // Redirect the browser to the provider consent screen.
  if (action === 'start') {
    const userId = url.searchParams.get('user') || '';
    if (!userId) return wjson({ error: 'missing_user' }, 400);

    const authUrl =
      P.auth +
      '?response_type=code' +
      '&client_id='    + encodeURIComponent(id) +
      '&redirect_uri=' + encodeURIComponent(callbackUrl) +
      '&scope='        + encodeURIComponent(P.scope) +
      '&state='        + encodeURIComponent(userId);

    return Response.redirect(authUrl, 302);
  }

  // ── GET /wearable/<provider>/callback?code=...&state=<uuid> ────────────
  // Exchange auth code for tokens, persist to Supabase, redirect back to app.
  if (action === 'callback') {
    const code     = url.searchParams.get('code');
    const userId   = url.searchParams.get('state') || '';
    const errParam = url.searchParams.get('error');

    const failUrl = APP_URL + '?wearable=error&provider=' + provider;

    if (errParam || !code || !userId) return Response.redirect(failUrl, 302);

    const tok = await exchangeCode(P, { id, secret, code, callbackUrl });
    if (!tok || !tok.access_token) return Response.redirect(failUrl, 302);

    const expiresAt = tok.expires_in
      ? new Date(Date.now() + tok.expires_in * 1000).toISOString()
      : null;

    const ok = await sbUpsert(env, 'wearable_tokens', {
      user_id:       userId,
      provider,
      access_token:  tok.access_token,
      refresh_token: tok.refresh_token || null,
      expires_at:    expiresAt,
      scope:         tok.scope || P.scope,
    });

    const dest = ok
      ? APP_URL + '?wearable=connected&provider=' + provider
      : failUrl;
    return Response.redirect(dest, 302);
  }

  // ── POST /wearable/<provider>/sync ──────────────────────────────────────
  // Validate Supabase Bearer JWT, load stored tokens, refresh if near-expiry,
  // call provider readiness API, return { score, source }.
  if (action === 'sync' && request.method === 'POST') {
    const userId = await requireUser(request, env);
    if (!userId) return wjson({ error: 'unauthorized' }, 401);

    let row = await sbGetToken(env, userId, provider);
    if (!row) return wjson({ error: 'not_connected' }, 404);

    row = await maybeRefresh(env, P, { id, secret, provider }, row, userId);
    if (!row) return wjson({ error: 'token_refresh_failed' }, 503);

    const result = await P.readiness(row.access_token);
    if (!result) return wjson({ error: 'no_data' }, 404);
    return wjson(result);
  }

  // ── POST /wearable/<provider>/disconnect ────────────────────────────────
  if (action === 'disconnect' && request.method === 'POST') {
    const userId = await requireUser(request, env);
    if (!userId) return wjson({ error: 'unauthorized' }, 401);

    await sbDeleteToken(env, userId, provider);
    return wjson({ ok: true });
  }

  return wjson({ error: 'unknown_action' }, 400);
}

// ── OAuth helpers ──────────────────────────────────────────────────────────

async function exchangeCode(P, { id, secret, code, callbackUrl }) {
  const body = new URLSearchParams({
    grant_type:   'authorization_code',
    code,
    redirect_uri: callbackUrl,
  });
  const headers = { 'Content-Type': 'application/x-www-form-urlencoded' };
  if (P.basicAuth) {
    headers['Authorization'] = 'Basic ' + btoa(id + ':' + secret);
  } else {
    body.set('client_id', id);
    body.set('client_secret', secret);
  }
  try {
    const r = await fetch(P.token, { method: 'POST', headers, body });
    return r.ok ? r.json() : null;
  } catch { return null; }
}

async function doRefresh(P, { id, secret }, refreshToken) {
  if (!refreshToken) return null;
  const body = new URLSearchParams({ grant_type: 'refresh_token', refresh_token: refreshToken });
  const headers = { 'Content-Type': 'application/x-www-form-urlencoded' };
  if (P.basicAuth) {
    headers['Authorization'] = 'Basic ' + btoa(id + ':' + secret);
  } else {
    body.set('client_id', id);
    body.set('client_secret', secret);
  }
  try {
    const r = await fetch(P.token, { method: 'POST', headers, body });
    return r.ok ? r.json() : null;
  } catch { return null; }
}

// Refresh the stored token if it expires within 5 minutes. Returns updated row.
async function maybeRefresh(env, P, creds, row, userId) {
  if (!row.expires_at) return row;                           // non-expiring (some Oura tokens)
  const expiresMs = new Date(row.expires_at).getTime();
  if (expiresMs - Date.now() > 5 * 60 * 1000) return row;  // still fresh

  const fresh = await doRefresh(P, creds, row.refresh_token);
  if (!fresh || !fresh.access_token) return row;            // use old token as fallback

  const updated = {
    user_id:       userId,
    provider:      creds.provider,
    access_token:  fresh.access_token,
    refresh_token: fresh.refresh_token || row.refresh_token,
    expires_at:    fresh.expires_in
      ? new Date(Date.now() + fresh.expires_in * 1000).toISOString()
      : null,
    scope: row.scope,
  };
  await sbUpsert(env, 'wearable_tokens', updated);
  return updated;
}

// ── Supabase REST helpers (service-role key — bypasses RLS) ───────────────

function sbAuthHeaders(env) {
  return {
    'apikey':        env.SUPABASE_SERVICE_ROLE_KEY,
    'Authorization': 'Bearer ' + env.SUPABASE_SERVICE_ROLE_KEY,
    'Content-Type':  'application/json',
  };
}

async function sbUpsert(env, table, row) {
  try {
    const r = await fetch(env.SUPABASE_URL + '/rest/v1/' + table, {
      method:  'POST',
      headers: { ...sbAuthHeaders(env), 'Prefer': 'resolution=merge-duplicates,return=minimal' },
      body:    JSON.stringify(row),
    });
    return r.ok || r.status === 201;
  } catch { return false; }
}

async function sbGetToken(env, userId, provider) {
  try {
    const r = await fetch(
      env.SUPABASE_URL + '/rest/v1/wearable_tokens' +
        '?user_id=eq.'  + encodeURIComponent(userId) +
        '&provider=eq.' + encodeURIComponent(provider) +
        '&limit=1',
      { headers: sbAuthHeaders(env) }
    );
    if (!r.ok) return null;
    const rows = await r.json();
    return rows[0] || null;
  } catch { return null; }
}

async function sbDeleteToken(env, userId, provider) {
  try {
    await fetch(
      env.SUPABASE_URL + '/rest/v1/wearable_tokens' +
        '?user_id=eq.'  + encodeURIComponent(userId) +
        '&provider=eq.' + encodeURIComponent(provider),
      { method: 'DELETE', headers: sbAuthHeaders(env) }
    );
  } catch { /* best effort */ }
}

// All token rows for a user (every provider). Returns [] if none, null on error.
async function sbGetAllTokens(env, userId) {
  try {
    const r = await fetch(
      env.SUPABASE_URL + '/rest/v1/wearable_tokens?user_id=eq.' + encodeURIComponent(userId),
      { headers: sbAuthHeaders(env) }
    );
    if (!r.ok) return null;
    return await r.json();
  } catch { return null; }
}

// Delete every token row for a user. Zero matching rows still succeeds.
async function sbDeleteAllTokens(env, userId) {
  try {
    const r = await fetch(
      env.SUPABASE_URL + '/rest/v1/wearable_tokens?user_id=eq.' + encodeURIComponent(userId),
      { method: 'DELETE', headers: { ...sbAuthHeaders(env), 'Prefer': 'return=minimal' } }
    );
    return r.ok;
  } catch { return false; }
}

// Revoke every connected provider's OAuth grant (best-effort — a provider-side
// failure never blocks account deletion) then delete all token rows for the
// user. Used by the account-deletion endpoint. Returns { dbOk } for the row
// delete; provider revoke outcomes are intentionally not surfaced.
export async function revokeUserWearables(env, userId) {
  const rows = await sbGetAllTokens(env, userId);
  if (rows === null) return { dbOk: false };   // couldn't read → report, let caller retry

  for (const row of rows) {
    const P = PROVIDERS[row.provider];
    if (P && P.revoke && row.access_token) {
      try { await P.revoke(row.access_token, providerCreds(env, row.provider)); } catch { /* best effort */ }
    }
  }

  const dbOk = rows.length === 0 ? true : await sbDeleteAllTokens(env, userId);
  return { dbOk };
}

// Validate a Supabase access token by calling /auth/v1/user.
// Returns the user's UUID or null.
async function sbValidateJwt(env, accessToken) {
  try {
    const r = await fetch(env.SUPABASE_URL + '/auth/v1/user', {
      headers: {
        'apikey':        env.SUPABASE_SERVICE_ROLE_KEY,
        'Authorization': 'Bearer ' + accessToken,
      },
    });
    if (!r.ok) return null;
    const user = await r.json();
    return (user && user.id) ? user.id : null;
  } catch { return null; }
}

// Extract and validate the Bearer token from Authorization header.
// Exported so other Worker modules (e.g. account.js) can authenticate callers.
export async function requireUser(request, env) {
  const auth = request.headers.get('Authorization') || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7).trim() : null;
  if (!token) return null;
  return sbValidateJwt(env, token);
}

function wjson(o, status = 200) {
  return new Response(JSON.stringify(o), {
    status,
    headers: {
      'Content-Type':                'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
}
