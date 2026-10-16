import { createHash } from "node:crypto";
import { readdir, readFile, writeFile } from "node:fs/promises";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url));
const manifest = {};

async function addDirectory(directory) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      await addDirectory(path);
    } else if (!entry.name.startsWith(".")) {
      const file = relative(root, path).split("\\").join("/");
      const prefix = file.startsWith("dist/") ? "dist/" : "public/";
      manifest[file.slice(prefix.length)] = {
        file,
        sha256: createHash("sha256")
          .update(await readFile(path))
          .digest("hex"),
      };
    }
  }
}

await addDirectory(join(root, "public"));
await addDirectory(join(root, "dist"));
await writeFile(
  join(root, "asset-manifest.json"),
  JSON.stringify(manifest, null, 2) + "\n"
);
