# Apple ADE

Lists the Apple Automated Device Enrollment profiles across every ADE token connected to the selected tenant, with summary cards covering token health above the table. Profiles for macOS, iOS/iPadOS, tvOS and visionOS all appear here, and the filter buttons narrow the list to macOS or iOS/iPadOS.

## Summary Cards

| Card                 | Description                                                                                                                                         |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| ADE Tokens           | How many ADE tokens are connected. Selecting it opens a flyout listing each token's Apple ID, expiry, synced device count and last successful sync. |
| Expiring Tokens      | How many tokens expire within thirty days. Shown in red when any do.                                                                                |
| ADE Profiles         | How many enrolment profiles exist across all tokens.                                                                                                |
| Last Successful Sync | The most recent successful sync across all tokens. Hovering shows the total number of synced devices.                                               |

{% hint style="warning" %}
Where a token's last sync did not succeed, a banner appears above the cards naming the token and the reason. New Apple Business Manager terms waiting to be accepted are the most common cause and are reported as a warning rather than an error, but the token will not sync until they are accepted in Apple Business Manager.
{% endhint %}

## Action Buttons

<details>

<summary>Sync DEP</summary>

Asks Intune to sync the tenant's Apple Device Enrollment Program tokens, pulling in devices and changes made in Apple Business Manager since the last sync.

</details>

## Table Details

The properties returned are for the Graph resource type `depEnrollmentBaseProfile`. For more information on the properties please see the [Graph documentation](https://learn.microsoft.com/en-us/graph/api/resources/intune-enrollment-depenrollmentbaseprofile?view=graph-rest-beta#properties). Platform-specific properties come from the matching subtype, such as `depIOSEnrollmentProfile` or `depMacOSEnrollmentProfile`.

CIPP adds the following columns by joining each profile to the token it belongs to:

| Column     | Description                                                                                                  |
| ---------- | ------------------------------------------------------------------------------------------------------------ |
| Platform   | The device family the profile targets, derived from the profile's type: macOS, iOS/iPadOS, visionOS or tvOS. |
| Token Name | The ADE token the profile was created under.                                                                 |

The Apple ID, token expiry and token type of the owning token are also carried onto each profile and can be added from the column chooser.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Delete Profile</td><td>Deletes the enrolment profile from its ADE token. Devices already assigned to it fall back to the token's default profile at next enrolment.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

{% include "../../../../../.gitbook/includes/feature-request.md" %}
