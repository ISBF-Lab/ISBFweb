import { not } from "discourse/truth-helpers";
import { formatActionCount } from "../lib/post-action-pulse";
import postActionCount from "../modifiers/post-action-count";

export default <template>
  <span
    class="isbf-post-action-count"
    hidden={{not (formatActionCount @value @format)}}
    {{postActionCount @pulse @kind @value @format}}
  ><span class="isbf-post-action-count__value">{{formatActionCount
        @value
        @format
      }}</span><span
      aria-hidden="true"
      class="isbf-post-action-count__motion"
    ></span></span>
</template>
