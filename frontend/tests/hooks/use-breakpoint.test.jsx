import React from 'react'
import { screen } from '@testing-library/react'
import { renderWithProviders, settingsWith } from '../test-utils'
import { useTableViewMode } from '../../src/hooks/use-breakpoint'

// jsdom has no width-based matchMedia, so useIsMobileLayout is always false here —
// which is exactly why the explicit settings/prop path must exist and is what we test.
const Probe = (props) => <div data-testid="mode">{useTableViewMode(props)}</div>

const renderMode = (props, settings) =>
  renderWithProviders(<Probe {...props} />, settings ? { settings: settingsWith(settings) } : undefined)

describe('useTableViewMode', () => {
  it("defaults to 'table' on desktop-width (auto + not mobile)", () => {
    renderMode()
    expect(screen.getByTestId('mode')).toHaveTextContent('table')
  })

  it('settings.tableViewMode=cards forces cards', () => {
    renderMode({}, { tableViewMode: 'cards' })
    expect(screen.getByTestId('mode')).toHaveTextContent('cards')
  })

  it('accepts {value,label} shaped settings', () => {
    renderMode({}, { tableViewMode: { value: 'cards', label: 'Card list' } })
    expect(screen.getByTestId('mode')).toHaveTextContent('cards')
  })

  it('per-call viewMode prop beats settings', () => {
    renderMode({ viewMode: 'table' }, { tableViewMode: 'cards' })
    expect(screen.getByTestId('mode')).toHaveTextContent('table')
  })

  it('simple always forces table, even against explicit cards', () => {
    renderMode({ viewMode: 'cards', simple: true }, { tableViewMode: 'cards' })
    expect(screen.getByTestId('mode')).toHaveTextContent('table')
  })

  it('invalid mode values fall back to auto behavior', () => {
    renderMode({}, { tableViewMode: 'bogus' })
    expect(screen.getByTestId('mode')).toHaveTextContent('table')
  })
})
