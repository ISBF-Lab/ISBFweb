const fs = require("node:fs");
const path = require("node:path");
const { createRequire } = require("node:module");
const requireFrontend = createRequire("/workspace/frontend/discourse/package.json");
const babel = requireFrontend("@babel/core");
const { Preprocessor } = requireFrontend("content-tag");
const config = requireFrontend("./babel.config.cjs");
config.plugins = config.plugins.map((entry) => {
  const [plugin, ...options] = Array.isArray(entry) ? entry : [entry];
  const resolved = typeof plugin === "string" ? requireFrontend.resolve(plugin.replace(/^module:/, "")) : plugin;
  if (options[0]?.compilerPath) {
    options[0] = { ...options[0], compilerPath: requireFrontend.resolve(options[0].compilerPath) };
  }
  return [resolved, ...options];
});
const preprocessor = new Preprocessor();
const files = JSON.parse(fs.readFileSync("/review/changed-files.json", "utf8"));
const results = [];
fs.mkdirSync("/review/compiled", { recursive: true });
(async () => {
for (const file of files.filter((name) => /\.(g?js)$/.test(name))) {
  try {
    let source = fs.readFileSync(`/workspace/${file}`, "utf8");
    if (file.endsWith(".gjs")) {
      source = preprocessor.process(source, { filename: file }).code;
    }
    const compiled = await babel.transformAsync(source, {
      ...config, filename: `/workspace/${file}`, babelrc: false, configFile: false,
    });
    fs.writeFileSync(`/review/compiled/${path.basename(file)}.js`, compiled.code);
    results.push({ file, compiled: true });
  } catch (error) {
    results.push({ file, compiled: false, error: error.message });
  }
}
fs.writeFileSync("/review/compilation.json", JSON.stringify(results, null, 2) + "\n");
console.log(JSON.stringify(results, null, 2));
if (results.some((result) => !result.compiled)) process.exitCode = 1;
})().catch((error) => { console.error(error); process.exitCode = 1; });
