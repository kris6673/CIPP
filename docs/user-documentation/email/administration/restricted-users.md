# Restricted Users

This page lists the accounts Exchange Online has blocked from sending mail for exceeding its outbound spam limits. An account normally lands here because something is sending through it in volume, so treat each entry as a suspected compromise until you have shown otherwise. The counts on each row tell you how far past the limit the account went and whether the traffic was internal or external.

{% hint style="warning" %}
**Users in this list have been restricted from sending email due to exceeding outbound spam limits.**\
This typically indicates a compromised account. [Before unblocking, ensure you have properly secured the account.](https://aka.ms/O365-compromise) Recommended actions include:

* Checked for suspicious sign-ins and activities
* Reviewed their mailbox rules and forwarding settings
* Investigated any unusual mailbox activity, such as unexpected sent items via message trace
* Reset the user's password if compromised
* Enabled MFA on the account if not already enabled
{% endhint %}

## Table Details

| Column           | Description                                                                      |
| ---------------- | -------------------------------------------------------------------------------- |
| Sender Address   | The address that has been blocked from sending.                                  |
| Block Type       | Which limit was exceeded, for example an internal or external recipient limit.   |
| Created Datetime | When the block was applied.                                                      |
| Changed Datetime | When the block was last changed.                                                 |
| Temporary Block  | Whether Exchange applied the block temporarily rather than until it is lifted.   |
| Internal Count   | The number of internal recipients the account sent to on the day it was blocked. |
| External Count   | The number of external recipients the account sent to on the day it was blocked. |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Unblock User</td><td>Removes the sending restriction from the selected user so they can send email again. Unblocking can take up to an hour to take effect, and the account should be secured before it is unblocked.</td><td>true</td></tr></tbody></table>

{% include "../../../../.gitbook/includes/feature-request.md" %}
