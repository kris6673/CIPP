# Diagnostics

{% include "../../../.gitbook/includes/ng-note.md" %}

This page runs [Kusto Query Language](https://learn.microsoft.com/en-us/kusto/query/?view=microsoft-fabric) (KQL) queries against your CIPP instance's own Application Insights telemetry, so you can investigate failed tasks, standards runs, and console output without leaving CIPP. The data queried is CIPP's own operational telemetry, not tenant data.

{% hint style="info" %}
Application Insights must be deployed for your CIPP environment, and the Function App's managed identity needs **Reader** permissions on the Application Insights resource. Without both, queries will fail.
{% endhint %}

## Query

Enter a KQL query directly, or load one of the presets as a starting point and adjust it. The query panel collapses once a query runs and reopens when you select **Clear**.

| Field       | Description                                                                                                                                                                 |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Load Preset | Loads a built-in or previously saved query into the editor. Selecting a preset populates both the KQL Query and the Preset Name, then clears itself so you can edit freely. |
| Preset Name | The name used when saving the current query as a preset. Required before the save option becomes available.                                                                 |
| KQL Query   | The query to run. Results are capped at 1001 rows, so use `take` or a tighter time window on noisy queries.                                                                 |

The save and delete controls sit alongside the Preset Name field.

| Control | Description                                                                                                                                                                            |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Save    | Stores the current query under the entered name. If a custom preset is loaded, the existing preset is updated. If a built-in preset is loaded, a new custom preset is created instead. |
| Delete  | Removes the loaded custom preset. Built-in presets cannot be deleted.                                                                                                                  |

Use **Execute Query** to run the query, or **Clear** to reset the editor and empty the results table.

{% hint style="warning" %}
Saved presets are stored against the CIPP instance rather than your individual account, so anyone with super admin access sees and can edit the same set.
{% endhint %}

### Built-in Presets

These presets ship with CIPP and cover the most common troubleshooting starting points. Each one defines its own result columns.

| Preset                                 | Purpose                                                                                                                                                                                              |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Completed Tasks Summary (Last 24h)     | Aggregates completed scheduled tasks over the past day by task, command, and tenant, with run counts and total, average, and maximum durations. Useful for finding slow or repeatedly running tasks. |
| Completed Standards Summary (Last 24h) | The same aggregation applied to standards runs, so you can see which standards are consuming the most time.                                                                                          |
| Console Logs (Last 24h)                | Every console log entry from the past day, with its timestamp, level, message, and invocation ID.                                                                                                    |
| Console Errors and Warnings (Last 24h) | The same view narrowed to entries logged at Error or Warning level. Usually the fastest place to start when something has failed.                                                                    |

## Table Details

The result columns are determined by the query rather than being fixed. Built-in presets define their own column set, and a query you write yourself returns whatever your `project` or `summarize` statement produces.

| Preset columns                                                                         | Applies to                                              |
| -------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| Task Name, Command, Tenant, Count, Total Duration Ms, Avg Duration Ms, Max Duration Ms | Completed Tasks Summary and Completed Standards Summary |
| Timestamp, Level, Message, Invocation ID                                               | Console Logs and Console Errors and Warnings            |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

The flyout adapts to the type of event in the row.

| Event                         | What the flyout shows                                                                                                                                           |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Console log entries           | A severity indicator, the timestamp, and the full message. If the message contains JSON, it is detected and formatted, with any surrounding text kept in place. |
| Task and standard completions | A summary card with the task or standard name, the command, the tenant, and the run count and duration figures where present.                                   |
| Anything else                 | A property list of every field returned by the query, with the custom dimensions listed separately and available to copy.                                       |

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
