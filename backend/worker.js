/* SummerBody reminders backend — Cloudflare Worker.
 *
 * Stores a device's push subscription + reminder schedule in KV, and on a cron
 * trigger sends Web Push notifications for protein and creatine at the chosen
 * times. Pushes are sent with no encrypted payload (only VAPID auth), so the
 * service worker asks /due which reminder to show. This keeps the crypto here
 * to just the VAPID JWT (ES256), which is simple and reliable.
 *
 * Required bindings (see backend/SETUP.md):
 *   KV namespace binding:  REMINDERS
 *   Secret:                VAPID_PRIVATE_JWK   (JSON string of the private JWK)
 *   Var:                   VAPID_PUBLIC_KEY    (base64url applicationServerKey)
 *   Var:                   VAPID_SUBJECT       (mailto:you@example.com)
 *
 * Cron trigger: every 5 minutes  (see SETUP.md for the exact expression)
 */

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
        return cors(json(due ? MESSAGES[due] : { title: "SummerBody", body: "Supplement reminder 💪" }));
      }

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

// ---- http helpers ----
function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { "Content-Type": "application/json" } });
}
function cors(res) {
  res.headers.set("Access-Control-Allow-Origin", "*");
  res.headers.set("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.headers.set("Access-Control-Allow-Headers", "Content-Type");
  return res;
}
