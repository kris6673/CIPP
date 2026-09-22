# Alert History

Every item a scripted CIPP alert reports is tracked from the moment it first appears until the alert stops reporting it. This page lists those tracked items across all tenants you can see, including items resolved in the last 90 days, so you can answer "did this fire last month?" and "how long was this open?" without digging through logs or notification emails.

## How Alert Items Are Tracked

Each scheduled alert reports the full set of things it found on every run. CIPP compares that set with what it already knows for that alert and tenant:

* An item that was not known before is **Open**, and a notification goes out.
* An item that was already open is left open. Nothing is sent again.
* An item that was open but is missing from the latest run is **Resolved**. Notifications are not sent for resolutions; the dashboard shows them under Recently resolved.
* An item that was resolved earlier and shows up again is reopened, and its reopen count goes up. A notification goes out again. Items that reopen three times or more are marked as flapping on the dashboard.

Only a run that completed can resolve items. If an alert could not check a tenant, for example because a Graph call failed or the tenant lacks the licence, its open items stay as they were and the last-checked time stops moving.

{% hint style="info" %}
Alerts that report events rather than conditions, such as a group membership change or a released quarantine message, resolve on their own once the event drops out of the alert's lookback window. That is expected: it means the event is no longer recent, not that anything was undone.
{% endhint %}

## Table Details

| Column               | Description                                                                                                                                            |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Tenant               | The tenant the item belongs to.                                                                                                                        |
| Alert                | The alert check that reported the item.                                                                                                                |
| Item                 | A short summary of the specific result, typically the user or object it relates to.                                                                    |
| Status               | `Open`, `Acknowledged`, `Snoozed` or `Resolved`.                                                                                                       |
| First Seen           | When this item was first reported, or first reported again after being resolved.                                                                       |
| Last Seen            | The most recent run that still reported the item.                                                                                                      |
| Last Checked         | The most recent run that completed for this alert and tenant. If this is older than expected, the alert may be failing for the tenant.                  |
| Resolved             | When the alert stopped reporting the item. Empty while it is still reported.                                                                           |
| Reopened             | How many times the item has come back after being resolved.                                                                                            |
| Acknowledged By      | The CIPP user who acknowledged the item, if anyone.                                                                                                    |
| Acknowledgement Note | The optional note recorded when the item was acknowledged.                                                                                             |
| Snoozed By           | The CIPP user who snoozed the item, if it is currently snoozed.                                                                                        |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Acknowledge</td><td>Marks an open item as known, with an optional note. It stays listed and keeps being checked, but is shown as acknowledged instead of open. The acknowledgement clears automatically if the item resolves and later reopens.</td><td>false</td></tr><tr><td>Remove Acknowledgement</td><td>Returns an acknowledged item to open.</td><td>false</td></tr><tr><td>Remove Snooze</td><td>Lifts the snooze on a snoozed item. It returns to open immediately and notifies again on the alert's next run.</td><td>false</td></tr></tbody></table>

## Acknowledge or Snooze?

Acknowledge means "I know, and I am dealing with it". The item stays visible on the dashboard so nobody forgets it, and the alert keeps confirming whether it is still true.

Snooze means "hide this for a while". The item leaves the active list until the snooze ends. Snoozes are set from the dashboard or from an alert email and reviewed on the [snoozed-alerts](snoozed-alerts.md "mention") page.

{% include "../../../../../.gitbook/includes/feature-request.md" %}
