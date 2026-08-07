# Mailbox Client Access Settings

This report lists all users and the status of various Client Access Settings on their mailbox, such as IMAP / OWA / POP.

## Use cases

* Finding users where MAPI has erroneously disabled and is causing Outlook connectivity issues
* Ensuring POP and IMAP is disabled for all users

## Table Details

The properties returned are for the Exchange Online PowerShell command `Get-CASMailbox`. For more information on the command please see the [Microsoft documentation](https://learn.microsoft.com/powershell/module/exchangepowershell/get-casmailbox).

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Set Client Access Protocols</td><td>Allows you to Enable/Disable selected client access protocols.</td><td>true</td></tr></tbody></table>

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
