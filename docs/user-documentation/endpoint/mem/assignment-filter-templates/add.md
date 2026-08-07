# Add Assignment Filter Template

Creates an assignment filter template in CIPP. The template can then be deployed to tenants from deploy.md.

## Filter Details

| Field        | Description                                                                                                                                                                                                                                 |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Display Name | The name of the filter the template creates. Required.                                                                                                                                                                                      |
| Description  | The description recorded against the filter.                                                                                                                                                                                                |
| Filter Type  | Whether the filter matches Devices or Apps. This determines which platforms are offered below.                                                                                                                                              |
| Platform     | The platform the filter applies to. For a Devices filter: Windows 10 and later, iOS, macOS, Android Enterprise, Android device administrator, Android Work Profile, or Android (AOSP). For an Apps filter: Windows, Android, or iOS/iPadOS. |
| Filter Rule  | The rule deciding what the filter matches, written in Intune filter syntax, for example `(device.deviceName -eq "Test Device")`. Required.                                                                                                  |

{% hint style="info" %}
See Microsoft's documentation on [filter device properties](https://learn.microsoft.com/en-us/mem/intune/fundamentals/filters-device-properties) for the properties and operators the rule syntax supports.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
