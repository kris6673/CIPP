# Message Encryption

Microsoft Purview Message Encryption lets users send protected email to any recipient, including Gmail and Outlook.com. This page shows the Information Rights Management (IRM) configuration for the selected tenant, lets you turn message encryption on, and verifies that it actually works.

{% hint style="info" %}
The only prerequisite for Purview Message Encryption is that Azure Rights Management is active for the tenant. For most eligible plans it is activated automatically. See [Set up Message Encryption](https://learn.microsoft.com/en-us/purview/set-up-new-message-encryption-capabilities).
{% endhint %}

## Current Configuration

| Field                                | Description                                                                                                                    |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| Purview Message Encryption           | Whether Azure RMS licensing is enabled. This is the switch that makes message encryption available to the tenant.              |
| Internal Licensing Enabled           | Whether IRM features are enabled for messages sent to internal recipients.                                                     |
| External Licensing Enabled           | Whether Exchange tries to acquire licenses from clusters other than the one it is configured to use.                           |
| Protect Button in Outlook on the Web | Whether the Protect button is shown in Outlook on the web. Defaults to disabled.                                               |
| Transport Decryption                 | Whether transport decryption is Disabled, Optional, or Mandatory.                                                              |
| Journal Report Decryption            | Whether a decrypted copy of a protected message is attached to the journal report.                                             |
| Licensing Location                   | The RMS licensing URLs for the tenant. Used to work out whether the tenant is on Azure RMS or still on on-premises AD RMS.     |

## AD RMS migration warning

Purview Message Encryption is **not compatible with Active Directory Rights Management Services (AD RMS)**. When the licensing location points at something other than an Azure RMS URL, the page shows a warning: that tenant is still using an on-premises AD RMS cluster and has to be [migrated to Azure RMS](https://learn.microsoft.com/en-us/azure/information-protection/migrate-from-ad-rms-to-azure-rms) before message encryption can be used.

The warning does not block the toggle, so you can still act on a tenant you know has already been migrated. The `Enable Purview Message Encryption` standard is stricter: it skips remediation entirely for these tenants and logs a warning instead, because it runs unattended.

## Actions

<table><thead><tr><th>Action</th><th>Details</th></tr></thead><tbody><tr><td>Enable Purview Message Encryption</td><td>Toggles Azure RMS licensing for the tenant, then Submit applies it. This is the only setting this page writes.</td></tr><tr><td>Run Test</td><td>Runs a test against the tenant that acquires the RMS templates and verifies that encryption and decryption both work. Enter any mailbox in the tenant as both the sender and the recipient. The button stays disabled until both addresses are filled in.</td></tr></tbody></table>

## Rolling this out across tenants

This page configures one tenant at a time. To deploy message encryption to many tenants and keep it that way, use the **Enable Purview Message Encryption** standard under Exchange Standards. In report mode it records the licensing state per tenant, including whether AD RMS was detected, which gives you the same pre-check across the whole estate without changing anything.

Encrypted message branding, one-time passcodes, and social ID sign-in are configured separately, through the **Configure Encrypted Message Branding (OME)** standard.

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
