/* SummerBody service worker — handles push reminders for protein & creatine.
   Pushes are sent with no encrypted payload (keeps the backend simple), so on
   receipt we ask the backend which reminder is due. If that lookup fails or the
   backend isn't configured yet, we still show a useful generic reminder — iOS
   requires every push to produce a visible notification. */

const BACKEND_URL = "https://summerbody.me-e29.workers.dev"; // Cloudflare Worker

self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (e) => e.waitUntil(self.clients.claim()));

self.addEventListener("push", (event) => {
  event.waitUntil(showReminder(event));
});

async function showReminder(event) {
  let title = "SummerBody";
  let body = "Time for your supplement — protein & creatine 💪";

  // If the push carried a payload, use it.
  try {
    if (event.data) {
      const d = event.data.json();
      if (d.title) title = d.title;
      if (d.body) body = d.body;
    }
  } catch (_) {}

  // Otherwise ask the backend what's due right now for this device.
  if (BACKEND_URL && !(event.data)) {
    try {
      const sub = await self.registration.pushManager.getSubscription();
      if (sub) {
        const res = await fetch(BACKEND_URL.replace(/\/$/, "") + "/due", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ endpoint: sub.endpoint }),
        });
        if (res.ok) {
          const d = await res.json();
          if (d && d.title) title = d.title;
          if (d && d.body) body = d.body;
        }
      }
    } catch (_) {}
  }

  return self.registration.showNotification(title, {
    body,
    icon: "icon-192.png",
    badge: "icon-192.png",
    tag: "summerbody-reminder",
    renotify: true,
    data: { url: "./" },
  });
}

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const url = (event.notification.data && event.notification.data.url) || "./";
  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((clients) => {
      for (const c of clients) {
        if ("focus" in c) return c.focus();
      }
      if (self.clients.openWindow) return self.clients.openWindow(url);
    })
  );
});
