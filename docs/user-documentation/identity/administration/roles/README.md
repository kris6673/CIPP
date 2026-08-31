---
description: Review every Entra role and role assignment with its PIM assignment type and move access in the secure direction
---

# Roles & PIM

The Roles & PIM page has two tabs: **Roles & Assignments**, covered here, and [PIM Templates](templates/README.md), the role settings templates the **PIM Role Settings Template** standard deploys.

## Roles & Assignments

One table for the tenant's directory roles and who holds them. Every assignment is a row - one per principal, role and scope - showing how it is held: permanently, as a Privileged Identity Management (PIM) eligibility, as a time-bound active assignment, or because an eligible administrator activated the role. Roles that nobody holds are listed too, as **Unassigned** rows, so the table is also the complete role catalogue; filter them out with **Assigned roles only** when reviewing access.

On Entra ID P2 tenants the data comes from PIM. On tenants without P2 every assignment is, by definition, permanent and only the legacy removal is offered. With **All Tenants** selected the page reads the reporting cache instead of Graph (catalogue rows are not included there).

### Table Details

| Column             | Description                                                                                                                                                                                                                                                                                      |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Role               | The directory role. The Extended Info flyout adds the role's description, whether it is built in or custom, and its template id.                                                                                                                                                                 |
| Principal          | The user, group or service principal holding the assignment, with its sign-in name where it has one. Empty on Unassigned rows.                                                                                                                                                                   |
| Assignment Type    | **Permanent** – active with no end date. **Eligible** – the principal can activate the role through PIM. **Active** – active with an end date set by an administrator. **ActivatedFromEligible** – active right now because the principal activated an eligibility. **Unassigned** – nobody holds the role. |
| Member Type        | **Direct**, or **Group** when the principal holds the role because it is a member of a role-assignable group. Group-inherited rows cannot be changed from this page; change the group's own assignment instead.                                                                                  |
| Scope              | The whole directory, or the administrative unit the assignment is limited to.                                                                                                                                                                                                                    |
| End Date Time      | When the assignment or eligibility ends. Empty for permanent assignments.                                                                                                                                                                                                                        |
| Is Privileged Role | Whether the role is on CIPP's privileged-roles list (the same list the standards and alerts use).                                                                                                                                                                                                |
| Policy Summary     | The role's PIM settings: maximum activation, whether MFA or an authentication context and a justification are required, approval, and whether eligible and active assignments must expire. The Extended Info flyout adds **Policy Below Floor** when these settings fall below CIPP's secure floor. |

### Filters

**Permanent admins**, **Eligible**, **Time-bound active**, **Activated from eligible**, **Privileged roles only**, **Permanent privileged admins**, **Inherited through a group**, **Policy below secure floor**, **Assigned roles only**, **Roles nobody holds** and **Custom roles**.

### Table Actions

All actions move access in the secure direction only. CIPP cannot turn an eligibility into a permanent assignment or create a new permanent assignment: every request must carry an end date or a duration, and the request is refused otherwise. Anything touching the Global Administrator role asks you to type the principal's name to confirm. Every change is written to the logbook with the assignment type before and after. Unassigned rows have no actions.

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Convert to eligible</td><td>For a permanent assignment. Creates a PIM eligibility with the chosen lifetime, confirms it exists, and only then removes the permanent assignment, so the principal never loses access without gaining eligibility. Refused for service principals (PIM eligibility does not support them), for the last active Global Administrator, and for the CIPP-SAM application.</td><td>true</td></tr><tr><td>Grant time-bound active assignment</td><td>For an eligible principal. Creates an active assignment that Entra removes automatically at the chosen end (a preset duration or a custom end date). The lifetime cannot exceed the role's PIM policy maximum or the JIT admin maximum duration.</td><td>true</td></tr><tr><td>Extend</td><td>Pushes out the end of a time-bound active assignment or an eligibility, counted from now and within the policy maximum.</td><td>true</td></tr><tr><td>Renew</td><td>Renews an expired time-bound assignment or eligibility.</td><td>true</td></tr><tr><td>Remove assignment</td><td>Removes the eligibility or the active assignment. The last active Global Administrator is never removed. On tenants without Entra ID P2 this removes the directory role membership directly.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

{% hint style="info" %}
A justification is required for every action. It is recorded on the PIM request in Entra and in the CIPP logbook. End times in the result messages are shown in your browser's time zone; the assignment itself is stored in UTC.
{% endhint %}

{% hint style="warning" %}
Service principals that hold roles permanently are listed but cannot be converted, because PIM eligibility is only available for users and groups. Review whether the application still needs the role and remove the assignment if it does not.
{% endhint %}

{% hint style="warning" %}
This page covers Entra ID directory roles. Permissions granted through Exchange Online role groups, Azure resource roles, or Microsoft Purview are held elsewhere and do not appear here, so a review of who holds administrative access needs to take in those as well.
{% endhint %}

{% include "../../../../../.gitbook/includes/feature-request.md" %}
