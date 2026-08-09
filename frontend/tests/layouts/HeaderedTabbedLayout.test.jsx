import React from "react";
import { describe, it, expect, beforeEach, vi } from "vitest";
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { renderWithProviders } from "../test-utils";

const layoutState = vi.hoisted(() => ({ mdDown: true }));
vi.mock("@mui/material", async (importOriginal) => {
  const actual = await importOriginal();
  return { ...actual, useMediaQuery: () => layoutState.mdDown };
});

vi.mock("next/router", () => ({
  useRouter: () => ({ query: {}, push: vi.fn(), pathname: "/tenant/manage/edit" }),
}));
vi.mock("next/navigation", () => ({ usePathname: () => "/tenant/manage/edit" }));

const idle = vi.hoisted(() => ({
  isSuccess: false,
  isFetching: false,
  isPending: false,
  isError: false,
  data: undefined,
  mutate: () => {},
  reset: () => {},
  refetch: () => {},
}));
vi.mock("../../src/api/ApiCall", () => ({
  ApiGetCall: () => idle,
  ApiPostCall: () => idle,
  ApiGetCallWithPagination: () => ({ ...idle, fetchNextPage: () => {} }),
}));

import { HeaderedTabbedLayout } from "../../src/layouts/HeaderedTabbedLayout";

const tabOptions = [
  { label: "Edit Tenant", path: "/tenant/manage/edit", icon: "Settings" },
  { label: "Manage Drift", path: "/tenant/manage/drift", icon: "Sync" },
];

const actions = [
  {
    label: "Reset Password",
    type: "POST",
    url: "/api/ExecResetPass",
    confirmText: "Reset the password?",
  },
];

const renderLayout = () =>
  renderWithProviders(
    <HeaderedTabbedLayout
      tabOptions={tabOptions}
      title="Adele Vance"
      actions={actions}
      actionsData={{ id: "u-1", userPrincipalName: "adele@contoso.com" }}
    >
      <div>page content</div>
    </HeaderedTabbedLayout>
  );

describe("HeaderedTabbedLayout mobile actions", () => {
  beforeEach(() => {
    layoutState.mdDown = true;
  });

  it("keeps the header Actions menu on desktop and drops it on mobile", async () => {
    renderLayout();
    expect(screen.queryByRole("button", { name: "Actions" })).not.toBeInTheDocument();

    layoutState.mdDown = false;
    renderLayout();
    await waitFor(() =>
      expect(screen.getAllByRole("button", { name: "Actions" }).length).toBeGreaterThan(0)
    );
  });

  // The sheet closing and the overlay opening happen in one tick; MUI's modal manager has
  // to settle the unmounting Drawer before the new one registers, or the overlay never
  // becomes interactive.
  it("opens the action's overlay from the sheet and leaves it open", async () => {
    const user = userEvent.setup();
    renderLayout();

    await user.click(screen.getByRole("button", { name: "Views" }));
    await user.click(await screen.findByText("Reset Password"));

    // sheet goes away — keepMounted keeps its rows in the DOM, so closed means hidden
    await waitFor(() => expect(screen.getByText("Manage Drift")).not.toBeVisible());

    // and the confirmation overlay is present and stays present
    const confirm = await screen.findByText(/Reset the password\?/i, {}, { timeout: 3000 });
    expect(confirm).toBeInTheDocument();
    await new Promise((resolve) => setTimeout(resolve, 400));
    expect(screen.getByText(/Reset the password\?/i)).toBeInTheDocument();
  });
});
