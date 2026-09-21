import { useEffect, useRef, useState } from 'react'
import { useRouter } from 'next/router'
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Container,
  Divider,
  Stack,
  ToggleButton,
  ToggleButtonGroup,
  Typography,
} from '@mui/material'
import {
  Timeline,
  TimelineConnector,
  TimelineContent,
  TimelineDot,
  TimelineItem,
  TimelineOppositeContent,
  TimelineSeparator,
} from '@mui/lab'
import { Grid } from '@mui/system'
import { Layout as DashboardLayout } from '../../../layouts/index'
import { TabbedLayout } from '../../../layouts/TabbedLayout'
import tabOptions from './tabOptions.json'
import { CippHead } from '../../../components/CippComponents/CippHead'
import { CippDataTable } from '../../../components/CippTable/CippDataTable'
import { CippTimeAgo } from '../../../components/CippComponents/CippTimeAgo'
import CippButtonCard from '../../../components/CippCards/CippButtonCard'
import CippFormSkeleton from '../../../components/CippFormPages/CippFormSkeleton'
import { CippBaselineAddStandardDialog } from '../../../components/CippBaselines/CippBaselineAddStandardDialog'
import { CippAlertPresetDialog } from '../../../components/CippComponents/CippAlertPresetDialog'
import { ApiGetCall, ApiPostCall } from '../../../api/ApiCall'
import { getCippError } from '../../../utils/get-cipp-error'
import { useSettings } from '../../../hooks/use-settings'
import { useDialog } from '../../../hooks/use-dialog'
import { CippIcons } from '../../../utils/icon-registry'

const asArray = (value) => (Array.isArray(value) ? value : value ? [value] : [])

const CATEGORY_ORDER = [
  'Identity & Conditional Access',
  'Audit & Detection',
  'Exchange & Email',
  'SharePoint & Data',
]
const severityDot = {
  Critical: 'error.main',
  High: 'warning.main',
  Medium: 'text.secondary',
}
const verdictDot = {
  blocked: 'success',
  pass: 'success',
  partial: 'warning',
  allowed: 'error',
  fail: 'error',
  unknown: 'grey',
  info: 'grey',
}
const outcomeChip = {
  Prevented: { label: 'Prevented', color: 'success' },
  Detected: { label: 'Alerted, not prevented', color: 'warning' },
  NotPrevented: { label: 'Not prevented', color: 'error' },
  NotRun: { label: 'Not checked yet', color: 'default' },
}
const fixStatusColor = {
  Missing: 'error',
  'Not configured': 'error',
  Drift: 'error',
  'Accepted deviation': 'warning',
}
const fixTypeLabel = {
  standard: 'Standard',
  caTemplate: 'CA policy',
  alertPreset: 'Alert',
}

const CheckLine = ({ state, text, note }) => {
  const mark =
    state === true ? '✓' : state === false ? '✕' : state === 'warn' ? '!' : '?'
  const color =
    state === true
      ? 'success.main'
      : state === false
        ? 'error.main'
        : state === 'warn'
          ? 'warning.main'
          : 'text.secondary'
  return (
    <Box sx={{ display: 'flex', alignItems: 'baseline', gap: 1 }}>
      <Typography
        variant="body2"
        sx={{ color, fontWeight: 700, width: 14, flexShrink: 0 }}
      >
        {mark}
      </Typography>
      <Typography variant="body2">
        {text}
        {note && (
          <Typography
            component="span"
            variant="body2"
            sx={{ color: 'text.secondary' }}
          >
            {' '}
            - {note}
          </Typography>
        )}
      </Typography>
    </Box>
  )
}

const Stat = ({ label, value, color }) => (
  <Box>
    <Typography
      variant="caption"
      sx={{
        color: 'text.secondary',
        fontWeight: 600,
        letterSpacing: 0.8,
        textTransform: 'uppercase',
      }}
    >
      {label}
    </Typography>
    <Typography
      variant="subtitle2"
      sx={{ color: color ?? 'text.primary', fontWeight: 700 }}
    >
      {value}
    </Typography>
  </Box>
)

