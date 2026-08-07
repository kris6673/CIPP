---
description: Manage Autopilot status page configuration across your Microsoft 365 tenants.
---

# Status Pages

Lists the Enrollment Status Page configurations on the selected tenant, showing what each one does while a device is being set up. This includes the built-in default configuration that applies to all users and all devices, alongside any additional configurations targeted at specific groups.

## Action Buttons

<details>

<summary>Add Status Page</summary>

Opens the Autopilot Status Page Wizard, which applies the settings below to one or more tenants at once.

| Field                                    | Description                                                                                                                    |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Select Tenants                           | The tenants to apply the settings to. At least one is required, and the same settings are applied to each.                     |
| Timeout in minutes                       | How long setup may run before the status page reports a failure. Required.                                                     |
| Custom Error Message                     | The message shown to the user when setup fails. Leave blank to keep Intune's wording.                                          |
| Show progress to users                   | Displays the status page during setup. Leaving it off means setup runs without one. On by default.                             |
| Turn on log collection                   | Offers the user the option to collect and send logs when setup fails. On by default.                                           |
| Show status page only with OOBE setup    | Restricts tracking to Autopilot out-of-box provisioning, so devices enrolled another way skip the status page. Off by default. |
| Install Windows Updates during setup     | Installs available quality updates as part of setup. On by default.                                                            |
| Block device usage during setup          | Prevents the user from using the device until setup completes. On by default.                                                  |
| Allow reset                              | Offers the user the option to reset the device when setup fails. On by default.                                                |
| Allow users to use device if setup fails | Lets the user carry on past the status page when setup fails. Off by default.                                                  |

{% hint style="warning" %}
Despite its name, **Add Status Page** does not create a new configuration. It overwrites the tenant's default Enrollment Status Page, the one named "All users and all devices", with the settings supplied. Existing group-targeted configurations are left alone, but the default is replaced rather than added to.
{% endhint %}

{% hint style="danger" %}
Submitting the wizard also clears two settings that it does not expose. Any specific applications chosen for the default configuration to wait on are reset so that it waits on all assigned applications, and any scope tags on it are removed. Where the default configuration has been tuned in the Microsoft Intune admin center, use the portal to change it rather than this wizard.
{% endhint %}

After a successful submission the drawer stays open so the same settings can be applied to another set of tenants.

</details>

## Table Details

The properties returned are for the Graph resource type `deviceEnrollmentConfiguration`. For more information on the properties please see the [Graph documentation](https://learn.microsoft.com/en-us/graph/api/resources/intune-shared-deviceenrollmentconfiguration?view=graph-rest-beta#properties). The status page settings themselves come from the `windows10EnrollmentCompletionPageConfiguration` subtype, documented [here](https://learn.microsoft.com/en-us/graph/api/resources/intune-onboarding-windows10enrollmentcompletionpageconfiguration?view=graph-rest-beta#properties).

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
