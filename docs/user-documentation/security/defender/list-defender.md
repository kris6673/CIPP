# Defender Status

Every Intune managed device in the selected tenant is listed with the state Microsoft Defender antivirus is reporting for it. Use it to spot devices where real time protection is off, where a scan or a signature update has fallen overdue, or where a reboot is outstanding, without opening each device in Intune.

## Table Details

The properties returned are for the Graph resource type `managedDevice`. For more information on the properties please see the [Graph documentation](https://learn.microsoft.com/en-us/graph/api/resources/intune-devices-manageddevice?view=graph-rest-beta#properties). The Defender specific columns come from the expanded `windowsProtectionState` object on each device. For more information on those properties please see the [Graph documentation](https://learn.microsoft.com/en-us/graph/api/resources/intune-devices-windowsprotectionstate?view=graph-rest-beta#properties).

{% hint style="info" %}
Every managed device in the tenant is listed, not just Windows ones. The protection state is a Windows specific object, so devices on other platforms appear in the list with their Defender columns empty.
{% endhint %}

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