// One action per gap: standards go straight into a baseline, alerts straight into the alert
// rules, both through the same dialogs and endpoints the Baselines and Alerts pages use.
const FixAction = ({ fix, onAddStandard, onEnableAlert }) => {
  const router = useRouter()
  if (fix.type === 'standard' && fix.assigned) {
    return (
      <Button
        size="small"
        sx={{ py: 0, minWidth: 0 }}
        onClick={() => router.push('/tenant/baselines/alignment')}
      >
        Review in alignment
      </Button>
    )
  }
  if (fix.type === 'standard') {
    return (
      <Button
        size="small"
        sx={{ py: 0, minWidth: 0 }}
        onClick={() => onAddStandard(fix)}
      >
        Add to a baseline
      </Button>
    )
  }
  if (fix.type === 'caTemplate') {
    return (
      <Button
        size="small"
        sx={{ py: 0, minWidth: 0 }}
        onClick={() => router.push('/tenant/conditional/list-template')}
      >
        Deploy a CA template
      </Button>
    )
  }
  if (fix.type === 'alertPreset') {
    return (
      <Button
        size="small"
        sx={{ py: 0, minWidth: 0 }}
        onClick={() => onEnableAlert(fix)}
      >
        Enable the alert
      </Button>
    )
  }
  return null
}

