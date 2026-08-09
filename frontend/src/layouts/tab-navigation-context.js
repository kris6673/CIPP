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
 * Lets a page's mobile FAB adopt the tab bar owned by a tabbed layout.
 *
 * Below md the scrollable tab row costs a band of vertical space and still hides tabs off
 * the right edge, so navigation moves into the bottom-right sheet instead. The corner only
 * fits one FAB, and about half the tabbed pages already grow one from a table's
 * `cardButton` — hence the claim registry: whichever FAB is already on screen renders the
 * tab list, and the layout supplies its own only when nothing else has claimed the corner.
 */
export const TabNavigationContext = createContext(null)

export const useTabNavigation = () => useContext(TabNavigationContext)

/**
 * Claims the bottom-right corner while `active`. A claimant takes responsibility for
 * making the tabs reachable — or for deliberately withholding them, as the card list does
 * while its select-mode bulk bar owns the bottom of the screen.
 */
export const useTabFabClaim = (active) => {
  const context = useContext(TabNavigationContext)
  const claimId = useId()
  const claim = context?.claim
  const release = context?.release

  useEffect(() => {
    if (!active || !claim || !release) return undefined
    claim(claimId)
    return () => release(claimId)
  }, [active, claim, release, claimId])
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
  const [claims, setClaims] = useState([])

  const claim = useCallback((id) => {
    setClaims((prev) => (prev.includes(id) ? prev : [...prev, id]))
  }, [])

  const release = useCallback((id) => {
    setClaims((prev) => prev.filter((claimId) => claimId !== id))
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
      isClaimed: claims.length > 0,
    }),
    [enabled, tabs, currentPath, onNavigate, actions, providesGutters, claim, release, claims.length]
  )
}
