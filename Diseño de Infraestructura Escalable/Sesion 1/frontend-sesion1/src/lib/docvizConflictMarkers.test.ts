import { describe, expect, it } from "vitest";

import {
  MARKER_DIV,
  MARKER_OURS,
  MARKER_THEIRS,
  buildResolvedDocvizMerge,
  hasDocvizMergeMarkers,
  parseDocvizMerge,
} from "./docvizConflictMarkers";

describe("docvizConflictMarkers", () => {
  it("parses new ORIGINAL/SUGGESTION format with closing divider", () => {
    const merged = `${MARKER_OURS}\na\n${MARKER_DIV}\n${MARKER_THEIRS}\nc\n${MARKER_DIV}\n`;
    expect(hasDocvizMergeMarkers(merged)).toBe(true);
    const m = parseDocvizMerge(merged);
    expect(m).not.toBeNull();
    if (!m) return;
    expect(m.original).toBe("a");
    expect(m.revised).toBe("c");
  });

  it("parses legacy DocViz markers", () => {
    const legacy =
      "<<<<<<< DocViz (original)\nx\n=======\ny\n>>>>>>> DocViz (propuesto)\n";
    const m = parseDocvizMerge(legacy);
    expect(m?.original).toBe("x");
    expect(m?.revised).toBe("y");
  });

  it("buildResolvedDocvizMerge removes block for theirs", () => {
    const merged = `${MARKER_OURS}\no\n${MARKER_DIV}\n${MARKER_THEIRS}\nn\n${MARKER_DIV}\n`;
    expect(buildResolvedDocvizMerge(`pre\n${merged}\npost`, "theirs")).toBe("pre\nn\npost");
  });
});
