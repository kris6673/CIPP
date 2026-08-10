import { useState } from 'react'
import { Box, ButtonBase, Typography } from '@mui/material'
import { visuallyHidden } from '@mui/utils'
import { KeyboardArrowDown } from '@mui/icons-material'
import { CippBottomSheet } from './CippBottomSheet'
import { CippTabNavigationSection } from './CippTabNavigationSection'
import { getIconByName } from '../../utils/icon-registry'
import {
  TAB_SLOT,
  useSlotClaim,
  useTabNavigation,
} from '../../layouts/tab-navigation-context'

/**
 * The mobile replacement for a tabbed layout's tab bar: a collapsed trigger that opens the tab
 * list as a bottom sheet.
 *
 * Navigation deliberately lives in the content flow rather than in the page FAB — a FAB is for a
 * screen's primary action, and putting destinations there also made them unreachable whenever
 * something else owned the corner (a card list in select mode draws no FAB at all).
 *
 * Two presentations, one behaviour:
 *   chip      a control beside a heading — HeaderedTabbedLayout's title row, or the row
 *             TabbedLayout supplies when nothing claimed the slot.
 *   heading   the heading *is* the trigger. Used where the page already draws a title that says
 *             the same thing as the current tab, so a separate chip would print it twice.
 */
/**
 * Whether a picker would render anything here — for hosts that need to choose between the
 * picker and their own heading before mounting either. `CippTabPicker` applies the same test
 * internally, so rendering it unconditionally is always safe.
 */
export const useTabPickerAvailable = () => {
  const tabNav = useTabNavigation()
  return Boolean(tabNav?.enabled) && (tabNav?.tabs?.length ?? 0) > 1
}

export const CippTabPicker = (props) => {
  const {
    label,
    variant = 'chip',
    // The claimant renders the picker; a layout's fallback must not claim the slot it is
    // filling, or claiming would flip isTabSlotClaimed, unmount it, release, and loop.
    claimSlot = true,
    sx,
  } = props

  const [open, setOpen] = useState(false)
  const tabNav = useTabNavigation()
  const tabs = tabNav?.tabs ?? []
  // One destination is not navigation. Two pages (View Group, View Device) have a single tab and
  // used to get a FAB whose sheet offered the page you were already on.
  const active = useTabPickerAvailable()
  useSlotClaim(TAB_SLOT, active && claimSlot)

  if (!active) return null

  const current = tabs.find((tab) => tab.path === tabNav.currentPath)
  const text = label ?? current?.label ?? 'Views'
  const isHeading = variant === 'heading'

  return (
    <>
      <ButtonBase
        onClick={() => setOpen(true)}
        aria-haspopup="dialog"
        sx={{
          minWidth: 0,
          display: 'flex',
          alignItems: 'center',
          textAlign: 'left',
          ...(isHeading
            ? { gap: 0.5, borderRadius: 1 }
            : {
                flexShrink: 0,
                // Long labels ("Policies and Settings Deployed" is 30 characters) must not push
                // the heading beside them off the row.
                maxWidth: '50%',
                height: 40,
                gap: 0.75,
                px: 1.25,
                borderRadius: 1,
                bgcolor: 'action.hover',
              }),
          ...sx,
        }}
      >
        {!isHeading &&
          getIconByName(current?.icon, {
            fontSize: 'small',
            sx: { flexShrink: 0, color: 'text.secondary' },
          })}
        <Typography
          variant={isHeading ? 'h6' : 'body2'}
          noWrap
          sx={{ minWidth: 0, flex: 1, fontWeight: isHeading ? undefined : 500 }}
        >
          {text}
        </Typography>
        {/* Not an aria-label: overriding the name would leave the visible text out of it, and
            a voice-control user saying "Relationships" could no longer activate this. The
            hidden suffix extends the name instead of replacing it. */}
        <Box component="span" sx={visuallyHidden}>
          {current && text !== current.label
            ? `switch view, currently ${current.label}`
            : 'switch view'}
        </Box>
        {/* Pinned to the control's edge so it reads as the affordance rather than punctuation
            trailing whatever the current view happens to be called. */}
        <KeyboardArrowDown
          sx={{
            flexShrink: 0,
            ml: 'auto',
            opacity: 0.7,
            fontSize: isHeading ? 20 : 16,
          }}
        />
      </ButtonBase>
      <CippBottomSheet open={open} onClose={() => setOpen(false)} title="Views">
        <CippTabNavigationSection title={null} onNavigate={() => setOpen(false)} />
      </CippBottomSheet>
    </>
  )
}