const ScenarioRun = ({ tenant, scenarioId, onBack }) => {
  const [mode, setMode] = useState('current')
  const [standardToAdd, setStandardToAdd] = useState(null)
  const [alertToEnable, setAlertToEnable] = useState(null)
  const addStandardDialog = useDialog()
  const alertDialog = useDialog()
  const runQueryKey = `SecuritySimulationRun-${tenant}-${scenarioId}`

  const stored = ApiGetCall({
    url: '/api/ListSecuritySimulations',
    data: { tenantFilter: tenant, scenarioId },
    queryKey: runQueryKey,
    waiting: Boolean(tenant && scenarioId),
  })
  const run = ApiPostCall({
    url: '/api/ExecSecuritySimulation',
    relatedQueryKeys: [`ListSecuritySimulations-${tenant}`, runQueryKey],
  })
  const startRun = () =>
    run.mutate({
      url: '/api/ExecSecuritySimulation',
      data: { tenantFilter: tenant, scenarioId },
    })

  const autoRanRef = useRef(null)
  useEffect(() => {
    setMode('current')
    run.reset()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tenant, scenarioId])
  useEffect(() => {
    if (stored.isFetching || !stored.isSuccess) return
    if (stored.data?.cached === false && autoRanRef.current !== runQueryKey) {
      autoRanRef.current = runQueryKey
      startRun()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stored.data, stored.isFetching, stored.isSuccess, runQueryKey])

  const fresh = run.data?.data
  const result =
    fresh?.scenario?.id === scenarioId
      ? fresh
      : stored.data?.cached
        ? stored.data.result
        : undefined
  const loading = run.isPending || (stored.isFetching && !result)
  const steps = asArray(result?.steps)
  const summary = result?.summary
  const fixes = asArray(summary?.fixes)
  const fixed = mode === 'fixed'
  const prevented = fixed ? summary?.preventedWhenFixed : summary?.prevented
  const preventedStep = steps.find(
    (step) =>
      step.id ===
      (fixed ? summary?.preventedWhenFixedAtStep : summary?.preventedAtStep)
  )
  const alreadyInPlace = [
    ...new Set(
      steps.flatMap((step) =>
        asArray(step.standards)
          .filter((s) => s.compliant === true)
          .map((s) => s.label)
      )
    ),
  ]

  const evaluationFailed = steps.some(
    (step) => step.reached && step.whatIf?.error
  )
  const headline = fixed
    ? prevented
      ? `Blocked at "${preventedStep?.title}"`
      : 'No mapped control stops this chain'
    : prevented
      ? `Blocked at "${preventedStep?.title}"`
      : evaluationFailed
        ? 'The sign-in could not be evaluated'
        : summary?.detected
          ? 'Attack succeeds, but an alert would fire'
          : 'Attack succeeds, undetected'
  const subline = result?.scenario?.outcome
    ? prevented
      ? result.scenario.outcome.prevented
      : result.scenario.outcome.notPrevented
    : ''

  const openAddStandard = (fix) => {
    setStandardToAdd(fix.name)
    addStandardDialog.handleOpen()
  }
  const openEnableAlert = (fix) => {
    setAlertToEnable(fix)
    alertDialog.handleOpen()
  }

  return (
    <Stack spacing={2}>
      <Box>
        <Button
          size="small"
          startIcon={<CippIcons.ArrowBack />}
          onClick={onBack}
        >
          All scenarios
        </Button>
      </Box>
      <Box
        sx={{
          display: 'flex',
          alignItems: 'flex-end',
          gap: 2,
          flexWrap: 'wrap',
        }}
      >
        <Box sx={{ flexGrow: 1, minWidth: 0 }}>
          <Typography variant="h4">
            {result?.scenario?.title ?? 'Checking scenario'}
          </Typography>
          {result?.scenario?.summary && (
            <Typography
              variant="body2"
              sx={{ color: 'text.secondary', mt: 0.5, maxWidth: 720 }}
            >
              {result.scenario.summary}
              {result.identity
                ? ` Sign-ins are evaluated live as ${result.identity.userPrincipalName}.`
                : ''}
            </Typography>
          )}
          {result?.lastRun && (
            <Typography
              variant="caption"
              sx={{ color: 'text.secondary', display: 'block', mt: 0.5 }}
            >
              Checked <CippTimeAgo data={result.lastRun} />
              {result.evidence?.whatIfCalls
                ? ` · ${result.evidence.whatIfCalls} live What If evaluation${result.evidence.whatIfCalls === 1 ? '' : 's'}`
                : ''}
              . Nothing was changed in the tenant.
            </Typography>
          )}
        </Box>
        <Stack direction="row" spacing={1} sx={{ alignItems: 'center' }}>
          <Button
            size="small"
            variant="outlined"
            disabled={loading}
            startIcon={
              run.isPending ? (
                <CircularProgress size={14} color="inherit" />
              ) : undefined
            }
            onClick={startRun}
          >
            {run.isPending ? 'Checking' : 'Run again'}
          </Button>
          {result && (
            <ToggleButtonGroup
              value={mode}
              exclusive
              size="small"
              onChange={(event, newMode) => {
                if (newMode !== null) setMode(newMode)
              }}
              sx={{
                '& .MuiToggleButton-root': {
                  py: 0.5,
                  px: 1.5,
                  fontSize: '0.8125rem',
                },
              }}
            >
              <ToggleButton value="current" aria-label="current state">
                Current state
              </ToggleButton>
              <ToggleButton value="fixed" aria-label="recommended state">
                Recommended state
              </ToggleButton>
            </ToggleButtonGroup>
          )}
        </Stack>
      </Box>

      {run.isError && <Alert severity="error">{getCippError(run.error)}</Alert>}
      {stored.isError && !result && (
        <Alert severity="error">{getCippError(stored.error)}</Alert>
      )}
      {loading && !result && <CippFormSkeleton layout={[1, 3, 1, 1, 1]} />}

      {result && result.licensed === false && (
        <Alert severity="warning">
          This tenant is not licensed for the capabilities this scenario needs,
          so the live sign-in evaluation was skipped. The standards checks still
          ran.
        </Alert>
      )}

      {result && (
        <>
          <Card>
            <CardContent
              sx={{
                display: 'flex',
                alignItems: 'center',
                gap: 4,
                flexWrap: 'wrap',
              }}
            >
              <Box sx={{ flex: 1, minWidth: 260 }}>
                <Typography
                  variant="h6"
                  sx={{
                    color: prevented
                      ? 'success.main'
                      : !fixed && evaluationFailed
                        ? 'warning.main'
                        : 'error.main',
                    fontWeight: 700,
                  }}
                >
                  {headline}
                </Typography>
                <Typography
                  variant="body2"
                  sx={{ color: 'text.secondary', maxWidth: 640 }}
                >
                  {subline}
                </Typography>
              </Box>
              <Stack direction="row" spacing={4}>
                <Stat
                  label="Prevented"
                  value={
                    prevented ? `Yes, step ${preventedStep?.index ?? ''}` : 'No'
                  }
                  color={prevented ? 'success.main' : 'error.main'}
                />
                <Stat
                  label="Alerted"
                  value={fixed || summary?.detected ? 'Yes' : 'No'}
                  color={
                    fixed || summary?.detected ? 'success.main' : 'error.main'
                  }
                />
                <Stat
                  label="Standards in place"
                  value={
                    fixed
                      ? `${summary?.standardsTotal ?? 0} / ${summary?.standardsTotal ?? 0}`
                      : `${summary?.standardsCompliant ?? 0} / ${summary?.standardsTotal ?? 0}`
                  }
                  color={
                    fixed || (summary?.standardsGap ?? 0) === 0
                      ? 'success.main'
                      : 'warning.main'
                  }
                />
              </Stack>
            </CardContent>
          </Card>

          {fixed && (
            <Alert severity="info">
              This view assumes every control listed under "Closes the gaps" is
              in place. The Conditional Access What If API only evaluates
              policies that exist, so sign-in outcomes here are the scenario's
              expected results, not a live evaluation.
            </Alert>
          )}

          <Grid container spacing={3}>
            <Grid size={{ md: 8, xs: 12 }}>
              <Timeline
                sx={{
                  p: 0,
                  m: 0,
                  [`& .MuiTimelineOppositeContent-root`]: {
                    flex: 0.08,
                    minWidth: 56,
                    pl: 0,
                  },
                  [`& .MuiTimelineContent-root`]: { flex: 0.92 },
                }}
              >
                {steps.map((step, index) => {
                  const reached = fixed ? step.reachedWhenFixed : step.reached
                  const verdict = fixed ? step.verdictWhenFixed : step.verdict
                  const label = fixed
                    ? verdict === 'blocked'
                      ? 'Blocked'
                      : verdict === 'pass'
                        ? 'Protected'
                        : verdict === 'allowed'
                          ? 'Still allowed'
                          : ''
                    : step.verdictLabel
                  const whatIf = step.whatIf
                  const triggeredGaps = asArray(whatIf?.gaps).filter(
                    (gap) => gap.triggered
                  )
                  const policies = asArray(whatIf?.policies)
                  const chipColor =
                    verdictDot[verdict] === 'grey'
                      ? 'default'
                      : verdictDot[verdict]
                  return (
                    <TimelineItem
                      key={step.id}
                      sx={{ opacity: reached ? 1 : 0.45 }}
                    >
                      <TimelineOppositeContent sx={{ m: 'auto 0' }}>
                        <Typography
                          variant="caption"
                          sx={{ color: 'text.secondary', fontWeight: 600 }}
                        >
                          Step {step.index}
                        </Typography>
                      </TimelineOppositeContent>
                      <TimelineSeparator>
                        <TimelineDot
                          color={verdictDot[verdict] ?? 'grey'}
                          variant="outlined"
                        />
                        {index < steps.length - 1 && <TimelineConnector />}
                      </TimelineSeparator>
                      <TimelineContent sx={{ py: 0.5, px: 2, pb: 3 }}>
                        <Stack spacing={1}>
                          <Box
                            sx={{
                              display: 'flex',
                              alignItems: 'center',
                              gap: 1,
                              flexWrap: 'wrap',
                            }}
                          >
                            <Typography
                              variant="subtitle1"
                              sx={{ fontWeight: 600 }}
                            >
                              {step.title}
                            </Typography>
                            {label && (
                              <Chip
                                size="small"
                                label={label}
                                color={chipColor}
                              />
                            )}
                            {!reached && (
                              <Chip
                                size="small"
                                variant="outlined"
                                label="Not reached"
                              />
                            )}
                          </Box>
                          <Typography
                            variant="body2"
                            sx={{ color: 'text.secondary', maxWidth: 720 }}
                          >
                            {fixed && step.whenFixed
                              ? step.whenFixed
                              : step.text}
                          </Typography>

                          {!fixed && whatIf?.error && (
                            <Alert severity="warning">{whatIf.error}</Alert>
                          )}

                          {!fixed && (
                            <Stack spacing={0.5}>
                              {triggeredGaps.map((gap) => (
                                <CheckLine
                                  key={gap.text}
                                  state={false}
                                  text={gap.text}
                                  note="missing control"
                                />
                              ))}
                              {whatIf &&
                                asArray(whatIf.reportOnlyWouldStop).length >
                                  0 && (
                                  <CheckLine
                                    state="warn"
                                    text={`Report-only policy would have stopped this sign-in: ${asArray(whatIf.reportOnlyWouldStop).join(', ')}`}
                                    note="never enforced"
                                  />
                                )}
                              {asArray(step.standards).map((standard) => (
                                <CheckLine
                                  key={standard.name}
                                  state={standard.compliant}
                                  text={standard.label}
                                  note={`${standard.status}${standard.detail ? `: ${standard.detail}` : ''} · ${standard.role}`}
                                />
                              ))}
                              {asArray(step.alerts).map((alert) => (
                                <CheckLine
                                  key={alert.operation}
                                  state={alert.configured}
                                  text={
                                    alert.configured
                                      ? `An alert rule watches "${alert.operation}"`
                                      : `No alert rule watches "${alert.operation}"`
                                  }
                                  note={
                                    alert.configured
                                      ? asArray(alert.rules).join(', ')
                                      : 'nobody is told'
                                  }
                                />
                              ))}
                            </Stack>
                          )}

                          {fixed && (
                            <Stack spacing={0.5}>
                              {asArray(step.fixes).map((fix) => (
                                <CheckLine
                                  key={`${fix.type}-${fix.name}`}
                                  state={true}
                                  text={
                                    fix.type === 'caTemplate'
                                      ? fix.name
                                      : fix.label
                                  }
                                  note={`${fixTypeLabel[fix.type] ?? fix.type} in place`}
                                />
                              ))}
                            </Stack>
                          )}

                          {!fixed && policies.length > 0 && (
                            <CippButtonCard
                              component="accordion"
                              title={`Policy-by-policy result (${policies.length})`}
                            >
                              <CippDataTable
                                queryKey={`SecuritySimulation-${scenarioId}-${step.id}-policies`}
                                title="Conditional Access policies"
                                data={policies}
                                simpleColumns={[
                                  'displayName',
                                  'state',
                                  'policyApplies',
                                  'result',
                                ]}
                              />
                            </CippButtonCard>
                          )}
                        </Stack>
                      </TimelineContent>
                    </TimelineItem>
                  )
                })}
              </Timeline>
            </Grid>
            <Grid size={{ md: 4, xs: 12 }}>
              <Card>
                <CardContent>
                  <Typography
                    variant="caption"
                    sx={{
                      color: 'text.secondary',
                      fontWeight: 600,
                      letterSpacing: 0.8,
                      textTransform: 'uppercase',
                    }}
                  >
                    Closes the gaps
                  </Typography>
                  {fixes.length === 0 && (
                    <Typography
                      variant="body2"
                      sx={{ color: 'text.secondary', mt: 1 }}
                    >
                      Every mapped control is already in place.
                    </Typography>
                  )}
                  <Stack divider={<Divider flexItem />} sx={{ mt: 1 }}>
                    {fixes.map((fix) => (
                      <Box key={`${fix.type}-${fix.name}`} sx={{ py: 1.25 }}>
                        <Box
                          sx={{ display: 'flex', alignItems: 'center', gap: 1 }}
                        >
                          <Typography
                            variant="body2"
                            sx={{ fontWeight: 600, flex: 1, minWidth: 0 }}
                          >
                            {fix.type === 'caTemplate' ? fix.name : fix.label}
                          </Typography>
                          <Chip
                            size="small"
                            label={fix.status}
                            color={fixStatusColor[fix.status] ?? 'default'}
                          />
                        </Box>
                        <Box
                          sx={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 1,
                            flexWrap: 'wrap',
                            mt: 0.25,
                          }}
                        >
                          <Typography
                            variant="caption"
                            sx={{ color: 'text.secondary' }}
                          >
                            {fixTypeLabel[fix.type] ?? fix.type} · {fix.role}{' '}
                            step{' '}
                            {steps.find((step) => step.id === fix.step)
                              ?.index ?? ''}
                          </Typography>
                          <FixAction
                            fix={fix}
                            onAddStandard={openAddStandard}
                            onEnableAlert={openEnableAlert}
                          />
                        </Box>
                      </Box>
                    ))}
                  </Stack>
                  {alreadyInPlace.length > 0 && (
                    <>
                      <Divider sx={{ my: 1.5 }} />
                      <Typography
                        variant="caption"
                        sx={{ color: 'text.secondary' }}
                      >
                        Already in place: {alreadyInPlace.join(', ')}
                      </Typography>
                    </>
                  )}
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </>
      )}

      {standardToAdd && (
        <CippBaselineAddStandardDialog
          createDialog={addStandardDialog}
          standardName={standardToAdd}
          relatedQueryKeys={[runQueryKey]}
        />
      )}
      {alertToEnable && (
        <CippAlertPresetDialog
          createDialog={alertDialog}
          tenant={tenant}
          preset={alertToEnable.name}
          operation={alertToEnable.operation}
          logbook={alertToEnable.logbook}
          relatedQueryKeys={[runQueryKey]}
        />
      )}
    </Stack>
  )
}

