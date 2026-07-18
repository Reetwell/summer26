/* SummerBody reminders backend — Cloudflare Worker.
 *
 * Stores a device's push subscription + reminder schedule in KV, and on a cron
 * trigger sends Web Push notifications for protein and creatine at the chosen
 * times. Pushes are sent with no encrypted payload (only VAPID auth), so the
 * service worker asks /due which reminder to show. This keeps the crypto here
 * to just the VAPID JWT (ES256), which is simple and reliable.
 *
 * Required bindings (Worker → Settings → Variables and Secrets):
 *   KV namespace binding:  REMINDERS
 *   Secret:  VAPID_PRIVATE_JWK          (JSON string of the EC private JWK)
 *   Secret:  ANTHROPIC_API_KEY          (enables /recipe/extract)
 *   Secret:  SUPABASE_SERVICE_ROLE_KEY  (enables /wearable/* token store)
 *   Secret:  OURA_ID, OURA_SECRET       (Oura Ring OAuth)
 *   Secret:  WHOOP_ID, WHOOP_SECRET     (Whoop OAuth)
 *   Secret:  FITBIT_ID, FITBIT_SECRET   (Fitbit OAuth)
 *   Var:     VAPID_PUBLIC_KEY           (base64url applicationServerKey)
 *   Var:     VAPID_SUBJECT              (mailto:you@example.com)
 *   Var:     SUPABASE_URL               (https://owqyrgufwvqgbrpdpskx.supabase.co)
 *
 * Cron trigger: every 5 minutes  (see SETUP.md for the exact expression)
 */

import { wearables } from './wearables.js';
import { account } from './account.js';
import { food } from './food.js';

const MESSAGES = {
  protein:  { title: "Protein time 🥤", body: "Have your whey protein shake." },
  creatine: { title: "Creatine time 💊", body: "Take your 5g creatine — even on rest days." },
};

const WINDOW_MIN = 6; // a reminder fires if cron runs within this many minutes after its time

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") return cors(new Response(null, { status: 204 }));

    try {
      if (url.pathname === "/subscribe" && request.method === "POST") {
        const body = await request.json();
        const sub = body.subscription;
        if (!sub || !sub.endpoint) return cors(json({ error: "missing subscription" }, 400));
        const record = {
          subscription: sub,
          schedule: body.schedule || {},   // { protein: "08:00", creatine: "19:00" } in UTC HH:MM
          updated: Date.now(),
        };
        await env.REMINDERS.put("sub:" + sub.endpoint, JSON.stringify(record));
        return cors(json({ ok: true }));
      }

      if (url.pathname === "/unsubscribe" && request.method === "POST") {
        const body = await request.json();
        if (body.endpoint) await env.REMINDERS.delete("sub:" + body.endpoint);
        return cors(json({ ok: true }));
      }

      // Service worker asks which reminder is due right now for this device.
      if (url.pathname === "/due" && request.method === "POST") {
        const body = await request.json();
        const raw = body.endpoint ? await env.REMINDERS.get("sub:" + body.endpoint) : null;
        if (!raw) return cors(json(MESSAGES.protein)); // sensible fallback
        const rec = JSON.parse(raw);
        const due = whichDue(rec.schedule, new Date(), 15); // wider window for receipt
        return cors(json(due ? { ...MESSAGES[due], type: due } : { title: "SummerBody", body: "Supplement reminder 💪" }));
      }

      // Recipe extraction — paste a TikTok/Instagram/YouTube link, get an
      // AI-structured draft recipe back. Spends Anthropic credits, so it's
      // origin-locked + per-IP rate limited (see SETUP.md).
      if (url.pathname === "/recipe/extract" && request.method === "POST") {
        const origin = request.headers.get("Origin") || "";
        const ip = request.headers.get("CF-Connecting-IP") || "anon";
        const rlKey = "rl:recipe:" + ip;
        const count = parseInt((await env.REMINDERS.get(rlKey)) || "0", 10);
        if (count >= 30) return corsFor(json({ error: "rate_limited" }, 429), origin);
        await env.REMINDERS.put(rlKey, String(count + 1), { expirationTtl: 3600 });

        const body = await request.json().catch(() => ({}));
        const parsed = parseRecipeUrl(body.url || "");
        if (!parsed) return corsFor(json({ error: "unsupported_url" }, 400), origin);

        const meta = await fetchPlatformMeta(parsed);
        const draft = await structureRecipe(meta, env);
        return corsFor(json({
          platform: parsed.platform,
          embedId: parsed.id || null,
          canonicalUrl: parsed.canonicalUrl,
          title: draft.title || meta.title || "",
          author: meta.author || "",
          thumbnail: meta.thumbnail || "",
          ingredients: draft.ingredients || [],
          steps: draft.steps || [],
          macros: draft.macros || null,
          tags: draft.tags || [],
          extractionSource: meta.source,
          extractionQuality: draft._quality || "empty",
        }), origin);
      }

      if (url.pathname.startsWith("/wearable/")) return wearables(request, env, url.pathname);
      if (url.pathname.startsWith("/account/")) return account(request, env, url.pathname);
      if (url.pathname.startsWith("/food/")) return food(request, env, url.pathname);

      if (url.pathname === "/" ) return cors(json({ ok: true, service: "summerbody-reminders" }));
      return cors(json({ error: "not found" }, 404));
    } catch (e) {
      return cors(json({ error: String(e && e.message || e) }, 500));
    }
  },

  // Cron — runs every 5 min. Send any reminder whose time just passed.
  async scheduled(event, env, ctx) {
    ctx.waitUntil(runReminders(env));
  },
};

