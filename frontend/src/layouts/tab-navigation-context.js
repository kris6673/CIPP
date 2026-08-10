import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useId,
  useMemo,
  useState,
} from 'react'

/**
 * Lets a tabbed layout hand its tab list — and, on the headered variant, its page actions — to
 * whichever surface is better placed to render them on mobile.
 *
 * Below md the scrollable tab row costs a band of vertical space and still hides tabs off the
 * right edge, so navigation collapses to a picker instead. Two different bits of screen are
 * contested, and they are contested independently:
 *
 *   TAB_SLOT     the mobile title row. A page that already draws a heading (a card list's
 *                "Users · 1,284 results") turns that heading into the picker rather than
 *                stacking a second copy of the same word above it.
 *   ACTION_SLOT  the bottom-right FAB corner, which fits exactly one FAB. About a quarter of
 *                tabbed pages already grow one from a table's `cardButton`, so a headered
 *                layout hands its actions to that FAB instead of adding another.
 *
 * A layout fills either slot itself only when nothing else has claimed it.
 */
export const TabNavigationContext = createContext(null)

export const TAB_SLOT = 'tabs'
export const ACTION_SLOT = 'actions'

export const useTabNavigation = () => useContext(TabNavigationContext)

const EMPTY_CLAIMS = {}

/**
 * Claims `slot` while `active`. A claimant takes responsibility for making that slot's content
 * reachable — the card list, for instance, holds the action corner through select mode, when its
 * bulk bar owns the bottom of the screen and no FAB may be drawn there.
 */
export const useSlotClaim = (slot, active) => {
  const context = useContext(TabNavigationContext)
  const claimId = useId()
  const claim = context?.claim
  const release = context?.release

  useEffect(() => {
    if (!active || !claim || !release) return undefined
    claim(slot, claimId)
    return () => release(slot, claimId)
  }, [slot, active, claim, release, claimId])
}

/**
 * Builds the context value for a tabbed layout. `tabs` are the already-filtered options
 * ({label, path, icon}); `onNavigate` receives a path.
 */
export const useTabNavigationValue = ({
  tabs,
  currentPath,
  onNavigate,
  actions = [],
  enabled,
  // HeaderedTabbedLayout wraps its children in a Container; TabbedLayout does not. Content
  // that renders its own Container (CippFormPage) reads this so the two don't double up.
  providesGutters = false,
}) => {
  const [claims, setClaims] = useState(EMPTY_CLAIMS)

  const claim = useCallback((slot, id) => {
    setClaims((prev) => {
      const ids = prev[slot] ?? []
      if (ids.includes(id)) return prev
      return { ...prev, [slot]: [...ids, id] }
    })
  }, [])

  const release = useCallback((slot, id) => {
    setClaims((prev) => {
      const ids = prev[slot]
      if (!ids?.includes(id)) return prev
      return { ...prev, [slot]: ids.filter((claimId) => claimId !== id) }
    })
  }, [])

  return useMemo(
    () => ({
      enabled,
      tabs,
      currentPath,
      onNavigate,
      actions,
      providesGutters,
      claim,
      release,
      isTabSlotClaimed: (claims[TAB_SLOT]?.length ?? 0) > 0,
      isActionSlotClaimed: (claims[ACTION_SLOT]?.length ?? 0) > 0,
    }),
    [enabled, tabs, currentPath, onNavigate, actions, providesGutters, claim, release, claims]
  )
}
