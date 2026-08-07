# App Policies

Lists the app protection and app configuration policies on the selected tenant, showing what type each policy is and who it is assigned to. App protection policies control how corporate data is handled inside managed apps, while app configuration policies push settings into those apps. Both families are listed together here.

## Action Buttons

{% include "../../../.gitbook/includes/deploy-policy-expand.md" %}

## Table Details

| Column                  | Description                                                                                                                                                                                                                                                                                                                                               |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Display Name            | The name of the policy.                                                                                                                                                                                                                                                                                                                                   |
| Policy Type Name        | The kind of policy and the platform it applies to. App protection policies show as iOS App Protection, Android App Protection, Windows App Protection, Windows Information Protection (MDM) or App Configuration (MAM). App configuration policies show as iOS App Configuration, Android Enterprise App Configuration or Android for Work Configuration. |
| Policy Assignment       | The groups and broad targets the policy is assigned to. All Devices and All Licensed Users appear here where those targets are used.                                                                                                                                                                                                                      |
| Policy Exclude          | The groups excluded from the policy.                                                                                                                                                                                                                                                                                                                      |
| Last Modified Date Time | When the policy was last changed.                                                                                                                                                                                                                                                                                                                         |

A Policy Source column is also available from the column chooser, and appears in the row flyout. It distinguishes the two families the list is assembled from, showing AppProtection for a managed app policy and AppConfiguration for a mobile app configuration.

## Table Actions

{% include "../../../../.gitbook/includes/intune-actions.md" %}

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
