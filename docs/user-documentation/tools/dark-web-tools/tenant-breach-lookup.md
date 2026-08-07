# Tenant Breach Lookup

This page lists the accounts in the selected tenant that appear in known data breaches, along with the credentials exposed. Results come from a background search that you start from this page, so the table shows what was found the last time a search ran rather than a live lookup.

{% hint style="danger" %}
The **Password** column contains credentials exposed in a breach, in the clear. Treat this page as sensitive: anyone who can view it can read those passwords. Where an account appears here and the password is still in use anywhere, reset it and check for reuse across other services rather than only in Microsoft 365.
{% endhint %}

## Action Buttons

<details>

<summary>Run Breach Check</summary>

Opens a confirmation dialog naming the tenant the search will run against. Selecting **Run Breach Search** queues the job and returns straight away, it does not wait for results.

The search collects every domain registered in the tenant and checks each one for breached accounts. Results are written back per domain as they are found.

</details>

{% hint style="info" %}
The search runs in the background and can take up to 24 hours to complete. Nothing on this page updates while it runs, so refresh the table later to pick up results rather than waiting on the dialog.
{% endhint %}

{% hint style="warning" %}
Results are only written back where the number of breached accounts found for a domain has changed since the last search. Re-running a check against a domain whose count is unchanged leaves the existing rows exactly as they are, so an unchanged table does not necessarily mean the search failed.
{% endhint %}

## Table Details

| Column   | Description                                               |
| -------- | --------------------------------------------------------- |
| Email    | The breached account.                                     |
| Password | The password exposed for that account in the breach data. |
| Sources  | The breaches the account was found in.                    |

An account exposed in several breaches appears once per breached credential, so the same address can be listed more than once.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>View User</td><td>Opens the <a data-mention href="breach-lookup.md">breach-lookup.md</a> page with the selected address already filled in, showing everything known about that individual account.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
