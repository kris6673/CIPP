# Copilot Settings

This is a simple table view of Microsoft 365 Copilot tenant settings for the selected tenant, mirroring the Copilot policy settings found in the Microsoft 365 admin center. The settings covered are:

* Pin Microsoft 365 Copilot Chat
* Block Copilot Access to Open Content
* Designer Image Generation
* Allow web search in Copilot
* Admin Copilot in Microsoft 365 Admin Center

## Table Details

| Column  | Description                                                                                                                                                                                                                         |
| ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Setting | The name of the Microsoft 365 Copilot tenant setting.                                                                                                                                                                               |
| State   | The setting's current configured state, for example Enabled, Disabled, or Not configured. The web search setting reports its three-state value instead, and a setting CIPP could not read from the tenant shows **Unable to read**. |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Set Status</td><td>Changes the selected setting's state. For most settings, prompts for a desired state: Enabled, Disabled, or Not configured. The web search setting is a three-state policy, so it instead offers the same options as the Microsoft 365 admin center: enabled in both Microsoft 365 Copilot and Microsoft 365 Copilot Chat, disabled in both, or disabled in Microsoft 365 Copilot Work mode while enabled in Microsoft 365 Copilot Chat, plus Not configured. Refetches the list so the updated state is reflected.</td><td>true</td></tr></tbody></table>

***

{% include "../../../.gitbook/includes/feature-request.md" %}
