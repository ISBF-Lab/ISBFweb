const fs = require("node:fs");
const { spawnSync } = require("node:child_process");
const files = JSON.parse(fs.readFileSync(`/review/${process.argv[2] || "lint-files.json"}`, "utf8"));
const name = process.argv[3] || "lint";
const args = ["bin/lint", "--fix", ...files];
const result = spawnSync("ruby", args, {
  cwd: "/workspace",
  env: { ...process.env, LEFTHOOK_CONFIG: "/tools/lefthook-serial.yml", RUBOCOP_CACHE_ROOT: "/tmp/rubocop-cache" },
  encoding: "utf8",
  maxBuffer: 4 * 1024 * 1024,
});
const output = (result.stdout || "") + (result.stderr || "");
fs.writeFileSync(`/review/${name}.log`, output);
fs.writeFileSync(`/review/${name}-status.json`, JSON.stringify({ command: ["ruby", ...args], exit_code: result.status, error: result.error?.message, configuration: "Existing offline tools/lefthook-serial.yml; serial execution, repository CI gates unchanged" }, null, 2) + "\n");
process.stdout.write(output);
process.exitCode = result.status ?? 1;
