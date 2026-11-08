// Regression tests for skills/hd-infra/assets/gen-env.ts (run: bun test scripts/tests).
import { afterEach, beforeEach, expect, test } from "bun:test";
import { mkdtemp, mkdir, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const script = resolve(import.meta.dir, "../../skills/hd-infra/assets/gen-env.ts");
let dir = "";

beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "gen-env-"));
});
afterEach(async () => {
  await rm(dir, { recursive: true, force: true });
});

const put = async (path: string, text: string): Promise<void> => {
  await mkdir(join(dir, path, ".."), { recursive: true });
  await writeFile(join(dir, path), text);
};
const read = (path: string): Promise<string> => Bun.file(join(dir, path)).text();
const run = (...args: string[]) => {
  const p = Bun.spawnSync(["bun", script, ...args], { cwd: dir, env: { PATH: process.env.PATH ?? "" } });
  return { code: p.exitCode, out: p.stdout.toString() + p.stderr.toString() };
};
const parse = (text: string): Record<string, string> =>
  Object.fromEntries(text.split("\n").filter((l) => /^[A-Z_]+=/.test(l)).map((l) => [l.slice(0, l.indexOf("=")), l.slice(l.indexOf("=") + 1)]));

test("generates secrets, copies defaults, interpolates root keys into apps and packages", async () => {
  await put(".env.example", "# db\nPOSTGRES_USER=app\nPOSTGRES_PASSWORD=<generate>\nPOSTGRES_PORT=5432\n");
  await put("apps/api/.env.example", "DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_PORT}/app\n");
  await put("packages/db/.env.example", "DATABASE_URL=postgresql://${POSTGRES_USER}@localhost:${POSTGRES_PORT}/app\n");
  const r = run(".", "apps/api", "packages/db");
  expect(r.code).toBe(0);
  const root = parse(await read(".env"));
  expect(root.POSTGRES_PASSWORD).toMatch(/^[A-Za-z0-9_-]{43}$/);
  expect(root.POSTGRES_USER).toBe("app");
  expect(parse(await read("apps/api/.env")).DATABASE_URL).toBe(`postgresql://app:${root.POSTGRES_PASSWORD}@localhost:5432/app`);
  expect(parse(await read("packages/db/.env")).DATABASE_URL).toBe("postgresql://app@localhost:5432/app");
  expect(r.out).not.toContain(root.POSTGRES_PASSWORD ?? "unreachable"); // names only, never values
});

test("is idempotent and never overwrites existing values", async () => {
  await put(".env.example", "SECRET=<generate>\nPORT=3000\n");
  run(".");
  const first = await read(".env");
  await put(".env", first.replace("PORT=3000", "PORT=4000"));
  await put(".env.example", "SECRET=<generate>\nPORT=3000\nNEW=1\n");
  const r = run(".");
  expect(r.code).toBe(0);
  const env = parse(await read(".env"));
  expect(env.SECRET).toBe(parse(first).SECRET);
  expect(env.PORT).toBe("4000");
  expect(env.NEW).toBe("1");
  expect(run(".").out).toContain("up to date");
});

test("writes .env with mode 600", async () => {
  await put(".env.example", "SECRET=<generate>\n");
  run(".");
  expect((await stat(join(dir, ".env"))).mode & 0o777).toBe(0o600);
});

test("fails on an undefined reference", async () => {
  await put(".env.example", "A=1\n");
  await put("apps/web/.env.example", "URL=http://localhost:${MISSING}\n");
  const r = run(".", "apps/web");
  expect(r.code).toBe(1);
  expect(r.out).toContain("undefined: MISSING");
});

test("fails on unquoted # and on unsafe values", async () => {
  await put(".env.example", "A=x#y\n");
  expect(run(".").code).toBe(1);
  await put(".env.example", "B='a#b'\nC=\"has $dollar\"\n");
  const r = run(".");
  expect(r.code).toBe(1);
  expect(r.out).toContain("C can't be written safely");
  expect(parse(await read(".env")).B).toBe("\"a#b\"");
});

test("fails when an existing value is still the placeholder", async () => {
  await put(".env.example", "S=<generate>\n");
  await put(".env", "S=<generate>\n");
  expect(run(".").code).toBe(1);
});

test("skips directories without .env.example", async () => {
  await mkdir(join(dir, "apps/empty"), { recursive: true });
  const r = run("apps/empty");
  expect(r.code).toBe(0);
  expect(await Bun.file(join(dir, "apps/empty/.env")).exists()).toBe(false);
});

test("values round-trip through Bun's own dotenv loader", async () => {
  await put(".env.example", "HASH='a#b'\nSPACE=\" padded \"\nDQ='say \"hi\"'\nSQ=\"it's\"\nPLAIN=v1\n");
  expect(run(".").code).toBe(0);
  const p = Bun.spawnSync(
    ["bun", "--env-file=.env", "-e", "console.log(JSON.stringify([Bun.env.HASH, Bun.env.SPACE, Bun.env.DQ, Bun.env.SQ, Bun.env.PLAIN]))"],
    { cwd: dir, env: { PATH: process.env.PATH ?? "" } },
  );
  expect(JSON.parse(p.stdout.toString())).toEqual(["a#b", " padded ", 'say "hi"', "it's", "v1"]);
});
