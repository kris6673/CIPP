# Spamfilter

This page lists the hosted content filter (anti-spam) policies in the selected tenant, together with the state and priority of the content filter rule that applies each one. Use it to see which policy is the tenant's default, which rules are live, and what each policy does with high confidence spam, bulk mail, and phishing.

## Action Buttons

{% content-ref url="add.md" %}
[add.md](add.md)
{% endcontent-ref %}

## Table Details

| Column                      | Description                                                                      |
| --------------------------- | -------------------------------------------------------------------------------- |
| Name                        | The name of the hosted content filter policy.                                    |
| Is Default                  | Whether this is the tenant's default anti-spam policy.                           |
| Rule State                  | Whether the content filter rule that applies this policy is enabled or disabled. |
| Rule Prio                   | The priority of that rule. Lower numbers are evaluated first.                    |
| High Confidence Spam Action | What Exchange does with messages classified as high confidence spam.             |
| Bulk Spam Action            | What Exchange does with bulk mail at or above the policy's bulk threshold.       |
| Phish Spam Action           | What Exchange does with messages classified as phishing.                         |
| When Created                | When the policy was created.                                                     |
| When Changed                | When the policy was last modified.                                               |

**Rule State** and **Rule Prio** come from the rule that applies the policy, so both are empty on a policy that has no rule attached to it.

**More Info** opens a flyout showing the policy's advanced scoring and marking options, covering the score increases for image links, numeric IPs, redirects to another port, and business or info URLs, along with the marking options such as **Mark As Spam Bulk Mail**, **Mark As Spam Spf Record Hard Fail**, and **Mark As Spam Ndr Backscatter**.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Create template based on rule</td><td>Saves the selected policy as a spam filter template, which then appears on <a data-mention href="../list-templates.md">list-templates.md</a>.</td><td>true</td></tr><tr><td>Enable Rule</td><td>Enables the content filter rule that applies the policy. Greyed out unless <strong>Rule State</strong> is <code>Disabled</code>.</td><td>true</td></tr><tr><td>Disable Rule</td><td>Disables the content filter rule that applies the policy, leaving the policy itself in place. Greyed out unless <strong>Rule State</strong> is <code>Enabled</code>.</td><td>true</td></tr><tr><td>Delete Rule</td><td>Deletes the content filter rule and the policy it applies. Both are removed, and this cannot be undone.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
