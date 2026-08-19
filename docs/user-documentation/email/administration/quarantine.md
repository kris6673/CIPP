# Quarantine

This page lists the messages Microsoft Defender for Office 365 and Exchange Online Protection have quarantined for the selected tenant. From here you can read a message safely, trace how it arrived, and release or deny it without going into the Defender portal.

## Filters

| Filter       | Shows                                                                                         |
| ------------ | --------------------------------------------------------------------------------------------- |
| Not Released | Messages still sitting in quarantine with no request against them.                            |
| Released     | Messages that have already been released to their recipients.                                 |
| Requested    | Messages a recipient has asked to have released, which are the ones waiting on your decision. |

## Table Details

The properties returned are for the Exchange Online PowerShell command `Get-QuarantineMessage`. For more information on the command please see the [Microsoft documentation](https://learn.microsoft.com/powershell/module/exchangepowershell/get-quarantinemessage).

Messages are listed newest first. Choosing AllTenants starts a background job to gather messages from every tenant, so the table reports that it is still loading until that job finishes.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>View Message</td><td>Opens a modal that renders the quarantined message so its contents, headers, and attachments can be inspected safely.</td><td>false</td></tr><tr><td>View Message Trace</td><td>Opens a modal with a table of the message's trace history, showing where it was received from and what happened to it at each step.</td><td>false</td></tr><tr><td>Release</td><td>Releases the message to all of its recipients. Greyed out on a message that has already been released.</td><td>true</td></tr><tr><td>Deny</td><td>Turns down a recipient's request to have the message released. Greyed out unless the recipient has actually requested release.</td><td>true</td></tr><tr><td>Release &#38; Allow Sender</td><td>Releases the message and adds the sender to the allowed senders list of the anti-spam policy that quarantined it, so future mail from them is not quarantined. Greyed out on a message that has already been released.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

The flyout highlights the message ID, recipient address, and quarantine type.

{% hint style="warning" %}
**Release &#38; Allow Sender** adds a standing allow entry to the anti-spam policy, and that entry stays until it is removed by hand. Use it for a sender that is genuinely being caught wrongly, and prefer a plain **Release** otherwise.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}
