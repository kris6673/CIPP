# Safe Attachment Filters

This report lists the Safe Attachments policies configured in the selected tenant, each paired with the rule that decides who it applies to. It shows whether a policy is in force, which domains it covers, what happens to a detected attachment, and where messages are redirected.

## Table Details

The properties returned are for the combination of the following Exchange PowerShell commands. For more information on the command please see the Microsoft documentation:

* [Get-SafeAttachmentPolicy](https://learn.microsoft.com/en-us/powershell/module/exchange/get-safeattachmentpolicy?view=exchange-ps)
* [Get-SafeAttachmentRule](https://learn.microsoft.com/en-us/powershell/module/exchange/get-safeattachmentrule?view=exchange-ps)

Every row is a policy. **Rule Name**, **Priority**, **Recipient Domain Is**, and **State** come from the rule paired with that policy, and everything else comes from the policy itself. **Action** is what happens to a message with a detected attachment, normally `Block` or `DynamicDelivery`, and **Redirect** with **Redirect Address** control whether a copy is sent on to an administrator mailbox for analysis.

{% hint style="warning" %}
Safe Attachments is part of Microsoft Defender for Office 365. A tenant licensed for Exchange Online Protection alone has no policies to report, so the table comes back empty.
{% endhint %}

{% hint style="warning" %}
The built-in default policy shows no **Rule Name**, **Priority**, **Recipient Domain Is**, or **State**, and cannot be enabled or disabled from this page. Manage it from the Microsoft 365 Defender portal or with a CIPP standard instead.
{% endhint %}

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Enable Rule</td><td>Brings the policy into force so it starts applying to the recipients its rule covers. Greyed out where <strong>State</strong> is already <code>Enabled</code>.</td><td>true</td></tr><tr><td>Disable Rule</td><td>Stops the policy applying while keeping all of its settings, so it can be brought back later. Greyed out where <strong>State</strong> is already <code>Disabled</code>.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

{% include "../../../../.gitbook/includes/feature-request.md" %}
