# Device Compliance

Every device registered in the selected tenant's directory, with its compliance and management state. Use it to find devices that are registered but unmanaged, devices failing compliance, and stale registrations that have not checked in for a long time.

## Table Details

The properties returned are for the Graph resource type `device`. For more information on the properties please see the [Graph documentation](https://learn.microsoft.com/en-us/graph/api/resources/device?view=graph-rest-beta#properties).

{% hint style="warning" %}
This is the directory's view of a device, not Intune's. A device shows as compliant here based on what the directory holds, so a device that has not checked in recently can keep reporting its last known state. Read **Approximate Last Sign In Date Time** and **Last Sync Date Time** alongside the compliance columns before treating a row as current.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}
