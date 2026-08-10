import React from 'react'
import { within, userEvent, waitFor, expect } from 'storybook/test'
import { Box, Stack, Typography } from '@mui/material'
import { CippTabPicker } from '../../../src/components/CippComponents/CippTabPicker'
import { TabNavigationContext } from '../../../src/layouts/tab-navigation-context'
import { shrinkToPhoneViewport } from '../../viewport'

// tenant/manage — the worst group in the app for label length. 30 characters on the longest.
const TABS = [
  { label: 'Edit Tenant', path: '/tenant/manage/edit', icon: 'Settings' },
  { label: 'Manage Drift', path: '/tenant/manage/drift', icon: 'Sync' },
  { label: 'Configuration Backup', path: '/tenant/manage/backup', icon: 'Backup' },
  { label: 'Applied Standards Report', path: '/tenant/manage/standards', icon: 'Assessment' },
  {
    label: 'Policies and Settings Deployed',
    path: '/tenant/manage/policies',
    icon: 'Assessment',
  },
]

const withTabs =
  (currentPath = '/tenant/manage/policies', tabs = TABS) =>
  (Story) => (
    <TabNavigationContext.Provider
      value={{
        enabled: true,
        tabs,
        currentPath,
        onNavigate: () => {},
        actions: [],
        claim: () => {},
        release: () => {},
        isTabSlotClaimed: false,
        isActionSlotClaimed: false,
      }}
    >
      <Story />
    </TabNavigationContext.Provider>
  )

export default {
  title: 'Components/CippComponents/CippTabPicker',
  component: CippTabPicker,
  tags: ['autodocs'],
}

// The HeaderedTabbedLayout title row, reproduced: heading left, picker right. jsdom cannot
// answer this one — it has no layout engine, so scrollWidth is always 0 there.
export const TitleRowAtPhoneWidth = {
  decorators: [withTabs()],
  render: () => (
    <Box data-testid="title-row-host" sx={{ px: 2 }}>
      <Stack
        alignItems="flex-start"
        direction="row"
        justifyContent="space-between"
        spacing={1}
      >
        <Stack spacing={1} sx={{ minWidth: 0 }}>
          <Typography variant="h6">Contoso Manufacturing Holdings GmbH</Typography>
          <Typography variant="body2" color="text.secondary">
            4,182 users · M365 E5
          </Typography>
        </Stack>
        <CippTabPicker />
      </Stack>
    </Box>
  ),
  play: async ({ canvasElement, step }) => {
    const onAPhone = await shrinkToPhoneViewport()
    const canvas = within(canvasElement)
    const picker = canvas.getByRole('button', { name: /switch view/i })

    await step('the trigger names the current view', async () => {
      await expect(picker).toHaveAccessibleName(
        'Policies and Settings Deployed switch view'
      )
    })

    if (!onAPhone) return

    await step('the longest label in the app does not widen the row', async () => {
      const host = canvasElement.querySelector('[data-testid="title-row-host"]')
      await waitFor(() => expect(host.scrollWidth).toBeLessThanOrEqual(host.clientWidth))
      // and it stays a control rather than eating the heading's half of the row
      await expect(picker.getBoundingClientRect().width).toBeLessThanOrEqual(
        host.clientWidth / 2 + 1
      )
    })

    await step('the chevron stays pinned to the right edge', async () => {
      const chevron = picker.querySelector('svg:last-of-type')
      const gap = picker.getBoundingClientRect().right - chevron.getBoundingClientRect().right
      await expect(gap).toBeLessThan(16)
    })
  },
}

// A single destination is not navigation — View Group and View Device have one tab each.
export const SingleTabRendersNothing = {
  decorators: [withTabs('/identity/groups/group', [TABS[0]])],
  render: () => (
    <Box data-testid="empty-host">
      <CippTabPicker />
    </Box>
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement)
    await expect(canvas.queryByRole('button', { name: /switch view/i })).toBeNull()
  },
}

// On table pages the current tab and the page heading are the same word, so the heading is
// the trigger rather than sitting under a second copy of itself.
export const HeadingVariant = {
  decorators: [withTabs('/tenant/manage/edit')],
  render: () => (
    <Box sx={{ px: 2, display: 'flex', alignItems: 'baseline', gap: 1 }}>
      <CippTabPicker variant="heading" label="Relationships" />
      <Typography variant="caption" color="text.secondary">
        1,284 results
      </Typography>
    </Box>
  ),
  play: async ({ canvasElement, step }) => {
    const canvas = within(canvasElement)

    await step('the heading is the trigger', async () => {
      const picker = canvas.getByRole('button', { name: /switch view/i })
      await expect(picker).toHaveTextContent('Relationships')
      // named for where you'd go, labelled for where you are
      await expect(picker).toHaveAccessibleName(
        'Relationships switch view, currently Edit Tenant'
      )
    })

    await step('it opens the same sheet', async () => {
      await userEvent.click(canvas.getByRole('button', { name: /switch view/i }))
      const body = within(document.body)
      await waitFor(() => expect(body.getByText('Configuration Backup')).toBeInTheDocument())
      await expect(body.getByText('Views')).toBeInTheDocument()
    })
  },
}
