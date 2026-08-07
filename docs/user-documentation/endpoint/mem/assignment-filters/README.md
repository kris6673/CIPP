# Assignment Filters

Lists the assignment filters configured in the selected tenant. A filter narrows an assignment to the devices or apps matching a rule, so a policy or application assigned to a broad group only reaches the subset that matches. Filters are chosen when assigning from the policy and application pages.

## Action Buttons

{% content-ref url="add.md" %}
[add.md](add.md)
{% endcontent-ref %}

## Table Details

The properties returned are for the Graph resource type `deviceAndAppManagementAssignmentFilter`. For more information on the properties please see the [Graph documentation](https://learn.microsoft.com/en-us/graph/api/resources/intune-policyset-deviceandappmanagementassignmentfilter?view=graph-rest-beta#properties).

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Create template based on filter</td><td>Saves the filter as an <a data-mention href="../assignment-filter-templates/">assignment-filter-templates</a> entry, so the same filter can be deployed to other tenants.</td><td>true</td></tr><tr><td>Edit Filter</td><td>Opens the filter for editing in <a data-mention href="edit.md">edit.md</a>.</td><td>false</td></tr><tr><td>Delete Filter</td><td>Deletes the filter from the tenant. Assignments using it lose the filter, so they apply to their full target group instead.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
