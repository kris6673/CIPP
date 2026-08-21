# BitLocker Key Search

BitLocker Key Search finds a device's BitLocker recovery key from either the recovery key ID shown on the device's recovery screen or the device's Entra ID device ID. It exists for the situation where a user is locked out and can read out the key ID from the prompt but nobody is sure which tenant, or which device, it belongs to.

## Search

| Field                     | Description                                                                                                                                           |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Lookup Type               | Whether the value entered below is a **Key ID** or a **Device ID**. Key ID is the default.                                                            |
| BitLocker Recovery Key ID | The key identifier shown on the device's BitLocker recovery screen, typically the first eight characters of a GUID. Shown when Lookup Type is Key ID. |
| Azure AD Device ID        | The device's Entra ID device identifier. Shown when Lookup Type is Device ID.                                                                         |

Select **Search** or press Enter to run the search. Results replace those from any previous search.

{% hint style="info" %}
Setting the tenant selector to All Tenants searches every tenant at once, which is the point of the page when a user reads out a key ID and the tenant is unknown. Selecting a single tenant narrows the search to that customer.
{% endhint %}

## Results

Each matching key is returned as its own card, split into details of the key itself and, where the device could be identified, details of the device it belongs to.

### BitLocker Key Information

| Field        | Description                                                                                                  |
| ------------ | ------------------------------------------------------------------------------------------------------------ |
| Key ID       | The identifier of the recovery key that matched.                                                             |
| Volume Type  | Which volume the key unlocks: Operating System Volume, Fixed Data Volume, Removable Data Volume, or Unknown. |
| Created      | When the key was escrowed.                                                                                   |
| Tenant       | The tenant the key was found in, which is what identifies the customer when searching across all of them.    |
| Recovery Key | A **Retrieve Key** button. Selecting it fetches the recovery key and displays it with a copy control.        |

### Device Information

Shown where the device the key belongs to could be identified.

| Field            | Description                                       |
| ---------------- | ------------------------------------------------- |
| Device Name      | The name of the device.                           |
| Device ID        | The device's identifier.                          |
| Operating System | The device's operating system and version.        |
| Account Status   | Whether the device object is enabled or disabled. |
| Trust Type       | How the device is joined to the directory.        |
| Last Sign In     | When the device last signed in or last synced.    |

Where the device cannot be identified, the card shows a notice in place of this section instead. The key details and the **Retrieve Key** button remain usable, so a key can still be recovered for a device that has since been deleted.

{% hint style="warning" %}
The search runs against CIPP's cached copy of each tenant's escrowed key records, not against Graph directly. A key that has been escrowed since the last cache collection will not be found, and neither will a device that has not yet been collected, which is the usual reason the device details are missing from an otherwise valid result.
{% endhint %}

{% hint style="danger" %}
The recovery key itself is not held in the cache. **Retrieve Key** fetches it live and shows it in plain text, and every retrieval is written to the CIPP audit log against the account that performed it.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}
