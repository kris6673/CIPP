import { useEffect, useRef } from 'react'
import { useRouter } from 'next/router'
import {
  Alert,
  Box,
  Button,
  Card,
  Container,
  Divider,
  Stack,
  Typography,
} from '@mui/material'
import { Layout as DashboardLayout } from '../../../layouts/index'
import { TabbedLayout } from '../../../layouts/TabbedLayout'
import tabOptions from './tabOptions.json'
import { CippHead } from '../../../components/CippComponents/CippHead'
import CippFormSkeleton from '../../../components/CippFormPages/CippFormSkeleton'
import { ApiGetCall } from '../../../api/ApiCall'
import { useSettings } from '../../../hooks/use-settings'

const asArray = (value) => (Array.isArray(value) ? value : value ? [value] : [])

const GROUP_ORDER = ['Admin accounts', 'Standard users', 'Guests']

const outcomeColor = (situation) => {
  if (situation.pass === true) return 'success.main'
  if (situation.pass === false) return 'error.main'
  return 'text.secondary'
}

const Page = () => {
  const pageTitle = 'Sign-in Situations'
  const router = useRouter()
  const tenant = useSettings().currentTenant
  const tenantSelected = Boolean(tenant) && tenant !== 'AllTenants'

  const battery = ApiGetCall({
    url: '/api/ListCASituations',
    data: { tenantFilter: tenant },
    queryKey: `ListCASituations-${tenant}`,
    waiting: tenantSelected,
  })

  const data = battery.data
  const situations = asArray(data?.situations)

  const retriedRef = useRef(false)
  useEffect(() => {
    if (battery.isFetching || data === undefined || (data && typeof data === 'object')) return
    if (retriedRef.current) return
    retriedRef.current = true
    battery.refetch()
  }, [data, battery.isFetching, battery])
  const summary = data?.summary
  const identities = data?.identities
  const groups = [
    ...GROUP_ORDER.filter((group) => situations.some((s) => s.group === group)),
    ...[...new Set(situations.map((s) => s.group))].filter((g) => !GROUP_ORDER.includes(g)),
  ]
  const personaFor = { 'Admin accounts': 'admin', 'Standard users': 'user', Guests: 'guest' }

  return (
    <>
      <CippHead title={pageTitle} />
      <Container maxWidth={false}>
        <Stack spacing={3}>
          {!tenantSelected && (
            <Alert severity="info">Select a tenant to evaluate its sign-in situations.</Alert>
          )}
          {tenantSelected && (
            <Box>
              <Typography variant="body2" sx={{ color: 'text.secondary', maxWidth: 760 }}>
                Every predefined sign-in below is evaluated live against this tenant's Conditional
                Access policies with the What If API - no sign-in happens and nothing changes. A
                sign-in that gets through names the control that is missing.
              </Typography>
              {summary && (
                <Typography variant="body2" sx={{ color: 'text.secondary', mt: 1 }}>
                  {summary.total} sign-ins evaluated ·{' '}
                  <Typography component="span" variant="body2" sx={{ color: 'success.main', fontWeight: 600 }}>
                    {summary.protected} protected
                  </Typography>{' '}
                  ·{' '}
                  <Typography component="span" variant="body2" sx={{ color: 'error.main', fontWeight: 600 }}>
                    {summary.unprotected} get through
                  </Typography>
                  {summary.reportOnly > 0 && (
                    <Typography component="span" variant="body2" sx={{ color: 'warning.main' }}>
                      {' '}
                      ({summary.reportOnly} only because a policy is report-only)
                    </Typography>
                  )}
                  {summary.notEvaluated > 0 && ` · ${summary.notEvaluated} could not be evaluated`}
                </Typography>
              )}
              {asArray(data?.excluded).length > 0 && (
                <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
                  {asArray(data.excluded).length} risk-based sign-in
                  {asArray(data.excluded).length === 1 ? '' : 's'} excluded because this tenant has no
                  Entra ID P2 license.
                </Typography>
              )}
            </Box>
          )}
          {tenantSelected && data?.licensed === false && (
            <Alert severity="warning">
              This tenant has no Entra ID P1 or P2 license, so there are no Conditional Access
              policies to evaluate sign-ins against.
            </Alert>
          )}
          {tenantSelected && battery.isFetching && !data && <CippFormSkeleton layout={[1, 1, 1, 1, 1]} />}
          {tenantSelected && !battery.isFetching && battery.isError && (
            <Alert
              severity="error"
              action={
                <Button color="inherit" size="small" onClick={() => battery.refetch()}>
                  Retry
                </Button>
              }
            >
              The sign-in situations could not be evaluated through the API.
            </Alert>
          )}
          {tenantSelected && data && battery.isFetching && (
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
              Refreshing...
            </Typography>
          )}
          {groups.map((group) => {
            const rows = situations.filter((s) => s.group === group)
            const identity = identities?.[personaFor[group]]
            return (
              <Box key={group}>
                <Box sx={{ display: 'flex', alignItems: 'baseline', gap: 1.5, mb: 1 }}>
                  <Typography
                    variant="caption"
                    sx={{ color: 'text.secondary', fontWeight: 600, letterSpacing: 1, textTransform: 'uppercase' }}
                  >
                    {group}
                  </Typography>
                  {identity && (
                    <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                      evaluated as {identity.userPrincipalName}
                    </Typography>
                  )}
                </Box>
                <Card>
                  <Stack divider={<Divider />}>
                    {rows.map((situation) => (
                      <Box
                        key={situation.id}
                        sx={{ display: 'flex', alignItems: 'center', gap: 2, px: 2.25, py: 1.5, flexWrap: 'wrap' }}
                      >
                        <Typography variant="subtitle2" sx={{ minWidth: 280, flex: '1 1 280px' }}>
                          {situation.title}
                        </Typography>
                        <Typography
                          variant="body2"
                          sx={{ color: outcomeColor(situation), fontWeight: 600, minWidth: 150, whiteSpace: 'nowrap' }}
                        >
                          {situation.error ? 'Not evaluated' : situation.outcome}
                        </Typography>
                        <Box sx={{ flex: '2 1 320px', minWidth: 0, display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
                          {situation.error && (
                            <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                              {situation.error}
                            </Typography>
                          )}
                          {!situation.error && situation.pass === false && (
                            <>
                              <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                                {situation.missingControl}
                                {asArray(situation.reportOnlyWouldStop).length > 0 && (
                                  <Typography component="span" variant="body2" sx={{ color: 'warning.main' }}>
                                    {' '}
                                    - a report-only policy would stop it: {asArray(situation.reportOnlyWouldStop).join(', ')}
                                  </Typography>
                                )}
                              </Typography>
                              {situation.fix?.caTemplate && (
                                <Button
                                  size="small"
                                  sx={{ py: 0, minWidth: 0, whiteSpace: 'nowrap' }}
                                  onClick={() => router.push('/tenant/conditional/list-template')}
                                >
                                  Deploy a CA template
                                </Button>
                              )}
                            </>
                          )}
                          {!situation.error && situation.pass === true && asArray(situation.blockedBy).length > 0 && (
                            <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                              by {asArray(situation.blockedBy).join(', ')}
                            </Typography>
                          )}
                        </Box>
                      </Box>
                    ))}
                  </Stack>
                </Card>
              </Box>
            )
          })}
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
