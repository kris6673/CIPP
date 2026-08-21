# Deploy Quarantine Policy

This page creates a custom quarantine policy in one or more tenants. The policy defines what end users are allowed to do with messages held for them in quarantine, and once deployed it becomes selectable from the tenant's anti-spam, anti-phishing, anti-malware, and Safe Attachments policies. It is reached from the **Deploy Custom Policy** button on [README.md](README.md "mention").

| Field                                        | Description                                                                                                          |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Select Tenants                               | The tenants to deploy to. More than one can be chosen, and the tenant you are currently on is preselected. Required. |
| Policy Name                                  | The name of the new quarantine policy. Required, and it cannot be changed afterwards.                                |
| Release Action Preference                    | Whether end users can release a quarantined message themselves, or only request its release. Required.               |
| Delete                                       | Lets end users delete quarantined messages.                                                                          |
| Preview                                      | Lets end users preview quarantined messages.                                                                         |
| Block Sender                                 | Lets end users add the sender to their blocked senders list.                                                         |
| Allow Sender                                 | Lets end users add the sender to their allowed senders list.                                                         |
| Quarantine Notification                      | Sends end users a quarantine notification message covering this policy.                                              |
| Include Messages From Blocked Sender Address | Includes messages from blocked senders. Disabled until **Quarantine Notification** is on.                            |

**Submit** creates the policy. The results panel reports the outcome for each tenant separately, so a failure against one tenant does not hide a success elsewhere.

{% hint style="info" %}
Releasing and requesting release are mutually exclusive in Exchange, which is why **Release Action Preference** is a single choice rather than two switches.
{% endhint %}

Once created, the policy appears on [README.md](README.md "mention"), where its permissions can be changed with the **Edit Policy** action. The global notification frequency, sender address, and branding are set separately from the **Edit Settings** button on that page.

{% include "../../../../../.gitbook/includes/feature-request.md" %}
