# View Device

The View Device page shows everything CIPP knows about a single Intune-managed device, and is where you act on that device individually. It brings together the device's own details, the compliance and configuration policies applied to it, the applications detected on it, the users associated with it, and the groups it belongs to. The full set of device actions is available from the page header, so a device can be synced, wiped, or renamed without returning to the device list.

The page header shows the device's name, with copyable chips for the device name and device ID, how long ago the device last synced, and a **View in Intune** link that opens the device in the Microsoft Intune admin centre.

## Device Actions

Every action available on the Devices list is available here from the [.](./ "mention") page, applied to this device alone.&#x20;

## Device Details

| Field            | Description                                                               |
| ---------------- | ------------------------------------------------------------------------- |
| Device Name      | The name of the device.                                                   |
| Device ID        | The device's identifier in Intune.                                        |
| Operating System | The device's operating system and version.                                |
| Manufacturer     | The device's manufacturer.                                                |
| Model            | The device's model.                                                       |
| Serial Number    | The device's serial number.                                               |
| Compliance State | Whether the device currently meets the compliance policies applied to it. |
| Enrolled Date    | When the device was enrolled in Intune.                                   |
| Last Sync        | When the device last checked in with Intune.                              |

{% hint style="info" %}
A refresh control on this card reloads the device's details and the sections below it.
{% endhint %}

## Compliance Policies

Lists the compliance policies applied to the device, one entry per policy. Each entry shows the policy's name and the state the device is in against it, marked as compliant or flagged for attention, and expands to show the number of settings in the policy and how many setting states were returned.

## Configuration Policies

Lists the configuration policies applied to the device in the same form as compliance policies: the policy name, the device's state against it, and the setting counts on expansion.

## Detected Applications

Reports the applications Intune has detected on the device, with a count in the section header. Expanding the entry shows the full list.

| Column       | Description                           |
| ------------ | ------------------------------------- |
| Display Name | The name of the detected application. |
| Version      | The version detected on the device.   |
| Platform     | The platform the application runs on. |

## Associated Users

Lists the users associated with the device. Expanding the entry shows the full list, and a **View User** action on each row opens that user's page in CIPP.

| Column              | Description               |
| ------------------- | ------------------------- |
| Display Name        | The user's name.          |
| User Principal Name | The user's sign-in name.  |
| Mail                | The user's email address. |

## Memberships

Lists the groups the device belongs to. Expanding the entry shows the full list, and an **Edit Group** action on each row opens that group for editing.

| Column           | Description                            |
| ---------------- | -------------------------------------- |
| Display Name     | The name of the group.                 |
| Group Types      | The group's type.                      |
| Security Enabled | Whether the group is security enabled. |
| Mail Enabled     | Whether the group is mail enabled.     |

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
