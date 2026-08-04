---
description: Review SharePoint sites and usage
---

# SharePoint

This page lists SharePoint site usage. You can also see file count, activity, and general usage in addition to the resource allocations for the site.

## Action Buttons

{% content-ref url="add-site.md" %}
[add-site.md](add-site.md)
{% endcontent-ref %}

{% content-ref url="bulk-add-site.md" %}
[bulk-add-site.md](bulk-add-site.md)
{% endcontent-ref %}

## Table Details

The properties returned are for the Graph resource type `site` but filtered to only return non-personal sites. For more information on the properties please see the [Graph documentation](https://learn.microsoft.com/en-us/graph/api/resources/site?view=graph-rest-1.0#properties).

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Add Member</td><td>Opens a modal to add a user to the site while setting the site role to grant permissions</td><td>true</td></tr><tr><td>Remove Member</td><td>Opens a modal to remove a user from the site</td><td>true</td></tr><tr><td>Add Site Admin</td><td>Opens a modal to add a site admin</td><td>true</td></tr><tr><td>Remove Site Admin</td><td>Opens a modal to remove a site admin</td><td>true</td></tr><tr><td>Manage Permissions</td><td>Opens a dialog showing who has access to the site, or to one of its document libraries, and the permission level each user or group holds. From here you can grant a user or group a permission level, change or remove an existing assignment, stop a library inheriting the site's permissions so that it can hold its own, or restore inheritance. Viewing permissions requires read access to the site; making changes requires write access.</td><td>false</td></tr><tr><td>Set Library Permission</td><td>Opens a modal to grant users or groups permissions on the selected library(ies)</td><td>true</td></tr><tr><td>Delete Site</td><td>Opens a modal to delete the selected site(s)</td><td>true</td></tr><tr><td>Start Version Cleanup Job</td><td>Triggers a cleanup job to delete versions. Options are to Sync Policy, Delete Older than Days, and Count Limits. See the app for explanation and options for each.</td><td>true</td></tr><tr><td>Check Cleanup Job Status</td><td>Checks the status of any running cleanup job for the selected library.</td><td>false</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
