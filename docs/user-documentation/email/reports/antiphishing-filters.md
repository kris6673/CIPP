# Anti-Phishing Filters

This report lists the anti-phishing policies configured in the selected tenant, each paired with the rule that decides who it applies to. It shows at a glance whether a policy is in force, which domains it covers, which senders and domains are excluded, and how its impersonation and spoof protections are set.

## Table Details

The properties returned are for the combination of the following Exchange PowerShell commands. For more information on the command please see the Microsoft documentation:

* [Get-AntiPhishPolicy](https://learn.microsoft.com/en-us/powershell/module/exchange/get-antiphishpolicy?view=exchange-ps)
* [Get-AntiPhishRule](https://learn.microsoft.com/en-us/powershell/module/exchange/get-antiphishrule?view=exchange-ps)

Every row is a policy. **Rule Name**, **Priority**, **Recipient Domain Is**, and **State** come from the rule paired with that policy, and everything else comes from the policy itself.

{% hint style="warning" %}
The built-in default policy shows no **Rule Name**, **Priority**, **Recipient Domain Is**, or **State**, and cannot be enabled or disabled from this page. Manage it from the Microsoft 365 Defender portal or with a CIPP standard instead.
{% endhint %}

Spoof intelligence, unauthenticated sender indicators, and the first contact safety tip are part of Exchange Online Protection. The impersonation protection settings, which are the mailbox intelligence protection action, the targeted user and targeted domain protection actions, and their quarantine tags, only take effect where the tenant is licensed for Microsoft Defender for Office 365.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Enable Rule</td><td>Brings the policy into force so it starts applying to the recipients its rule covers. Greyed out where <strong>State</strong> is already <code>Enabled</code>.</td><td>true</td></tr><tr><td>Disable Rule</td><td>Stops the policy applying while keeping all of its settings, so it can be brought back later. Greyed out where <strong>State</strong> is already <code>Disabled</code>.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
