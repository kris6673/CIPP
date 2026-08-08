# Deploy Connection Filter

This page applies connection filter settings to one or more tenants, either from a saved template or from JSON you enter yourself. It is reached from the **Deploy ConnectionFilter** button on [README.md](README.md "mention").

| Field                        | Description                                                                                                                                       |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Select Tenants               | The tenants to deploy to. More than one can be chosen, and the tenant you are currently on is preselected. Required.                              |
| Select a template (optional) | A saved connection filter template. Choosing one fills **Parameters (JSON)** with the template's settings, which can be edited before submitting. |
| Parameters (JSON)            | The connection filter settings to apply, as JSON. Required.                                                                                       |

**Submit** applies the settings. The results panel reports the outcome for each tenant separately, so a failure against one tenant does not hide a success elsewhere.

{% hint style="info" %}
Deploying updates the tenant's existing connection filter policy rather than adding a second one, so the IP allow list, IP block list, and safe list switch in the template replace what the tenant had before.
{% endhint %}

Templates are managed on [list-connectionfilter-templates.md](../list-connectionfilter-templates.md "mention").

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
