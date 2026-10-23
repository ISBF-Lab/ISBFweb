export function learningConfig(site) {
  const config = site?.isbf_learning;
  return Number.isSafeInteger(config?.category_id) &&
    config.category_id > 0 &&
    Array.isArray(config.grades) &&
    config.grades.every(
      (grade) =>
        Number.isSafeInteger(grade?.id) &&
        grade.id >= 1 &&
        typeof grade.label === "string"
    ) &&
    new Set(config.grades.map((grade) => grade.id)).size ===
      config.grades.length
    ? config
    : null;
}

export function learningResourceQuery(courseId, query, page = 0) {
  return query.trim()
    ? { q: query.trim(), page }
    : { course_id: courseId, page };
}

export function learningFileSize(bytes) {
  const size = Number(bytes);
  if (!Number.isFinite(size) || size < 0) {
    return "";
  }
  return size >= 1048576
    ? `${(size / 1048576).toFixed(1)} MB`
    : `${Math.ceil(size / 1024)} KB`;
}

export function learningSafeUrl(value) {
  if (typeof value !== "string" || /[\\\u0000-\u0020]/.test(value)) {
    return null;
  }
  return /^(https?:\/\/|\/(?!\/))/i.test(value) ? value : null;
}

export function learningEditableResource(resource) {
  return (
    Number.isSafeInteger(resource?.id) &&
    resource.id > 0 &&
    resource.link_only === true &&
    Array.isArray(resource.files) &&
    resource.files.length === 0
  );
}

export function learningEditDetails(
  topic,
  post,
  courseId,
  prefix = "isbf_learning"
) {
  const firstPost = Array.isArray(topic?.post_stream?.posts)
    ? topic.post_stream.posts.find((entry) => entry.post_number === 1)
    : null;
  if (
    !Number.isSafeInteger(topic?.id) ||
    topic.id <= 0 ||
    !Number.isSafeInteger(firstPost?.id) ||
    post?.id !== firstPost.id ||
    post.topic_id !== topic.id ||
    post.post_number !== 1 ||
    post.can_edit !== true ||
    typeof topic.title !== "string" ||
    typeof post.raw !== "string" ||
    !courseId ||
    post[
      `${prefix}_${prefix === "isbf_library" ? "group_id" : "course_id"}`
    ] !== courseId ||
    !Array.isArray(post[`${prefix}_files`]) ||
    post[`${prefix}_files`].length !== 0 ||
    typeof post[`${prefix}_link`] !== "string" ||
    !post[`${prefix}_link`].trim() ||
    (post[`${prefix}_description`] != null &&
      typeof post[`${prefix}_description`] !== "string") ||
    (post[`${prefix}_contributor`] != null &&
      typeof post[`${prefix}_contributor`] !== "string")
  ) {
    return null;
  }
  return {
    postId: post.id,
    topicId: topic.id,
    title: topic.title,
    raw: post.raw,
    link: post[`${prefix}_link`],
    description: post[`${prefix}_description`] ?? "",
    contributor:
      post[`${prefix}_contributor`]?.trim() || post.name || post.username || "",
  };
}

export function learningLinkBody(title, link, description = "") {
  const escapeHTML = (value) =>
    value.replace(/[&<>"']/g, (character) => {
      return {
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;",
      }[character];
    });
  const label = escapeHTML(title).replace(/[\\\[\]]/g, "\\$&");
  const body = `[${label}](<${link}>)`;
  const introduction = description.replace(/\r\n?/g, "\n").trim();
  return introduction
    ? `${body}\n\n${escapeHTML(introduction.replace(/[\\`*_{}\[\]()#+.!|~:\/-]/g, "\\$&"))}`
    : body;
}

export function libraryConfig(site) {
  const config = site?.isbf_library;
  return Number.isSafeInteger(config?.category_id) &&
    config.category_id > 0 &&
    config.category_id !== site?.isbf_learning?.category_id &&
    config.link_sharing === true &&
    config.catalog_requests === true
    ? config
    : null;
}
