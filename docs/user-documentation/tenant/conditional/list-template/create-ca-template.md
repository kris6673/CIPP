# Create CA Template

This page builds a Conditional Access template from scratch, using the same structured editor as the policy editor. Nothing is deployed when you save: the template is stored in CIPP, ready to deploy to any tenant, add to a standard, or push to a GitHub repository.

Because the template is not tied to a tenant, the editor asks you to name users, groups, and locations rather than pick them from a directory. Those names are resolved against the target tenant at deployment time.

New templates default to a state of **Report-only**, so a template deployed without changing the state will log what it would have done rather than enforce anything.

## Policy Basics

| Field        | Description                                                                                          |
| ------------ | ---------------------------------------------------------------------------------------------------- |
| Display Name | The name of the policy the template creates. Required.                                               |
| Policy State | Whether the deployed policy is enabled, disabled, or report only. Defaults to Report-only. Required. |

## Users and Groups

| Field                   | Description                                                        |
| ----------------------- | ------------------------------------------------------------------ |
| Include Users           | The users the policy targets.                                      |
| Exclude Users           | Users exempt from the policy.                                      |
| Include Groups          | The groups the policy targets.                                     |
| Exclude Groups          | Groups exempt from the policy.                                     |
| Include Directory Roles | Directory roles the policy targets, for scoping to administrators. |
| Exclude Directory Roles | Directory roles exempt from the policy.                            |

### Exclude Guests or External Users

| Field                          | Description                                                                                                           |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| External User Types to Exclude | The categories of external user to exempt, such as service providers or B2B collaboration guests.                     |
| Tenant Scope                   | Whether the exclusion covers all external tenants or only named ones. Appears once an external user type is selected. |
| External Tenant IDs            | The tenant GUIDs the exclusion applies to. Appears only when the scope is set to specific tenants.                    |

## Cloud Apps or Actions

| Field                                | Description                                                                                |
| ------------------------------------ | ------------------------------------------------------------------------------------------ |
| Include Applications                 | The applications the policy targets.                                                       |
| Exclude Applications                 | Applications exempt from the policy.                                                       |
| User Actions (instead of cloud apps) | Targets a user action, such as registering security information, in place of applications. |

## Conditions

| Field             | Description                                                           |
| ----------------- | --------------------------------------------------------------------- |
| Client App Types  | The client app types the policy applies to. At least one is required. |
| Include Platforms | Device platforms the policy targets.                                  |
| Exclude Platforms | Device platforms exempt from the policy.                              |
| Include Locations | Named locations the policy targets, referenced by name.               |
| Exclude Locations | Named locations exempt from the policy, referenced by name.           |

### Device Filter

| Field              | Description                                                                |
| ------------------ | -------------------------------------------------------------------------- |
| Device Filter Mode | Whether devices matching the rule are included or excluded.                |
| Device Filter Rule | The filter expression, for example `device.extensionAttribute1 -eq "SAW"`. |

### Risk Levels

{% hint style="warning" %}
These require **Entra ID P2**. Usage of these without proper licensing could risk your client's tenant and your partner status.
{% endhint %}

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

## Named Locations

This section is unique to templates. Named locations defined here are stored inside the template and recreated in the target tenant on deployment, or matched to an existing location of the same display name. Reference them by name in the **Include Locations** and **Exclude Locations** fields under Conditions.

Use **Add Named Location** to add an entry, and the delete icon on any entry to remove it. Each entry has a display name and a location type, and the remaining fields depend on the type chosen.

| Field         | Description                                                                          |
| ------------- | ------------------------------------------------------------------------------------ |
| Display Name  | The name of the location. This is the name you reference under Conditions. Required. |
| Location Type | Either Countries / Regions or IP Ranges. Required.                                   |

### IP Ranges

| Field                          | Description                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| IP Ranges (CIDR, one per line) | The address ranges in CIDR notation, one per line, for example `203.0.113.0/24`. At least one is required. |
| Mark as Trusted Location       | Marks the location as trusted, which some policies and risk evaluations treat differently.                 |

### Countries / Regions

| Field                               | Description                                                                                              |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Countries / Regions                 | The countries or regions the location covers. At least one is required.                                  |
| Country Lookup Method               | Whether the country is determined from the client IP address or from the Authenticator app's GPS signal. |
| Include Unknown Countries / Regions | Includes addresses that cannot be mapped to a country.                                                   |

{% hint style="info" %}
A template deployed to a tenant is not linked to it afterwards. Editing the template later does not change policies already deployed from it, unless the template is applied through a standard, which redeploys on drift.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
