# Check Alerts

This page collects the alerts from Check by CyberDrain, a browser plugin that blocks AiTM (Adversary-in-the-Middle) attacks. Check provides real-time protection against phishing and credential theft attempts. Learn more at [docs.check.tech](https://docs.check.tech/) or install the plugin now: [Microsoft Edge](https://microsoftedge.microsoft.com/addons/detail/check-by-cyberdrain/knepjpocdagponkonnbggpcnhnaikajg) | [Chrome](https://chromewebstore.google.com/detail/check-by-cyberdrain/benimdeioplgkhanklclahllklceahbe)

Each row is one page the plugin flagged on a user's machine, so the table tells you which of your users met something suspicious, what they met, and why the plugin acted.

## Table Details

| Column | Description |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Type                         | The kind of detection the plugin reported.                                                                     |
| Url                          | The address the plugin flagged.                                                                                |
| Reason                       | Why the plugin flagged it.                                                                                     |
| Score                        | The score the plugin gave the page.                                                                            |
| Threshold                    | The score the plugin was configured to act at. Compare it against **Score** to see how far over the line a detection was. |
| Potential User Name          | The email address of the user the plugin reported the detection for.                                            |
| Potential User Display Name  | That user's display name.                                                                                       |
| Reported By IP               | The public IP address the report was sent from.                                                                 |
| Timestamp                    | When the alert was recorded. The table is sorted on this, newest first.                                         |

{% hint style="warning" %}
The user columns are named "potential" for a reason. They carry whatever identity the browser plugin believed it was seeing at the time, which is not an authenticated claim, so treat them as a lead to investigate rather than a confirmed identification.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}
