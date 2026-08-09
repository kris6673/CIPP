import React from 'react'
import { within, expect, userEvent, waitFor } from 'storybook/test'
import { Box, Button } from '@mui/material'
import { Add, Block, Delete, Edit } from '@mui/icons-material'
import { CippDataTable } from '../../../src/components/CippTable/CippDataTable'
import { SettingsProvider } from '../../../src/contexts/settings-context'

// Card view is normally chosen by viewport (below md), but no story in this repo sets a
// viewport — the explicit viewMode prop is the supported override and is what the unit
// tests use too.
const users = [
  {
    id: 'u-1',
    displayName: 'Alice Smith',
    userPrincipalName: 'alice@contoso.com',
    mail: 'alice@contoso.com',
    department: 'IT',
    jobTitle: 'Engineer',
    accountEnabled: true,
    createdDateTime: '2024-01-15T10:30:00Z',
  },
  {
    id: 'u-2',
    displayName: 'Bob Johnson',
    userPrincipalName: 'bob@contoso.com',
    mail: 'bob@contoso.com',
    department: 'Sales',
    jobTitle: 'Account Manager',
    accountEnabled: true,
    createdDateTime: '2024-03-22T14:15:00Z',
  },
  {
    id: 'u-3',
    displayName: 'Carol Williams',
    userPrincipalName: 'carol@contoso.com',
    mail: 'carol@contoso.com',
    department: 'IT',
    jobTitle: 'Director',
    accountEnabled: false,
    createdDateTime: '2023-11-01T09:00:00Z',
  },
]

const manyUsers = Array.from({ length: 120 }, (_, i) => ({
  id: `bulk-${i}`,
  displayName: `User ${String(i).padStart(3, '0')}`,
  userPrincipalName: `user${i}@contoso.com`,
  mail: `user${i}@contoso.com`,
  department: i % 2 ? 'Sales' : 'IT',
  accountEnabled: i % 5 !== 0,
}))

const simpleColumns = ['displayName', 'userPrincipalName', 'accountEnabled', 'department', 'jobTitle']

const actions = [
  { label: 'Edit user', icon: <Edit />, link: '/identity/administration/users/edit?id=[id]' },
  { label: 'Block sign-in', icon: <Block />, type: 'POST', url: '/api/ExecDisableUser' },
  { label: 'Delete user', icon: <Delete />, type: 'POST', url: '/api/RemoveUser', color: 'error' },
]

export default {
  title: 'Components/CippTable/CippMobileCardList',
  component: CippDataTable,
  tags: ['autodocs'],
  args: {
    viewMode: 'cards',
    maxHeightOffset: '100px',
  },
  decorators: [
    (Story) => (
      <SettingsProvider>
        <Box sx={{ maxWidth: 420 }}>
          <Story />
        </Box>
      </SettingsProvider>
    ),
  ],
}

export const Default = {
  args: {
    title: 'Users',
    data: users,
    simpleColumns,
    actions,
  },
  play: async ({ canvasElement, step }) => {
    const canvas = within(canvasElement)

    await step('one card per row, titled by the name column', async () => {
      await waitFor(() => expect(canvas.getByText('Alice Smith')).toBeInTheDocument())
      expect(canvas.getByText('Carol Williams')).toBeInTheDocument()
      // no <table> in card view
      expect(canvasElement.querySelector('table')).toBeNull()
    })

    await step('row kebab opens the action sheet with the page actions', async () => {
      const kebabs = canvas.getAllByRole('button', { name: /row actions/i })
      await userEvent.click(kebabs[0])
      const body = within(document.body)
      await waitFor(() => expect(body.getByText('Block sign-in')).toBeInTheDocument())
      expect(body.getByText('Delete user')).toBeInTheDocument()
    })
  },
}

export const SelectMode = {
  args: {
    title: 'Users',
    data: users,
    simpleColumns,
    actions,
  },
  play: async ({ canvasElement, step }) => {
    const canvas = within(canvasElement)
    await waitFor(() => expect(canvas.getByText('Alice Smith')).toBeInTheDocument())

    await step('Select reveals per-card checkboxes and the bulk bar', async () => {
      await userEvent.click(canvas.getByRole('button', { name: /select/i }))
      const checkboxes = await canvas.findAllByRole('checkbox')
      await userEvent.click(checkboxes[0])
      await waitFor(() => expect(canvasElement.textContent).toContain('1 selected'))
    })
  },
}

