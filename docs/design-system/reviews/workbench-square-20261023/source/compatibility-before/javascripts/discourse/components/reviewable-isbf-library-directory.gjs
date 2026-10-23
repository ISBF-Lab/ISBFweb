import Component from "@glimmer/component";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";

export default class ReviewableIsbfLibraryDirectory extends Component {
  get kindLabel() {
    return i18n(
      themePrefix(
        this.args.reviewable.payload.kind === "category"
          ? "isbf_v2.library_category"
          : "isbf_v2.library_groups",
      ),
    );
  }

  <template>
    <p>{{this.kindLabel}}：{{@reviewable.payload.name}}</p>
  </template>
}
