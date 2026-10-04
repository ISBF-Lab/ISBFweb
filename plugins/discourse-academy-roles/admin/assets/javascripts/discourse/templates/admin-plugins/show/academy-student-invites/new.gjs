import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import BackButton from "discourse/components/back-button";
import AcademyStudentInviteForm from "discourse/plugins/discourse-academy-roles/discourse/components/academy-student-invite-form";

export default <template>
  <BackButton @route="adminPlugins.show.academy-student-invites.index" />
  <AdminConfigAreaCard @heading="academy_roles.student_invites.create">
    <:content>
      <AcademyStudentInviteForm />
    </:content>
  </AdminConfigAreaCard>
</template>