export const PageActionsFab = {
  args: {
    title: 'Users',
    data: users,
    simpleColumns,
    cardButton: (
      <Box sx={{ display: 'flex', gap: 1 }}>
        <Button variant="contained" startIcon={<Add />}>
          Add User
        </Button>
        <Button variant="outlined">Bulk Add</Button>
      </Box>
    ),
  },
  play: async ({ canvasElement, step }) => {
    const canvas = within(canvasElement)
    const body = within(document.body)
    await waitFor(() => expect(canvas.getByText('Alice Smith')).toBeInTheDocument())

    await step('cardButton children live behind the FAB', async () => {
      await userEvent.click(body.getByRole('button', { name: 'Page actions' }))
      await waitFor(() => expect(body.getByRole('button', { name: 'Add User' })).toBeInTheDocument())
      expect(body.getByRole('button', { name: 'Bulk Add' })).toBeInTheDocument()
    })
  },
}

export const LoadMore = {
  args: {
    title: 'Users',
    data: manyUsers,
    simpleColumns: ['displayName', 'userPrincipalName', 'accountEnabled'],
  },
  play: async ({ canvasElement, step }) => {
    const canvas = within(canvasElement)

    await step('starts at the configured page size', async () => {
      await waitFor(() => expect(canvasElement.textContent).toContain('Showing 25 of 120'), {
        timeout: 10000,
      })
    })

    await step('Load more grows the same list rather than paging', async () => {
      await userEvent.click(canvas.getByRole('button', { name: /load 50 more/i }))
      await waitFor(() => expect(canvasElement.textContent).toContain('Showing 75 of 120'))
      // still one continuous list — no pagination control appeared
      expect(canvas.queryByRole('button', { name: /go to next page/i })).toBeNull()
    })
  },
}

export const EmptyAfterFilter = {
  args: {
    title: 'Users',
    data: users,
    simpleColumns,
  },
  play: async ({ canvasElement, step }) => {
    const canvas = within(canvasElement)
    await waitFor(() => expect(canvas.getByText('Alice Smith')).toBeInTheDocument())

    await step('a search with no matches offers to clear filters', async () => {
      await userEvent.type(canvas.getByPlaceholderText(/search/i), 'zzzzz')
      await waitFor(
        () => expect(canvas.getByRole('button', { name: /clear filters/i })).toBeInTheDocument(),
        { timeout: 3000 }
      )
    })
  },
}

// The pair that proves "one table instance, two presentations": same data, same filter,
// same resulting row set — only the presentation differs.
const FILTERED_DEPARTMENT = 'IT'

// The search box is debounced 200ms, so the filter landing is observed by waiting for the
// excluded row to disappear — the included rows are on screen before the filter applies.
const applyDepartmentSearch = async (canvas) => {
  await userEvent.type(canvas.getByPlaceholderText(/search/i), FILTERED_DEPARTMENT)
  await waitFor(() => expect(canvas.queryByText('Bob Johnson')).toBeNull(), { timeout: 5000 })
  return [canvas.getByText('Alice Smith'), canvas.getByText('Carol Williams')]
}

export const DesktopTable = {
  args: {
    title: 'Users',
    viewMode: 'table',
    data: users,
    simpleColumns,
  },
  play: async ({ canvasElement, step }) => {
    const canvas = within(canvasElement)

    await step('table view lists exactly the IT users', async () => {
      expect(canvasElement.querySelector('table')).not.toBeNull()
      const matched = await applyDepartmentSearch(canvas)
      expect(matched).toHaveLength(2)
    })
  },
}

export const MobileCards = {
  args: {
    title: 'Users',
    viewMode: 'cards',
    data: users,
    simpleColumns,
  },
  play: async ({ canvasElement, step }) => {
    const canvas = within(canvasElement)

    await step('card view yields the identical row set from the same state', async () => {
      expect(canvasElement.querySelector('table')).toBeNull()
      const matched = await applyDepartmentSearch(canvas)
      expect(matched).toHaveLength(2)
    })
  },
}
