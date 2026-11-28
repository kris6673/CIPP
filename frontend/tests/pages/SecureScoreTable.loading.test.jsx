import React from 'react'
import { describe, it, expect, vi } from 'vitest'
import { renderWithProviders } from '../test-utils'

const tablePage = vi.hoisted(() => ({ props: null }))
const secureScore = vi.hoisted(() => ({ value: null }))
vi.mock('../../src/hooks/use-securescore', () => ({
  useSecureScore: () => secureScore.value,
}))
vi.mock('../../src/components/CippComponents/CippTablePage', () => ({
  default: (props) => {
    tablePage.props = props
    return null
  },
}))
vi.mock('../../src/components/CippCards/CippInfoBar', () => ({
  CippInfoBar: () => null,
}))

import Page from '../../src/pages/tenant/administration/securescore/table.jsx'

describe('Secure Score table page', () => {
  it('passes the loading state to the table so it shows skeletons', () => {
    secureScore.value = { isFetching: true, isError: false, translatedData: [] }
    renderWithProviders(<Page />)
    expect(tablePage.props.isFetching).toBe(true)
  })
})