const ScenarioList = ({ tenant, catalog, onOpen }) => {
  const scenarios = asArray(catalog.data).filter(
    (s) => s && typeof s === 'object' && s.id
  )
  const retriedRef = useRef(false)
  useEffect(() => {
    if (
      catalog.isFetching ||
      catalog.data === undefined ||
      Array.isArray(catalog.data)
    )
      return
    if (retriedRef.current) return
    retriedRef.current = true
    catalog.refetch()
  }, [catalog.data, catalog.isFetching, catalog])

  const runAll = ApiPostCall({
    url: '/api/ExecSecuritySimulation',
    relatedQueryKeys: [`ListSecuritySimulations-${tenant}`],
  })
  const categories = [
    ...CATEGORY_ORDER.filter((category) =>
      scenarios.some((s) => s.category === category)
    ),
    ...[...new Set(scenarios.map((s) => s.category))].filter(
      (c) => !CATEGORY_ORDER.includes(c)
    ),
  ]
  const checked = scenarios.filter((s) => s.lastRun)
  const lastRun = checked.reduce(
    (max, s) => Math.max(max, Number(s.lastRun) || 0),
    0
  )
  const preventedCount = scenarios.filter(
    (s) => s.outcome === 'Prevented'
  ).length
  const notPreventedCount = scenarios.filter(
    (s) => s.outcome === 'NotPrevented' || s.outcome === 'Detected'
  ).length

  return (
    <Stack spacing={3}>
      <Box
        sx={{
          display: 'flex',
          alignItems: 'flex-start',
          gap: 2,
          flexWrap: 'wrap',
        }}
      >
        <Box sx={{ flex: 1, minWidth: 280 }}>
          <Typography
            variant="body2"
            sx={{ color: 'text.secondary', maxWidth: 720 }}
          >
            Pick an event that could happen to this tenant to see how it plays
            out today and which standard, policy or alert closes each gap.
          </Typography>
          {scenarios.length > 0 && (
            <Typography
              variant="body2"
              sx={{ color: 'text.secondary', mt: 0.5 }}
            >
              {checked.length === 0 ? (
                'No scenario has been checked yet.'
              ) : (
                <>
                  Last checked <CippTimeAgo data={lastRun} /> ·{' '}
                  <Typography
                    component="span"
                    variant="body2"
                    sx={{ color: 'success.main', fontWeight: 600 }}
                  >
                    {preventedCount} prevented
                  </Typography>{' '}
                  ·{' '}
                  <Typography
                    component="span"
                    variant="body2"
                    sx={{ color: 'error.main', fontWeight: 600 }}
                  >
                    {notPreventedCount} not prevented
                  </Typography>
                  {checked.length < scenarios.length
                    ? ` · ${scenarios.length - checked.length} not checked yet`
                    : ''}
                </>
              )}
            </Typography>
          )}
        </Box>
        <Button
          variant="contained"
          size="small"
          disabled={runAll.isPending || scenarios.length === 0}
          startIcon={
            runAll.isPending ? (
              <CircularProgress size={14} color="inherit" />
            ) : undefined
          }
          onClick={() =>
            runAll.mutate({
              url: '/api/ExecSecuritySimulation',
              data: { tenantFilter: tenant, scenarioId: 'All' },
            })
          }
        >
          {runAll.isPending ? 'Checking every scenario' : 'Run all checks'}
        </Button>
      </Box>
      {runAll.isError && (
        <Alert severity="error">{getCippError(runAll.error)}</Alert>
      )}
      {catalog.isFetching && scenarios.length === 0 && (
        <CippFormSkeleton layout={[1, 1, 1, 1]} />
      )}
      {!catalog.isFetching && scenarios.length === 0 && (
        <Alert
          severity={catalog.isError ? 'error' : 'info'}
          action={
            <Button
              color="inherit"
              size="small"
              onClick={() => catalog.refetch()}
            >
              Retry
            </Button>
          }
        >
          {catalog.isError
            ? 'The scenario catalog could not be loaded from the API.'
            : 'No scenarios are available.'}
        </Alert>
      )}
      {categories.map((category) => {
        const rows = scenarios.filter((s) => s.category === category)
        return (
          <Box key={category}>
            <Typography
              variant="caption"
              sx={{
                color: 'text.secondary',
                fontWeight: 600,
                letterSpacing: 1,
                textTransform: 'uppercase',
                display: 'block',
                mb: 1,
              }}
            >
              {category}
            </Typography>
            <Card>
              {rows.map((scenario, index) => {
                const chip = outcomeChip[scenario.outcome] ?? outcomeChip.NotRun
                return (
                  <Box
                    key={scenario.id}
                    onClick={() => onOpen(scenario.id)}
                    sx={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 1.5,
                      px: 2.25,
                      py: 1.5,
                      cursor: 'pointer',
                      borderBottom: index < rows.length - 1 ? 1 : 0,
                      borderColor: 'divider',
                      '&:hover': { bgcolor: 'action.hover' },
                    }}
                  >
                    <Box
                      sx={{
                        width: 8,
                        height: 8,
                        borderRadius: '50%',
                        flexShrink: 0,
                        bgcolor:
                          severityDot[scenario.severity] ?? 'text.secondary',
                      }}
                      title={scenario.severity}
                    />
                    <Box sx={{ flex: 1, minWidth: 0 }}>
                      <Typography variant="subtitle2" noWrap>
                        {scenario.title}
                      </Typography>
                      <Typography
                        variant="body2"
                        noWrap
                        sx={{ color: 'text.secondary' }}
                      >
                        {scenario.summary}
                      </Typography>
                    </Box>
                    <Box sx={{ textAlign: 'right', flexShrink: 0 }}>
                      <Chip
                        size="small"
                        label={chip.label}
                        color={chip.color}
                        variant={
                          scenario.outcome === 'NotRun' ? 'outlined' : 'filled'
                        }
                      />
                      <Typography
                        variant="caption"
                        sx={{
                          color: 'text.secondary',
                          display: 'block',
                          mt: 0.25,
                        }}
                      >
                        {scenario.lastRun ? (
                          <>
                            checked <CippTimeAgo data={scenario.lastRun} />
                            {scenario.fixCount > 0
                              ? ` · ${scenario.fixCount} gap${scenario.fixCount === 1 ? '' : 's'}`
                              : ''}
                          </>
                        ) : scenario.licensed === false ? (
                          'not licensed for this scenario'
                        ) : (
                          'not checked yet'
                        )}
                      </Typography>
                    </Box>
                  </Box>
                )
              })}
            </Card>
          </Box>
        )
      })}
    </Stack>
  )
}

