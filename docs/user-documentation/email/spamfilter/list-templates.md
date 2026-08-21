# Spamfilter Templates

This page lists the spam filter templates saved in CIPP. Templates hold the settings that the **Deploy Spamfilter** form applies to a tenant, and they are created either with the **Create template based on rule** action on [README.md](list-spamfilter/README.md "mention") or by importing from a community repository.

## Table Details

The columns come from the saved template, so a column is empty where the template does not set that value.

| Column                      | Description                                                                                   |
| --------------------------- | --------------------------------------------------------------------------------------------- |
| Name                        | The template name, taken from the policy it was created from.                                 |
| High Confidence Spam Action | What the template sets Exchange to do with messages classified as high confidence spam.       |
| Bulk Spam Action            | What the template sets Exchange to do with bulk mail at or above the policy's bulk threshold. |
| Phish Spam Action           | What the template sets Exchange to do with messages classified as phishing.                   |
| GUID                        | The unique identifier CIPP assigns to the template.                                           |

**More Info** opens a flyout with the same five fields as the table.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Save to GitHub</td><td>Uploads the selected template to a community repository. You are asked for a <strong>Repository</strong>, listing only repositories CIPP can write to, and a <strong>Commit Message</strong>. Greyed out unless the GitHub integration is enabled.</td><td>true</td></tr><tr><td>Delete Template</td><td>Deletes the template from CIPP. Policies already deployed from it in a tenant are not affected.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

{% include "../../../../.gitbook/includes/feature-request.md" %}
