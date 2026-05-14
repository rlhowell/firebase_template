import { onRequest } from "firebase-functions/v2/https";
import {
  REGION,
  APPLE_TEAM_ID,
  IOS_BUNDLE_ID,
  ANDROID_PACKAGE,
  ANDROID_SHA256_CERT,
} from "./config";

export const appleAppSiteAssociation = onRequest({ region: REGION }, (req, res) => {
  const teamId = APPLE_TEAM_ID.value();
  const bundleId = IOS_BUNDLE_ID.value();
  if (!teamId || !bundleId) {
    res.status(404).send("Not configured");
    return;
  }
  res.set("Content-Type", "application/json");
  res.set("Cache-Control", "public, max-age=3600");
  res.json({
    applinks: {
      apps: [],
      details: [{ appID: `${teamId}.${bundleId}`, paths: ["/l/*"] }],
    },
  });
});

export const assetLinks = onRequest({ region: REGION }, (req, res) => {
  const pkg = ANDROID_PACKAGE.value();
  const sha256 = ANDROID_SHA256_CERT.value();
  if (!pkg || !sha256) {
    res.status(404).send("Not configured");
    return;
  }
  res.set("Content-Type", "application/json");
  res.set("Cache-Control", "public, max-age=3600");
  res.json([
    {
      relation: ["delegate_permission/common.handle_all_urls"],
      target: {
        namespace: "android_app",
        package_name: pkg,
        sha256_cert_fingerprints: [sha256],
      },
    },
  ]);
});
