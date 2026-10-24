import { registerDestructor } from "@ember/destroyable";
import { cancel } from "@ember/runloop";
import { waitForPromise } from "@ember/test-waiters";
import { isTesting } from "discourse/lib/environment";
import discourseLater from "discourse/lib/later";
import { prefersReducedMotion } from "discourse/lib/utilities";

export default function waitForOtpFeedback(owner) {
  if (isTesting() || prefersReducedMotion()) {
    return Promise.resolve();
  }

  return waitForPromise(
    new Promise((resolve) => {
      const timer = discourseLater(resolve, 650);
      registerDestructor(owner, () => {
        cancel(timer);
        resolve();
      });
    })
  );
}
