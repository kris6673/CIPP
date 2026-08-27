# Assignment Filter Templates

Lists the assignment filter templates saved in CIPP. A template holds a filter's platform, type and rule so the same filter can be created across tenants. Templates are stored in CIPP rather than in a tenant, so the list is the same whichever tenant is selected.

## Action Buttons

{% content-ref url="add.md" %}
[add.md](add.md)
{% endcontent-ref %}

{% content-ref url="deploy.md" %}
[deploy.md](deploy.md)
{% endcontent-ref %}

## Table Details

| Column       | Description                                    |
| ------------ | ---------------------------------------------- |
| Display Name | The name given to the template.                |
| Description  | The description recorded against the template. |
| Platform     | The platform the filter is created for.        |
| GUID         | CIPP's identifier for the template.            |

The template's rule and filter type are not shown as columns, but appear in the row flyout alongside everything else the template holds.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Edit Template</td><td>Opens the template for editing in <a data-mention href="edit-assignment-filter-template.md">edit-assignment-filter-template.md</a>.</td><td>false</td></tr><tr><td>Save to GitHub</td><td>Uploads the template to one of your GitHub repositories, prompting for the repository and a commit message. Only repositories you have write access to are offered. Hidden unless the GitHub integration is enabled.</td><td>true</td></tr><tr><td>Delete Template</td><td>Deletes the template from CIPP. Filters already created in a tenant from it are unaffected.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

{% include "../../../../../.gitbook/includes/feature-request.md" %}
