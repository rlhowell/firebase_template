import { defineString } from "firebase-functions/params";

export const REGION = defineString("FUNCTIONS_REGION", { default: "europe-west2" });
export const DEEP_LINK_HOST = defineString("DEEP_LINK_HOST", { default: "" });
export const CUSTOM_SCHEME = defineString("CUSTOM_SCHEME", { default: "yourapp" });
export const APP_STORE_ID = defineString("APP_STORE_ID", { default: "" });
export const PLAY_STORE_PACKAGE = defineString("PLAY_STORE_PACKAGE", { default: "" });
export const APPLE_TEAM_ID = defineString("APPLE_TEAM_ID", { default: "" });
export const IOS_BUNDLE_ID = defineString("IOS_BUNDLE_ID", { default: "" });
export const ANDROID_PACKAGE = defineString("ANDROID_PACKAGE", { default: "" });
export const ANDROID_SHA256_CERT = defineString("ANDROID_SHA256_CERT", { default: "" });
