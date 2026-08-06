# Custom Test Report

Custom tests are checks you write yourself, in PowerShell, to assert something about a tenant that CIPP does not check out of the box. This page is where their results are read: it collects the outcome of every custom test across your tenants into one table, so you can answer "which of my clients fail this check" without opening each tenant in turn.

Tests are authored and enabled elsewhere, under [custom-tests](../../tools/custom-tests/ "mention"). This page only reports on them and triggers reruns.

## Scope

What the table covers is driven by two things: the tenant selector in the menu bar, and the test picker on the page.

| Selection                | Result                                                          |
| ------------------------ | --------------------------------------------------------------- |
| A single tenant          | Results for that tenant only.                                   |
| AllTenants               | Results for every tenant, one row per tenant per test.          |
| No tests picked          | Every custom test is included. This is the default.             |
| One or more tests picked | Only the selected tests, across whichever tenants are in scope. |

Leaving the picker empty and selecting AllTenants gives you the widest view, which is the usual starting point when auditing a new check across a client base.

## Running Tests

**Run Custom Tests** re-evaluates your enabled custom tests against the tenants currently in scope. Results appear in the table as each tenant finishes, so an all-tenants run populates progressively rather than all at once.

{% hint style="warning" %}
Tests are evaluated against CIPP's most recent cached data for the tenant, not against a fresh pull from Microsoft. A change made in a tenant minutes ago may not be reflected until the underlying cache has refreshed, so a rerun that returns an unchanged result is not necessarily wrong.
{% endhint %}

{% hint style="info" %}
Only enabled tests are run. A disabled test still appears in the table with its last recorded result, which is why the Enabled column matters when interpreting an old Last Run date.
{% endhint %}

## Table Details

| Column   | Description                                                                                           |
| -------- | ----------------------------------------------------------------------------------------------------- |
| Tenant   | The tenant the result applies to.                                                                     |
| Name     | The name of the custom test that produced this result.                                                |
| Enabled  | Whether the test is currently turned on. Only enabled tests are re-evaluated by **Run Custom Tests**. |
| Risk     | How serious a failure of this test is considered to be, as set by the test's author.                  |
| Status   | The outcome of the test. See below.                                                                   |
| Last Run | When this test was last evaluated against this tenant.                                                |

### Status

| Status      | Meaning                                                                                                               |
| ----------- | --------------------------------------------------------------------------------------------------------------------- |
| Passed      | The tenant met the condition the test checks for.                                                                     |
| Failed      | The tenant did not meet the condition.                                                                                |
| Investigate | The test ran but could not reach a clear pass or fail, and the result needs a human decision.                         |
| Skipped     | The test did not run against this tenant, for example because it did not apply or the data it needed was unavailable. |

### Risk

| Risk   | Meaning                                          |
| ------ | ------------------------------------------------ |
| High   | Treat a failure as urgent.                       |
| Medium | Worth addressing, but not immediately dangerous. |
| Low    | Informational or best-practice.                  |

Risk is assigned by whoever wrote the test, so it reflects your own judgement of severity rather than a Microsoft or CIPP classification.

### Filters

Quick filters are available for each Status value and each Risk level. **Failed** combined with **High Risk** is the fastest route to the findings that need attention first.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

Selecting any row opens the flyout directly, without going through the actions menu.

## Reading the Test Detail Flyout

The flyout is where a result becomes actionable. It has three parts.

### Assessment

A summary of how the test's author classified this check.

| Field                 | Description                                                  |
| --------------------- | ------------------------------------------------------------ |
| Risk                  | The severity assigned to a failure.                          |
| User Impact           | How noticeable the remediation would be to end users.        |
| Implementation Effort | How much work the remediation is expected to take.           |
| Standard Available    | Whether a CIPP standard exists that would satisfy this test. |

Where a matching standard exists, it is listed under **CIPP Standards that satisfy this test**, which turns a finding into a fix: rather than remediating by hand, apply the named standard to the tenant.

### Result

The output the test itself produced for this tenant. Custom tests can return either structured JSON or Markdown, and the flyout renders whichever the test was written to produce. This is the evidence behind the status, so it is where you look to understand _why_ a tenant failed rather than just _that_ it did.

### What did we check

The test's category and its description, rendered from the author's Markdown. Links here open in a new tab, so a well-written test can point directly at vendor documentation or an internal runbook.

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
