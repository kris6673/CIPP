import React from 'react'
import { within, expect, userEvent, waitFor } from 'storybook/test'
import {
  Button,
  Dialog,
  DialogContent,
  List,
  ListItemButton,
  ListItemText,
  Typography,
} from '@mui/material'
import { CippBottomSheet } from '../../../src/components/CippComponents/CippBottomSheet'

// The mobile stand-in for a desktop Menu: every place the app opens a Menu on a pointer
// device opens one of these below md instead.
const SheetHarness = ({ children, triggerLabel = 'Open sheet', ...sheetProps }) => {
  const [open, setOpen] = React.useState(false)
  return (
    <>
      <Button variant="contained" onClick={() => setOpen(true)}>
        {triggerLabel}
      </Button>
      <CippBottomSheet open={open} onClose={() => setOpen(false)} {...sheetProps}>
        {children}
      </CippBottomSheet>
    </>
  )
}

const actionRows = ['Edit user', 'Reset password', 'Block sign-in'].map((label) => (
  <ListItemButton key={label} sx={{ minHeight: 48 }}>
    <ListItemText primary={label} />
  </ListItemButton>
))

export default {
  title: 'Components/CippComponents/CippBottomSheet',
  component: CippBottomSheet,
  tags: ['autodocs'],
}

export const WithTitle = {
  render: () => (
    <SheetHarness title="Row actions">
      <List sx={{ py: 0 }}>{actionRows}</List>
    </SheetHarness>
  ),
  play: async ({ canvasElement, step }) => {
    const canvas = within(canvasElement)
    const body = within(document.body)

    await step('opens on tap and shows its rows', async () => {
      await userEvent.click(canvas.getByRole('button', { name: 'Open sheet' }))
      await waitFor(() => expect(body.getByText('Row actions')).toBeInTheDocument())
      expect(body.getByText('Reset password')).toBeInTheDocument()
    })

    await step('closes on backdrop tap', async () => {
      await userEvent.click(document.querySelector('.MuiBackdrop-root'))
      await waitFor(() => expect(body.queryByText('Row actions')).not.toBeInTheDocument())
    })
  },
}

export const WithFooter = {
  render: () => (
    <SheetHarness
      title="Bulk actions"
      footer={
        <Button fullWidth variant="contained">
          Apply to 12 selected
        </Button>
      }
    >
      <List sx={{ py: 0 }}>{actionRows}</List>
    </SheetHarness>
  ),
}

export const LongContentScrolls = {
  render: () => (
    <SheetHarness title="Fields shown">
      <List sx={{ py: 0 }}>
        {Array.from({ length: 30 }, (_, i) => (
          <ListItemButton key={i} sx={{ minHeight: 48 }}>
            <ListItemText primary={`Column ${i + 1}`} />
          </ListItemButton>
        ))}
      </List>
    </SheetHarness>
  ),
}

// Regression guard for the live bug: popout table dialogs sit at zIndex.modal (1300), so a
// plain Drawer (1200) opened from inside one is invisible. The sheet claims modal + 1.
export const OverADialog = {
  render: () => {
    const [dialogOpen, setDialogOpen] = React.useState(true)
    return (
      <>
        <Button variant="outlined" onClick={() => setDialogOpen(true)}>
          Reopen dialog
        </Button>
        <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} fullWidth>
          <DialogContent>
            <Typography variant="body2" sx={{ mb: 2 }}>
              A popout table lives here. Its filter sheet must layer above this dialog.
            </Typography>
            <SheetHarness title="Filters" triggerLabel="Open filters">
              <List sx={{ py: 0 }}>{actionRows}</List>
            </SheetHarness>
          </DialogContent>
        </Dialog>
      </>
    )
  },
  play: async ({ step }) => {
    const body = within(document.body)

    await step('sheet renders above the dialog', async () => {
      await userEvent.click(body.getByRole('button', { name: 'Open filters' }))
      const sheetRoot = await waitFor(() => {
        const title = body.getByText('Filters')
        return title.closest('.MuiDrawer-root')
      })
      const dialogRoot = document.querySelector('.MuiDialog-root')
      const sheetZ = Number(window.getComputedStyle(sheetRoot).zIndex)
      const dialogZ = Number(window.getComputedStyle(dialogRoot).zIndex)
      expect(sheetZ).toBeGreaterThan(dialogZ)
    })
  },
}
