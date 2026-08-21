# Quarantine Policies

This page will allow you to view and manage custom quarantine policies that apply to your client tenants.

## Global Quarantine Settings

The properties returned are for the Exchange Online PowerShell command `Get-QuarantinePolicy`. For more information on the command please see the [Microsoft documentation](https://learn.microsoft.com/powershell/module/exchangepowershell/get-quarantinepolicy). The following additional columns are calculated by CIPP.

| Column                    | Description                                                                  |
| ------------------------- | ---------------------------------------------------------------------------- |
| Quarantine Notification   | Whether end-user quarantine notifications are enabled for the policy.        |
| Release Action Preference | The release action end users are permitted to take on quarantined messages.  |
| Builtin                   | Whether the policy is one of the built-in policies rather than a custom one. |

## Action Buttons

{% content-ref url="add.md" %}
[add.md](add.md)
{% endcontent-ref %}

## Table Details

The table outputs basic information for all of the custom quarantine policies you have created.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Edit Policy</td><td>Edits the selected policy(ies)</td><td>true</td></tr><tr><td>Delete Policy</td><td>Deletes the selected policy(ies)</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
