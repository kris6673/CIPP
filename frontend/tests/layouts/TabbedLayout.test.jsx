import React from "react";
import { describe, it, expect, beforeEach, vi } from "vitest";
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Button } from "@mui/material";
import { renderWithProviders } from "../test-utils";

// jsdom has no width-based matchMedia, so the mobile branch is driven by mocking the hook
const layoutState = vi.hoisted(() => ({ isMobile: false }));
vi.mock("../../src/hooks/use-breakpoint", () => ({
  useIsMobileLayout: () => layoutState.isMobile,
  useIsTabletLayout: () => false,
  useTableViewMode: () => "table",
}));

const routerState = vi.hoisted(() => ({ push: vi.fn(), pathname: "/dashboardv2" }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: routerState.push }),
  usePathname: () => routerState.pathname,
  useSearchParams: () => new URLSearchParams(""),
}));

vi.mock("../../src/api/ApiCall", () => ({
  ApiGetCall: () => ({ isSuccess: false, isFetching: false, data: undefined }),
}));

import { TabbedLayout } from "../../src/layouts/TabbedLayout";
import { CippPageActionsFab } from "../../src/components/CippComponents/CippPageActionsFab";

const tabOptions = [
  { label: "Overview", path: "/dashboardv2", icon: "Dashboard" },
  { label: "Identity", path: "/dashboardv2/identity", icon: "Person" },
  { label: "Devices", path: "/dashboardv2/devices", icon: "Devices" },
];

const openFab = async (user, name = "Views") => {
  await user.click(screen.getByRole("button", { name }));
};

describe("TabbedLayout", () => {
  beforeEach(() => {
    layoutState.isMobile = false;
    routerState.push = vi.fn();
    routerState.pathname = "/dashboardv2";
  });

  it("renders a tab bar on desktop and no FAB", () => {
    renderWithProviders(
      <TabbedLayout tabOptions={tabOptions}>
        <div>page content</div>
      </TabbedLayout>
    );

    expect(screen.getByRole("tab", { name: /Overview/ })).toBeInTheDocument();
    expect(screen.getByRole("tab", { name: /Devices/ })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Views" })).not.toBeInTheDocument();
  });

  it("replaces the tab bar with a Views FAB on mobile", async () => {
    layoutState.isMobile = true;
    const user = userEvent.setup();
    renderWithProviders(
      <TabbedLayout tabOptions={tabOptions}>
        <div>page content</div>
      </TabbedLayout>
    );

    expect(screen.queryByRole("tab")).not.toBeInTheDocument();
    await openFab(user);

    // every tab is a full-width row now, none of them scrolled off the edge
    expect(await screen.findByText("Overview")).toBeInTheDocument();
    tabOptions.forEach((tab) => expect(screen.getByText(tab.label)).toBeInTheDocument());
  });

  it("navigates when a tab row is tapped, and does nothing for the current tab", async () => {
    layoutState.isMobile = true;
    const user = userEvent.setup();
    renderWithProviders(
      <TabbedLayout tabOptions={tabOptions}>
        <div>page content</div>
      </TabbedLayout>
    );

    await openFab(user);
    await user.click(await screen.findByText("Devices"));
    expect(routerState.push).toHaveBeenCalledWith("/dashboardv2/devices");

    routerState.push = vi.fn();
    await openFab(user);
    await user.click(await screen.findByText("Overview"));
    expect(routerState.push).not.toHaveBeenCalled();
  });

  // The corner fits one FAB, and about half the tabbed pages already grow one from a
  // table's cardButton — the page's FAB must adopt the tabs rather than stack beside it.
  it("hands the tabs to a page FAB instead of adding a second one", async () => {
    layoutState.isMobile = true;
    const user = userEvent.setup();
    renderWithProviders(
      <TabbedLayout tabOptions={tabOptions}>
        <CippPageActionsFab>
          <Button>Add Variable</Button>
        </CippPageActionsFab>
      </TabbedLayout>
    );

    await waitFor(() =>
      expect(screen.queryByRole("button", { name: "Views" })).not.toBeInTheDocument()
    );
    const fabs = screen.getAllByRole("button", { name: /Page actions|Views/ });
    expect(fabs).toHaveLength(1);

    await user.click(fabs[0]);
    expect(await screen.findByRole("button", { name: "Add Variable" })).toBeInTheDocument();
    expect(screen.getByText("Identity")).toBeInTheDocument();
  });

  // The sheet heading and the section subheader were both saying "Views"
  it("names the views once when the sheet holds nothing else", async () => {
    layoutState.isMobile = true;
    const user = userEvent.setup();
    renderWithProviders(
      <TabbedLayout tabOptions={tabOptions}>
        <div>page content</div>
      </TabbedLayout>
    );

    await openFab(user);
    await screen.findByText("Overview");
    expect(screen.getAllByText("Views")).toHaveLength(1);
  });

  it("labels both sections when a page action shares the sheet", async () => {
    layoutState.isMobile = true;
    const user = userEvent.setup();
    renderWithProviders(
      <TabbedLayout tabOptions={tabOptions}>
        <CippPageActionsFab>
          <Button>Add Variable</Button>
        </CippPageActionsFab>
      </TabbedLayout>
    );

    await user.click(screen.getByRole("button", { name: "Page actions" }));
    await screen.findByText("Overview");
    // one "Views" subheader, and no sheet title repeating it
    expect(screen.getAllByText("Views")).toHaveLength(1);
    expect(screen.queryByText("Actions")).not.toBeInTheDocument();
  });

  it("hides tabs that the user's advanced setting gates off", async () => {
    layoutState.isMobile = true;
    const user = userEvent.setup();
    renderWithProviders(
      <TabbedLayout tabOptions={[...tabOptions, { label: "Diagnostics", path: "/x", advanced: true }]}>
        <div>page content</div>
      </TabbedLayout>
    );

    await openFab(user);
    await screen.findByText("Overview");
    expect(screen.queryByText("Diagnostics")).not.toBeInTheDocument();
  });
});
