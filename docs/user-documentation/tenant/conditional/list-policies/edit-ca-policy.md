# Edit CA Policy

This page opens an existing Conditional Access policy in a structured editor, laid out to mirror the sections in the Entra admin center. The current settings are loaded from the tenant, so you are always editing the live policy rather than a copy. Review changes carefully before saving, since an overly restrictive policy can lock users, or you, out of the tenant.

The editor is built from the Graph schema, so it exposes conditions the policy list does not show as columns, including risk levels, device filters, and session controls.

## Policy Basics

| Field        | Description                                                                |
| ------------ | -------------------------------------------------------------------------- |
| Display Name | The name of the policy. Required.                                          |
| Policy State | Whether the policy is enabled, disabled, or in report-only mode. Required. |

## Users and Groups

Defines who the policy applies to.

| Field                   | Description                                                        |
| ----------------------- | ------------------------------------------------------------------ |
| Include Users           | The users the policy targets.                                      |
| Exclude Users           | Users exempt from the policy.                                      |
| Include Groups          | The groups the policy targets.                                     |
| Exclude Groups          | Groups exempt from the policy.                                     |
| Include Directory Roles | Directory roles the policy targets, for scoping to administrators. |
| Exclude Directory Roles | Directory roles exempt from the policy.                            |

### Exclude Guests or External Users

| Field                          | Description                                                                                                                                                                                            |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| External User Types to Exclude | The categories of external user to exempt, such as service providers or B2B collaboration guests.                                                                                                      |
| Tenant Scope                   | Whether the exclusion covers all external tenants or only named ones. Appears once an external user type is selected, and is only meaningful for genuinely external users rather than internal guests. |
| External Tenant IDs            | The tenant GUIDs the exclusion applies to. Appears only when the scope is set to specific tenants.                                                                                                     |

{% hint style="info" %}
Excluding your own partner tenant here is what the **Add service provider exception to policy** action on the policy list does for you. Use that action rather than setting this by hand unless you need something more specific.
{% endhint %}

## Cloud Apps or Actions

| Field                                | Description                                                                                |
| ------------------------------------ | ------------------------------------------------------------------------------------------ |
| Include Applications                 | The applications the policy targets.                                                       |
| Exclude Applications                 | Applications exempt from the policy.                                                       |
| User Actions (instead of cloud apps) | Targets a user action, such as registering security information, in place of applications. |

## Conditions

| Field             | Description                                                                                               |
| ----------------- | --------------------------------------------------------------------------------------------------------- |
| Client App Types  | The client app types the policy applies to, for example browser or mobile apps. At least one is required. |
| Include Platforms | Device platforms the policy targets.                                                                      |
| Exclude Platforms | Device platforms exempt from the policy.                                                                  |
| Include Locations | Named locations the policy targets.                                                                       |
| Exclude Locations | Named locations exempt from the policy.                                                                   |

### Device Filter

| Field              | Description                                                                |
| ------------------ | -------------------------------------------------------------------------- |
| Device Filter Mode | Whether devices matching the rule are included or excluded.                |
| Device Filter Rule | The filter expression, for example `device.extensionAttribute1 -eq "SAW"`. |

### Risk Levels

Marked in the interface as requiring **Entra ID P2**.

| Field                         | Description                                                  |
| ----------------------------- | ------------------------------------------------------------ |
| Sign-in Risk Levels           | Risk levels for the sign-in attempt that trigger the policy. |
| User Risk Levels              | Risk levels for the account itself that trigger the policy.  |
| Service Principal Risk Levels | Risk levels for workload identities that trigger the policy. |
| Insider Risk Levels           | Insider risk levels that trigger the policy.                 |

### Authentication Flows

| Field                                | Description                                                                          |
| ------------------------------------ | ------------------------------------------------------------------------------------ |
| Authentication Flow Transfer Methods | The authentication transfer methods the policy applies to, such as device code flow. |

## Grant Controls

What the policy requires before granting access.

| Field                          | Description                                                                                 |
| ------------------------------ | ------------------------------------------------------------------------------------------- |
| Grant Operator                 | Whether the built-in controls are combined with AND or OR.                                  |
| Built-in Controls              | The requirements to grant access, such as multifactor authentication or a compliant device. |
| Authentication Strength Policy | An authentication strength policy to require in place of plain MFA.                         |
| Terms of Use                   | Terms of use the user must accept.                                                          |

## Session Controls

Collapsed by default, since most policies do not use these.

| Field                            | Description                                                                                                                    |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Enable App Enforced Restrictions | Hands session limits to the application itself, used by SharePoint and Exchange to restrict downloads.                         |
| Enable App Control               | Routes the session through Defender for Cloud Apps.                                                                            |
| Control Type                     | How the session is proxied when app control is enabled.                                                                        |
| Enable Sign-in Frequency         | Forces reauthentication on a schedule.                                                                                         |
| Interval Mode                    | Whether the frequency is a recurring period or a fixed time.                                                                   |
| Value                            | The number of units in the sign-in frequency.                                                                                  |
| Unit                             | Hours or days.                                                                                                                 |
| Auth Type                        | Which authentication the frequency applies to.                                                                                 |
| Enable Persistent Browser        | Controls whether the browser session persists across restarts.                                                                 |
| Persistence Mode                 | Whether sessions are always persistent or never persistent.                                                                    |
| Disable Resilience Defaults      | Stops Entra extending existing sessions during an outage. Leaving resilience defaults on is the safer choice for most tenants. |

{% hint style="warning" %}
Test changes with the policy set to report only before enabling it, particularly when adding grant controls or narrowing the users the policy applies to. A policy that excludes no break-glass account can remove your own access to the tenant.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
