import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input, setComponentTemplate } from "@ember/component";
import { action } from "@ember/object";
import DButton from "discourse/ui-kit/d-button";
import DDatePicker from "discourse/ui-kit/d-date-picker";
import DModal from "discourse/ui-kit/d-modal";
import DModalCancel from "discourse/ui-kit/d-modal-cancel";
import { i18n } from "discourse-i18n";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class JumpToPost extends Component {
  static {
    g(this.prototype, "postNumber", [tracked]);
  }
  #postNumber = (i(this, "postNumber"), void 0);
  static {
    g(this.prototype, "postDate", [tracked]);
  }
  #postDate = (i(this, "postDate"), void 0);
  get filteredPostsCount() {
    return this.args.model.postCount ?? this.args.model.topic.postStream.filteredPostsCount;
  }
  jump() {
    if (this.postNumber) {
      this._jumpToIndex(this.filteredPostsCount, this.postNumber);
    } else if (this.postDate) {
      this._jumpToDate(this.postDate);
    }
  }
  static {
    n(this.prototype, "jump", [action]);
  }
  _jumpToIndex(postsCounts, postNumber) {
    const where = Math.min(postsCounts, Math.max(1, parseInt(postNumber, 10)));
    this.args.model.jumpToIndex(where);
    this.args.closeModal();
  }
  _jumpToDate(date) {
    this.args.model.jumpToDate(date);
    this.args.closeModal();
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="jump-to-post-modal"
      @closeModal={{@closeModal}}
      @title={{i18n "topic.progress.jump_prompt_long"}}
    >
      <:body>
        <div class="jump-to-post-form">
          <div class="jump-to-post-control">
            <span class="index">#</span>
            <Input
              autofocus="true"
              id="post-jump"
              @type="number"
              @value={{this.postNumber}}
            />
            <span class="input-hint-text post-number">
              {{i18n
                "topic.progress.jump_prompt_of"
                count=this.filteredPostsCount
              }}
            </span>
          </div>
    
          <div class="separator">
            <span class="text">
              {{i18n "topic.progress.jump_prompt_or"}}
            </span>
            <hr class="right" />
          </div>
    
          <div class="jump-to-date-control">
            <span class="input-hint-text post-date">
              {{i18n "topic.progress.jump_prompt_to_date"}}
            </span>
            <DDatePicker
              class="date-input"
              id="post-date"
              @defaultDate="YYYY-MM-DD"
              @value={{this.postDate}}
            />
          </div>
        </div>
      </:body>
    
      <:footer>
        <DButton
          class="btn-primary"
          type="submit"
          @action={{this.jump}}
          @label="composer.modal_ok"
        />
        <DModalCancel @close={{@closeModal}} />
      </:footer>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"jump-to-post-modal\"]],[[\"@closeModal\",\"@title\"],[[30,1],[28,[32,1],[\"topic.progress.jump_prompt_long\"],null]]],[[\"body\",\"footer\"],[[[[1,\"\\n    \"],[10,0],[14,0,\"jump-to-post-form\"],[12],[1,\"\\n      \"],[10,0],[14,0,\"jump-to-post-control\"],[12],[1,\"\\n        \"],[10,1],[14,0,\"index\"],[12],[1,\"#\"],[13],[1,\"\\n        \"],[8,[32,2],[[24,\"autofocus\",\"true\"],[24,1,\"post-jump\"]],[[\"@type\",\"@value\"],[\"number\",[30,0,[\"postNumber\"]]]],null],[1,\"\\n        \"],[10,1],[14,0,\"input-hint-text post-number\"],[12],[1,\"\\n          \"],[1,[28,[32,1],[\"topic.progress.jump_prompt_of\"],[[\"count\"],[[30,0,[\"filteredPostsCount\"]]]]]],[1,\"\\n        \"],[13],[1,\"\\n      \"],[13],[1,\"\\n\\n      \"],[10,0],[14,0,\"separator\"],[12],[1,\"\\n        \"],[10,1],[14,0,\"text\"],[12],[1,\"\\n          \"],[1,[28,[32,1],[\"topic.progress.jump_prompt_or\"],null]],[1,\"\\n        \"],[13],[1,\"\\n        \"],[10,\"hr\"],[14,0,\"right\"],[12],[13],[1,\"\\n      \"],[13],[1,\"\\n\\n      \"],[10,0],[14,0,\"jump-to-date-control\"],[12],[1,\"\\n        \"],[10,1],[14,0,\"input-hint-text post-date\"],[12],[1,\"\\n          \"],[1,[28,[32,1],[\"topic.progress.jump_prompt_to_date\"],null]],[1,\"\\n        \"],[13],[1,\"\\n        \"],[8,[32,3],[[24,0,\"date-input\"],[24,1,\"post-date\"]],[[\"@defaultDate\",\"@value\"],[\"YYYY-MM-DD\",[30,0,[\"postDate\"]]]],null],[1,\"\\n      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"]],[]],[[[1,\"\\n    \"],[8,[32,4],[[24,0,\"btn-primary\"],[24,4,\"submit\"]],[[\"@action\",\"@label\"],[[30,0,[\"jump\"]],\"composer.modal_ok\"]],null],[1,\"\\n    \"],[8,[32,5],null,[[\"@close\"],[[30,1]]],null],[1,\"\\n  \"]],[]]]]]],[\"@closeModal\"],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        i18n,
        Input,
        DDatePicker,
        DButton,
        DModalCancel
      }),
      "isStrictMode": true
    }), this);
  }
}