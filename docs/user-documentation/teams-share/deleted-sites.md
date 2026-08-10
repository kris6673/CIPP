# Deleted Sites

This page lists the SharePoint sites that have been deleted in the selected tenant but are still recoverable from the tenant recycle bin, along with how long is left to recover each one. Microsoft keeps deleted sites for 93 days, after which the site and everything in it is permanently removed.

## Table Details

| Column                | Description                                                                                                        |
| --------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Name                  | The site name, taken from the last part of its address.                                                            |
| Url                   | The address the site had before it was deleted.                                                                    |
| Status                | The state of the deleted site in the recycle bin.                                                                  |
| Deletion Time         | When the site was deleted.                                                                                         |
| Days Remaining        | How many days are left before the site is permanently removed and can no longer be restored.                       |
| Storage Maximum Level | The storage quota that had been allocated to the site, in megabytes. This is the quota, not the storage it was using. |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Restore Site</td><td>Restores the selected site from the tenant recycle bin back to active use, at the address shown in the <strong>Url</strong> column. You are asked to confirm first, and large sites can take a while to finish restoring. Greyed out unless you have SharePoint site write access.</td><td>true</td></tr></tbody></table>

***

{% include "../../../.gitbook/includes/feature-request.md" %}
