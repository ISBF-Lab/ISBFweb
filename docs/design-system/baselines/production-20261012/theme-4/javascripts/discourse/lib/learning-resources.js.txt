export function learningConfig(site) {
  const config = site?.isbf_learning;
  return Number.isSafeInteger(config?.category_id) &&
    config.category_id > 0 &&
    Array.isArray(config.grades) &&
    [1, 2, 3, 4].every((id) =>
      config.grades.some(
        (grade) => grade.id === id && typeof grade.label === "string",
      ),
    )
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

export function learningEditDetails(topic, post, courseId) {
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
    post.isbf_learning_course_id !== courseId ||
    !Array.isArray(post.isbf_learning_files) ||
    post.isbf_learning_files.length !== 0 ||
    typeof post.isbf_learning_link !== "string" ||
    !post.isbf_learning_link.trim() ||
    (post.isbf_learning_description != null &&
      typeof post.isbf_learning_description !== "string") ||
    (post.isbf_learning_contributor != null &&
      typeof post.isbf_learning_contributor !== "string")
  ) {
    return null;
  }
  return {
    postId: post.id,
    topicId: topic.id,
    title: topic.title,
    raw: post.raw,
    link: post.isbf_learning_link,
    description: post.isbf_learning_description ?? "",
    contributor:
      post.isbf_learning_contributor?.trim() ||
      post.name ||
      post.username ||
      "",
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
