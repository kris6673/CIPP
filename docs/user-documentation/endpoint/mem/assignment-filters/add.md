# Add Assignment Filter

Creates an assignment filter in the selected tenant.

## Filter Details

| Field        | Description                                                                                                                                                                                                                                                                                     |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Display Name | The name of the filter. Required.                                                                                                                                                                                                                                                               |
| Description  | The description recorded against the filter.                                                                                                                                                                                                                                                    |
| Filter Type  | Whether the filter matches Devices or Apps. This determines which platforms are offered below, and cannot be changed once the filter has been created.                                                                                                                                          |
| Platform     | The platform the filter applies to. For a Devices filter: Windows 10 and later, iOS, macOS, Android Enterprise, Android device administrator, Android Work Profile, or Android (AOSP). For an Apps filter: Windows, Android, or iOS/iPadOS. Cannot be changed once the filter has been created. |
| Filter Rule  | The rule deciding what the filter matches, written in Intune filter syntax, for example `(device.deviceName -eq "Test Device")`. Required.                                                                                                                                                      |

{% hint style="info" %}
See Microsoft's documentation on [filter device properties](https://learn.microsoft.com/en-us/mem/intune/fundamentals/filters-device-properties) for the properties and operators the rule syntax supports.
{% endhint %}

{% hint style="warning" %}
Filter Type and Platform are fixed at creation. Getting either wrong means deleting the filter and creating it again, so check both before saving.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
