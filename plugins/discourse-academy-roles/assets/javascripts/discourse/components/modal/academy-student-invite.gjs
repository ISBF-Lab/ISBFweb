import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import AcademyStudentInviteForm from "../academy-student-invite-form";

export default <template>
  <DModal
    @closeModal={{@closeModal}}
    @title={{i18n "academy_roles.student_invites.create"}}
  >
    <:body>
      <AcademyStudentInviteForm />
    </:body>
  </DModal>
</template>
