import { initializeApp } from "firebase-admin/app";
initializeApp();

export { createShortLink, getLink, openLink } from "./links";
export { appleAppSiteAssociation, assetLinks } from "./well_known";