const Page = () => {
  const pageTitle = 'Security Simulations'
  const router = useRouter()
  const tenant = useSettings().currentTenant
  const scenarioId = router.query.scenario
  const tenantSelected = Boolean(tenant) && tenant !== 'AllTenants'

  const catalog = ApiGetCall({
    url: '/api/ListSecuritySimulations',
    data: { tenantFilter: tenant },
    queryKey: `ListSecuritySimulations-${tenant}`,
    waiting: tenantSelected,
  })

  return (
    <>
      <CippHead title={pageTitle} />
      <Container maxWidth={false}>
        <Stack spacing={2}>
          {!tenantSelected && (
            <Alert severity="info">
              Select a tenant to see what an attacker would experience there
              today.
            </Alert>
          )}
          {tenantSelected && scenarioId && (
            <ScenarioRun
              tenant={tenant}
              scenarioId={scenarioId}
              onBack={() => router.push('/tenant/security-simulator')}
            />
          )}
          {tenantSelected && !scenarioId && (
            <ScenarioList
              tenant={tenant}
              catalog={catalog}
              onOpen={(id) =>
                router.push(
                  `/tenant/security-simulator?scenario=${encodeURIComponent(id)}`
                )
              }
            />
          )}
        </Stack>
      </Container>
    </>
  )
}

Page.getLayout = (page) => (
  <DashboardLayout>
    <TabbedLayout tabOptions={tabOptions}>{page}</TabbedLayout>
  </DashboardLayout>
)

export default Page
