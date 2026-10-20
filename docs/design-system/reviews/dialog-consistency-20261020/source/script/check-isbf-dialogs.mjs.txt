import { createHash } from "node:crypto";
import { readdir, readFile, realpath, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sharedStyles =
  "themes/isbf-campus-feed/stylesheets/dialog-consistency.scss";
const omitted = new Set([
  ".git",
  "node_modules",
  "dist",
  "vendor",
  "test",
  "tests",
  "spec",
  "admin",
  "public",
]);
const sourceExtensions = new Set([
  ".gjs",
  ".gts",
  ".js",
  ".ts",
  ".jsx",
  ".tsx",
  ".hbs",
  ".html",
  ".erb",
]);
const sha256 = (value) => createHash("sha256").update(value).digest("hex");

export function modalTags(source) {
  const template = source.includes("<template>")
    ? source.slice(
        source.indexOf("<template>") + 10,
        source.lastIndexOf("</template>")
      )
    : source;
  return [
    ...template
      .replace(/<!--[^]*?-->|{{![^]*?}}/g, "")
      .matchAll(/<(?![!/])[\w.-]+\b(?:"[^"]*"|'[^']*'|[^'">])*>/g),
  ]
    .map(([tag]) => tag)
    .filter(
      (tag) =>
        /^<dialog\b/.test(tag) ||
        /\b(?:role\s*=\s*["'](?:alertdialog|dialog)["']|aria-modal\s*=\s*["']true["'])/.test(
          tag
        )
    );
}

export function declarations(source) {
  const cleaned = source.replace(/\/\*[^]*?\*\/|\/\/[^\n]*/g, (match) =>
    match.replace(/[^\n]/g, " ")
  );
  const result = [];
  const stack = [];
  let beginning = 0;
  let quote = null;
  let parentheses = 0;
  for (let index = 0; index < cleaned.length; index++) {
    const character = cleaned[index];
    if (quote) {
      if (character === "\\") {
        index++;
      } else if (character === quote) {
        quote = null;
      }
      continue;
    }
    if (character === '"' || character === "'") {
      quote = character;
      continue;
    }
    if (character === "(") {
      parentheses++;
    }
    if (character === ")") {
      parentheses--;
    }
    if (parentheses) {
      continue;
    }
    if (character === "{") {
      stack.push(cleaned.slice(beginning, index).trim());
      beginning = index + 1;
    } else if (character === ";" || character === "}") {
      const statement = cleaned.slice(beginning, index).trim();
      const declaration = statement.match(/^([\w-]+)\s*:\s*([^]*)$/);
      if (declaration && stack.length) {
        result.push({
          selectors: stack
            .filter((selector) => !selector.startsWith("@"))
            .reduce(
              (parent, selector) =>
                selector.includes("&")
                  ? selector.replaceAll("&", parent)
                  : `${parent} ${selector}`.trim(),
              ""
            ),
          context: stack.join(" "),
          property: declaration[1],
          value: declaration[2].replace(/\s+/g, " ").trim(),
          line: cleaned.slice(0, beginning).split("\n").length,
        });
      }
      if (character === "}") {
        stack.pop();
      }
      beginning = index + 1;
    }
  }
  return result;
}

export function protectedDeclaration(declaration, dialogClasses = new Set()) {
  const { selectors, property } = declaration;
  const shell =
    /(?:^|\s)\.(?:d-modal__(?:container|header|body|footer)|dialog-(?:content|header|body|footer))[^\s]*$/.test(
      selectors
    );
  const dialog =
    /modal|dialog|resume-confirmation/.test(selectors) ||
    (selectors.match(/\.[\w-]+/g) || []).some((name) =>
      dialogClasses.has(name.slice(1))
    );
  const button =
    /(?:\.btn\b|\bbutton\b|__actions\b|__footer\b|dialog-footer)/.test(
      selectors
    );
  const radius =
    /^(?:border-(?:radius|(?:start|end)-(?:start|end)-radius|(?:top|bottom)-(?:left|right)-radius)|--d-button-border-radius)$/;
  return (
    (shell &&
      /^(?:border(?:-[\w-]+)?|background(?:-[\w-]+)?|box-shadow|padding(?:-[\w-]+)?)$/.test(
        property
      )) ||
    (dialog &&
      (shell || button || property === "--d-button-border-radius") &&
      radius.test(property))
  );
}

