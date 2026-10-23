import { optionalRequire } from "discourse/lib/utilities";

function text(node) {
  const copy = node?.cloneNode(true);
  copy?.querySelectorAll("img.emoji").forEach((image) => {
    image.replaceWith(document.createTextNode(image.getAttribute("alt") || ""));
  });
  return copy?.textContent?.replace(/\s+/g, " ").trim() || "";
}

export function extractFeedPolls(html = "") {
  if (!html || !html.includes("data-poll-name")) {
    return { html, polls: [] };
  }
  const element = document.createElement("div");
  element.innerHTML = html;
  const polls = [];
  element.querySelectorAll(".poll[data-poll-name]").forEach((poll) => {
    if (poll.closest("aside.quote")) {
      return;
    }
    const options = [...poll.querySelectorAll("li[data-poll-option-id]")].map(
      (option) => ({
        id: option.getAttribute("data-poll-option-id"),
        label: text(option),
      })
    );
    polls.push({
      name: poll.getAttribute("data-poll-name"),
      title: text(poll.querySelector(".poll-title")),
      type: poll.getAttribute("data-poll-type") || "regular",
      options,
    });
    (poll.closest(".poll-outer") || poll).remove();
  });
  return { html: element.innerHTML, polls };
}

export function buildPollPreviews(descriptors, metadata = []) {
  return descriptors.map((descriptor) => {
    const poll = metadata?.find((item) => item.name === descriptor.name);
    const options = descriptor.options;
    const actual = poll?.options || [];
    const voters = poll?.voters;
    // Votes are omitted by the native serializer when this viewer cannot see results.
    const visible =
      actual.length === options.length &&
      actual.length > 0 &&
      options.every((option) =>
        actual.some(
          (item) =>
            item.id === option.id &&
            Number.isFinite(item.votes) &&
            item.votes >= 0
        )
      ) &&
      Number.isFinite(voters) &&
      voters >= 0;
    const type = poll?.type || descriptor.type;
    const percentages = new Map();
    const round = optionalRequire("discourse/plugins/poll/lib/even-round");
    if (visible && ["regular", "multiple", "number"].includes(type) && round) {
      const ordered = [...actual].sort(
        (a, b) => b.votes - a.votes || (a.html < b.html ? -1 : 1)
      );
      const values = ordered.map((option) =>
        voters ? (100 * option.votes) / voters : 0
      );
      const rounded =
        voters === 0
          ? values
          : type === "multiple"
            ? values.map(Math.floor)
            : round(values);
      ordered.forEach((option, index) =>
        percentages.set(option.id, rounded[index])
      );
    }
    return {
      name: descriptor.name,
      title: descriptor.title,
      type,
      voters: visible ? voters : null,
      closed: poll?.status === "closed",
      remaining: Math.max(0, options.length - 3),
      options: options.slice(0, 3).map((option) => ({
        ...option,
        percentage: percentages.has(option.id)
          ? percentages.get(option.id)
          : null,
      })),
    };
  });
}
