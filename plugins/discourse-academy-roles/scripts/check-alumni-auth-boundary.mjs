import assert from "node:assert/strict";
import fs from "node:fs";

const authSource = fs.readFileSync(
  new URL(
    "../assets/javascripts/discourse/components/academy-auth-page.gjs",
    import.meta.url
  ),
  "utf8"
);
assert.doesNotMatch(authSource, /from ["']discourse\/plugins\/isbf-alumni/);
assert.match(
  authSource,
  /import PluginOutlet from "discourse\/components\/plugin-outlet"/
);
assert.match(authSource, /<PluginOutlet @name="academy-alumni-registration"/);
assert.match(authSource, /{{#if this.invitation}}[\s\S]*?<CodeLoginForm/);
process.stdout.write(
  "Auth module depends only on the native outlet; invitation completion remains independent of Alumni assets.\n"
);
