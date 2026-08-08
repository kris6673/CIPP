# Connection Filter Templates

This page lists the connection filter templates saved in CIPP. Templates hold the settings that the **Deploy ConnectionFilter** form applies to a tenant, and they are created either with the **Create template based on filter** action on [README.md](list-connectionfilter/README.md "mention") or by importing from a community repository.

## Table Details

The columns come from the saved template, so a column is empty where the template does not set that value.

| Column           | Description                                                                                                |
| ---------------- | ---------------------------------------------------------------------------------------------------------- |
| Name             | The template name, taken from the policy it was created from.                                              |
| Is Default       | Carried over from the policy the template was created from. It has no effect when the template is applied. |
| IP Allow List    | The IP addresses and ranges the template always allows through connection filtering.                       |
| IP Block List    | The IP addresses and ranges the template always blocks.                                                    |
| Enable Safe List | Whether the template turns on Microsoft's safe list of trusted senders.                                    |
| GUID             | The unique identifier CIPP assigns to the template.                                                        |

**More Info** opens a flyout with the same six fields as the table.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Save to GitHub</td><td>Uploads the selected template to a community repository. You are asked for a <strong>Repository</strong>, listing only repositories CIPP can write to, and a <strong>Commit Message</strong>. Greyed out unless the GitHub integration is enabled.</td><td>true</td></tr><tr><td>Delete Template</td><td>Deletes the template from CIPP. Connection filter settings already applied from it in a tenant are not affected.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
