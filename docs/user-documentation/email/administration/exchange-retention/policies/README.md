# Policies

A retention policy is the container that groups retention tags together and is then applied to a mailbox. A mailbox can have only one retention policy at a time, and the tags in that policy are the retention options its user sees in Outlook. This page lists the retention policies in the selected tenant, alongside [README.md](../tags/README.md "mention").

## Action Buttons

{% content-ref url="policy.md" %}
[policy.md](policy.md)
{% endcontent-ref %}

## Table Details

The properties returned are for the Exchange Online PowerShell command `Get-RetentionPolicy`. For more information on the command please see the [Microsoft documentation](https://learn.microsoft.com/powershell/module/exchangepowershell/get-retentionpolicy).

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Edit Policy</td><td>Opens <a data-mention href="policy.md">policy.md</a></td><td>false</td></tr><tr><td>Delete Policy</td><td>Opens a modal to confirm you want to delete the policy. A policy that is still applied to at least one mailbox cannot be deleted, and the results panel tells you so, so move those mailboxes onto another policy first.</td><td>true</td></tr></tbody></table>

***

{% include "../../../../../../.gitbook/includes/feature-request.md" %}
