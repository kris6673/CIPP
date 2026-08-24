import { useRouter } from 'next/router'
import { Layout as DashboardLayout } from '../../../../layouts/index.js'
import { TabbedLayout } from '../../../../layouts/TabbedLayout'
import { CippTablePage } from '../../../../components/CippComponents/CippTablePage.jsx'
import { useCippRoleAssignmentActions } from '../../../../components/CippComponents/CippRoleAssignmentActions'
import tabOptions from './tabOptions.json'

/**
 * Roles and their assignments in one table: one row per principal x role x scope with the PIM
 * assignment type, plus one row per role nobody holds (AssignmentType 'Unassigned') so the
 * role catalogue is here too. Single tenant reads live; AllTenants reads the reporting cache
 * (which has no catalogue rows).
 */
const Page = () => {
  const pageTitle = 'Roles & Assignments'
  const router = useRouter()
  // Deep links (user page, alerts) narrow the list to one role or principal.
  const { roleTemplateId, principalId } = router.query
  const apiData = {}
  if (roleTemplateId) apiData.roleTemplateId = roleTemplateId
  if (principalId) apiData.principalId = principalId
  const actions = useCippRoleAssignmentActions()

  const filters = [
    {
      filterName: 'Permanent admins',
      value: [{ id: 'AssignmentType', value: 'Permanent' }],
      type: 'column',
    },
    {
      filterName: 'Eligible',
      value: [{ id: 'AssignmentType', value: 'Eligible' }],
      type: 'column',
    },
    {
      filterName: 'Time-bound active',
      value: [{ id: 'AssignmentType', value: 'Active' }],
      type: 'column',
    },
    {
      filterName: 'Activated from eligible',
      value: [{ id: 'AssignmentType', value: 'ActivatedFromEligible' }],
      type: 'column',
    },
    {
      filterName: 'Privileged roles only',
      value: [{ id: 'IsPrivilegedRole', value: 'Yes' }],
      type: 'column',
    },
    {
      filterName: 'Permanent privileged admins',
      value: [
        { id: 'AssignmentType', value: 'Permanent' },
        { id: 'IsPrivilegedRole', value: 'Yes' },
      ],
      type: 'column',
    },
    {
      filterName: 'Inherited through a group',
      value: [{ id: 'MemberType', value: 'Group' }],
      type: 'column',
    },
    {
      filterName: 'Policy below secure floor',
      value: [{ id: 'PolicyBelowFloor', value: 'Yes' }],
      type: 'column',
    },
    {
      filterName: 'Assigned roles only',
      value: [{ id: 'IsAssigned', value: 'Yes' }],
      type: 'column',
    },
    {
      filterName: 'Roles nobody holds',
      value: [{ id: 'AssignmentType', value: 'Unassigned' }],
      type: 'column',
    },
    {
      filterName: 'Custom roles',
      value: [{ id: 'RoleIsBuiltIn', value: 'No' }],
      type: 'column',
    },
  ]

  const offCanvas = {
    extendedInfoFields: [
      'RoleDisplayName',
      'RoleDescription',
      'RoleIsBuiltIn',
      'RoleDefinitionId',
      'PrincipalDisplayName',
      'PrincipalUserPrincipalName',
      'PrincipalType',
      'AssignmentType',
      'MemberType',
      'Scope',
      'StartDateTime',
      'EndDateTime',
      'Source',
      'PolicySummary',
      'PolicyBelowFloor',
      'PIMCapable',
    ],
    actions: actions,
  }

  return (
    <CippTablePage
      title={pageTitle}
      apiUrl="/api/ListRoleAssignments"
      apiData={apiData}
      queryKey={`ListRoleAssignments-${roleTemplateId ?? 'all'}-${principalId ?? 'all'}`}
      actions={actions}
      offCanvas={offCanvas}
      filters={filters}
      simpleColumns={[
        'Tenant',
        'RoleDisplayName',
        'PrincipalDisplayName',
        'PrincipalUserPrincipalName',
        'PrincipalType',
        'AssignmentType',
        'MemberType',
        'Scope',
        'EndDateTime',
        'IsPrivilegedRole',
        'PolicySummary',
      ]}
    />
  )
}

Page.getLayout = (page) => (
  <DashboardLayout allTenantsSupport={true}>
    <TabbedLayout tabOptions={tabOptions}>{page}</TabbedLayout>
  </DashboardLayout>
)

export default Page
