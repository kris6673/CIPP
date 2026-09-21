---
description: See how real attacks would play out in a tenant today, test sign-ins against its Conditional Access policies, and find the gaps in those policies.
---

# Security Simulations

Security Simulations shows you what an attacker would experience in a tenant right now. Instead of listing settings, it walks through the events that lead to a breach, checks each step against the tenant's real configuration, and tells you which control stops the chain or which one is missing.

The page has three tabs. They answer different questions and get their data in different ways, so it helps to know which is which:

| Tab                | Question it answers                                                   | Where the data comes from                                                           |
| ------------------ | --------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Scenarios          | If this attack happened today, would it succeed?                      | The tenant's stored test results. They refresh nightly and can be re-run on demand. |
| Sign-in Situations | Would this kind of sign-in be blocked, challenged, or let through?    | A live evaluation through Microsoft's Conditional Access What If API on every load. |
| CA Gap Analysis    | What is wrong with the tenant's Conditional Access policies as a set? | CIPP's cached copy of the tenant's Conditional Access policies.                     |

{% hint style="info" %}
Every tab needs a single tenant selected in the tenant selector. With AllTenants selected the page only asks you to pick one.
{% endhint %}

Nothing on this page signs in as a user or changes a tenant by itself. The only changes happen when you pick a fix on the Scenarios tab and confirm it.

## Scenarios

A scenario is an attack told as a sequence of steps, for example a stolen session token being replayed, a password spray against an account without MFA, a mailbox rule that forwards mail out of the tenant, or a Global Admin signing in from a device that is not compliant. Each step is checked against the tenant: standards are judged from the tenant's baseline alignment, alert steps from the alerts configured for the tenant, and the sign-in step live through the Conditional Access What If API using an account from the tenant.

The scenarios run alongside the nightly tests, so the list shows the last known result without you doing anything. Every scenario can also be checked again from this page.

### The scenario list

Scenarios are grouped by area, such as Identity & Conditional Access, Audit & Detection, Exchange & Email, and SharePoint & Data. Scenarios that have never run sit under Not checked yet. Each row shows an outcome:

| Outcome                | Meaning                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------- |
| Prevented              | A control in the tenant stops the attack.                                                |
| Alerted, not prevented | The attack succeeds, but an alert configured for the tenant would fire.                  |
| Not prevented          | The attack succeeds and nothing detects it.                                              |
| Not licensed           | The tenant lacks a licence the scenario needs, so the live sign-in check was skipped.    |
| Could not be evaluated | The sign-in step could not be evaluated, for example because no suitable account exists. |
| Not checked yet        | The scenario has no stored result.                                                       |

Outcomes that are not fully prevented also show how many gaps were found. A summary line above the list shows when the tenant was last checked and how many scenarios fall in each outcome.

**Run all checks** re-runs every scenario for the selected tenant, one at a time, and the button counts down as it goes.

### The scenario detail

Open a scenario to see how it plays out. The page shows which account was used for the evaluation, when it was checked, and a verdict such as which step blocked the attack, or that the attack succeeds with or without an alert firing. Below that is a timeline of the attack steps. Each step reports whether it is blocked, protected, or still allowed, and lists the checks behind it: whether an alert watches the action, whether the relevant standard is in a baseline and still aligned, and, for a sign-in step, which Conditional Access policies were evaluated and which applied.

{% hint style="info" %}
If a sign-in step is only stopped by a policy that is in report-only mode, the step says so. The policy would have blocked the sign-in had it been enforced, so it counts as a gap until it is switched on.
{% endhint %}

Two views are available at the top of the detail:

* **Today** shows what happens in the tenant right now.
* **With fixes** replays the same timeline as if every fix listed under What closes the gaps were in place. The sign-in outcomes in this view are the expected results, not a live evaluation.

**Run again** re-checks just this scenario. A scenario that has never been checked runs by itself the first time you open it.

### What closes the gaps

The card beside the timeline lists every control that would close a gap, with the step it belongs to and a one-click way to put it in place:

<details>

<summary>Add to baseline</summary>

Shown for a CIPP standard that is not in any baseline yet. Pick the baseline, the stage if the baseline has more than one, whether to remediate automatically when the tenant drifts, and the standard's own settings. The baseline applies the standard to its tenants on its next run. A baseline has to exist before this can be used; see [baselines](../baselines/ "mention").

