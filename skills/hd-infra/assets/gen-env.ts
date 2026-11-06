#!/usr/bin/env bun
/**
 * Create/complete `.env` files from `.env.example`, one per directory.
 *   bun scripts/gen-env.ts . apps/*      (root first: it feeds ${VAR} references)
 * - `KEY=<generate>`  → random 32-byte base64url secret.
 * - `KEY=...${NAME}...` → NAME taken from this file's values, else from the root `.env`
 *   (so apps reuse credentials that docker compose uses, e.g. DATABASE_URL).
 * - Comments only on their own lines. Unquoted values can't contain `#` (Bun reads it as a comment);
 *   quote them. Values with `$`, `\` or both quote kinds are rejected (Bun would expand or mangle them).
 * - Existing values are never overwritten; only missing keys are appended.
 *   An existing value still equal to `<generate>` is an error.
 * - Prints key names only, never values. `.env` is written atomically via a mode-600 temp file.
 * - Directories without `.env.example` are skipped. Exit 1 on any error.
 */
import { chmod, open, rename, rm } from "node:fs/promises";
import { join } from "node:path";

const PLACEHOLDER = "<generate>";
const LINE = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)$/;
const REF = /\$\{([A-Za-z_][A-Za-z0-9_]*)\}/g;
const UNSAFE = /[$\\\r\n]/;

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
  const quoted = /^(["'`])(.*)\1$/.exec(value);
  if (quoted) return quoted[2] ?? "";
  if (value.includes("#")) {
    if (report) fail(`${where}: unquoted '#' starts a comment — quote the value or move the comment to its own line`);
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

/** Write a value so Bun's dotenv loader reads it back unchanged, or null if it can't. */
const serialize = (value: string): string | null => {
  if (UNSAFE.test(value) || (value.includes('"') && value.includes("'"))) return null;
  if (!/^\s|\s$|#|^["'`]/.test(value)) return value; // Bun also quotes with backticks
  return value.includes('"') ? `'${value}'` : `"${value}"`;
};

const readText = async (path: string): Promise<string> => {
  const file = Bun.file(path);
  return (await file.exists()) ? file.text() : "";
};

/** Secrets never sit in a readable file: write a new mode-600 temp file, then rename over the target. */
const writeSecure = async (path: string, text: string): Promise<void> => {
  const tmp = `${path}.${process.pid}.tmp`;
  const handle = await open(tmp, "wx", 0o600);
  try {
    await handle.writeFile(text);
    await handle.sync();
  } finally {
    await handle.close();
  }
  try {
    await rename(tmp, path);
  } catch (error) {
    await rm(tmp, { force: true });
    throw error;
  }
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
    const isSecret = raw === PLACEHOLDER;
    if (isSecret) {
      value = secret();
    } else {
      const missing = [...raw.matchAll(REF)]
        .map((r) => r[1] ?? "")
        .filter((name) => !values.has(name) && !rootEnv.has(name));
      if (missing.length) {
        fail(`${targetPath}: ${key} skipped, undefined: ${missing.join(", ")}`);
        continue;
      }
      value = raw.replace(REF, (_, name: string) => values.get(name) ?? rootEnv.get(name) ?? "");
    }
    const serialized = serialize(value);
    if (serialized === null) {
      fail(`${examplePath}: ${key} can't be written safely (contains $, \\, a newline or both quote kinds)`);
      continue;
    }
    values.set(key, value);
    out.push(`${key}=${serialized}`);
    (isSecret ? generated : added).push(key);
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
