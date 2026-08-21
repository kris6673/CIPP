# Tenant Select

The tenant selector sits at the top of CIPP and controls which tenant you are managing. Changing it reloads the data on the current page for the newly selected tenant, and cancels any requests still running for the previous one.

## Selecting a Tenant

Tenants are listed as their display name followed by their default domain in brackets. Start typing to narrow the list by either part, then choose a tenant to switch to it.

**\*All Tenants** appears at the top of the list. Selecting it shows data across every tenant you manage on pages that support it. Some pages behave differently under All Tenants, most notably tables, which always read from cached data in this mode.

The circular arrows button beside the selector refreshes the tenant list from Microsoft. Use it after adding a new customer relationship so the tenant appears without having to reload CIPP.

The selected tenant is reflected in the page address as a `tenantFilter` parameter, so any CIPP page can be linked to with a tenant already chosen. The parameter accepts the tenant's default domain, its initial `onmicrosoft.com` domain, or its tenant ID, and CIPP rewrites the address to the default domain once the page loads.

{% hint style="info" %}
Your selected tenant is remembered between sessions. If you open CIPP at a page with no tenant in its address, the tenant you last used is applied automatically.
{% endhint %}

## Tenant Information

The building icon to the left of the selector opens a flyout with details of the currently selected tenant, available from any page. It is unavailable while All Tenants is selected.

| Field                                    | Description                                                                     |
| ---------------------------------------- | ------------------------------------------------------------------------------- |
| Display Name                             | The tenant's display name.                                                      |
| ID                                       | The tenant's directory ID.                                                      |
| Street                                   | The street recorded on the tenant's address.                                    |
| Postal Code                              | The postal code recorded on the tenant's address.                               |
| Technical Notification Mails             | The technical contact addresses Microsoft uses for service notifications.       |
| On Premises Sync Enabled                 | Whether directory synchronisation from on-premises Active Directory is enabled. |
| On Premises Last Sync Date Time          | When the directory last synchronised.                                           |
| On Premises Last Password Sync Date Time | When passwords last synchronised.                                               |

## Portal Shortcuts

The same flyout lists shortcuts for jumping straight to the tenant's Microsoft portals, each opening with the selected tenant already in context.

| Action                | Description                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------------------- |
| Manage Tenant         | Opens the tenant's settings within CIPP. See [edit.md](../../tenant/manage/edit.md "mention"). |
| M365 Admin Portal     | Microsoft 365 admin center.                                                                    |
| Exchange Portal       | Exchange admin center.                                                                         |
| Entra Portal          | Microsoft Entra admin center.                                                                  |
| Teams Portal          | Teams admin center.                                                                            |
| Azure Portal          | Azure portal.                                                                                  |
| Intune Portal         | Microsoft Intune admin center.                                                                 |
| SharePoint Portal     | SharePoint admin center.                                                                       |
| Security Portal       | Microsoft Defender portal.                                                                     |
| Purview Portal        | Microsoft Purview portal.                                                                      |
| Power Platform Portal | Power Platform admin center.                                                                   |
| Power BI Portal       | Power BI admin portal.                                                                         |

Every portal other than **Manage Tenant** can be hidden from this list using the **Portal Links Configuration** settings described in [user-settings.md](user-settings.md "mention"), so you can shorten it to the portals you actually use.

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
