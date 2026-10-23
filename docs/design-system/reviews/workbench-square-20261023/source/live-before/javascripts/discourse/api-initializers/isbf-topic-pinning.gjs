import { registerDestructor } from "@ember/destroyable";
import { apiInitializer } from "discourse/lib/api";
import {
  compareHomeTopics,
  isPinningContext,
  PinExpiryScheduler,
} from "../lib/pinning";

function methodDescriptor(prototype, name) {
  while (prototype) {
    const descriptor = Object.getOwnPropertyDescriptor(prototype, name);
    if (descriptor) {
      return descriptor;
    }
    prototype = Object.getPrototypeOf(prototype);
  }
}

export default apiInitializer((api) => {
  const router = api.container.lookup("service:router");
  const site = api.container.lookup("service:site");
  const siteSettings = api.container.lookup("service:site-settings");
  const appEvents = api.container.lookup("service:app-events");
  const scheduler = new PinExpiryScheduler({
    enabled: () => isPinningContext(router, site, siteSettings),
    onChange: () => appEvents.trigger("isbf:home-pins-changed"),
  });
  const topicListClass = api.container.factoryFor("model:topic-list").class;
  const originalMunge = topicListClass.munge;
  topicListClass.munge = function (json, ...args) {
    const result = originalMunge.call(this, json, ...args);
    result.isbfHomePinScope = json.topic_list?.isbf_home_pinning_scope === true;
    return result;
  };
  api.registerValueTransformer(
    "topic-list-topics-from",
    ({ value, context }) =>
      context.result.topic_list?.isbf_home_pinning_scope === true &&
      (!context.opts.listKey || context.opts.listKey === "topics")
        ? [...value].sort((left, right) => compareHomeTopics(left, right))
        : value,
  );
  for (const name of ["init", "loadBefore", "loadMore", "willDestroy"]) {
    const descriptor = methodDescriptor(topicListClass.prototype, name);
    if (!descriptor) {
      continue;
    }
    const invoke = (instance, args) => {
      const original = descriptor.get
        ? descriptor.get.call(instance)
        : descriptor.value;
      return original.apply(instance, args);
    };
    if (name === "loadBefore" || name === "loadMore") {
      api.addModelMethod("topic-list", name, async function (...args) {
        const result = await invoke(this, args);
        if (!this.isDestroying && !this.isDestroyed) {
          scheduler.register(this);
          scheduler.refresh();
        }
        return result;
      });
    } else {
      api.addModelMethod("topic-list", name, function (...args) {
        if (name === "willDestroy") {
          scheduler.remove(this);
        }
        const result = invoke(this, args);
        if (name === "init") {
          scheduler.register(this);
        }
        return result;
      });
    }
  }
  appEvents.on("isbf:home-pin-saved", scheduler, "refresh");
  router.on("routeDidChange", scheduler, "refresh");
  registerDestructor(router, () => {
    scheduler.destroy();
    appEvents.off("isbf:home-pin-saved", scheduler, "refresh");
    router.off("routeDidChange", scheduler, "refresh");
  });
});
