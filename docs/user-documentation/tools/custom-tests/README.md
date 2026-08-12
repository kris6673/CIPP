# Custom Tests

This page lists the custom tests you have created, which run alongside CIPP's built-in tests and can be surfaced in the [dashboard](../../dashboard/ "mention")or the [builder.md](../report-builder/builder.md "mention").

### Feature Walkthrough

{% @storylane/embed subdomain="app" url="https://app.storylane.io/share/qevotii3ats1" linkValue="qevotii3ats1" %}

## Action Buttons

**Add Test** opens the test editor with a blank test:

{% content-ref url="add.md" %}
[add.md](add.md)
{% endcontent-ref %}

<details>

<summary>Import from GitHub</summary>

Opens the **Browse Custom Test Catalog** flyout, listing custom tests published in the community-repos registered with your instance. Search for a test, preview it, then select **Import** to add it to your own tests.

There is no option to import from one of your tenants, as custom tests are not tenant objects.

</details>

## Table Details

| Column                | Description                                                                                                                                                                                                                   |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Script Name           | The display name of the script.                                                                                                                                                                                               |
| Description           | The description set on the script.                                                                                                                                                                                            |
| Enabled               | Whether the test runs with the rest of the tests on schedule.                                                                                                                                                                 |
| Alert On Failure      | Whether CIPP sends an alert when the test produces a result matching its configured alert statuses.                                                                                                                           |
| Result Mode           | How the test's pass or fail state is decided. `Auto` lets the script's own output determine the outcome, while `Always Pass`, `Always Info` and `Always Investigate` force that result regardless of what the script returns. |
| Return Type           | `JSON` or `Markdown`.                                                                                                                                                                                                         |
| Category              | Existing options: `License Management`, `Security`, `Compliance`, `User Management`, `Group Management`, `Device Management`, `Guest Management`, `General`, or any custom category you create.                               |
| Pillar                | Classifies which area the test belongs to. One of `Identity`, `Devices`, `Data`.                                                                                                                                              |
| Risk                  | The risk label associated with the script. One of `Low`, `Medium`, `High`, `Critical`.                                                                                                                                        |
| User Impact           | Classifies the impact to the end user. One of `Low`, `Medium`, or `High`.                                                                                                                                                     |
| Implementation Effort | Classifies the effort to remediate a failed test. One of `Low`, `Medium`, or `High`.                                                                                                                                          |
| Version               | The version of the script. Latest is shown by default.                                                                                                                                                                        |
| Created By            | The UPN of the user that created the script.                                                                                                                                                                                  |
| Created Date          | Relative time since the script was created.                                                                                                                                                                                   |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Edit Test</td><td>Opens <a data-mention href="add.md">add.md</a> with the selected test populated.</td><td>false</td></tr><tr><td>View Versions</td><td>Opens <a data-mention href="versions.md">versions.md</a> for the selected test script.</td><td>false</td></tr><tr><td>Enable Test</td><td>Enables the selected test to run with the rest of the test suite. Only shown on tests that are currently disabled.</td><td>true</td></tr><tr><td>Disable Test</td><td>Stops the selected test from running. Only shown on tests that are currently enabled.</td><td>true</td></tr><tr><td>Enable Alerts</td><td>Enables alerting for the selected test. Only shown where alerts are currently off.</td><td>true</td></tr><tr><td>Disable Alerts</td><td>Turns off alerting for the selected test. Only shown where alerts are currently on.</td><td>true</td></tr><tr><td>Delete Test</td><td>Permanently deletes the selected test, including every version of it.</td><td>true</td></tr><tr><td>Save to GitHub</td><td>Publishes the selected test to a community repository, so it can be shared or reused elsewhere. You choose the repository and supply a commit message. Only shown when the GitHub integration is enabled.</td><td>true</td></tr></tbody></table>

{% hint style="warning" %}
Deleting a test removes all of its versions and cannot be undone. Where you only want the test to stop running, disable it instead.
{% endhint %}

{% hint style="info" %}
Only repositories you have write access to are offered when saving to GitHub. Where the list is empty, the repositories registered with your instance are all read-only, which includes the built-in CyberDrain ones.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}
