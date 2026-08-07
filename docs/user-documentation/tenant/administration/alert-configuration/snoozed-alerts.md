# Snoozed Alerts

Alert snoozes let you suppress a single noisy result from a scripted CIPP alert without disabling the alert itself. A snooze is scoped to one specific item in one tenant, so the rest of the alert keeps reporting as normal. This page lists everything currently snoozed so you can review it and lift a snooze early.

## Snoozing Alerts

Snoozes are set from the alert results, not from this page. There are two routes:

* **From an alert email** - Each result in the notification carries its own set of snooze buttons for 7, 14, 30 or 90 days. Clicking one opens CIPP and applies the snooze straight away, with no reason recorded, then offers a link back to this page.
* **From the dashboard** - The Alerts overview card has a snooze action per result, which opens a dialog offering 7, 14 or 30 days along with an optional free-text reason.

{% hint style="info" %}
A snooze is matched on the content of the alert item, not just the user or object name. If the underlying detail changes, CIPP treats it as a new item and it will alert again even though a snooze exists for the earlier version.
{% endhint %}

## Table Details

| Column          | Description                                                                                          |
| --------------- | ---------------------------------------------------------------------------------------------------- |
| Cmdlet Name     | The alert check the snooze applies to.                                                               |
| Tenant          | The tenant the snoozed item belongs to. A snooze never applies across tenants.                       |
| Content Preview | A short summary of the specific result that was snoozed, typically the user or object it relates to. |
| Snooze Reason   | The optional reason recorded when the snooze was set. Empty for snoozes applied from an alert email. |
| Snoozed By      | The CIPP user who set the snooze.                                                                    |
| Status          | `Active` while the snooze is in effect, and `Expired` once it has run out.                           |
| Remaining Days  | Whole days left before the snooze expires, rounded up. Shows `0` once expired.                       |

{% hint style="info" %}
Expired snoozes stay listed until they are removed. They no longer suppress anything, so they are safe to leave in place, but clearing them keeps the list readable.
{% endhint %}

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Remove Snooze</td><td>Removes the snooze after confirmation, so the alert fires again for that item on its next run.</td><td>true</td></tr></tbody></table>

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