export function declarationKey(file, declaration) {
  return sha256(
    [file, declaration.selectors, declaration.property, declaration.value].join(
      "\n"
    )
  );
}

async function* files(directory, excluded, seen = new Set()) {
  const resolved = await realpath(directory);
  if (seen.has(resolved)) {
    return;
  }
  seen.add(resolved);
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    if (omitted.has(entry.name)) {
      continue;
    }
    const target = path.join(directory, entry.name);
    if (excluded.has(target)) {
      continue;
    }
    const type = entry.isSymbolicLink() ? await stat(target) : entry;
    if (type.isDirectory()) {
      yield* files(target, excluded, seen);
    } else if (
      type.isFile() &&
      (sourceExtensions.has(path.extname(target)) || target.endsWith(".scss"))
    ) {
      yield target;
    }
  }
}

export async function inspect(repository = root) {
  const exceptions = JSON.parse(
    await readFile(
      path.join(repository, "docs/design-system/dialog-exceptions.json"),
      "utf8"
    )
  );
  for (const exception of [
    ...exceptions.sources,
    ...exceptions.declarations,
    ...exceptions.excluded_surfaces,
  ]) {
    if (!exception.reason || !exception.reference || !exception.verification) {
      throw new Error(
        "Dialog exceptions require a reason, reference, and verification"
      );
    }
  }
  const sources = new Map(
    exceptions.sources.map((entry) => [entry.path, entry])
  );
  const allowed = new Set(exceptions.declarations.map((entry) => entry.sha256));
  const excluded = new Set(
    exceptions.excluded_surfaces
      .filter((entry) => entry.path)
      .map((entry) => path.join(repository, entry.path))
  );
  const inventory = [];
  const errors = [];
  const styleDeclarations = [];
  const dialogClasses = new Set();
  const references = [];
  for (const directory of [
    "frontend/discourse/app",
    "frontend/discourse/dialog-holder",
    "frontend/discourse/float-kit",
    "app/assets/stylesheets",
    "themes/isbf-campus-feed",
    "plugins",
  ]) {
    for await (const absolute of files(
      path.join(repository, directory),
      excluded
    )) {
      const file = path
        .relative(repository, absolute)
        .split(path.sep)
        .join("/");
      const source = await readFile(absolute, "utf8");
      const exempt = sources.get(file);
      if (file.endsWith(".scss")) {
        if (file !== sharedStyles) {
          styleDeclarations.push(
            ...declarations(source)
              .filter((entry) =>
                /^(?:border|background|box-shadow|padding|--d-button-border-radius)/.test(
                  entry.property
                )
              )
              .map((entry) => ({ file, ...entry }))
          );
        }
        continue;
      }
      const rawTags = modalTags(source);
      const nativeModal =
        /\.showModal\s*\(|\b(?:window|globalThis)\.(?:alert|confirm|prompt)\s*\(/.test(
          source
        );
      const component = /discourse\/(?:ui-kit|components)\/d-modal["']/.test(
        source
      );
      const alias =
        source.match(
          /import\s+(\w+)\s+from\s+["']discourse\/(?:ui-kit|components)\/d-modal["']/
        )?.[1] || "DModal";
      const componentTags = [
        ...source.matchAll(new RegExp(`<${alias}\\b[^>]*>`, "g")),
      ].map(([tag]) => tag);
      const roots = [];
      for (const tag of componentTags) {
        const classes =
          tag.match(/\bclass="([^"]+)"/)?.[1] ||
          tag.match(/\bclass={{dConcatClass\s+"([^"]+)"/)?.[1];
        for (const name of (classes || "").split(/\s+/).filter(Boolean)) {
          dialogClasses.add(name);
          roots.push(name);
        }
      }
      for (const match of source.matchAll(
        /import\s+[^;]*?\s+from\s+["']([^"']+)["']/g
      )) {
        const module = match[1];
        let target;
        const plugin = module.match(
          /^discourse\/plugins\/([^/]+)\/discourse\/(.+)$/
        );
        if (module.startsWith(".")) {
          target = path.posix.join(path.posix.dirname(file), module);
        } else if (plugin) {
          target = `plugins/${plugin[1]}/assets/javascripts/discourse/${plugin[2]}`;
        } else if (module.startsWith("discourse/dialog-holder/")) {
          target = `frontend/discourse/dialog-holder/${module.slice("discourse/dialog-holder/".length)}`;
        } else if (module.startsWith("discourse/")) {
          target = `frontend/discourse/app/${module.slice("discourse/".length)}`;
        }
        if (target) {
          references.push({
            target,
            path: file,
            line: source.slice(0, match.index).split("\n").length,
          });
        }
      }
      if ((rawTags.length || nativeModal) && !exempt) {
        errors.push({
          file,
          message:
            "Use DModal for modal dialogs; non-modal surfaces and native dialog exceptions need a reviewed entry",
        });
      }
      if (
        component &&
        componentTags.some((tag) => /\bstyle\s*=/.test(tag)) &&
        !exempt
      ) {
        errors.push({
          file,
          message:
            "Use a reviewed CSS layout variant instead of inline dialog styles",
        });
      }
      const confirmation =
        file ===
        "frontend/discourse/dialog-holder/components/dialog-holder.gjs";
      if (component || rawTags.length || nativeModal || confirmation) {
        const excludedSurface = exceptions.excluded_surfaces.find(
          (entry) => entry.selector && roots.includes(entry.selector.slice(1))
        );
        const boundary = exempt || excludedSurface;
        inventory.push({
          path: file,
          sha256: sha256(source),
          implementation: component
            ? "DModal"
            : confirmation
              ? "dialog service"
              : nativeModal
                ? "native dialog"
                : "custom surface",
          classes: confirmation ? ["dialog-content"] : [...new Set(roots)],
          classification:
            boundary?.reason ||
            "Shared foreground dialog appearance; business widths retained",
          desktop: boundary
            ? "Retains its own presentation"
            : "C07 frame and actions; existing task width",
          mobile: boundary
            ? "Retains its own presentation"
            : "C07 rounded frame, 16px gutter plus safe areas, body scroll",
          verification:
            boundary?.verification ||
            "Shared computed-style regression; individual business coverage varies",
          references: [],
        });
      }
    }
  }
  const byModule = new Map(
    inventory.map((entry) => [
      entry.path.replace(/\.(?:g?[jt]s|[jt]sx|hbs)$/, ""),
      entry,
    ])
  );
  for (const { target, ...reference } of references) {
    byModule
      .get(target.replace(/\.(?:g?[jt]s|[jt]sx|hbs)$/, ""))
      ?.references.push(reference);
  }
  for (const declaration of styleDeclarations.filter((entry) =>
    protectedDeclaration(entry, dialogClasses)
  )) {
    const key = declarationKey(declaration.file, declaration);
    if (!allowed.has(key)) {
      errors.push({
        ...declaration,
        sha256: key,
        message:
          "Dialog chrome belongs in the shared theme stylesheet; register reviewed exceptions",
      });
    }
  }
  inventory.sort((first, second) => first.path.localeCompare(second.path));
  return {
    errors,
    inventory,
    exclusions: exceptions.excluded_surfaces,
    layoutVariants: exceptions.layout_variants,
  };
}

if (
  process.argv[1] &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  const result = await inspect();
  const output = process.argv.indexOf("--report");
  if (output !== -1) {
    await writeFile(
      process.argv[output + 1],
      JSON.stringify(result, null, 2) + "\n"
    );
  }
  if (result.errors.length) {
    for (const error of result.errors) {
      process.stderr.write(`${JSON.stringify(error)}\n`);
    }
    process.exitCode = 1;
  }
  process.stdout.write(
    `Dialog policy: ${result.inventory.length} source candidates, ${result.errors.length} violations\n`
  );
}
