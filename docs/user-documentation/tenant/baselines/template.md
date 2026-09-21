---
description: Build a baseline, assign it to tenants and stage its rollout
hidden: true
noIndex: true
---

# Add or Edit Baseline

The editor is where a baseline is given its name, its tenants, and the standards it applies. Standards are organised into stages, and a tenant receives a stage's standards only once it has met that stage's graduation conditions, which lets a baseline roll out gradually rather than all at once.

{% hint style="warning" %}
Baselines is in beta. Behaviour and screens are still changing between releases.
{% endhint %}

Leaving the page with unsaved work prompts you to confirm first.

## Page Actions

| Button        | Description                                                                                                                                                                                                                                                                                                 |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Back          | Returns to the previous page.                                                                                                                                                                                                                                                                               |
| Save Baseline | Saves the baseline. Greyed out until the three items in **Setup Progress** are complete. After a save you are offered a check of the assigned tenants, which makes no changes and reports its results on the [Alignment](alignment.md) page. Otherwise the schedule picks the baseline up within twelve hours. |
| Add Stage     | Adds a stage, either empty or as a copy of the stage currently open, including its standards and graduation conditions.                                                                                                                                                                                      |

## Baseline Details

| Field                  | Description                                                                                                                                          |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Baseline Name          | The name the baseline is listed under. Required.                                                                                                     |
| Description            | Free text describing what the baseline is for.                                                                                                       |
| Assigned Tenants       | The tenants and tenant groups the baseline applies to. Required before the baseline can be saved.                                                     |
| Excluded Tenants       | Tenants that are left out even though a group or All Tenants assignment would otherwise include them.                                                 |
| Disable Scheduled Runs | Stops the baseline running on its schedule. It then runs only when you run it yourself, and deviations are neither detected nor corrected in between. |

## Alerting

| Field                                          | Description                                                                                                                            |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Custom alert email addresses (comma separated) | Sends this baseline's alerts to these addresses instead of the global notification settings.                                            |
| Custom webhook URL                             | Sends this baseline's alerts to this webhook instead of the global notification settings.                                               |
| Disable Alerts for this baseline               | Stops all email, webhook, and PSA notifications for the baseline. Deviations are still detected and still shown on the Alignment page.  |

Leave the address and webhook fields empty to deliver through the global CIPP notification settings. Which events raise an alert at all is set per standard, in the standard's own settings.

## Setup Progress

A checklist of the three things a baseline needs before it can be saved: a name, at least one tenant or tenant group, and at least one standard in any stage.

## Baseline Summary

| Field                       | Description                                                                              |
| --------------------------- | ------------------------------------------------------------------------------------------ |
| Stages                      | How many stages the baseline currently has.                                              |
| Standards across all stages | How many distinct standards it applies in total.                                         |
| Potential Secure Score gain | The Secure Score increase available if every standard in the baseline becomes compliant. |
| Last updated                | When the baseline was last saved, and by whom.                                           |

## Stages

Each stage has its own tab. Stage 1 always applies to every assigned tenant, so it carries no conditions. Every stage after it has graduation conditions deciding when a tenant moves up. Earlier stages keep applying, and where the same standard appears in two stages the later stage's settings win.

A chip next to the stage name shows how many tenants are currently sitting in that stage.

### Graduation Conditions

Add as many conditions as you need. With more than one, a **Condition Logic** field appears and sets whether all of them must match or any one of them is enough. A stage with no conditions can only be advanced into by hand, from the Alignment page.

| Condition                                     | Description                                                                                                                                                                       |
| --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Time in previous stage                        | The tenant has spent a given number of days or weeks in the stage before this one.                                                                                                |
| Tenant variable                               | A custom variable on the tenant matches the value you give, compared with equals, not equals, starts with, or does not start with.                                                 |
| Is in tenant group                            | The tenant belongs to the tenant group you choose.                                                                                                                                |
| All previous stage items applied successfully | Every standard from the earlier stages reports as compliant for the tenant.                                                                                                       |
| Manual approval by an operator                | The tenant waits until an operator advances it from the [Alignment](alignment.md) page.                                                                                           |

### Standards In This Stage

**Add Standards** opens the catalogue, where standards can be searched by name, description, or benchmark tag, and narrowed by category, impact, the source that recommends them, and compliance tags. The results can be sorted, and shown as cards or as a list.

Each standard added to the stage expands to show its own settings, along with its impact, the Secure Score points it is worth, the benchmarks that recommend it, and the licences a tenant needs before it counts towards scoring. Standards that support it can be added more than once, so the same standard can be configured differently within one stage.

Three settings are common to every standard.

| Setting                                        | Description                                                                                             |
| ---------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Automatically fix this when the setting drifts | Corrects the setting back to its expected value on every run. Left off, the deviation is only reported.  |
| Alert on new deviation                         | Raises an alert the first time the setting is found to deviate.                                          |
| Alert when remediated                          | Raises an alert whenever automatic fixing corrects the setting.                                          |

**Set all standards to** applies any one of those settings across every standard in the stage at once.

{% hint style="info" %}
Standards arrive with automatic fixing switched off. Nothing is changed in a tenant until you turn it on, either per standard or with **Set all standards to**.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}
