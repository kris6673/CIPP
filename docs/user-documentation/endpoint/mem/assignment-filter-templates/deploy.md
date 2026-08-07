# Deploy Assignment Filter Template

Creates an assignment filter in one or more tenants from a saved template.

{% stepper %}
{% step %}
### Tenant Selection

Select the tenants the filter should be created in. Several can be selected, and the same filter is created in each.
{% endstep %}

{% step %}
### Choose Template

Select the template under **Choose a Template**, which lists each one with its platform. The remaining fields fill in from the template and can be adjusted before deploying, without changing the template itself.

| Field               | Description                                                                                    |
| ------------------- | ---------------------------------------------------------------------------------------------- |
| Filter Type         | Whether the filter matches Devices or Apps. Changing this changes which platforms are offered. |
| Platform            | The platform the filter applies to.                                                            |
| Filter Display Name | The name the filter is created under. Required.                                                |
| Filter Description  | The description recorded against the filter.                                                   |
| Filter Rule         | The rule deciding what the filter matches. Required.                                           |
{% endstep %}

{% step %}
### Confirmation

Review the tenants and the filter, then submit.
{% endstep %}
{% endstepper %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
