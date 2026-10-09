import AcademyAuthPage from "../../components/academy-auth-page";
import academyAuthEnabled from "../../lib/academy-auth-enabled";

export default class AcademyEntranceConnector extends Component {
  static shouldRender(args, component, owner) {
    return academyAuthEnabled(args, component, owner);
  }

  <template><AcademyAuthPage /></template>
}
import Component from "@glimmer/component";
