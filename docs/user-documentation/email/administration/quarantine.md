# Quarantine

This page will display all messages quarantined by Microsoft Defender.

## Table Details

The properties returned are for the Exchange Online PowerShell command `Get-QuarantineMessage`. For more information on the command please see the [Microsoft documentation](https://learn.microsoft.com/powershell/module/exchangepowershell/get-quarantinemessage).

## Table Actions

<table><thead><tr><th></th><th></th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>View Message</td><td>Opens modal to display the message contents</td><td>true</td></tr><tr><td>View Message Trace</td><td>Opens a modal with a table of the message's trace history</td><td>true</td></tr><tr><td>Release</td><td>Opens modal to confirm you want to release the message</td><td>true</td></tr><tr><td>Deny</td><td>Opens modal to confirm you want to deny release of the message</td><td>true</td></tr><tr><td>Release &#x26; Allow Sender</td><td>Opens modal to confirm you want to release the message and add the sender to the allowed sender list</td><td>true</td></tr><tr><td>More Info</td><td>Opens Extended Info flyout</td><td>false</td></tr></tbody></table>

***

{% include "../../../../.gitbook/includes/feature-request.md" %}

