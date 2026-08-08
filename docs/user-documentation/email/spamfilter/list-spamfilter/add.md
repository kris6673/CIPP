# Deploy Spamfilter

This page creates an anti-spam policy in one or more tenants, either from a saved template or from JSON you enter yourself. Alongside the policy it creates the content filter rule that applies it to every accepted domain in the tenant, and that rule is enabled straight away. It is reached from the **Deploy Spamfilter** button on [README.md](README.md "mention").

| Field                        | Description                                                                                                                                 |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Select Tenants               | The tenants to deploy to. More than one can be chosen, and the tenant you are currently on is preselected. Required.                        |
| Select a template (optional) | A saved spam filter template. Choosing one fills **Parameters (JSON)** with the template's settings, which can be edited before submitting. |
| Parameters (JSON)            | The anti-spam policy settings to apply, as JSON. Required.                                                                                  |

**Submit** creates the policy and its rule. The results panel reports the outcome for each tenant separately, so a failure against one tenant does not hide a success elsewhere.

{% hint style="info" %}
The policy and the rule are named after each other, so the new rule appears against the new policy in the table with its **Rule State** set to `Enabled`.
{% endhint %}

Templates are managed on [list-templates.md](../list-templates.md "mention").

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
