import getURL from "discourse/lib/get-url";
import { isLearningComposer } from "./learning-composer";
import { isMarketplaceComposer } from "./marketplace";

const nativeEndpoints = new WeakMap();

export function configurePrivateUploadEndpoint(uppy, composer) {
  const learning = isLearningComposer(composer);
  const marketplace = isMarketplaceComposer(composer);
  const uploader = uppy.getPlugin("XHRUpload");
  if (!uploader) {
    if (learning || marketplace) {
      throw new Error("私有上传需要登录后的文件传输。");
    }
    return;
  }
  // Both feature processors use one original endpoint, regardless of their order.
  if (!nativeEndpoints.has(uploader)) {
    nativeEndpoints.set(uploader, uploader.opts.endpoint);
  }
  uploader.setOptions({
    endpoint: learning
      ? getURL("/isbf/learning/uploads.json")
      : marketplace
        ? getURL("/isbf/marketplace/uploads.json")
        : nativeEndpoints.get(uploader),
  });
  if (learning && !composer.isbf_learning_course_id) {
    throw new Error("请先选择课程，再上传资料。");
  }
}
