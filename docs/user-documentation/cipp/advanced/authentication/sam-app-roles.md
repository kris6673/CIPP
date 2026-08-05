# SAM App Roles

This page adds the CIPP-SAM application's service principal directly to admin roles inside your client tenants. It exists for the advanced case where CIPP needs access to Graph endpoints or Exchange cmdlets that are not available through delegated permissions.

{% hint style="danger" %}
This is an advanced configuration of CIPP currently in beta. Please proceed with caution. Granting directory roles to an application is a significant privilege change in every tenant it applies to, and CIPP does not remove roles it has previously granted.
{% endhint %}

## Settings

| Field           | Description                                                                                                                         |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Admin Roles     | The Entra directory roles to grant the CIPP-SAM service principal. The list covers the same roles available for GDAP relationships. |
| Select a tenant | The tenants the roles should be applied to. Multiple tenants can be selected, and All Tenants is available.                         |

Select **Submit** to save. Saving stores the configuration; it does not apply anything on its own.

{% hint style="warning" %}
Leaving the tenant list empty does not mean no tenants. With roles configured and no tenants selected, the roles are applied to every tenant CIPP manages. Select All Tenants deliberately if that is what you want, and remove the roles rather than the tenants if it is not.
{% endhint %}

{% hint style="info" %}
The Compliance Administrator role is always granted alongside whatever you select, whether or not it appears in the list. CIPP requires it for compliance and Purview functionality.
{% endhint %}

## When Roles Are Applied

Roles are not granted at the moment you save. They are applied during the next Update Permissions run, or when a CPV refresh is performed for the tenant.

A tenant is reprocessed when the saved role configuration is newer than that tenant's last permissions refresh, so changing the roles or the tenant list causes the affected tenants to be picked up on the next run rather than requiring a manual refresh of each one.

## What Happens in the Tenant

For each tenant in scope, CIPP adds the CIPP-SAM service principal as a member of each configured directory role, and registers the service principal in both Exchange Online and the Security and Compliance Center. That registration is what allows CIPP to call Exchange and compliance cmdlets in application context rather than as the service account.

| Outcome                                         | Description                                                                                                    |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| Role granted                                    | The service principal is added to the directory role.                                                          |
| Role already held                               | Roles the service principal already holds are skipped, so repeat runs are harmless.                            |
| Role not present in tenant                      | Where a directory role does not exist in the tenant, it is skipped and noted rather than treated as a failure. |
| Exchange or compliance registration unavailable | Tenants without the relevant licensing are skipped with an explanatory entry.                                  |

Every run writes a log entry under `Set-CIPPSAMAdminRoles`, with the individual actions attached as log data. That entry is the place to confirm what was actually granted in a given tenant, and it is recorded as an error where any part of the run failed.

{% hint style="warning" %}
Removing a role from this page stops it being granted in future, but does not revoke it from tenants where it has already been applied. Roles that are no longer wanted have to be removed from the service principal in each tenant by hand.
{% endhint %}

To confirm which Exchange cmdlets the application context actually gains, use [exchange-cmdlets.md](../exchange-cmdlets.md "mention") with **As App** enabled and compare it against the delegated result.

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
