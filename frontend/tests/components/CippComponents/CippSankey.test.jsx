import React from "react";
import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, within } from "@testing-library/react";

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

// The shape that broke on a phone: one node carrying nearly everything and three carrying a
// handful each, so the small ones are a couple of pixels tall and their labels are not.
const lopsided = {
  nodes: [
    { id: "users", label: "Users", nodeColor: "orange" },
    { id: "mfa", label: "Multi factor", nodeColor: "blue" },
    { id: "single", label: "Single factor", nodeColor: "red" },
    { id: "phish", label: "Phishing-resistant", nodeColor: "green" },
  ],
  links: [
    { source: "users", target: "mfa", value: 471 },
    { source: "users", target: "single", value: 3 },
    { source: "users", target: "phish", value: 2 },
  ],
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

  // A node worth 2 of 476 users is a couple of pixels tall; its label, rotated or not, is
  // longer than the node it belongs to, so the small ones stack into an unreadable smear.
  // Below md the chart stops drawing labels and the legend names the nodes instead.
  it("moves node names out of the chart and into a legend on narrow screens", () => {
    layoutState.isMobile = true;
    render(<CippSankey data={lopsided} />);

    expect(sankeyProps.last.enableLabels).toBe(false);

    const legend = screen.getByRole("list");
    const rows = within(legend).getAllByRole("listitem");
    expect(rows).toHaveLength(4);
    expect(legend).toHaveTextContent("Phishing-resistant");
    // weight comes from the links, not the nodes: incoming, or outgoing for the first column
    expect(within(legend).getByText("476")).toBeInTheDocument();
    expect(within(legend).getByText("471")).toBeInTheDocument();
  });

  it("keeps the chart labelled and adds no legend on desktop", () => {
    render(<CippSankey data={lopsided} />);
    expect(sankeyProps.last.enableLabels).toBe(true);
    expect(screen.queryByRole("list")).not.toBeInTheDocument();
  });

  it("makes each legend row a tap target that selects its node", async () => {
    const onNodeClick = vi.fn();
    layoutState.isMobile = true;
    const { default: userEvent } = await import("@testing-library/user-event");
    const user = userEvent.setup();
    render(<CippSankey data={lopsided} onNodeClick={onNodeClick} />);

    await user.click(screen.getByText("Single factor"));
    expect(onNodeClick).toHaveBeenCalledWith(expect.objectContaining({ id: "single" }));
  });
});
