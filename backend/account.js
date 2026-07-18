// ============================================================================
// Build Your Body — account management (Cloudflare Worker module).
//
// Mount in worker.js fetch() before the 404 fallback:
//   import { account } from './account.js';
//   ...
//   if (url.pathname.startsWith('/account/')) return account(request, env, url.pathname);
//
// Route
//   POST /account/delete
//        Authorization: Bearer <supabase-access-token>
//        → permanently deletes the caller's account and ALL their data.
//          This is the AADC "data-deletion-on-request" hard gate (Path A).
//        → 200 { ok: true } on success
//          401 { error: 'unauthorized' }         — bad/expired/no JWT
//          503 { error: 'not_configured' }        — Supabase secrets missing
//          500 { ok: false, failed: [...] }       — partial failure, SAFE TO RETRY
//
// Deletion order (PII-minimisation first; provider tokens revoked before the
// row is deleted because revocation needs the token value):
//   1. revoke each connected wearable's OAuth grant (best-effort), delete
//      wearable_tokens rows
//   2. delete app_data rows
//   3. Supabase Admin: hard-delete the auth user (cascades any remainder)
//
// Idempotent: every step is safe to repeat. A retry after partial failure
// re-runs cleanly. Once the auth user is gone the JWT no longer validates, so a
// duplicate call simply returns 401 (nothing left to delete). Correct even when
// the user never synced anything (app_data = 0 rows) or never connected a
// wearable (0 token rows) — deleting zero rows is success.
//
// Required CF bindings (same as wearables.js):
//   Secret: SUPABASE_SERVICE_ROLE_KEY
//   Var:    SUPABASE_URL   (https://owqyrgufwvqgbrpdpskx.supabase.co)
// ============================================================================

import { requireUser, revokeUserWearables } from './wearables.js';

export async function account(request, env, pathname) {
  const parts  = pathname.split('/');   // ['', 'account', action]
  const action = parts[2] || '';

  if (action === 'delete' && request.method === 'POST') {
    return deleteAccount(request, env);
  }
  return ajson({ error: 'unknown_action' }, 400);
}

async function deleteAccount(request, env) {
  if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
    return ajson({ error: 'not_configured' }, 503);
  }

  const userId = await requireUser(request, env);
  if (!userId) return ajson({ error: 'unauthorized' }, 401);

  const failed = [];

  // 1. Wearables — revoke provider OAuth grants (best-effort), delete token rows.
  //    Only the DB delete failing counts as a failure; provider revoke is best-effort.
  try {
    const { dbOk } = await revokeUserWearables(env, userId);
    if (!dbOk) failed.push('wearable_tokens');
  } catch {
    failed.push('wearable_tokens');
  }

  // 2. app_data — explicit delete (also cascades on user delete, but we remove
  //    PII first). Deleting zero rows is success.
  if (!(await sbDeleteAppData(env, userId))) failed.push('app_data');

  // 3. Auth user — hard delete, cascades anything left. 404 = already gone (idempotent).
  if (!(await sbAdminDeleteUser(env, userId))) failed.push('auth_user');

  if (failed.length) {
    return ajson(
      { ok: false, failed, message: 'Partial deletion — safe to retry.' },
      500
    );
  }
  return ajson({ ok: true });
}

// ── Supabase service-role helpers (bypass RLS) ──────────────────────────────

function sbHeaders(env) {
  return {
    'apikey':        env.SUPABASE_SERVICE_ROLE_KEY,
    'Authorization': 'Bearer ' + env.SUPABASE_SERVICE_ROLE_KEY,
    'Content-Type':  'application/json',
  };
}

// DELETE every app_data row for the user. Zero matching rows still returns 2xx.
async function sbDeleteAppData(env, userId) {
  try {
    const r = await fetch(
      env.SUPABASE_URL + '/rest/v1/app_data?user_id=eq.' + encodeURIComponent(userId),
      { method: 'DELETE', headers: { ...sbHeaders(env), 'Prefer': 'return=minimal' } }
    );
    return r.ok;
  } catch {
    return false;
  }
}

// Admin hard-delete of the auth user. Treat 404 (already deleted) as success so
// a retry after partial failure is idempotent.
async function sbAdminDeleteUser(env, userId) {
  try {
    const r = await fetch(
      env.SUPABASE_URL + '/auth/v1/admin/users/' + encodeURIComponent(userId),
      { method: 'DELETE', headers: sbHeaders(env) }
    );
    return r.ok || r.status === 404;
  } catch {
    return false;
  }
}

function ajson(o, status = 200) {
  return new Response(JSON.stringify(o), {
    status,
    headers: {
      'Content-Type':                'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
}