async function runReminders(env) {
  const now = new Date();
  const dateKey = now.toISOString().slice(0, 10); // yyyy-mm-dd (UTC)
  const list = await env.REMINDERS.list({ prefix: "sub:" });

  for (const key of list.keys) {
    const raw = await env.REMINDERS.get(key.name);
    if (!raw) continue;
    const rec = JSON.parse(raw);
    const sched = rec.schedule || {};

    for (const type of ["protein", "creatine"]) {
      if (!sched[type]) continue;
      if (!inWindow(sched[type], now, WINDOW_MIN)) continue;

      const sentKey = "sent:" + dateKey + ":" + type + ":" + rec.subscription.endpoint;
      if (await env.REMINDERS.get(sentKey)) continue; // already sent today

      const status = await sendPush(rec.subscription, env);
      if (status === 404 || status === 410) {
        await env.REMINDERS.delete(key.name); // subscription gone
      } else {
        await env.REMINDERS.put(sentKey, "1", { expirationTtl: 60 * 60 * 26 });
      }
    }
  }
}

// ---- schedule helpers ----
function toMinutes(hhmm) {
  const m = /^(\d{1,2}):(\d{2})$/.exec(hhmm);
  if (!m) return null;
  return parseInt(m[1], 10) * 60 + parseInt(m[2], 10);
}
function nowMinutesUTC(d) { return d.getUTCHours() * 60 + d.getUTCMinutes(); }
function inWindow(hhmm, d, windowMin) {
  const t = toMinutes(hhmm);
  if (t == null) return false;
  const diff = nowMinutesUTC(d) - t;
  return diff >= 0 && diff < windowMin;
}
function whichDue(sched, d, windowMin) {
  for (const type of ["protein", "creatine"]) {
    if (sched && sched[type] && inWindow(sched[type], d, windowMin)) return type;
  }
  return null;
}

// ---- Web Push (empty payload, VAPID only) ----
async function sendPush(subscription, env) {
  const endpoint = subscription.endpoint;
  const aud = new URL(endpoint).origin;
  const jwt = await vapidJwt(aud, env.VAPID_SUBJECT, env.VAPID_PRIVATE_JWK);
  const res = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Authorization": "vapid t=" + jwt + ", k=" + env.VAPID_PUBLIC_KEY,
      "TTL": "86400",
      "Content-Length": "0",
    },
  });
  return res.status;
}

const enc = new TextEncoder();
function b64url(buf) {
  let s = "";
  const bytes = new Uint8Array(buf);
  for (let i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function b64urlStr(str) { return b64url(enc.encode(str)); }

async function vapidJwt(aud, subject, privateJwkStr) {
  const jwk = typeof privateJwkStr === "string" ? JSON.parse(privateJwkStr) : privateJwkStr;
  const key = await crypto.subtle.importKey(
    "jwk", jwk, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]
  );
  const header = b64urlStr(JSON.stringify({ typ: "JWT", alg: "ES256" }));
  const payload = b64urlStr(JSON.stringify({
    aud,
    exp: Math.floor(Date.now() / 1000) + 12 * 60 * 60,
    sub: subject || "mailto:admin@example.com",
  }));
  const data = header + "." + payload;
  const sig = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, enc.encode(data));
  return data + "." + b64url(sig);
}

