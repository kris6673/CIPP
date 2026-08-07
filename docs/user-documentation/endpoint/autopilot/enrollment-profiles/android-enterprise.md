# Android Enterprise

Lists the Android Enterprise device owner enrolment profiles on the selected tenant, along with how many devices have enrolled through each and when its enrolment token expires.

## Table Details

The properties returned are for the Graph resource type `androidDeviceOwnerEnrollmentProfile`. For more information on the properties please see the [Graph documentation](https://learn.microsoft.com/en-us/graph/api/resources/intune-androidforwork-androiddeviceownerenrollmentprofile?view=graph-rest-beta#properties).

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Show QR</td><td>Displays the enrolment QR code for the profile, with the token value shown underneath and a button to copy it. Only offered on profiles that have an enrolment token.</td><td>false</td></tr><tr><td>Delete Profile</td><td>Deletes the enrolment profile from the tenant. Devices already enrolled through it stay enrolled, but the QR code and token stop working.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
