#!/usr/bin/env bun
/**
 * Regenerate the skill map in skills/hd-index/SKILL.md from every skill's own topic table,
 * so the two can never drift. Skill order and rows for skills without a topic table
 * (hd-index itself, single-file skills) are kept from the current map; new skills are appended.
 *   bun scripts/sync-map.ts           rewrite the map
 *   bun scripts/sync-map.ts --check   exit 1 if the map is out of date (used by validate.sh)
 */
import { Glob } from "bun";

const INDEX = "skills/hd-index/SKILL.md";
const HEADER = "| Skill | Topic file | Read when the task touches |";
const check = process.argv.includes("--check");

type Row = { skill: string; topic: string; when: string };

const cells = (line: string): string[] =>
  line.split("|").slice(1, -1).map((c) => c.trim());
const unquote = (s: string): string => s.replace(/^`|`$/g, "");

const index = await Bun.file(INDEX).text();
const lines = index.split("\n");
const start = lines.indexOf(HEADER);
if (start < 0) throw new Error(`${INDEX}: map header not found`);
let end = start + 2;
while (end < lines.length && lines[end]?.startsWith("|")) end++;

// Current map: order of skills + rows to keep for skills without their own topic table.
const current: Row[] = [];
let skill = "";
for (const line of lines.slice(start + 2, end)) {
  const [s = "", topic = "", when = ""] = cells(line);
  if (s) skill = unquote(s);
  current.push({ skill, topic: unquote(topic), when });
}
const order = [...new Set(current.map((r) => r.skill))];

// Topic tables of every skill: rows like | `references/<topic>.md` | <when> |
const own = new Map<string, Row[]>();
for await (const path of new Glob("skills/*/SKILL.md").scan(".")) {
  const name = path.split("/")[1] ?? "";
  const rows: Row[] = [];
  for (const line of (await Bun.file(path).text()).split("\n")) {
    const [ref = "", when = ""] = cells(line);
    const m = /^`references\/([^`]+)`$/.exec(ref);
    if (line.startsWith("|") && m?.[1]) rows.push({ skill: name, topic: m[1], when });
  }
  if (!order.includes(name)) order.push(name);
  if (rows.length) own.set(name, rows);
}

const rows: Row[] = [];
for (const name of order) {
  const generated = own.get(name);
  const kept = current.filter((r) => r.skill === name);
  if (generated) rows.push(...generated);
  else if (kept.length) rows.push(...kept);
  else rows.push({ skill: name, topic: "—", when: "TODO: describe when to load this skill" });
}

const table = [HEADER, "|---|---|---|"];
let previous = "";
for (const r of rows) {
  const s = r.skill === previous ? "" : `\`${r.skill}\``;
  const t = r.topic === "—" ? "—" : `\`${r.topic}\``;
  table.push(`| ${s} | ${t} | ${r.when} |`.replace("|  |", "| |"));
  previous = r.skill;
}

const next = [...lines.slice(0, start), ...table, ...lines.slice(end)].join("\n");
if (next === index) {
  if (!check) console.log("✓ skill map up to date");
  process.exit(0);
}
if (check) {
  console.error(`✗ ${INDEX} skill map is out of date — run: bun scripts/sync-map.ts`);
  process.exit(1);
}
await Bun.write(INDEX, next);
console.log(`✓ rewrote the skill map in ${INDEX}`);
