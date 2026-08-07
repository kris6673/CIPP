# Edit Assignment Filter

Opens an assignment filter from the selected tenant so its name, description and rule can be changed. Changes take effect on every assignment already using the filter.

The form is the same as [add.md](add.md "mention"), populated with the filter's stored values.

| Field        | Description                                                                           |
| ------------ | ------------------------------------------------------------------------------------- |
| Display Name | The name of the filter. Required.                                                     |
| Description  | The description recorded against the filter.                                          |
| Filter Type  | Shown for reference and cannot be changed.                                            |
| Platform     | Shown for reference and cannot be changed.                                            |
| Filter Rule  | The rule deciding what the filter matches, written in Intune filter syntax. Required. |

{% hint style="warning" %}
Editing the rule changes what every assignment using this filter reaches, so a device matching the old rule but not the new one loses the policies and applications the filter was narrowing.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
