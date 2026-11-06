#!/usr/bin/env bun
/**
 * Create/complete `.env` files from `.env.example`, one per directory.
 *   bun scripts/gen-env.ts . apps/*      (root first: it feeds ${VAR} references)
 * - `KEY=<generate>`  → random 32-byte base64url secret.
 * - `KEY=...${NAME}...` → NAME taken from this file's values, else from the root `.env`
 *   (so apps reuse credentials that docker compose uses, e.g. DATABASE_URL).
 * - Comments only on their own lines; a value with a trailing ` # …` is rejected.
 * - Existing values are never overwritten; only missing keys are appended.
 *   An existing value still equal to `<generate>` is an error.
 * - Prints key names only, never values. `.env` is created with mode 600 and kept at 600.
 * - Directories without `.env.example` are skipped. Exit 1 on any error.
 */
import { chmod, open } from "node:fs/promises";
import { join } from "node:path";

const PLACEHOLDER = "<generate>";
const LINE = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)$/;
const REF = /\$\{([A-Za-z_][A-Za-z0-9_]*)\}/g;
const INLINE_COMMENT = /\s#/;

const secret = (): string =>
  Buffer.from(crypto.getRandomValues(new Uint8Array(32))).toString("base64url");

let failed = false;
const fail = (message: string): void => {
  console.error(`✗ ${message}`);
  failed = true;
};

/** Strip one pair of matching quotes; reject unquoted values with an inline comment. */
const readValue = (raw: string, where: string, report = true): string | null => {
  const value = raw.trim();
  const quoted = /^(["'])(.*)\1$/.exec(value);
  if (quoted) return quoted[2] ?? "";
  if (INLINE_COMMENT.test(value)) {
    if (report) fail(`${where}: inline comment not allowed, put it on its own line`);
    return null;
  }
  return value;
};

const parse = (text: string, path: string, report = true): Map<string, string> => {
  const map = new Map<string, string>();
  for (const line of text.split("\n")) {
    const m = LINE.exec(line);
    if (!m?.[1]) continue;
    const value = readValue(m[2] ?? "", `${path}: ${m[1]}`, report);
    if (value === PLACEHOLDER && report) fail(`${path}: ${m[1]} is still ${PLACEHOLDER} — delete the line and rerun`);
    map.set(m[1], value ?? ""); // keep the key so it is never appended twice
  }
  return map;
};

/** Quote values that would not survive an unquoted round trip. */
const serialize = (value: string): string =>
  /^\s|\s$|\s#|^["']/.test(value) ? (value.includes('"') ? `'${value}'` : `"${value}"`) : value;

const readText = async (path: string): Promise<string> => {
  const file = Bun.file(path);
  return (await file.exists()) ? file.text() : "";
};

/** Write with mode 600 from the first byte; re-apply 600 on files that already existed. */
const writeSecure = async (path: string, text: string): Promise<void> => {
  const handle = await open(path, "w", 0o600);
  try {
    await handle.writeFile(text);
  } finally {
    await handle.close();
  }
  await chmod(path, 0o600);
};

const generate = async (dir: string, rootEnv: Map<string, string>): Promise<Map<string, string>> => {
  const examplePath = join(dir, ".env.example");
  const targetPath = join(dir, ".env");
  if (!(await Bun.file(examplePath).exists())) return new Map();

  const current = await readText(targetPath);
  const values = parse(current, targetPath);
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
    const raw = readValue(m[2] ?? "", `${examplePath}: ${key}`);
    if (raw === null) continue;
    let value = raw;
    if (raw === PLACEHOLDER) {
      value = secret();
      generated.push(key);
    } else {
      const missing = [...raw.matchAll(REF)]
        .map((r) => r[1] ?? "")
        .filter((name) => !values.has(name) && !rootEnv.has(name));
      if (missing.length) {
        fail(`${targetPath}: ${key} skipped, undefined: ${missing.join(", ")}`);
        continue;
      }
      value = raw.replace(REF, (_, name: string) => values.get(name) ?? rootEnv.get(name) ?? "");
      added.push(key);
    }
    values.set(key, value);
    out.push(`${key}=${serialize(value)}`);
  }

  if (generated.length + added.length === 0) {
    if (current) await chmod(targetPath, 0o600);
    console.log(`✓ ${targetPath} up to date`);
    return values;
  }
  const prefix = current && !current.endsWith("\n") ? "\n" : "";
  await writeSecure(targetPath, current + prefix + out.join("\n").replace(/\n*$/, "\n"));
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

let rootEnv = parse(await readText(".env"), ".env", false); // reported when "." itself is processed
for (const dir of rootFirst) {
  const values = await generate(dir, rootEnv);
  if (dir === ".") rootEnv = values.size ? values : rootEnv;
}
if (failed) process.exit(1);
