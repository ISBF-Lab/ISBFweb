import { apiInitializer } from "discourse/lib/api";
import ISBFFrontendHeading from "../components/isbf-frontend-heading";
import ISBFFrontendScope from "../components/isbf-frontend-scope";

export default apiInitializer((api) => {
  api.renderInOutlet("before-main-outlet", ISBFFrontendScope);
  api.renderInOutlet("users-top", ISBFFrontendHeading);
  api.renderInOutlet("above-user-preferences", ISBFFrontendHeading);
});
