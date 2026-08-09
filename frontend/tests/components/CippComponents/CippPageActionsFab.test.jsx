import { describe, it, expect, vi } from "vitest";
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Button, ListItemButton, MenuItem, Typography } from "@mui/material";
import { CippPageActionsFab } from "../../../src/components/CippComponents/CippPageActionsFab";
import { renderWithProviders } from "../../test-utils";

const openSheet = async (user, label = "Page actions") => {
  await user.click(screen.getByRole("button", { name: label }));
  await screen.findByText("Sheet content");
};

describe("CippPageActionsFab", () => {
  it("renders the FAB and opens the sheet with its children", async () => {
    const user = userEvent.setup();
    renderWithProviders(
      <CippPageActionsFab>
        <Typography>Sheet content</Typography>
        <Button>Do a thing</Button>
      </CippPageActionsFab>
    );

    expect(screen.queryByText("Sheet content")).not.toBeInTheDocument();
    await openSheet(user);

    expect(screen.getByText("Sheet content")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Do a thing" })).toBeInTheDocument();
    expect(screen.getByText("Actions")).toBeInTheDocument();
  });

  it("uses custom title and aria-label", async () => {
    const user = userEvent.setup();
    renderWithProviders(
      <CippPageActionsFab title="Dashboard actions" ariaLabel="Dashboard shortcuts">
        <Typography>Sheet content</Typography>
      </CippPageActionsFab>
    );

    await openSheet(user, "Dashboard shortcuts");
    expect(screen.getByText("Dashboard actions")).toBeInTheDocument();
  });

  it("closes the sheet when a child button is tapped", async () => {
    const user = userEvent.setup();
    const onClick = vi.fn();
    renderWithProviders(
      <CippPageActionsFab>
        <Typography>Sheet content</Typography>
        <Button onClick={onClick}>Do a thing</Button>
      </CippPageActionsFab>
    );

    await openSheet(user);
    await user.click(screen.getByRole("button", { name: "Do a thing" }));

    expect(onClick).toHaveBeenCalledTimes(1);
    await waitFor(() => expect(screen.queryByText("Sheet content")).not.toBeInTheDocument());
  });

  it("closes the sheet when a child link is tapped", async () => {
    const user = userEvent.setup();
    renderWithProviders(
      <CippPageActionsFab restackButtons={false}>
        <Typography>Sheet content</Typography>
        <ListItemButton component="a" href="https://example.test" target="_blank">
          External portal
        </ListItemButton>
      </CippPageActionsFab>
    );

    await openSheet(user);
    await user.click(screen.getByRole("link", { name: "External portal" }));

    await waitFor(() => expect(screen.queryByText("Sheet content")).not.toBeInTheDocument());
  });

  it("closes the sheet when a MenuItem child is tapped", async () => {
    // ExecutiveReportButton renders variant="menuItem" — a <li role="menuitem">, not a button
    const user = userEvent.setup();
    const onClick = vi.fn();
    renderWithProviders(
      <CippPageActionsFab restackButtons={false}>
        <Typography>Sheet content</Typography>
        <MenuItem onClick={onClick}>Executive Summary</MenuItem>
      </CippPageActionsFab>
    );

    await openSheet(user);
    await user.click(screen.getByRole("menuitem", { name: "Executive Summary" }));

    expect(onClick).toHaveBeenCalledTimes(1);
    await waitFor(() => expect(screen.queryByText("Sheet content")).not.toBeInTheDocument());
  });

  it("keeps the sheet open when non-interactive content is tapped", async () => {
    const user = userEvent.setup();
    renderWithProviders(
      <CippPageActionsFab>
        <Typography>Sheet content</Typography>
      </CippPageActionsFab>
    );

    await openSheet(user);
    await user.click(screen.getByText("Sheet content"));

    expect(screen.getByText("Sheet content")).toBeInTheDocument();
  });
});
