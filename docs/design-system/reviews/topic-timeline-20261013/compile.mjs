import { readFileSync, mkdirSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { resolve } from "node:path";

const root = "/workspace";
process.chdir(resolve(root, "frontend/discourse"));
const require = createRequire(resolve(root, "frontend/discourse/package.json"));
const { transformAsync } = require("@babel/core");
const { Preprocessor } = require("content-tag");
const preprocessor = new Preprocessor();
const files = [
  "themes/isbf-campus-feed/javascripts/discourse/modifiers/isbf-close-on-click-outside.js",
  "themes/isbf-campus-feed/test/integration/topic-reading-test.gjs",
  "themes/isbf-campus-feed/javascripts/discourse/components/isbf-topic-reading.gjs",
  "themes/isbf-campus-feed/test/acceptance/topic-reading-test.js",
];
mkdirSync("/review/compiled", { recursive: true });
const results = [];
for (const file of files) {
  const filename = resolve(root, file);
  let source = readFileSync(filename, "utf8");
  if (file.endsWith(".gjs")) {
    source = preprocessor.process(source, { filename }).code;
  }
  const result = await transformAsync(source, {
    filename,
    configFile: resolve(root, "frontend/discourse/babel.config.cjs"),
    babelrc: false,
    cwd: resolve(root, "frontend/discourse"),
  });
  writeFileSync(`/review/compiled/${file.split("/").at(-1)}.js`, result.code);
  results.push({ file, compiled: true, outputBytes: result.code.length });
}
writeFileSync("/review/compilation.json", JSON.stringify({ javascript: results }, null, 2) + "\n");
console.log(JSON.stringify({ javascript_compiled: results.length }));
