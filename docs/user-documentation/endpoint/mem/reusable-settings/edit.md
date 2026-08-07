# Edit Reusable Setting

Opens a reusable setting from the selected tenant so its name, description and configuration can be changed. The setting is loaded from the tenant it belongs to, which is carried through from the row the page was opened from, so the correct tenant is used even when the list was showing All Tenants.

## Setting Details

| Field        | Description                                   |
| ------------ | --------------------------------------------- |
| Display Name | The name of the reusable setting. Required.   |
| Description  | The description recorded against the setting. |
| Raw JSON     | The setting's configuration. Required.        |

The configuration is rendered below the fields so it can be read without working through the JSON.

{% hint style="warning" %}
Configuration policies that reference this setting take its new value as soon as it is saved. A reusable setting exists precisely so that one change reaches every policy using it, so check how many policies reference it before changing the configuration.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
