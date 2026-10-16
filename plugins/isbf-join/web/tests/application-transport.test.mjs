import assert from "node:assert/strict";
import test from "node:test";
import { submitApplication } from "../src/application-transport.js";

const fields = {
  name: "申请人",
  studentId: "2026101401",
  phone: "+86 138-0013-8000",
  submissionId: "491e9a65-3270-4acd-8ba9-dc726a6a0307",
};
const submissionError =
  "暂时无法提交，请稍后重试。您也可以先将简历发送至以上邮箱。";

test("gets a session CSRF token before posting the unchanged contact fields", async (context) => {
  const signal = new AbortController().signal;
  const saved = new Response(
    JSON.stringify({ ok: true, id: fields.submissionId }),
    { status: 201 }
  );
  const fetch = context.mock.method(globalThis, "fetch", async (url) =>
    url === "/session/csrf.json"
      ? new Response(JSON.stringify({ csrf: "session-token" }))
      : saved
  );

  assert.equal(await submitApplication(fields, { signal }), saved);
  assert.equal(fetch.mock.calls.length, 2);
  assert.deepEqual(fetch.mock.calls[0].arguments, [
    "/session/csrf.json",
    {
      credentials: "same-origin",
      headers: { "X-Requested-With": "XMLHttpRequest" },
      signal,
    },
  ]);
  assert.deepEqual(fetch.mock.calls[1].arguments, [
    "/api/applications",
    {
      method: "POST",
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": "session-token",
        "X-Requested-With": "XMLHttpRequest",
      },
      body: JSON.stringify(fields),
      signal,
    },
  ]);
});

test("uses the configured endpoint and returns an HTTP failure for the existing UI to handle", async (context) => {
  const conflict = new Response(JSON.stringify({ ok: false }), { status: 409 });
  const fetch = context.mock.method(globalThis, "fetch", async (url) =>
    url === "/session/csrf.json"
      ? new Response(JSON.stringify({ csrf: "session-token" }))
      : conflict
  );

  assert.equal(
    await submitApplication(fields, { endpoint: "/custom/applications" }),
    conflict
  );
  assert.equal(fetch.mock.calls[1].arguments[0], "/custom/applications");
  assert.equal(
    fetch.mock.calls.length,
    2,
    "HTTP failures are not silently retried"
  );
});

test("never submits when the CSRF endpoint fails or returns an unusable token", async (context) => {
  for (const [status, body] of [
    [403, { csrf: "token" }],
    [200, null],
    [200, {}],
    [200, { csrf: "" }],
    [200, { csrf: 123 }],
  ]) {
    const fetch = context.mock.method(
      globalThis,
      "fetch",
      async () => new Response(JSON.stringify(body), { status })
    );

    await assert.rejects(submitApplication(fields), {
      name: "Error",
      message: submissionError,
    });
    assert.equal(
      fetch.mock.calls.length,
      1,
      "only the CSRF request was attempted"
    );
    fetch.mock.restore();
  }
});

test("never submits after a CSRF network or JSON parsing failure", async (context) => {
  const fetch = context.mock.method(globalThis, "fetch", async () => {
    throw new TypeError("Network unavailable");
  });
  await assert.rejects(submitApplication(fields), /Network unavailable/);
  assert.equal(fetch.mock.calls.length, 1);

  fetch.mock.resetCalls();
  fetch.mock.mockImplementation(async () => new Response("invalid JSON"));
  await assert.rejects(submitApplication(fields), {
    name: "Error",
    message: submissionError,
  });
  assert.equal(fetch.mock.calls.length, 1);
});

test("cancelling the CSRF request never sends a submission", async (context) => {
  const controller = new AbortController();
  controller.abort();
  const fetch = context.mock.method(
    globalThis,
    "fetch",
    async (_url, { signal }) => {
      signal.throwIfAborted();
    }
  );

  await assert.rejects(
    submitApplication(fields, { signal: controller.signal }),
    { name: "AbortError" }
  );
  assert.equal(fetch.mock.calls.length, 1);

  fetch.mock.resetCalls();
  fetch.mock.mockImplementation(async () => ({
    ok: true,
    json: async () => {
      throw new DOMException("Cancelled while decoding", "AbortError");
    },
  }));
  await assert.rejects(submitApplication(fields), { name: "AbortError" });
  assert.equal(
    fetch.mock.calls.length,
    1,
    "cancelling token decoding never sends a POST"
  );
});

test("passes cancellation through to the submission request", async (context) => {
  const controller = new AbortController();
  const fetch = context.mock.method(
    globalThis,
    "fetch",
    async (url, { signal }) => {
      if (url === "/session/csrf.json") {
        return new Response(JSON.stringify({ csrf: "session-token" }));
      }
      controller.abort();
      signal.throwIfAborted();
    }
  );

  await assert.rejects(
    submitApplication(fields, { signal: controller.signal }),
    { name: "AbortError" }
  );
  assert.equal(
    fetch.mock.calls.length,
    2,
    "cancelling does not retry the POST"
  );
});
