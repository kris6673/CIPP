# Registration Campaign

The registration campaign prompts users to set up a stronger authentication method during sign-in. After completing multi-factor authentication, targeted users are asked to register Microsoft Authenticator or a passkey and can postpone the prompt for a set number of days. This page shows the campaign currently configured in the tenant and saves changes back to it.

## Campaign Settings

| Field                                                            | Description                                                                                                                                                                      |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Campaign state                                                   | Whether the campaign runs. **Enabled** and **Disabled** are explicit; **Microsoft managed** hands the decision to Microsoft, which may turn the prompt on or off as it sees fit. |
| Authentication method to nudge users to register                 | Which method users are prompted to set up: **Microsoft Authenticator** or **Passkey (FIDO2)**. The choice applies to everyone the campaign targets, not per group.               |
| Days allowed to snooze (0-14)                                    | How long a user may postpone the prompt before being asked again. Setting this to 0 means the prompt appears at every sign-in until the method is registered.                    |
| Limited number of snoozes (require registration after 3 snoozes) | When on, users may postpone three times, after which registration is required to finish signing in.                                                                              |

## Targeting

| Field             | Description                                                                                           |
| ----------------- | ----------------------------------------------------------------------------------------------------- |
| Include all users | Targets every user in the tenant. When this is on, the include group and user selections are ignored. |
| Include group(s)  | Targets the members of the selected groups.                                                           |
| Include user(s)   | Targets the selected users individually.                                                              |
| Exclude group(s)  | Removes the members of the selected groups from the campaign, overriding any inclusion.               |
| Exclude user(s)   | Removes the selected users from the campaign, overriding any inclusion.                               |

{% hint style="warning" %}
A campaign must always have at least one include target. Saving with **Include all users** off and nothing chosen in the include fields does not scope the campaign to nobody: it falls back to targeting all users. Use **Campaign state** set to **Disabled** to stop the prompt, rather than emptying the targeting.
{% endhint %}

{% hint style="info" %}
Groups and users already targeted are shown by their object ID rather than their name until you change the selection, because the campaign stores only IDs and the page does not look them up on load. Anything you add through the pickers shows its display name.
{% endhint %}

{% hint style="info" %}
The **Sets the state for the request to setup Authenticator** standard writes the same campaign settings. Where that standard is applied to a tenant, changes made here are overwritten the next time it runs, so use one or the other rather than both.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
