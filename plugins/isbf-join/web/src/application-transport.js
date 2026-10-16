export async function submitApplication(
  fields,
  { signal, endpoint = "/api/applications" } = {}
) {
  const csrfResponse = await fetch("/session/csrf.json", {
    credentials: "same-origin",
    headers: { "X-Requested-With": "XMLHttpRequest" },
    signal,
  });
  const token = await csrfResponse.json().catch((failure) => {
    if (failure.name === "AbortError") {
      throw failure;
    }
    return null;
  });
  if (!csrfResponse.ok || typeof token?.csrf !== "string" || !token.csrf) {
    throw new Error(
      "暂时无法提交，请稍后重试。您也可以先将简历发送至以上邮箱。"
    );
  }
  return fetch(endpoint, {
    method: "POST",
    credentials: "same-origin",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": token.csrf,
      "X-Requested-With": "XMLHttpRequest",
    },
    body: JSON.stringify(fields),
    signal,
  });
}
