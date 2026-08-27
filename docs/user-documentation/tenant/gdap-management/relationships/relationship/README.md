# Relationship Summary

The relationship summary shows the full detail of a single GDAP relationship, including its status, the roles it grants, and how it was created. The header shows the customer name alongside the relationship name and how long ago it was created, and every action available on the relationships list can be run directly from here.

## Alerts

CIPP inspects the relationship when the page loads and raises the following notices where they apply.

| Alert                       | Description                                                                                                                                                                     |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Microsoft-Led Transition    | The relationship was created by Microsoft as part of a Microsoft-Led Transition and only grants read permissions.                                                               |
| Global Administrator access | The relationship includes the Global Administrator role, which makes it ineligible for automatic extension.                                                                     |
| Recommended roles           | Confirms whether the relationship includes every role CIPP recommends. If any are missing, CIPP may not function correctly where this is the only relationship with the tenant. |

## Relationship Details

| Field                | Description                                                                                                                                     |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Customer             | The name of the customer tenant the relationship is with.                                                                                       |
| Tenant ID            | The directory ID of the customer tenant.                                                                                                        |
| Relationship Type    | How the relationship was created. See the table below.                                                                                          |
| Relationship ID      | The unique identifier of the relationship, with a button to copy it to your clipboard.                                                          |
| Status               | The current state of the relationship, for example active or approval pending.                                                                  |
| Auto Extend Duration | How long the relationship extends by when it renews, or a note that it is not eligible for automatic extension.                                 |
| Activated Date       | When the relationship was approved and became active.                                                                                           |
| Last Modified Date   | When the relationship was last changed.                                                                                                         |
| End Date             | When the relationship is due to expire.                                                                                                         |
| Invite URL           | The link for a Global Administrator in the customer tenant to approve the relationship. Only shown while the relationship is awaiting approval. |

### Relationship Types

CIPP works out the relationship type from the relationship name.

| Type                           | Description                                                                                               |
| ------------------------------ | --------------------------------------------------------------------------------------------------------- |
| CIPP                           | Created through CIPP, either from a generated invite or the onboarding process.                           |
| Microsoft-Led Transition (MLT) | Created automatically by Microsoft during the transition away from delegated admin privileges. Read only. |
| Lighthouse                     | Created through Microsoft 365 Lighthouse.                                                                 |
| Manual                         | Created directly in Partner Center, or by any other means outside CIPP.                                   |

## Approved Roles

Lists the admin roles the customer has approved for this relationship. These are the roles the relationship is permitted to grant, which is not the same as the roles that have actually been assigned to your technicians.

{% include "../../../../../../.gitbook/includes/feature-request.md" %}
