# Mailbox Statistics

This report lists every mailbox in the selected tenant with its last activity date, how much space it is using against its quota, how many items it holds, and whether an online archive exists. It is the fastest way to find mailboxes that are close to full, and mailboxes that have not been touched in months.

## Table Details

The information displayed comes from the prebuilt Graph report `getMailboxUsageDetail`. For additional details please see the [Graph documentation](https://learn.microsoft.com/en-us/graph/api/reportroot-getmailboxusagedetail?view=graph-rest-beta\&tabs=http).

**Storage Used** and **Quota** are reported by Microsoft in bytes and shown here in GB.

{% hint style="info" %}
The CIPP call to the Graph endpoint is hard coded to 7 days. There is no period selector on this page, because the figures are a snapshot of each mailbox as it stands rather than a count of activity over time.
{% endhint %}

Selecting All Tenants queues the report as a background job, so the table stays empty with a queued message until every tenant has been collected.

## Anonymised Reports

Microsoft 365 has a tenant-wide setting that conceals user names in usage reports, replacing them with hashes rather than user principal names. Where CIPP detects that this report has come back anonymised, it shows a warning above the results.

The fix is on the tenant, not in CIPP. Enabling the **Enable Usernames instead of pseudo anonymised names in reports** standard turns the setting off, after which the report needs running again to pick up real names.

{% include "../../../../.gitbook/includes/feature-request.md" %}
