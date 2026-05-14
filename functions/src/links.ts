import * as crypto from "crypto";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import type { Request } from "firebase-functions/v2/https";
import {
  REGION,
  CUSTOM_SCHEME,
  DEEP_LINK_HOST,
  APP_STORE_ID,
  PLAY_STORE_PACKAGE,
} from "./config";

interface LinkData {
  path: string;
  params?: Record<string, string>;
  title?: string;
  description?: string;
  imageUrl?: string;
}

function generateCode(length = 8): string {
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  const bytes = crypto.randomBytes(length);
  return Array.from(bytes)
    .map((b) => chars[b % chars.length])
    .join("");
}

function getClientIp(req: Request): string {
  const forwarded = req.headers["x-forwarded-for"];
  if (typeof forwarded === "string") return forwarded.split(",")[0].trim();
  return req.ip ?? "";
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function buildRedirectHtml(opts: {
  title: string;
  description: string;
  imageUrl: string;
  customSchemeUrl: string;
  appStoreUrl: string;
  playStoreUrl: string;
}): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>${escapeHtml(opts.title)}</title>
  <meta name="description" content="${escapeHtml(opts.description)}">
  <meta property="og:title" content="${escapeHtml(opts.title)}">
  <meta property="og:description" content="${escapeHtml(opts.description)}">
  ${opts.imageUrl ? `<meta property="og:image" content="${escapeHtml(opts.imageUrl)}">` : ""}
  <style>
    body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
         display:flex;flex-direction:column;align-items:center;
         justify-content:center;min-height:100vh;margin:0;background:#f5f5f5}
    .card{background:#fff;border-radius:16px;padding:32px;max-width:360px;
          width:90%;text-align:center;box-shadow:0 2px 16px rgba(0,0,0,.08)}
    h1{font-size:20px;margin:0 0 8px}
    p{color:#666;font-size:14px;margin:0 0 24px}
    a{display:block;padding:14px;border-radius:12px;text-decoration:none;
      font-weight:600;font-size:15px;margin-bottom:12px}
    .primary{background:#000;color:#fff}
    .secondary{background:#f0f0f0;color:#333}
  </style>
</head>
<body>
  <div class="card">
    <h1>${escapeHtml(opts.title)}</h1>
    ${opts.description ? `<p>${escapeHtml(opts.description)}</p>` : ""}
    <a class="primary" href="${escapeHtml(opts.appStoreUrl)}">Download on App Store</a>
    <a class="secondary" href="${escapeHtml(opts.playStoreUrl)}">Get it on Google Play</a>
  </div>
  <script>
  (function(){
    var ua=navigator.userAgent;
    var isIOS=/iPhone|iPad|iPod/.test(ua);
    var isAndroid=/Android/.test(ua);
    if(!isIOS&&!isAndroid)return;
    var fallback=setTimeout(function(){
      window.location.href=isIOS?"${escapeHtml(opts.appStoreUrl)}":"${escapeHtml(opts.playStoreUrl)}";
    },1600);
    window.addEventListener("blur",function(){clearTimeout(fallback)});
    document.addEventListener("visibilitychange",function(){
      if(document.hidden)clearTimeout(fallback);
    });
    window.location.href="${escapeHtml(opts.customSchemeUrl)}";
  })();
  </script>
</body>
</html>`;
}

// ── Callable: create a short link ─────────────────────────────────────────────

export const createShortLink = onCall<
  LinkData,
  Promise<{ shortUrl: string; code: string }>
>({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in to create links.");
  }
  const db = getFirestore();
  let code = generateCode();
  // Collision is astronomically rare with 8 chars but guard anyway.
  for (let i = 0; i < 3; i++) {
    if (!(await db.collection("deep_links").doc(code).get()).exists) break;
    code = generateCode();
  }
  await db.collection("deep_links").doc(code).set({
    path: request.data.path,
    params: request.data.params ?? {},
    title: request.data.title ?? "",
    description: request.data.description ?? "",
    imageUrl: request.data.imageUrl ?? "",
    createdAt: Timestamp.now(),
    creatorUid: request.auth.uid,
  });
  const host = DEEP_LINK_HOST.value();
  return { shortUrl: `https://${host}/l/${code}`, code };
});

// ── Callable: resolve a code or claim a deferred link ────────────────────────

export const getLink = onCall<
  { code?: string; isFirstOpen?: boolean },
  Promise<{ path: string; params: Record<string, string> } | null>
>({ region: REGION }, async (request) => {
  const db = getFirestore();
  const { code, isFirstOpen } = request.data;

  if (code) {
    const doc = await db.collection("deep_links").doc(code).get();
    if (!doc.exists) return null;
    const d = doc.data()!;
    return { path: d.path as string, params: (d.params ?? {}) as Record<string, string> };
  }

  if (isFirstOpen) {
    const ip = getClientIp(request.rawRequest);
    if (!ip) return null;
    const tenMinAgo = Timestamp.fromMillis(Date.now() - 10 * 60 * 1000);
    const snap = await db
      .collection("link_clicks")
      .where("ip", "==", ip)
      .where("claimed", "==", false)
      .where("clickedAt", ">=", tenMinAgo)
      .orderBy("clickedAt", "desc")
      .limit(1)
      .get();
    if (snap.empty) return null;
    const click = snap.docs[0];
    await click.ref.update({ claimed: true, claimedAt: Timestamp.now() });
    const linkDoc = await db.collection("deep_links").doc(click.data().code).get();
    if (!linkDoc.exists) return null;
    const d = linkDoc.data()!;
    return { path: d.path as string, params: (d.params ?? {}) as Record<string, string> };
  }

  return null;
});

// ── HTTP: redirect page (called via Firebase Hosting rewrite at /l/*) ────────

export const openLink = onRequest({ cors: false, region: REGION }, async (req, res) => {
  // Path is /l/<code> when called via Hosting rewrite.
  // Query param ?code= is the fallback for direct function invocation.
  const code =
    (req.query["code"] as string | undefined) ||
    req.path.replace(/^\/+l\/+/, "").replace(/\/+$/, "");

  if (!code) {
    res.status(400).send("Missing link code");
    return;
  }

  const db = getFirestore();
  const doc = await db.collection("deep_links").doc(code).get();

  const scheme = CUSTOM_SCHEME.value();
  const appStoreId = APP_STORE_ID.value();
  const playPkg = PLAY_STORE_PACKAGE.value();

  let title = "Open App";
  let description = "";
  let imageUrl = "";

  if (doc.exists) {
    const d = doc.data()!;
    title = (d.title as string) || title;
    description = (d.description as string) || "";
    imageUrl = (d.imageUrl as string) || "";
    // Record the click for deferred deep-link matching.
    await db.collection("link_clicks").add({
      code,
      ip: getClientIp(req),
      userAgent: req.headers["user-agent"] ?? "",
      clickedAt: Timestamp.now(),
      claimed: false,
    });
  }

  const customSchemeUrl = `${scheme}://l/${code}`;
  const appStoreUrl = appStoreId
    ? `https://apps.apple.com/app/id${appStoreId}`
    : "https://apple.com";
  const playStoreUrl = playPkg
    ? `https://play.google.com/store/apps/details?id=${playPkg}`
    : "https://play.google.com";

  // Universal Links / App Links hit the app directly — this page only shows
  // when the app is not installed or the OS falls through to the browser.
  res.set("Cache-Control", "no-store");
  res.send(
    buildRedirectHtml({ title, description, imageUrl, customSchemeUrl, appStoreUrl, playStoreUrl })
  );
});