</details>

<details>

<summary>Review</summary>

Shown for a standard that is already assigned but drifted or not applied. Opens [alignment.md](../baselines/alignment.md "mention") so you can see why.

</details>

<details>

<summary>Deploy</summary>

Shown for a Conditional Access policy fix. Opens [list-template](../conditional/list-template/ "mention") so you can deploy the matching template.

</details>

<details>

<summary>Enable</summary>

Shown for an alert. Pick the actions the alert should take and an optional comment, and the alert is created for the tenant. It then appears in [alert-configuration](../administration/alert-configuration/ "mention") like any other alert, where its conditions and actions can be changed.

</details>

When every mapped control is already in place, the card says so instead.

## Sign-in Situations

This tab takes a set of realistic sign-ins and runs each of them through Microsoft's Conditional Access What If API against the tenant's real policies. Nothing signs in and nothing changes; the API only reports what the policies would do. Situations are grouped by who is signing in: admin accounts, standard users, and guests. They cover things like an admin on an unmanaged device, a user signing in from a foreign country, a device-code flow, a legacy authentication client, and risk-based sign-ins.

Each situation reports whether the sign-in is blocked, requires a control such as MFA or a compliant device, or is allowed. Rows that get through explain which control is missing. If a report-only policy would have stopped the sign-in, the row says that too. A summary line above the list totals the sign-ins that are protected, the ones that get through, and the ones that could not be evaluated.

The situations are evaluated as real accounts from the tenant. CIPP picks an admin, a standard user, and a guest for you, and the **Sign in as** card lets you change them:

| Selector              | What it does                                                                                      |
| --------------------- | ------------------------------------------------------------------------------------------------- |
| Admin account         | The account used for the admin situations. Only accounts that hold a privileged role are offered. |
| Standard user account | The account used for the standard user situations. Guests and disabled accounts are left out.     |
| Guest account         | The account used for the guest situations.                                                        |
| Foreign country       | Where the "sign-in from a foreign country" situations originate.                                  |

Changing any selector re-evaluates immediately. The selectors reset to CIPP's own picks when you switch tenants.

Where a failing situation maps to a Conditional Access template, a **Deploy a CA template** link takes you to [list-template](../conditional/list-template/ "mention").

{% hint style="warning" %}
The tenant needs an Entra ID P1 or P2 licence for there to be any Conditional Access policies to evaluate. The risk-based situations need Entra ID P2; without it they are left out and the summary line says how many were excluded.
{% endhint %}

A situation shows Not evaluated when no suitable account is available in CIPP's cache for that group, for example a tenant with no guest accounts.

## CA Gap Analysis

This tab reviews the tenant's Conditional Access policies as a whole rather than one sign-in at a time. It works from CIPP's cached copy of the policies, so it needs no live calls and cannot change anything. It looks for well-known weaknesses such as MFA that is required in one policy but excluded in another, exclusions that let a whole class of apps bypass a policy, missing legacy authentication blocks, policies left in report-only mode, no break-glass accounts, and guests left out of the policies that should cover them.

The page has three parts:

* **Conditional Access score** is a number out of 10 with a caption showing how many of the expected controls are enforced and how many critical and high findings there are.
* **Coverage by persona** is a grid of the kinds of identity the policies target against the controls they should be subject to. Each cell shows whether that control is enforced, report-only, missing, not licensed, or not applicable for that persona. Hover a cell to see the policies behind it. The grid also counts the tenant's policies by state: enforced, report-only, and disabled.
* **Policy findings** lists every issue found, most severe first, with the policies it affects and what to change. Findings that map to Microsoft guidance link to the **Microsoft Documentation** for that control.

{% hint style="warning" %}
The analysis reads the cached policies only. A policy changed in the tenant a few minutes ago is not reflected until CIPP's copy refreshes, and a tenant that has never been cached shows nothing to analyse. Like the other tabs, it needs an Entra ID P1 or P2 licence; risk-based columns need P2 and are left out without it.
{% endhint %}

## Permissions

Viewing any tab needs the Security Simulations read permission. Running or re-running a scenario also needs write access to tests, and the fix buttons need whatever the page they hand off to requires: adding to a baseline, creating an alert, or deploying a Conditional Access template.
