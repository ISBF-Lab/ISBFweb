export async function mountElasticStatus(root, options) {
  const { mountElasticStatus: mount } =
    await import("../../scripts/js/elastic-not-found.js");
  if (options.signal?.aborted || !root.isConnected) {
    return () => {};
  }
  return mount(root, options);
}
