// ============================================================================
// Build Your Body — food search (Cloudflare Worker module).
//
// Proxies + trims the free Open Food Facts API so users can log real foods with
// accurate macros. No API key, no cost — OFF is open data. We proxy (rather than
// hitting OFF from the browser) to add a per-IP rate limit, keep an origin
// allowlist, normalise the response shape, and let responses cache.
//
// Mount in worker.js fetch() before the 404 fallback:
//   import { food } from './food.js';
//   ...
//   if (url.pathname.startsWith('/food/')) return food(request, env, url.pathname);
//
// Routes (both GET)
//   GET /food/search?q=<terms>     → { results: [Food, ...] }   (up to 20)
//   GET /food/barcode/<code>       → { item: Food } | 404 { error:'not_found' }
//
// Food shape (macros are PER 100g — FEATURES scales by the logged amount):
//   { code, name, brand, kcal, p, c, f, serving, basis:'100g' }
//     code    barcode string (or null) — handy for dedupe / re-fetch
//     kcal    integer kcal / 100g
//     p,c,f   grams / 100g (protein, carbs, fat; 1 dp; 0 if OFF omits it)
//     serving OFF's serving-size text e.g. "30 g" (or null)
//     basis   always '100g' so the client knows how to interpret the numbers
//
// Uses the shared REMINDERS KV for rate-limiting (rl:food:<ip>). No secrets.
// ============================================================================

const OFF = 'https://world.openfoodfacts.org';
// OFF asks proxies to send a descriptive User-Agent with contact info.
const UA = 'BuildYourBody/1.0 (brian.rothwell@clickbill.co.uk)';
const RATE_LIMIT = 60;   // requests/hour/IP — generous (free endpoint), abuse guard only

// Only echo known origins (prevents the Worker being used as an open proxy).
const ALLOWED_ORIGINS = new Set([
  'https://reetwell.github.io',
  'http://localhost:8753',
  'http://localhost',
]);

export async function food(request, env, pathname) {
  const url    = new URL(request.url);
  const origin = request.headers.get('Origin') || '';

  if (request.method !== 'GET') return fjson({ error: 'method_not_allowed' }, 405, origin);

  // Per-IP rate limit (shared KV, same pattern as /recipe/extract).
  const ip    = request.headers.get('CF-Connecting-IP') || 'anon';
  const rlKey = 'rl:food:' + ip;
  const count = parseInt((await env.REMINDERS.get(rlKey)) || '0', 10);
  if (count >= RATE_LIMIT) return fjson({ error: 'rate_limited' }, 429, origin);
  await env.REMINDERS.put(rlKey, String(count + 1), { expirationTtl: 3600 });

  const parts  = pathname.split('/');   // ['', 'food', action, code?]
  const action = parts[2] || '';

  if (action === 'search') {
    const q = (url.searchParams.get('q') || '').trim();
    if (!q) return fjson({ error: 'missing_query' }, 400, origin);
    return fjson({ results: await searchFoods(q) }, 200, origin);
  }

  if (action === 'barcode') {
    const code = (parts[3] || '').trim();
    if (!code) return fjson({ error: 'missing_barcode' }, 400, origin);
    const item = await fetchBarcode(code);
    return item
      ? fjson({ item }, 200, origin)
      : fjson({ error: 'not_found' }, 404, origin);
  }

  return fjson({ error: 'unknown_action' }, 400, origin);
}

// ── Open Food Facts calls ───────────────────────────────────────────────────

async function searchFoods(q) {
  const u = OFF + '/cgi/search.pl?search_terms=' + encodeURIComponent(q) +
    '&search_simple=1&action=process&json=1&page_size=20' +
    '&fields=code,product_name,brands,nutriments,serving_size';
  try {
    const r = await fetch(u, { headers: { 'User-Agent': UA } });
    if (!r.ok) return [];
    const d = await r.json();
    return (d.products || []).map(trim).filter(Boolean);
  } catch { return []; }
}

async function fetchBarcode(code) {
  const u = OFF + '/api/v2/product/' + encodeURIComponent(code) +
    '.json?fields=code,product_name,brands,nutriments,serving_size';
  try {
    const r = await fetch(u, { headers: { 'User-Agent': UA } });
    if (!r.ok) return null;
    const d = await r.json();
    if (d.status !== 1 || !d.product) return null;   // OFF returns status:0 when a code is unknown
    return trim(d.product);
  } catch { return null; }
}

// ── Normalise one OFF product → our Food shape (or null if unusable) ─────────

function num(v, dp) {
  const n = parseFloat(v);
  if (!isFinite(n)) return null;
  const m = Math.pow(10, dp);
  return Math.round(n * m) / m;
}

function trim(p) {
  const name = (p.product_name || '').trim();
  const nut  = p.nutriments || {};
  const kcal = num(nut['energy-kcal_100g'], 0);
  // Need at least a name and a calorie figure to be worth logging.
  if (!name || kcal == null) return null;
  return {
    code:    p.code || null,
    name,
    brand:   (p.brands || '').split(',')[0].trim() || null,
    kcal,
    p:       num(nut.proteins_100g, 1)      ?? 0,
    c:       num(nut.carbohydrates_100g, 1) ?? 0,
    f:       num(nut.fat_100g, 1)           ?? 0,
    serving: (p.serving_size || '').trim() || null,
    basis:   '100g',
  };
}

// ── CORS / JSON (origin-locked; cache successful lookups) ───────────────────

function fjson(obj, status, origin) {
  const allow = ALLOWED_ORIGINS.has(origin) ? origin : 'https://reetwell.github.io';
  const headers = {
    'Content-Type':                 'application/json',
    'Access-Control-Allow-Origin':  allow,
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Vary':                         'Origin',
  };
  // Food macros are effectively static — let the browser cache good responses.
  if (status === 200) headers['Cache-Control'] = 'public, max-age=86400';
  return new Response(JSON.stringify(obj), { status, headers });
}
