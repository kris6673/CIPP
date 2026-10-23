import { useEffect, useState } from 'react'
import { useRouter } from 'next/router'
import { useForm } from 'react-hook-form'
import { Button } from '@mui/material'
import { Grid } from '@mui/system'
import { CippTablePage } from '../../../../components/CippComponents/CippTablePage.jsx'
import { CippFormComponent } from '../../../../components/CippComponents/CippFormComponent.jsx'
import CippButtonCard from '../../../../components/CippCards/CippButtonCard'
import { CippIcons } from '../../../../utils/icon-registry'
import { Layout as DashboardLayout } from '../../../../layouts/index'
import { TabbedLayout } from '../../../../layouts/TabbedLayout'
import tabOptions from './tabOptions.json'

// Run history is kept for 30 days; ListAlertRunHistory caps Days there too.
const MAX_DAYS = 30

const Page = () => {
  const router = useRouter()
  const taskId = router.query.taskId
  // One alert: its whole retained history. Every alert: the last day, which is already one row per run per tenant.
  const defaultDays = taskId ? MAX_DAYS : 1
  const formControl = useForm({ defaultValues: { Days: defaultDays } })
  const [appliedDays, setAppliedDays] = useState(null)
  const [filterExpanded, setFilterExpanded] = useState(false)
  const days = appliedDays ?? defaultDays

  // taskId arrives once the router is ready, after the form was created with the all-alerts default.
  useEffect(() => {
    formControl.reset({ Days: defaultDays })
  }, [defaultDays])

  const handleFilterSubmit = formControl.handleSubmit((data) => {
    setAppliedDays(Math.min(Math.max(Number(data.Days) || 1, 1), MAX_DAYS))
    setFilterExpanded(false)
  })

  if (!router.isReady) return null

  const tableFilter = (
    <CippButtonCard
      title="Filter Options"
      component="accordion"
      accordionExpanded={filterExpanded}
      onAccordionChange={setFilterExpanded}
    >
      <Grid container spacing={2}>
        <Grid size={{ sm: 6, xs: 12 }}>
          <CippFormComponent
            type="number"
            label="Days"
            name="Days"
            formControl={formControl}
            fullWidth
            helperText={`Days of run history to show, up to ${MAX_DAYS}`}
          />
        </Grid>
        <Grid size={{ xs: 12 }}>
          <Button
            variant="contained"
            color="primary"
            onClick={handleFilterSubmit}
            startIcon={<CippIcons.FilterList />}
          >
            Apply Filter
          </Button>
        </Grid>
      </Grid>
    </CippButtonCard>
  )

  return (
    <CippTablePage
      title={`Run History${taskId ? ' for this alert' : ''} (last ${days === 1 ? '24 hours' : `${days} days`})`}
      tableFilter={tableFilter}
      apiUrl="/api/ListAlertRunHistory"
      apiData={{ tenantFilter: 'AllTenants', Days: days, TaskId: taskId }}
      tenantInTitle={false}
      simpleColumns={[
        'ExecutedTime',
        'ScheduledTime',
        'TaskName',
        'Tenant',
        'Outcome',
        'Summary',
        'New',
        'Reopened',
        'Resolved',
        'DurationMs',
      ]}
      queryKey={`ListAlertRunHistory-${taskId ?? 'all'}-${days}`}
    />
  )
}

Page.getLayout = (page) => (
  <DashboardLayout>
    <TabbedLayout tabOptions={tabOptions}>{page}</TabbedLayout>
  </DashboardLayout>
)

export default Page