// ───────────────────────────────────────────────────────────────────
// Recipe extraction helpers
// ───────────────────────────────────────────────────────────────────

// Normalise a pasted URL into { platform, id, canonicalUrl, shortUrl? }.
function parseRecipeUrl(raw) {
  let u;
  try { u = new URL(String(raw).trim()); } catch { return null; }
  const host = u.hostname.replace(/^www\./, "").toLowerCase();
  const path = u.pathname;

  // YouTube
  if (host === "youtu.be") {
    const id = path.slice(1).split("/")[0];
    return id ? { platform: "youtube", id, canonicalUrl: "https://www.youtube.com/watch?v=" + id } : null;
  }
  if (host.endsWith("youtube.com")) {
    if (path.startsWith("/shorts/")) {
      const id = path.split("/")[2];
      return id ? { platform: "youtube", id, canonicalUrl: "https://www.youtube.com/watch?v=" + id } : null;
    }
    const id = u.searchParams.get("v");
    return id ? { platform: "youtube", id, canonicalUrl: "https://www.youtube.com/watch?v=" + id } : null;
  }

  // TikTok
  if (host === "vm.tiktok.com" || host === "vt.tiktok.com") {
    return { platform: "tiktok", id: null, shortUrl: u.href, canonicalUrl: u.href };
  }
  if (host.endsWith("tiktok.com")) {
    const m = path.match(/\/video\/(\d+)/) || path.match(/\/photo\/(\d+)/);
    const id = m ? m[1] : null;
    return { platform: "tiktok", id, canonicalUrl: id ? "https://www.tiktok.com" + path.split("?")[0] : u.href };
  }

  // Instagram
  if (host.endsWith("instagram.com")) {
    const m = path.match(/\/(reel|reels|p|tv)\/([A-Za-z0-9_-]+)/);
    if (!m) return null;
    const kind = m[1] === "reels" ? "reel" : m[1];
    return { platform: "instagram", id: m[2], canonicalUrl: "https://www.instagram.com/" + kind + "/" + m[2] + "/" };
  }

  return null;
}

// Best-effort caption/metadata fetch per platform. Never throws fatally.
async function fetchPlatformMeta(p) {
  try {
    if (p.platform === "tiktok") return await fetchTikTok(p);
    if (p.platform === "youtube") return await fetchYouTube(p);
    if (p.platform === "instagram") return await fetchInstagram(p);
  } catch (_) {}
  return { title: "", author: "", thumbnail: "", caption: "", source: p.platform + "-error" };
}

async function fetchTikTok(p) {
  const target = p.shortUrl || p.canonicalUrl;
  const r = await fetch("https://www.tiktok.com/oembed?url=" + encodeURIComponent(target));
  if (!r.ok) return { title: "", author: "", thumbnail: "", caption: "", source: "tiktok-oembed-fail" };
  const d = await r.json();
  if (!p.id && d.embed_product_id) p.id = d.embed_product_id;          // recover id from short link
  return {
    title: d.title || "",
    author: d.author_name || "",
    thumbnail: d.thumbnail_url || "",
    caption: d.title || "",            // TikTok puts the whole caption in title
    source: "tiktok-oembed",
  };
}

async function fetchYouTube(p) {
  const o = await fetch("https://www.youtube.com/oembed?format=json&url=" + encodeURIComponent(p.canonicalUrl))
    .then(r => r.ok ? r.json() : null).catch(() => null);
  let description = "";
  try {
    const html = await fetch(p.canonicalUrl, { headers: { "User-Agent": UA } }).then(r => r.text());
    const m = html.match(/"shortDescription":"((?:\\.|[^"\\])*)"/);
    if (m) description = JSON.parse('"' + m[1] + '"');
    else {
      const og = html.match(/<meta name="description" content="([^"]*)"/);
      if (og) description = decodeHtml(og[1]);
    }
  } catch (_) {}
  return {
    title: (o && o.title) || "",
    author: (o && o.author_name) || "",
    thumbnail: (o && o.thumbnail_url) || ("https://i.ytimg.com/vi/" + p.id + "/hqdefault.jpg"),
    caption: [o && o.title, description].filter(Boolean).join("\n\n"),
    source: description ? "youtube-page" : "youtube-oembed",
  };
}

