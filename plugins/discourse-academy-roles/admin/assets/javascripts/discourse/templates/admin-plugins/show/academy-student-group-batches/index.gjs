import { array } from "@ember/helper";
import AcademyStudentGroupBatches from "discourse/plugins/discourse-academy-roles/discourse/components/academy-student-group-batches";

export default <template>
  {{#each (array @model) key="@identity" as |model|}}
    <AcademyStudentGroupBatches @model={{model}} />
  {{/each}}
</template>
