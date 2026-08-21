# Search Results

Opening a manual search shows the audit records it returned, straight from the tenant. The heading is the name you gave the search, falling back to the search ID where no name was recorded. Records arrive unsorted, so use the table's own sorting and filtering to work through them.

{% hint style="info" %}
A search only has records once it has finished running. If the table is empty, check the search's status on the Manual Searches tab: anything still showing `notStarted` or `running` has not completed yet.
{% endhint %}

## Action Buttons

| Button           | Description                                                                                                                                          |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Back to Searches | Returns you to the audit log searches list.                                                                                                          |
| Process Logs     | Runs these results through your alert rules after confirmation, generating alerts for anything that matches. Records that match no rule are ignored. |

## Table Details

The properties returned are for the Graph resource type `microsoft.graph.security.auditLogRecord`. For more information on the properties please see the [Graph documentation](https://learn.microsoft.com/en-us/graph/api/resources/security-auditlogrecord?view=graph-rest-1.0#properties).

## Audit Log Details

Selecting a row opens a flyout with the full record laid out in two sections. The first covers the record itself, and the second expands the audit data payload, which is where the detail specific to that operation lives.

CIPP does some work to make the record readable. Object IDs are resolved to the display names of the directory objects they refer to, both as property values and where they appear inside longer strings, with the original identifier available on hover. Any identifier that cannot be resolved is marked as such rather than silently left raw. Where the record carries a client IP address, an approximate geographic location is shown alongside it.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
