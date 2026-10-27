import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const extensions = new Set([".gjs", ".gts", ".hbs", ".js", ".ts", ".scss"]);
const ignored = new Set([
  "node_modules",
  ".git",
  "vendor",
  "dist",
  "test",
  "tests",
  "type-tests",
  "public",
]);
const carrier = "frontend/discourse/app/ui-kit/d-select/native.gjs";
const popovers = new Map([
  [
    "frontend/discourse/app/form-kit/components/fk/control/color.gjs",
    "Two-dimensional color palette",
  ],
  [
    "frontend/discourse/admin/components/dashboard/date-range.gjs",
    "Calendar date-range panel",
  ],
  [
    "frontend/discourse/admin/components/ip-lookup.gjs",
    "IP lookup information panel",
  ],
  [
    "frontend/discourse/admin/components/admin-report-table-summary.gjs",
    "Report information panel",
  ],
]);

function files(directory, seen = new Set()) {
  if (!fs.existsSync(directory)) {
    return [];
  }
  const real = fs.realpathSync(directory);
  if (seen.has(real)) {
    return [];
  }
  seen.add(real);
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    if (ignored.has(entry.name)) {
      return [];
    }
    const full = path.join(directory, entry.name);
    if (!fs.existsSync(full)) {
      return [];
    }
    const stat = fs.statSync(full);
    if (stat.isDirectory()) {
      return files(full, seen);
    }
    return extensions.has(path.extname(full)) ? [full] : [];
  });
}

function normalized(file) {
  const real = fs.realpathSync(file);
  const workspace = path.dirname(root);
  if (real.startsWith(path.join(workspace, "external") + path.sep)) {
    return "external/" + path.relative(path.join(workspace, "external"), real);
  }
  return path.relative(root, real);
}

export function inspectTemplate(name, text) {
  if (/(^|\/)(?:test|tests|type-tests)\//.test(name)) {
    return [];
  }
  const findings = [];
  if (name !== carrier && /<select(?=[\s>])/.test(text)) {
    findings.push("Use DSelect or FormKit instead of a visible native select");
  }
  for (const match of text.matchAll(/<DMenu\b([\s\S]*?)>/g)) {
    const tag = match[1];
    if (/@surface=["']popover["']/.test(tag)) {
      if (!popovers.has(name)) {
        findings.push(
          "Register the non-menu popover's purpose in the menu policy"
        );
      }
    } else if (/@modalForMobile=\{\{true\}\}/.test(tag)) {
      findings.push("Menus use an anchored floating panel on mobile");
    }
  }
  if (
    /<details\b[^>]*class=["'][^"']*(?:dropdown|__menu|__picker)[^"']*["']/.test(
      text
    )
  ) {
    findings.push("Use DMenu for a dropdown disclosure");
  }
  return findings;
}

export function inspectStyles(name, text, menuClasses) {
  if (
    name.endsWith("/stylesheets/dropdowns.scss") ||
    name.startsWith("app/assets/stylesheets/") ||
    name.endsWith("d-menu-surface.scss")
  ) {
    return [];
  }
  const findings = [];
  const stack = [];
  let start = 0;
  let quote = null;
  let comment = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (comment) {
      if (ch === "*" && text[i + 1] === "/") {
        comment = false;
        i++;
      }
      continue;
    }
    if (quote) {
      if (ch === quote && text[i - 1] !== "\\") {
        quote = null;
      }
      continue;
    }
    if (ch === "/" && text[i + 1] === "*") {
      comment = true;
      i++;
      continue;
    }
    if (ch === '"' || ch === "'") {
      quote = ch;
      continue;
    }
    if (ch === "{") {
      const header = text
        .slice(start, i)
        .replace(/\/\*[\s\S]*?\*\//g, "")
        .replace(/\/\/[^\n]*/g, "")
        .trim();
      const parent = stack.at(-1) ?? "";
      stack.push(
        header.startsWith("@")
          ? parent
          : header.includes("&")
            ? header.replaceAll("&", parent)
            : `${parent} ${header}`
      );
      start = i + 1;
    } else if (ch === "}") {
      stack.pop();
      start = i + 1;
    } else if (ch === ";") {
      const declaration = text.slice(start, i).trim();
      const parsed =
        /^(border-radius|box-shadow|animation(?:-[\w-]+)?)\s*:\s*([\s\S]+)$/.exec(
          declaration
        );
      const selector = stack.at(-1) ?? "";
      const relevant =
        [...menuClasses].some((menuClass) =>
          selector.includes("." + menuClass)
        ) || /\.select-kit-(body|row)\b/.test(selector);
      const field =
        /(?:__trigger|__search|__icon|\.d-icon|spinner|\.select-kit-filter|\binput\b|\bsummary\b)/.test(
          selector
        );
      if (
        parsed &&
        relevant &&
        !field &&
        !parsed[2].includes("var(--d-menu-") &&
        !["none", "inherit"].includes(parsed[2].trim())
      ) {
        findings.push(
          `Shared menu ${parsed[1]} belongs in dropdowns.scss: ${selector.trim()}`
        );
      }
      start = i + 1;
    }
  }
  return [...new Set(findings)];
}

export function audit(paths) {
  const sources = paths.map((file) => ({
    file,
    name: normalized(file),
    text: fs.readFileSync(file, "utf8"),
  }));
  const classes = new Set([
    "isbf-v2-more-menu",
    "isbf-v2-account-menu__panel",
    "isbf-notifications__menu-items",
    "isbf-explore-picker__menu",
  ]);
  for (const source of sources) {
    for (const match of source.text.matchAll(
      /@contentClass=["']([^"']+)["']/g
    )) {
      for (const name of match[1].split(/\s+/)) {
        classes.add(name);
      }
    }
  }
  const findings = sources.flatMap(({ name, text }) =>
    (name.endsWith(".scss")
      ? inspectStyles(name, text, classes)
      : inspectTemplate(name, text)
    ).map((message) => ({ file: name, message }))
  );
  return {
    scanned: sources.length,
    findings,
    popovers: Object.fromEntries(popovers),
  };
}

if (
  process.argv[1] &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  const explicit = process.argv.slice(2).filter((arg) => arg !== "--json");
  const themeDirectory = fs.existsSync(
    path.resolve(root, "../external/active-theme")
  )
    ? "../external/active-theme"
    : "themes/isbf-campus-feed";
  const paths = explicit.length
    ? explicit
        .map((file) => path.resolve(file))
        .filter(
          (file) => fs.existsSync(file) && extensions.has(path.extname(file))
        )
    : ["frontend/discourse", "plugins", themeDirectory].flatMap((directory) =>
        files(path.resolve(root, directory))
      );
  const unique = [
    ...new Map(paths.map((file) => [fs.realpathSync(file), file])).values(),
  ];
  const report = audit(unique);
  if (process.argv.includes("--json")) {
    process.stdout.write(JSON.stringify(report, null, 2) + "\n");
  } else {
    for (const finding of report.findings) {
      process.stderr.write(`${finding.file}: ${finding.message}\n`);
    }
    process.stdout.write(
      `Menu policy: ${report.scanned} files, ${report.findings.length} findings\n`
    );
  }
  process.exitCode = report.findings.length ? 1 : 0;
}
