# Compliance Policies

Lists the device compliance policies on the selected tenant, showing what type each policy is and who it is assigned to. Compliance policies define the conditions a device must meet to be considered compliant, which conditional access and other controls can then act on.

## Action Buttons

{% include "../../../.gitbook/includes/deploy-policy-expand.md" %}

## Table Details

| Column                  | Description                                                                                                                                  |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Display Name            | The name of the policy.                                                                                                                      |
| Policy Type Name        | The platform the policy applies to, for example Windows 10/11 Compliance, iOS Compliance, macOS Compliance or Android Enterprise Compliance. |
| Policy Assignment       | The groups and broad targets the policy is assigned to. All Devices and All Licensed Users appear here where those targets are used.         |
| Policy Exclude          | The groups excluded from the policy.                                                                                                         |
| Description             | The description recorded against the policy.                                                                                                 |
| Last Modified Date Time | When the policy was last changed.                                                                                                            |

The remaining properties, available from the column chooser and in the row flyout, are those of the Graph resource type `deviceCompliancePolicy`. For more information on the properties please see the [Graph documentation](https://learn.microsoft.com/en-us/graph/api/resources/intune-shared-devicecompliancepolicy?view=graph-rest-beta#properties).

## Table Actions

{% include "../../../../.gitbook/includes/intune-actions.md" %}

{% include "../../../../.gitbook/includes/feature-request.md" %}
