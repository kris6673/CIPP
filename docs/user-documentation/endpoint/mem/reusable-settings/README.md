# Reusable Settings

Lists the reusable settings configured in the selected tenant. A reusable setting holds a value once, such as a certificate authority or a trusted root certificate, so that many configuration policies can reference it instead of each carrying its own copy. Changing the reusable setting updates every policy that references it. Microsoft's own overview is at [reusable settings groups](https://learn.microsoft.com/en-us/intune/intune-service/protect/reusable-settings-groups).

## Action Buttons

<details>

<summary>Deploy Reusable Settings</summary>

Opens a drawer that creates a reusable setting in one or more tenants from a saved template.

| Field                               | Description                                                                                 |
| ----------------------------------- | ------------------------------------------------------------------------------------------- |
| Select Tenants                      | The tenants to deploy to. Several can be selected, and the same setting is created in each. |
| Choose a Reusable Settings Template | The template to deploy, chosen from those saved in Reusable Settings Templates.             |
| Raw JSON                            | The template's configuration, shown for review before deploying.                            |

The configuration is also rendered below the field so it can be read without working through the JSON.

{% hint style="info" %}
Deploying does not create duplicates. CIPP looks for a setting in the target tenant whose name matches the template's, and where one is found it compares the two: an identical setting is reported as already compliant and left alone, and a differing one is updated in place. A new setting is only created where no match exists.
{% endhint %}

</details>

{% hint style="info" %}
Reusable settings templates can also be applied through the Reusable Settings Template standard, which keeps them in place across tenants rather than deploying them once. See [available-standards.md](../../../tenant/standards/alignment/templates/available-standards.md "mention").
{% endhint %}

## Table Details

The properties returned are for the Graph resource type `deviceManagementReusablePolicySetting`. For more information on the properties please see the [Graph documentation](https://learn.microsoft.com/en-us/graph/api/resources/intune-deviceconfigv2-devicemanagementreusablepolicysetting?view=graph-rest-beta#properties).

{% hint style="info" %}
A Referencing Configuration Policy Count column is available from the column chooser, showing how many configuration policies use each setting. It is worth checking before deleting one or changing its configuration.
{% endhint %}

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Edit Reusable Setting</td><td>Opens the setting for editing in edit.md.</td><td>false</td></tr><tr><td>Delete Reusable Setting</td><td>Deletes the reusable setting from the tenant. Configuration policies referencing it are left pointing at a setting that no longer exists.</td><td>true</td></tr><tr><td>Create Template from Setting</td><td>Saves the setting as a reusable settings template in CIPP, so the same setting can be deployed to other tenants.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
