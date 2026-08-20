# Quarantine

This page lists the messages Microsoft Defender for Office 365 and Exchange Online Protection have quarantined for the selected tenant. From here you can inspect a message safely, trace how it arrived, and release, deny, or delete it without going into the Defender portal.

The page has three tabs, one per quarantine type:

| Tab            | What it shows                                                         |
| -------------- | --------------------------------------------------------------------- |
| Email          | Quarantined email messages (Exchange Online Protection).              |
| Files          | Safe Attachments files quarantined from SharePoint/OneDrive.          |
| Teams Messages | Quarantined Teams messages.                                           |

Files and Teams quarantine require Defender for Office 365, so those tabs are empty for tenants without it. Rows in the AllTenants view are tagged with their tenant, and every per-message action is executed against the tenant the message belongs to.

## Filters

The Email tab offers release-status and quarantine-reason filters:

| Filter       | Shows                                                                                         |
| ------------ | --------------------------------------------------------------------------------------------- |
| Not Released | Messages still sitting in quarantine with no request against them.                            |
| Released     | Messages that have already been released to their recipients.                                 |
| Requested    | Messages a recipient has asked to have released, which are the ones waiting on your decision. |
| High Confidence Phishing / Phishing / Spam / Malware / Bulk / Transport Rule | Messages quarantined for that reason.                                       |

## Table Details

The properties returned are for the Exchange Online PowerShell command `Get-QuarantineMessage`. For more information on the command please see the [Microsoft documentation](https://learn.microsoft.com/powershell/module/exchangepowershell/get-quarantinemessage).

Messages are listed newest first. Choosing AllTenants starts a background job to gather messages from every tenant, so the table reports that it is still loading until that job finishes.

## Row Details Flyout

Clicking a row opens a flyout with the message's full details in expandable sections: **Quarantine Details**, **Delivery Details**, **Email Details**, and **Authentication**. When Microsoft Defender for Office 365 Plan 2 is available the delivery and authentication sections are enriched with the analyzed threat data, including per-URL and per-attachment threat verdicts. Without it, CIPP falls back to parsing the message headers and contents, so the sections are populated but individual URL/attachment verdicts are not shown. The actions at the bottom of the flyout are the same as the table actions.

## Table Actions

The Email tab offers the full action set:

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Preview Message</td><td>Opens a modal that renders the quarantined message so its contents, headers, and attachments can be inspected safely.</td><td>false</td></tr><tr><td>View Message Headers</td><td>Opens a modal with the raw RFC 5322 message headers.</td><td>false</td></tr><tr><td>Download Message (.eml)</td><td>Downloads the quarantined message as a .eml file for offline analysis.</td><td>false</td></tr><tr><td>View Message Trace</td><td>Opens a modal with a table of the message's trace history, showing where it was received from and what happened to it at each step.</td><td>false</td></tr><tr><td>Release</td><td>Releases the message to all of its recipients. Greyed out on a message that has already been released.</td><td>true</td></tr><tr><td>Release &#38; Allow Sender</td><td>Releases the message and adds the sender to the allowed senders list of the anti-spam policy that quarantined it, so future mail from them is not quarantined. Greyed out on a message that has already been released.</td><td>true</td></tr><tr><td>Deny</td><td>Turns down a recipient's request to have the message released. Greyed out unless the recipient has actually requested release.</td><td>true</td></tr><tr><td>Delete from Quarantine</td><td>Permanently deletes the message from quarantine. Greyed out on a message that has already been released.</td><td>true</td></tr><tr><td>Submit to Microsoft for Review</td><td>Submits the quarantined message to Microsoft as a threat submission so they can review its classification. Prompts for a category (clean, spam, phishing, or malware).</td><td>false</td></tr><tr><td>Block Sender</td><td>Adds the sender to the tenant's sender block list, optionally without an expiration date or with a note.</td><td>true</td></tr><tr><td>Open Email Entity in Defender</td><td>Opens the message's entity view in Microsoft Defender to surface the full detection details.</td><td>false</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

The flyout highlights the message ID, recipient address, and quarantine type.

{% hint style="warning" %}
**Release &#38; Allow Sender** adds a standing allow entry to the anti-spam policy, and that entry stays until it is removed by hand. Use it for a sender that is genuinely being caught wrongly, and prefer a plain **Release** otherwise.
{% endhint %}

{% hint style="info" %}
**Submit to Microsoft for Review** exports the quarantined message and submits it to Microsoft's threat submission pipeline. Submissions are analysed by Microsoft and can help correct false positives and false negatives.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}
