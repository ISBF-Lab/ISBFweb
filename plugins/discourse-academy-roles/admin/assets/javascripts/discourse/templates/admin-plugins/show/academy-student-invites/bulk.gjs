import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import BackButton from "discourse/components/back-button";
import AcademyStudentInviteBulkForm from "../../../../components/academy-student-invite-bulk-form";

export default <template>
  <BackButton @route="adminPlugins.show.academy-student-invites.index" />
  <AdminConfigAreaCard @heading="academy_roles.student_invites.bulk.title">
    <:content>
      <AcademyStudentInviteBulkForm />
    </:content>
  </AdminConfigAreaCard>
</template>
