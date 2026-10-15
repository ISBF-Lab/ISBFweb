import { i18n } from "discourse-i18n";
import IsbfResumeRoute from "./isbf-resume";

export default class IsbfResumeSharesRoute extends IsbfResumeRoute {
  titleToken() {
    return i18n("isbf_resume.sharing.title");
  }
}
