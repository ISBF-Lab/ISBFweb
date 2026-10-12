import FlagModal from "discourse/components/modal/flag";
import PostFlag from "discourse/lib/flag-targets/post-flag";
import ISBFFlagModal from "../components/isbf-flag-modal";
import { invalidateCookedPost } from "./feed-post-loader";

const hiddenPosts = new Set();
const reportedModels = new Map();

export function isReportedHidden(postId) {
  return hiddenPosts.has(Number(postId));
}

export function rememberHiddenPost(
  postId,
  appEvents,
  hidden = true,
  severePending
) {
  const id = Number(postId);
  if (!Number.isInteger(id) || id <= 0) {
    return;
  }
  if (hidden) {
    hiddenPosts.add(id);
  } else {
    hiddenPosts.delete(id);
  }
  invalidateCookedPost(id, hidden);
  reportedModels.get(id)?.setProperties({
    cooked: "",
    hidden,
    ...(!hidden || typeof severePending === "boolean"
      ? { isbf_severe_report_pending: hidden && severePending === true }
      : {}),
  });
  appEvents.trigger("isbf:post-hidden", id, hidden);
}

export function severeReportAvailable(post, siteSettings, site) {
  return Boolean(
    (site?.isbf_severe_reports_enabled ??
      siteSettings?.isbf_severe_reports_enabled) === true &&
    post.isbf_can_severe_report &&
    !post.isbf_severe_report_pending &&
    !post.hidden &&
    post.post_type === 1 &&
    post.topic?.archetype !== "private_message"
  );
}

export function openPostReport({ post, modal, siteSettings, site, appEvents }) {
  reportedModels.set(Number(post.id), post);
  return modal.show(
    post.post_type === 1 && post.topic?.archetype !== "private_message"
      ? ISBFFlagModal
      : FlagModal,
    {
      model: {
        canSevereReport: () => severeReportAvailable(post, siteSettings, site),
        flagTarget: new PostFlag(),
        flagModel: post,
        setHidden: () => {
          post.set("hidden", true);
          rememberHiddenPost(post.id, appEvents);
        },
      },
    }
  );
}
