# SIEM

This page issues a read-only SAS URL that lets an external SIEM or script query CIPP's log table directly through the Azure Table Storage REST API, without going through the CIPP API. It also documents how those logs are structured so you can write sensible queries against them.

## CIPP Logs Table Access

| Setting        | Description                                                                                                                                                                                      |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Token Validity | How long the SAS URL remains valid. Presets run from 30 days to 3650 days (10 years), and the default is 365 days. A custom value in days can be typed directly, and must be between 1 and 3650. |

Selecting **Generate SAS Token** produces two pieces of information.

| Output     | Description                                                                                                                                       |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| SAS URL    | The full URL to query, including the token and a format parameter that returns JSON without metadata. A copy button sits at the end of the field. |
| Expires On | The date and time the URL stops working, shown in your local time.                                                                                |

{% stepper %}
{% step %}
### Choose a validity period

Set **Token Validity** to how long the SIEM connection should last. Prefer the shortest period that avoids a renewal you will forget about.
{% endstep %}

{% step %}
### Generate

Select **Generate SAS Token**. The SAS URL and its expiry appear beneath the form.
{% endstep %}

{% step %}
### Store it securely

Copy the URL into your SIEM configuration and your password manager or documentation before leaving the page.
{% endstep %}
{% endstepper %}

{% hint style="danger" %}
The SAS URL is displayed once and cannot be retrieved again. If you lose it, the only option is to generate a new one.
{% endhint %}

{% hint style="warning" %}
Generating a new URL does not invalidate the old ones, and there is no way to revoke an individual URL from within CIPP. Every URL issued stays valid until its own expiry date. Treat the expiry period as a commitment, and bear in mind that revoking early means rotating the underlying storage account key, which affects your whole CIPP instance.
{% endhint %}

{% hint style="info" %}
The URL is scoped to the `CippLogs` table with read permission only. It cannot be used to write log entries, and it cannot reach any other table in the storage account, so sharing it with a SIEM does not expose the rest of your CIPP data.
{% endhint %}

## Querying CIPP Logs

### How Logs Are Stored

CIPP writes all log entries to an Azure Table Storage table called `CippLogs`. Each row is partitioned by date using the format `YYYYMMDD` as the `PartitionKey`, with a unique GUID as the `RowKey`.

{% hint style="warning" %}
Always include a `PartitionKey` filter in your queries. Azure Table Storage performs a full table scan without one, which is slow and expensive on large tables. Use `eq` for a single day, or `ge` and `le` for a date range. The date partition is in UTC, so you may need a date range to account for time zone differences.
{% endhint %}

### Available Columns

| Column       | Description                                      |
| ------------ | ------------------------------------------------ |
| PartitionKey | Date in YYYYMMDD format.                         |
| RowKey       | Unique log entry ID (GUID).                      |
| Timestamp    | When the entry was written.                      |
| Tenant       | Tenant domain name.                              |
| Username     | User who triggered the action.                   |
| API          | API endpoint or function name.                   |
| Message      | Log message text.                                |
| Severity     | Log level, one of Info, Warning, Error or Debug. |
| LogData      | Additional JSON data, where present.             |
| TenantID     | Tenant GUID, where available.                    |
| IP           | Source IP address, where available.              |

### Example Filter Queries

Append `&$filter=` to your SAS URL to filter results. The operators `eq`, `ne`, `gt`, `lt`, `ge` and `le` are supported, and conditions can be combined with `and` and `or`.

A specific day:

```
$filter=PartitionKey eq 'YYYYMMDD'
```

Replace `YYYYMMDD` with the date you want, for example `20260312`.

A date range covering the last seven days:

```
$filter=PartitionKey ge '20260305' and PartitionKey le '20260312'
```

### Further Reading

* [Querying Tables and Entities](https://learn.microsoft.com/en-us/rest/api/storageservices/querying-tables-and-entities) covers filter syntax, operators, and supported data types.
* [Query Timeout and Pagination](https://learn.microsoft.com/en-us/rest/api/storageservices/query-timeout-and-pagination) covers continuation tokens for large result sets.

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
