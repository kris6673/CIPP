# Tags

A retention tag sets what happens to mail of a given age, and it takes effect only once it is linked to a retention policy that is applied to a mailbox. This page lists the retention tags in the selected tenant, alongside [README.md](../policies/README.md "mention").

## Action Buttons

{% content-ref url="tag.md" %}
[tag.md](tag.md)
{% endcontent-ref %}

## Table Details

The properties returned are for the Exchange Online PowerShell command `Get-RetentionPolicyTag`. For more information on the command please see the [Microsoft documentation](https://learn.microsoft.com/powershell/module/exchangepowershell/get-retentionpolicytag).

For an explanation of what each tag type covers and what each retention action does, see the Microsoft guidance on [retention tags and policies](https://learn.microsoft.com/exchange/security-and-compliance/messaging-records-management/retention-tags-and-policies).

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Edit Tag</td><td>Opens <a data-mention href="tag.md">tag.md</a> for the selected tag.</td><td>false</td></tr><tr><td>Delete Tag</td><td>Opens a modal to confirm you want to delete the tag. A tag that is still linked to a retention policy cannot be deleted, and the results panel names the policies using it, so remove it from those policies first.</td><td>true</td></tr></tbody></table>

{% include "../../../../../../.gitbook/includes/feature-request.md" %}
