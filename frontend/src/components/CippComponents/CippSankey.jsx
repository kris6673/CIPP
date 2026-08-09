import { ResponsiveSankey } from "@nivo/sankey";
import { useSettings } from "../../hooks/use-settings";
import { useIsMobileLayout } from "../../hooks/use-breakpoint";

export const CippSankey = ({ data, onNodeClick, onLinkClick }) => {
  const settings = useSettings();
  const isDark = settings.currentTheme?.value === "dark";
  // A sankey is three columns of nodes plus their labels. At desktop widths the labels sit
  // horizontally inside an 18px-thick node and still read; on a ~350px card they overrun the
  // node and collide with the links. Narrow screens get thinner nodes, tighter spacing and
  // labels rotated to run along the node instead of across the chart.
  const isMobile = useIsMobileLayout();

  const theme = {
    tooltip: {
      container: {
        background: isDark ? "rgba(33, 33, 33, 0.95)" : "rgba(255, 255, 255, 0.95)",
        color: isDark ? "#ffffff" : "#000000",
        border: isDark ? "1px solid #555" : "1px solid #ccc",
        borderRadius: "4px",
        boxShadow: "0 2px 8px rgba(0, 0, 0, 0.15)",
        fontSize: "12px",
        padding: "8px 12px",
      },
    },
    labels: {
      text: {
        fontSize: isMobile ? 9 : 12,
      },
    },
  };

  return (
    <div
      className={`h-full w-full ${isDark ? "sankey-dark-mode" : "sankey-light-mode"}`}
      style={{
        height: "100%",
        width: "100%",
        cursor: onNodeClick || onLinkClick ? "pointer" : "default",
      }}
    >
      <ResponsiveSankey
        data={data}
        theme={theme}
        margin={
          isMobile
            ? { top: 6, right: 4, bottom: 6, left: 4 }
            : { top: 10, right: 10, bottom: 10, left: 10 }
        }
        align="justify"
        colors={(node) => node.nodeColor}
        label={(node) => node.label ?? node.id}
        nodeOpacity={1}
        nodeHoverOthersOpacity={0.35}
        nodeThickness={isMobile ? 10 : 18}
        nodeSpacing={isMobile ? 12 : 24}
        nodeBorderWidth={0}
        nodeBorderColor={{
          from: "color",
          modifiers: [["darker", 0.8]],
        }}
        nodeBorderRadius={3}
        linkOpacity={isMobile ? 0.75 : 0.5}
        linkHoverOthersOpacity={0.1}
        // Contracting each end eats into the gap between node columns; on a narrow chart
        // that gap is small enough that 3px a side visibly thins the ribbons.
        linkContract={isMobile ? 0 : 3}
        // mix-blend-mode on SVG is unreliable in mobile WebKit — combined with a gradient
        // fill it can composite the ribbons to nothing, which shows as bare node bars with
        // no links between them. Blend is decoration here, so mobile renders them plainly
        // and leans on opacity instead.
        linkBlendMode={isMobile ? "normal" : isDark ? "lighten" : "multiply"}
        enableLinkGradient={!isMobile}
        labelPosition="inside"
        labelOrientation={isMobile ? "vertical" : "horizontal"}
        labelPadding={isMobile ? 6 : 16}
        labelTextColor={isDark ? "#ffffff" : "#000000"}
        sort="input"
        legends={[]}
        valueFormat={(value) => `${value}`}
        isInteractive={true}
        onClick={(node, event) => {
          if (onNodeClick && node.id) {
            onNodeClick(node);
          } else if (onLinkClick && node.source) {
            onLinkClick(node);
          }
        }}
      />
    </div>
  );
};
