# Add Directory Extension

Create a custom directory extension. Once saved, the extension is registered against the CIPP application registration and becomes selectable as a destination when you create a mapping.

## Directory Extension Details

| Field           | Description                                                                                                                                                                                         |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Extension Name  | A unique name for the extension. Microsoft Graph prefixes this with `extension_<applicationId>_` when the extension is created, so the stored property name is longer than the name you enter here. |
| Data Type       | The type of value the extension stores. Choose from Binary (256 bytes maximum), Boolean, DateTime (ISO 8601, UTC), Integer (32-bit), LargeInteger (64-bit), or String (256 characters maximum).     |
| Is Multi-Valued | Stores a collection of values rather than a single value. Required if you intend to map an array dataset such as Mailbox Permissions.                                                               |
| Target Objects  | The directory object types the extension can be set on. Choose one or more of User, Group, Administrative Unit, Application, Device, or Organization. At least one is required.                     |

{% hint style="info" %}
The data type and the multi-valued setting cannot be changed after creation. If you get either wrong, you will need to delete the extension and create a replacement, which means losing any values already written.
{% endhint %}

{% hint style="warning" %}
Only select the target objects you genuinely need. Directory objects are limited to 100 extension values per instance across all extensions.
{% endhint %}

{% include "../../../../../.gitbook/includes/feature-request.md" %}
