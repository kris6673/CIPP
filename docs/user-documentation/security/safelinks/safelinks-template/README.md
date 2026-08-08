# Safe Links Templates

Safe Links policy templates are saved Safe Links configurations held in CIPP rather than in a tenant, so a policy and rule pair you have settled on can be deployed to any number of customers without rebuilding it each time. Templates get here in two ways: capture one from a live policy with **Create template based on policy** on the Safe Links Policies page, or build one from scratch here. From this page you can also publish a template to a GitHub repository to share it.

## Action Buttons

{% content-ref url="create.md" %}
[create.md](create.md)
{% endcontent-ref %}

{% content-ref url="add.md" %}
[add.md](add.md)
{% endcontent-ref %}

## Table Details

| Column               | Description                                                                                        |
| -------------------- | -------------------------------------------------------------------------------------------------- |
| Template Name        | The name given to the template.                                                                     |
| Template Description | The description for the template.                                                                   |
| GUID                 | CIPP's identifier for the template. Quote it when raising a support request about a specific template. |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Edit Template</td><td>Opens the <a data-mention href="edit.md">edit.md</a> page for the selected template.</td><td>false</td></tr><tr><td>Save to GitHub</td><td>Publishes the selected template to a repository you have write access to, prompting for the repository and a commit message. Greyed out unless the GitHub integration is enabled.</td><td>true</td></tr><tr><td>Delete Template</td><td>Removes the selected template from CIPP. Policies already deployed from it are unaffected.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
