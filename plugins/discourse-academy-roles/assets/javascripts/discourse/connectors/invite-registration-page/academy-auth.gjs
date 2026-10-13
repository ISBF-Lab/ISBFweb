import AcademyAuthPage from "../../components/academy-auth-page";
import academyAuthEnabled from "../../lib/academy-auth-enabled";

export default class AcademyInvitationConnector extends Component {
  static shouldRender(args, component, owner) {
    return (
      academyAuthEnabled(args, component, owner) &&
      owner.lookup("service:site-settings").enable_local_logins_via_code
    );
  }

  <template>
    <AcademyAuthPage
      @controller={{@outletArgs.controller}}
      @inviteInfo={{@outletArgs.controller.model}}
    />
  </template>
}
import Component from "@glimmer/component";
