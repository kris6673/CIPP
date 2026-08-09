import { useState } from 'react'
import {
  Divider,
  Fab,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  ListSubheader,
  Stack,
} from '@mui/material'
import { MoreHoriz } from '@mui/icons-material'
import { CippBottomSheet } from './CippBottomSheet'
import { CippTabNavigationSection } from './CippTabNavigationSection'
import {
  useTabFabClaim,
  useTabNavigation,
} from '../../layouts/tab-navigation-context'

// The mobile page-actions pattern: one FAB in the bottom-right corner opening a bottom
// sheet of actions. CippSpeedDial cedes this corner below md, so the FAB is the only
// fixed control there. With restackButtons (default), children laid out for a desktop
// CardHeader are restacked vertically at full width; purpose-built sheet content (list
// rows) should pass restackButtons={false}.
//
// Under a tabbed layout the sheet also carries that layout's tabs, and claims the corner
// so the layout doesn't add a second FAB of its own.
export const CippPageActionsFab = (props) => {
  const {
    title,
    // One glyph for every page-actions FAB. A "+" only ever told the truth on pages whose
    // sheet creates things — on a report page the single action is a sync, and under a
    // tabbed layout the sheet also holds views. MoreVert is the row kebab, so the FAB
    // takes the horizontal variant.
    icon = <MoreHoriz />,
    ariaLabel = 'Page actions',
    restackButtons = true,
    sheetProps,
    // The tabbed layout's own fallback FAB must not claim the corner it is filling —
    // claiming would flip isClaimed, unmount it, release, and loop.
    claimTabCorner = true,
    children,
  } = props

  const [open, setOpen] = useState(false)
  const tabNav = useTabNavigation()
  const showTabs = Boolean(tabNav?.enabled && tabNav.tabs?.length)
  // A tabbed layout may own page-level actions too (HeaderedTabbedLayout's ActionsMenu);
  // they belong in this sheet rather than in a cramped header menu.
  const layoutActions = (tabNav?.enabled && tabNav.actions) || []
  useTabFabClaim(claimTabCorner)

  const hasOwnActions = Boolean(children) || layoutActions.length > 0

  // With both kinds of content the sections label themselves, so a sheet title would only
  // repeat one of them; a single-purpose sheet takes the heading instead of a subheader.
  const sectioned = hasOwnActions && showTabs
  const resolvedTitle = title ?? (sectioned ? undefined : showTabs ? 'Views' : 'Actions')

  return (
    <>
      <Fab
        color="primary"
        aria-label={ariaLabel}
        onClick={() => setOpen(true)}
        sx={{
          position: 'fixed',
          right: 16,
          bottom: 'calc(env(safe-area-inset-bottom) + 20px)',
          zIndex: (theme) => theme.zIndex.speedDial,
        }}
      >
        {icon}
      </Fab>
      <CippBottomSheet
        open={open}
        onClose={() => setOpen(false)}
        title={resolvedTitle}
        {...sheetProps}
      >
        <Stack
          spacing={restackButtons ? 1 : 0}
          sx={{
            p: restackButtons ? 2 : 0,
            ...(restackButtons && {
              '& > * ': { width: '100%' },
              '& .MuiBox-root': {
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'stretch',
                gap: 1,
              },
              '& .MuiButton-root': {
                width: '100%',
                justifyContent: 'flex-start',
                minHeight: 44,
              },
            }),
          }}
          onClick={(event) => {
            // A tap on any action has done its job — close the sheet so the drawer/dialog
            // it opened isn't stacked under it. menuitem covers MenuItem-rendered children.
            if (event.target?.closest?.("button, a, [role='menuitem']")) {
              setOpen(false)
            }
          }}
        >
          {children}
        </Stack>
        {showTabs && (
          <>
            {children ? <Divider sx={{ my: 0.5 }} /> : null}
            <CippTabNavigationSection
              title={sectioned ? 'Views' : null}
              onNavigate={() => setOpen(false)}
            />
          </>
        )}
        {layoutActions.length > 0 && (
          <>
            {sectioned ? <Divider sx={{ my: 0.5 }} /> : null}
            <List
              sx={{ py: 0 }}
              subheader={
                sectioned ? (
                  <ListSubheader disableSticky sx={{ bgcolor: 'transparent' }}>
                    Actions
                  </ListSubheader>
                ) : null
              }
            >
              {layoutActions.map((action, index) => (
                <ListItemButton
                  key={action.label ?? index}
                  disabled={action.disabled}
                  sx={{ minHeight: 48, color: action.color }}
                  onClick={() => {
                    setOpen(false)
                    action.onClick?.()
                  }}
                >
                  {action.icon && (
                    <ListItemIcon sx={{ minWidth: 40, color: action.color }}>
                      {action.icon}
                    </ListItemIcon>
                  )}
                  <ListItemText primary={action.label} />
                </ListItemButton>
              ))}
            </List>
          </>
        )}
      </CippBottomSheet>
    </>
  )
}
