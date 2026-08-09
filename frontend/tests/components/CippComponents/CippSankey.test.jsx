import React from "react";
import { describe, it, expect, vi, beforeEach } from "vitest";
import { render } from "@testing-library/react";

// A sankey is three node columns plus labels. Desktop draws labels horizontally inside an
// 18px node; at ~350px they overrun the node and collide with the links, which is what
// "messed up on mobile" looks like. Assert the narrow-screen geometry instead of pixels.
const layoutState = vi.hoisted(() => ({ isMobile: false }));
vi.mock("../../../src/hooks/use-breakpoint", () => ({
  useIsMobileLayout: () => layoutState.isMobile,
  useIsTabletLayout: () => false,
  useTableViewMode: () => "table",
}));

vi.mock("../../../src/hooks/use-settings", () => ({
  useSettings: () => ({ currentTheme: { value: "light" } }),
}));

const sankeyProps = vi.hoisted(() => ({ last: null }));
vi.mock("@nivo/sankey", () => ({
  ResponsiveSankey: (props) => {
    sankeyProps.last = props;
    return <div data-testid="sankey" />;
  },
}));

import { CippSankey } from "../../../src/components/CippComponents/CippSankey";

const data = {
  nodes: [{ id: "A", nodeColor: "red" }, { id: "B", nodeColor: "blue" }],
  links: [{ source: "A", target: "B", value: 1 }],
};

describe("CippSankey", () => {
  beforeEach(() => {
    layoutState.isMobile = false;
    sankeyProps.last = null;
  });

  it("keeps horizontal inside labels and blended gradient links on desktop", () => {
    render(<CippSankey data={data} />);
    expect(sankeyProps.last.labelOrientation).toBe("horizontal");
    expect(sankeyProps.last.nodeThickness).toBe(18);
    expect(sankeyProps.last.enableLinkGradient).toBe(true);
    expect(sankeyProps.last.linkBlendMode).toBe("multiply");
  });

  // Bare node bars with no ribbons between them: mix-blend-mode on SVG is unreliable in
  // mobile WebKit and can composite gradient-filled links away entirely.
  it("draws links without blend modes or gradients on narrow screens", () => {
    layoutState.isMobile = true;
    render(<CippSankey data={data} />);

    expect(sankeyProps.last.linkBlendMode).toBe("normal");
    expect(sankeyProps.last.enableLinkGradient).toBe(false);
    expect(sankeyProps.last.linkOpacity).toBeGreaterThan(0.5);
    expect(sankeyProps.last.linkContract).toBe(0);
  });

  it("rotates labels and thins the nodes on narrow screens", () => {
    layoutState.isMobile = true;
    render(<CippSankey data={data} />);

    expect(sankeyProps.last.labelOrientation).toBe("vertical");
    expect(sankeyProps.last.nodeThickness).toBeLessThan(18);
    expect(sankeyProps.last.nodeSpacing).toBeLessThan(24);
    expect(sankeyProps.last.labelPadding).toBeLessThan(16);
    // margins shrink so the chart itself keeps the width it has
    expect(sankeyProps.last.margin.left).toBeLessThan(10);
    expect(sankeyProps.last.theme.labels.text.fontSize).toBeLessThan(12);
  });
});
