import { waitForPromise } from "@ember/test-waiters";

export default async function loadMotion() {
  return await waitForPromise(import("motion"));
}
