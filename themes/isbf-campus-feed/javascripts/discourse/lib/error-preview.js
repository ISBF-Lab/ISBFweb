export function errorPreview(params, { development }) {
  if (!development) {
    return;
  }

  const scenarios = {
    403: { status: 403, requestedUrl: "/admin/users/1.json" },
    500: { status: 500, requestedUrl: "/preview/server.json" },
    503: { status: 503, requestedUrl: "/preview/unavailable.json" },
    network: {
      status: 0,
      readyState: 0,
      requestedUrl: "/preview/network.json",
    },
    timeout: {
      status: 0,
      jqTextStatus: "timeout",
      requestedUrl: "/preview/timeout.json",
    },
    unknown: { requestedUrl: "/preview/unknown.json" },
  };
  const code = params.get("preview_error");
  if (!Object.hasOwn(scenarios, code)) {
    return;
  }

  const scheme = params.get("preview_scheme");
  return {
    error: scenarios[code],
    scheme: ["light", "dark"].includes(scheme) ? scheme : null,
  };
}
