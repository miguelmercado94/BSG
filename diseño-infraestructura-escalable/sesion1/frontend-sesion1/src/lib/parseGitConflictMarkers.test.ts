import { describe, expect, it } from "vitest";

import { hasGitConflictMarkers, parseGitConflictDocument } from "./parseGitConflictMarkers";

describe("parseGitConflictDocument", () => {
  it("parses one conflict and surrounding lines", () => {
    const src = ["line1", "<<<<<<< CURRENT", "old", "=======", "new", ">>>>>>> SUGGESTED", "tail"].join("\n");
    const r = parseGitConflictDocument(src);
    expect(r.ok).toBe(true);
    if (!r.ok) return;
    expect(r.segments).toHaveLength(3);
    expect(r.segments[0]).toEqual({ type: "normal", lines: ["line1"] });
    expect(r.segments[1]).toMatchObject({
      type: "conflict",
      index: 0,
      original: ["old"],
      suggested: ["new"],
    });
    expect(r.segments[2]).toEqual({ type: "normal", lines: ["tail"] });
  });

  it("returns ok false when closing marker missing", () => {
    const src = "<<<<<<< A\nx\n=======\ny\n";
    expect(parseGitConflictDocument(src).ok).toBe(false);
  });
});

describe("hasGitConflictMarkers", () => {
  it("detects minimal markers", () => {
    expect(hasGitConflictMarkers("a\n<<<<<<< X\no\n=======\nn\n>>>>>>> Y\n")).toBe(true);
    expect(hasGitConflictMarkers("no markers")).toBe(false);
  });
});
