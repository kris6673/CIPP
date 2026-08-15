# Connection Filter

This page lists the hosted connection filter policies in the selected tenant. The connection filter is the first thing Exchange Online Protection applies to inbound mail, and it holds the IP allow list, the IP block list, and the safe list switch.

## Action Buttons

{% content-ref url="add.md" %}
[add.md](add.md)
{% endcontent-ref %}

## Table Details

The properties returned are for the Exchange Online PowerShell command `Get-HostedConnectionFilterPolicy`. For more information on the command please see the [Microsoft documentation](https://learn.microsoft.com/powershell/module/exchangepowershell/get-hostedconnectionfilterpolicy).

**More Info** opens a flyout with the policy's directory and object details, covering **Distinguished Name**, **Directory Based Edge Block Mode**, **Exchange Version**, **Exchange Object Id**, **Organizational Unit Root**, **When Created**, **When Changed**, and **Guid**.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Create template based on filter</td><td>Saves the selected policy as a connection filter template, which then appears on <a data-mention href="../list-connectionfilter-templates.md">list-connectionfilter-templates.md</a>.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

{% include "../../../../../.gitbook/includes/feature-request.md" %}