async function fetchInstagram(p) {
  let title = "", thumbnail = "", caption = "";
  try {
    const html = await fetch(p.canonicalUrl, { headers: { "User-Agent": UA } }).then(r => r.text());
    const ogD = html.match(/<meta property="og:description" content="([^"]*)"/);
    const ogI = html.match(/<meta property="og:image" content="([^"]*)"/);
    const ogT = html.match(/<meta property="og:title" content="([^"]*)"/);
    if (ogD) caption = decodeHtml(ogD[1]);
    if (ogI) thumbnail = ogI[1];
    if (ogT) title = decodeHtml(ogT[1]);
  } catch (_) {}
  return { title, thumbnail, caption, author: "", source: caption ? "instagram-og" : "instagram-none" };
}

const UA = "Mozilla/5.0 (compatible; SummerBodyBot/1.0)";

function decodeHtml(s) {
  return String(s)
    .replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"').replace(/&#0?39;/g, "'").replace(/&#x27;/gi, "'")
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(parseInt(n, 10)));
}

// Turn a caption into a structured recipe with Claude Haiku. Always returns a
// valid (possibly empty) draft so the client can show an editable form.
async function structureRecipe(meta, env) {
  const empty = { title: meta.title || "", ingredients: [], steps: [], macros: null, tags: [], _quality: "empty" };
  const text = (meta.caption || meta.title || "").trim();
  if (!text || !env.ANTHROPIC_API_KEY) return empty;

  const system =
    "You convert a social-media food video caption into a structured recipe. " +
    "Return ONLY a JSON object, no prose, no markdown fences. Schema: " +
    '{"title":string,"ingredients":[string],"steps":[string],' +
    '"macros":{"p":number,"c":number,"f":number,"kcal":number}|null,"tags":[string]}. ' +
    "Rules: ingredients are short lines like '180g chicken breast'. steps are imperative sentences. " +
    "Only include macros if the caption states them or they are trivially derivable; otherwise null. " +
    "If the caption has no real recipe, return empty arrays and your best-guess title. Do not invent steps.";

  try {
    const r = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5",
        max_tokens: 1024,
        system,
        messages: [{ role: "user", content: "Caption:\n" + text.slice(0, 6000) }],
      }),
    });
    if (!r.ok) return empty;
    const data = await r.json();
    let rawText = ((data.content && data.content[0] && data.content[0].text) || "").trim();
    rawText = rawText.replace(/^```(?:json)?/i, "").replace(/```$/, "").trim();
    const obj = JSON.parse(rawText);

    const out = {
      title: typeof obj.title === "string" ? obj.title : (meta.title || ""),
      ingredients: Array.isArray(obj.ingredients) ? obj.ingredients.filter(s => typeof s === "string").slice(0, 40) : [],
      steps: Array.isArray(obj.steps) ? obj.steps.filter(s => typeof s === "string").slice(0, 40) : [],
      macros: obj.macros && typeof obj.macros === "object"
        ? { p: +obj.macros.p || 0, c: +obj.macros.c || 0, f: +obj.macros.f || 0, kcal: +obj.macros.kcal || 0 }
        : null,
      tags: Array.isArray(obj.tags) ? obj.tags.filter(s => typeof s === "string").slice(0, 8) : [],
    };
    out._quality = (out.ingredients.length || out.steps.length) ? "good" : "partial";
    return out;
  } catch (_) {
    return empty;
  }
}

// ---- http helpers ----
function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { "Content-Type": "application/json" } });
}
function cors(res) {
  res.headers.set("Access-Control-Allow-Origin", "*");
  res.headers.set("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  // Authorization needed for the Bearer-auth routes (/account/*, /wearable/*/sync).
  res.headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  return res;
}

// Stricter CORS for credit-spending endpoints: only echo known origins.
const ALLOWED_ORIGINS = new Set([
  "https://reetwell.github.io",
  "http://localhost:8753",
  "http://localhost",
]);
function corsFor(res, origin) {
  const allow = ALLOWED_ORIGINS.has(origin) ? origin : "https://reetwell.github.io";
  res.headers.set("Access-Control-Allow-Origin", allow);
  res.headers.set("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.headers.set("Access-Control-Allow-Headers", "Content-Type");
  res.headers.set("Vary", "Origin");
  return res;
}
