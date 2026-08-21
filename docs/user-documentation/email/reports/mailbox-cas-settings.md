# Mailbox Client Access Settings

This report lists every mailbox in the selected tenant alongside the client access protocols enabled on it, such as OWA, MAPI, IMAP, and POP. The same protocols can be turned on or off in bulk from the table, so it doubles as the place to remediate whatever the report turns up.

## Use Cases

* Finding users where MAPI has erroneously been disabled and is causing Outlook connectivity issues
* Ensuring POP and IMAP are disabled for all users
* Confirming SMTP client authentication (SMTP AUTH) is switched off, since it cannot be protected by multi-factor authentication

## Table Details

The properties returned are for the Exchange Online PowerShell command `Get-CASMailbox`. For more information on the command please see the [Microsoft documentation](https://learn.microsoft.com/powershell/module/exchangepowershell/get-casmailbox).

{% hint style="warning" %}
**Smtp Client Authentication Disabled** reads the opposite way round to the other protocol columns. `Yes` means SMTP client authentication is switched off for that mailbox, which is the secure state, and `No` means legacy SMTP authentication is still permitted.
{% endhint %}

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Set Client Access Protocols</td><td>Turns the client access protocols you choose on or off for the selected mailbox(es). Choose <strong>Enable</strong> or <strong>Disable</strong> under <strong>Action</strong>, then pick one or more entries under <strong>Protocols</strong>: ECP, EWS, IMAP, MAPI, OWA, POP, ActiveSync, and SMTP Client Authentication.</td><td>true</td></tr></tbody></table>

Choosing **Disable** with **SMTP Client Authentication** selected does turn SMTP AUTH off, despite the inverted column name. The reverse is not possible: SMTP client authentication can only be turned off from here, and an attempt to turn it back on comes back as a warning, though any other protocols chosen at the same time are still applied.

{% include "../../../../.gitbook/includes/feature-request.md" %}
