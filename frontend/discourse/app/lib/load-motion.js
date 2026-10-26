import { waitForPromise } from "@ember/test-waiters";

/** @returns {Promise<typeof import("motion")>} */
export default async function loadMotion() {
  return await waitForPromise(import("motion"));
}
