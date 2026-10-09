import AcademyAuthPage from "../../components/academy-auth-page";
import academyAuthEnabled from "../../lib/academy-auth-enabled";

export default class AcademyLoginConnector extends Component {
  static shouldRender(args, component, owner) {
    return academyAuthEnabled(args, component, owner);
  }

  <template>
    <AcademyAuthPage @controller={{@outletArgs.controller}} />
  </template>
}
import Component from "@glimmer/component";
