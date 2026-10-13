import { UploadPreProcessorPlugin } from "discourse/lib/uppy-plugin-base";
import { configurePrivateUploadEndpoint } from "./private-upload-endpoint";

export default class MarketplaceUpload extends UploadPreProcessorPlugin {
  static pluginId = "isbf-marketplace-private-upload";

  #process;

  constructor(uppy, options) {
    super(uppy, options);
    this.#process = this.process.bind(this);
  }

  install() {
    this._install(this.#process);
  }

  uninstall() {
    this._uninstall(this.#process);
  }

  process(ids) {
    configurePrivateUploadEndpoint(
      this.uppy,
      this.opts.composerModel,
      this.opts.composerModel?.site,
    );
    return this._emitAllComplete(ids, true);
  }
}
