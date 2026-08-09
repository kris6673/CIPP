import { describe, it, expect } from "vitest";
import fs from "node:fs";
import path from "node:path";

// Two MUI patterns account for nearly every mobile layout bug in this app, and both are
// invisible on a desktop screen — so they ship freely and only surface as a phone report.
// This walks src/ and fails on either, which is cheaper than finding them one at a time.
//
//  1. <Grid size={N}> / size={{ xs: N }} with N < 12 holds a desktop column split at 390px.
//  2. A Stack with flexWrap but no useFlexGap: MUI's `spacing` is a margin-left between
//     children, and every wrapped row inherits it, so each new line starts indented.

const SRC = path.resolve(__dirname, "../../src");

// Dead Devias template code — nothing in pages/, components/ or layouts/ imports it.
const IGNORED_DIRS = new Set(["sections"]);

const walk = (dir) =>
  fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      return IGNORED_DIRS.has(entry.name) ? [] : walk(full);
    }
    return /\.(js|jsx)$/.test(entry.name) ? [full] : [];
  });

const rel = (file) => path.relative(SRC, file);

// Commented-out JSX is not shipped markup — blank it (preserving newlines so reported
// line numbers stay accurate) rather than flagging code nobody renders.
const stripComments = (source) =>
  source
    .replace(/\{\s*\/\*[\s\S]*?\*\/\s*\}/g, (m) => m.replace(/[^\n]/g, " "))
    .replace(/\/\*[\s\S]*?\*\//g, (m) => m.replace(/[^\n]/g, " "));

/** Opening tags for `name`, brace-aware so multi-line JSX props stay in one string. */
const openingTags = (source, name) => {
  const tags = [];
  const re = new RegExp(`<${name}\\b`, "g");
  let match;
  while ((match = re.exec(source))) {
    let depth = 0;
    for (let i = match.index; i < source.length; i += 1) {
      const char = source[i];
      if (char === "{") depth += 1;
      else if (char === "}") depth -= 1;
      else if (char === ">" && depth === 0) {
        tags.push({ text: source.slice(match.index, i + 1), line: source.slice(0, match.index).split("\n").length });
        break;
      }
    }
  }
  return tags;
};

const files = walk(SRC);

describe("mobile layout patterns", () => {
  it("has files to check", () => {
    expect(files.length).toBeGreaterThan(100);
  });

  it("declares no Grid column split that survives a phone", () => {
    const offenders = [];
    for (const file of files) {
      const source = stripComments(fs.readFileSync(file, "utf8"));
      for (const { text, line } of openingTags(source, "Grid")) {
        const bare = text.match(/\bsize=\{(\d+(?:\.\d+)?)\}/);
        if (bare && Number(bare[1]) !== 12) {
          offenders.push(`${rel(file)}:${line} size={${bare[1]}}`);
        }
        const xs = text.match(/\bsize=\{\{[^}]*?\bxs:\s*(\d+(?:\.\d+)?)/);
        if (xs && Number(xs[1]) < 12) {
          offenders.push(`${rel(file)}:${line} xs: ${xs[1]}`);
        }
        // v1 props are silently inert under Grid v2 — the split never applied at all
        if (/<Grid\s+(?!item\b)[^>]*\bxs=\{/.test(text)) {
          offenders.push(`${rel(file)}:${line} legacy xs= prop (inert under Grid v2)`);
        }
      }
    }
    expect(offenders, `Use size={{ xs: 12, sm|md: N }} instead:\n${offenders.join("\n")}`).toEqual(
      []
    );
  });

  it("gives every wrapping Stack useFlexGap", () => {
    const offenders = [];
    for (const file of files) {
      const source = stripComments(fs.readFileSync(file, "utf8"));
      if (!source.includes("flexWrap")) continue;
      for (const { text, line } of openingTags(source, "Stack")) {
        if (!text.includes("flexWrap") || text.includes("useFlexGap")) continue;
        if (/flexWrap[=:]\s*[{'"\s]*nowrap/.test(text)) continue;
        offenders.push(`${rel(file)}:${line}`);
      }
    }
    expect(
      offenders,
      `Stack spacing is a margin that wrapped rows inherit — add useFlexGap:\n${offenders.join("\n")}`
    ).toEqual([]);
  });
});
