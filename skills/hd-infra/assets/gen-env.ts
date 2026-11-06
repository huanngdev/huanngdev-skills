#!/usr/bin/env bun
/**
 * Create/complete `.env` files from `.env.example`, one per directory.
 *   bun scripts/gen-env.ts . apps/*      (root first: it feeds ${VAR} references)
 * - `KEY=<generate>`  → random 32-byte base64url secret.
 * - `KEY=...${NAME}...` → NAME taken from this file's values, else from the root `.env`
 *   (so apps reuse credentials that docker compose uses, e.g. DATABASE_URL).
 * - Existing values are never overwritten; only missing keys are appended.
 * - Prints key names only, never values. Sets `.env` to mode 600.
 * - Directories without `.env.example` are skipped.
 */
import { chmod } from "node:fs/promises";
import { join } from "node:path";

const PLACEHOLDER = "<generate>";
const LINE = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)$/;
const REF = /\$\{([A-Za-z_][A-Za-z0-9_]*)\}/g;

const secret = (): string =>
  Buffer.from(crypto.getRandomValues(new Uint8Array(32))).toString("base64url");

const parse = (text: string): Map<string, string> => {
  const map = new Map<string, string>();
  for (const line of text.split("\n")) {
    const m = LINE.exec(line);
    if (m?.[1]) map.set(m[1], (m[2] ?? "").trim());
  }
  return map;
};

const readText = async (path: string): Promise<string> => {
  const file = Bun.file(path);
  return (await file.exists()) ? file.text() : "";
};

let failed = false;

const generate = async (dir: string, rootEnv: Map<string, string>): Promise<Map<string, string>> => {
  const examplePath = join(dir, ".env.example");
  const targetPath = join(dir, ".env");
  if (!(await Bun.file(examplePath).exists())) return new Map();

  const current = await readText(targetPath);
  const values = parse(current);
  const generated: string[] = [];
  const added: string[] = [];
  const out: string[] = [];

  for (const line of (await Bun.file(examplePath).text()).split("\n")) {
    const m = LINE.exec(line);
    if (!m?.[1]) {
      if (!current) out.push(line); // keep comments/blank lines on first creation
      continue;
    }
    const key = m[1];
    if (values.has(key)) continue;
    const raw = (m[2] ?? "").trim();
    let value = raw;
    if (raw === PLACEHOLDER) {
      value = secret();
      generated.push(key);
    } else {
      const missing = [...raw.matchAll(REF)]
        .map((r) => r[1] ?? "")
        .filter((name) => !values.has(name) && !rootEnv.has(name));
      if (missing.length) {
        console.error(`✗ ${targetPath}: ${key} skipped, undefined: ${missing.join(", ")}`);
        failed = true;
        continue;
      }
      value = raw.replace(REF, (_, name: string) => values.get(name) ?? rootEnv.get(name) ?? "");
      added.push(key);
    }
    values.set(key, value);
    out.push(`${key}=${value}`);
  }

  if (generated.length + added.length === 0) {
    console.log(`✓ ${targetPath} up to date`);
    return values;
  }
  const prefix = current && !current.endsWith("\n") ? "\n" : "";
  await Bun.write(targetPath, current + prefix + out.join("\n").replace(/\n*$/, "\n"));
  await chmod(targetPath, 0o600);
  const parts = [
    generated.length ? `generated ${generated.join(", ")}` : "",
    added.length ? `added ${added.join(", ")}` : "",
  ].filter(Boolean);
  console.log(`✓ ${targetPath}: ${parts.join("; ")}`);
  return values;
};

const dirs = process.argv.slice(2);
if (dirs.length === 0) dirs.push(".");
const rootFirst = [...new Set(dirs.map((d) => d.replace(/\/+$/, "") || "."))].sort((a, b) =>
  a === "." ? -1 : b === "." ? 1 : a.localeCompare(b),
);

let rootEnv = parse(await readText(".env"));
for (const dir of rootFirst) {
  const values = await generate(dir, rootEnv);
  if (dir === ".") rootEnv = values.size ? values : rootEnv;
}
if (failed) process.exit(1);
