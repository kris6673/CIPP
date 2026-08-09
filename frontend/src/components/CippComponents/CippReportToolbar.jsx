import {
  Box,
  Button,
  IconButton,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Tooltip,
} from '@mui/material'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import { useForm, useWatch } from 'react-hook-form'
import { useSettings } from '../../hooks/use-settings'
import { useIsMobileLayout } from '../../hooks/use-breakpoint'
import { ApiGetCall } from '../../api/ApiCall.jsx'
import { useQueryClient } from '@tanstack/react-query'
import {
  Add,
  Delete as DeleteIcon,
  Edit,
  MoreVert,
  Refresh as RefreshIcon,
  Sync,
} from '@mui/icons-material'
import CippFormComponent from './CippFormComponent'
import { CippAddTestReportDrawer } from './CippAddTestReportDrawer'
import { CippApiDialog } from './CippApiDialog'
import { CippBottomSheet } from './CippBottomSheet'
import { useSheetHandoff } from '../../hooks/use-sheet-handoff'

export const CippReportToolbar = () => {
  const settings = useSettings()
  const router = useRouter()
  const { currentTenant } = settings
  const queryClient = useQueryClient()
  const isMobile = useIsMobileLayout()
  const [deleteDialog, setDeleteDialog] = useState({ open: false })
  const [refreshDialog, setRefreshDialog] = useState({ open: false })
  const [actionSheetOpen, setActionSheetOpen] = useState(false)
  // Every row here opens a drawer or dialog — let the sheet close first
  const actionSheet = useSheetHandoff(() => setActionSheetOpen(false))
  const [createDrawerOpen, setCreateDrawerOpen] = useState(false)
  const [editDrawerOpen, setEditDrawerOpen] = useState(false)

  const defaultReportId =
    settings.UserSpecificSettings?.defaultTestSuite?.value ||
    settings.defaultTestSuite?.value ||
    'ztna'
  const selectedReport =
    router.isReady && !router.query.reportId
      ? defaultReportId
      : router.query.reportId || defaultReportId

  const formControl = useForm({ mode: 'onChange' })
  const reportIdValue = useWatch({ control: formControl.control })

  const reportsApi = ApiGetCall({
    url: '/api/ListTestReports',
    queryKey: 'ListTestReports',
  })

  const reports = reportsApi.data || []

  useEffect(() => {
    if (selectedReport && router.isReady && reports.length > 0) {
      const matchingReport = reports.find((r) => r.id === selectedReport)
      if (matchingReport) {
        formControl.setValue('reportId', {
          value: matchingReport.id,
          label: matchingReport.name,
        })
      }
    }
  }, [selectedReport, router.isReady, reports])

  useEffect(() => {
    if (reportIdValue?.reportId?.value && reportIdValue.reportId.value !== selectedReport) {
      router.push(
        {
          pathname: router.pathname,
          query: { ...router.query, reportId: reportIdValue.reportId.value },
        },
        undefined,
        { shallow: true }
      )
    }
  }, [reportIdValue])

  const handleRefresh = () => {
    reportsApi.refetch()
    queryClient.invalidateQueries({
      queryKey: [`${currentTenant}-ListTests-${selectedReport}`],
    })
  }

  const selectedReportObject = reports.find((r) => r.id === selectedReport)
  const isBuiltIn = selectedReportObject?.source === 'file'
  const selectedCustomReport = selectedReportObject?.type === 'custom' ? selectedReportObject : null

  const openRefreshDialog = () => {
    setRefreshDialog({
      open: true,
      handleClose: () => setRefreshDialog({ open: false }),
    })
  }

  const openDeleteDialog = () => {
    const report = reports.find((r) => r.id === selectedReport)
    if (report) {
      setDeleteDialog({
        open: true,
        handleClose: () => setDeleteDialog({ open: false }),
        row: { ReportId: selectedReport, name: report.name },
      })
    }
  }

  const suiteSelector = (withRefreshAction) => (
    <CippFormComponent
      name="reportId"
      label="Select a test suite"
      type="autoComplete"
      multiple={false}
      formControl={formControl}
      disableClearable={true}
      options={reports.map((r) => ({
        label: r.name,
        value: r.id,
        description: r.description,
      }))}
      placeholder="Choose a test suite"
      {...(withRefreshAction && {
        customAction: {
          position: 'outside',
          icon: <RefreshIcon fontSize="small" />,
          tooltip: 'Refresh test suites',
          onClick: handleRefresh,
        },
      })}
      isFetching={reportsApi.isFetching}
    />
  )

  return (
    <>
      {isMobile ? (
        // Selector + kebab only; suite actions live in the bottom sheet. The overlays they
        // open are mounted below, outside the sheet, so closing it doesn't unmount them.
        <Box sx={{ display: 'flex', gap: 1, alignItems: 'center', width: '100%' }}>
          <Box sx={{ flex: 1, minWidth: 0 }}>{suiteSelector(false)}</Box>
          <IconButton
            aria-label="Test suite actions"
            onClick={() => setActionSheetOpen(true)}
            sx={{ minWidth: 44, minHeight: 44 }}
          >
            <MoreVert />
          </IconButton>
        </Box>
      ) : (
        <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'center', width: '100%' }}>
          {/* minWidth: 0 lets the selector shrink when the row is tight instead of pushing
              the trailing buttons off-screen. Layout is unchanged at widths where it fit. */}
          <Box sx={{ flex: 1, minWidth: 0 }}>{suiteSelector(true)}</Box>
          <CippAddTestReportDrawer />
          <Button
            variant="contained"
            color="primary"
            sx={{
              minWidth: 'auto',
              fontWeight: 'bold',
              textTransform: 'none',
              borderRadius: 2,
              boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
              transition: 'all 0.2s ease-in-out',
              px: 2,
            }}
            onClick={openRefreshDialog}
            startIcon={<RefreshIcon />}
          >
            Refresh
          </Button>
          <Tooltip
            title={
              isBuiltIn ? 'Built-in test suites cannot be edited' : 'Edit this custom test suite'
            }
            arrow
          >
            <Box component="span">
              <CippAddTestReportDrawer
                buttonText="Edit"
                mode="edit"
                reportToEdit={selectedCustomReport}
                disabled={!selectedCustomReport}
              />
            </Box>
          </Tooltip>
          <Tooltip
            title={
              isBuiltIn ? 'Built-in test suites cannot be deleted' : 'Delete this custom test suite'
            }
            arrow
          >
            <Box component="span">
              <Button
                variant="contained"
                color="error"
                disabled={isBuiltIn}
                startIcon={<DeleteIcon />}
                sx={{
                  fontWeight: 'bold',
                  textTransform: 'none',
                  borderRadius: 2,
                  boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
                  transition: 'all 0.2s ease-in-out',
                }}
                onClick={openDeleteDialog}
              >
                Delete
              </Button>
            </Box>
          </Tooltip>
        </Box>
      )}

      {isMobile && (
        <>
          <CippBottomSheet
            open={actionSheetOpen}
            onClose={actionSheet.cancel}
            onExited={actionSheet.handleExited}
            title="Test suite actions"
          >
            <List sx={{ py: 0 }}>
              <ListItemButton
                sx={{ minHeight: 48 }}
                onClick={() => actionSheet.run(() => setCreateDrawerOpen(true))}
              >
                <ListItemIcon sx={{ minWidth: 40 }}>
                  <Add fontSize="small" />
                </ListItemIcon>
                <ListItemText primary="Create Suite" />
              </ListItemButton>
              <ListItemButton
                sx={{ minHeight: 48 }}
                onClick={() => actionSheet.run(() => openRefreshDialog())}
              >
                <ListItemIcon sx={{ minWidth: 40 }}>
                  <RefreshIcon fontSize="small" />
                </ListItemIcon>
                <ListItemText primary="Run Tests" secondary="Refresh cached data or re-run tests" />
              </ListItemButton>
              <ListItemButton
                sx={{ minHeight: 48 }}
                disabled={!selectedCustomReport}
                onClick={() => actionSheet.run(() => setEditDrawerOpen(true))}
              >
                <ListItemIcon sx={{ minWidth: 40 }}>
                  <Edit fontSize="small" />
                </ListItemIcon>
                <ListItemText
                  primary="Edit Suite"
                  secondary={
                    // Tooltips don't work on touch — surface the reason inline instead
                    !selectedCustomReport ? 'Built-in test suites cannot be edited' : undefined
                  }
                />
              </ListItemButton>
              <ListItemButton
                sx={{ minHeight: 48, color: 'error.main' }}
                disabled={isBuiltIn}
                onClick={() => actionSheet.run(() => openDeleteDialog())}
              >
                <ListItemIcon sx={{ minWidth: 40, color: 'error.main' }}>
                  <DeleteIcon fontSize="small" />
                </ListItemIcon>
                <ListItemText
                  primary="Delete Suite"
                  secondary={isBuiltIn ? 'Built-in test suites cannot be deleted' : undefined}
                />
              </ListItemButton>
              <ListItemButton
                sx={{ minHeight: 48 }}
                onClick={() => actionSheet.run(() => handleRefresh())}
              >
                <ListItemIcon sx={{ minWidth: 40 }}>
                  <Sync fontSize="small" />
                </ListItemIcon>
                <ListItemText primary="Reload suite list" />
              </ListItemButton>
            </List>
          </CippBottomSheet>
          <CippAddTestReportDrawer
            hideTrigger
            open={createDrawerOpen}
            onClose={() => setCreateDrawerOpen(false)}
          />
          <CippAddTestReportDrawer
            hideTrigger
            mode="edit"
            reportToEdit={selectedCustomReport}
            open={editDrawerOpen}
            onClose={() => setEditDrawerOpen(false)}
          />
        </>
      )}

      <CippApiDialog
        createDialog={deleteDialog}
        title="Delete Custom Test Suite"
        fields={[]}
        api={{
          url: '/api/DeleteTestReport',
          type: 'POST',
          data: { ReportId: selectedReport },
          confirmText: 'Are you sure you want to delete this test suite? This action cannot be undone.',
          relatedQueryKeys: ['ListTestReports'],
        }}
      />

      <CippApiDialog
        createDialog={refreshDialog}
        title="Refresh Test Data"
        fields={[
          {
            type: 'radio',
            name: 'mode',
            label: 'What would you like to refresh?',
            defaultValue: 'both',
            options: [
              { label: 'Cache & Tests (full refresh)', value: 'both' },
              { label: 'Cache only (collect tenant data)', value: 'cache' },
              { label: 'Tests only (re-run against existing cache)', value: 'tests' },
            ],
            validators: { required: 'Please select a refresh mode' },
          },
        ]}
        api={{
          url: '/api/ExecTestRun',
          type: 'POST',
          data: { tenantFilter: currentTenant },
          confirmText: `Choose what to refresh for ${currentTenant}. A full refresh can take up to 2 hours; tests-only is much faster when the cache is already populated.`,
          relatedQueryKeys: [`${currentTenant}-ListTests-${selectedReport}`],
        }}
      />
    </>
  )
}
