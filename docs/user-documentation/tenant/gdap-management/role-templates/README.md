# Role Templates

This page lists the GDAP role templates you have created. A template is a named set of role mappings, and it is what you select when generating an invite or onboarding a tenant, so that every relationship is built with a consistent set of permissions.

If this is your first time setting up CIPP, the page prompts you to create the **CIPP Defaults** template, which contains the 15 roles included on the [recommended-roles.md](../../../../setup/maintaining-cipp/recommended-roles.md "mention") page. The prompt appears whenever no template named `CIPP Defaults` exists, so it will return if you delete or rename that template.

Use the **Add Template** button to create a new template via [add.md](add.md "mention").

## Table Details

| Column        | Description                                                                                                       |
| ------------- | ----------------------------------------------------------------------------------------------------------------- |
| Template Id   | The name of the template. This is the value you select when creating invites and onboarding tenants.              |
| Role Mappings | The role mappings contained in the template, showing the group name, group ID, role name, and GDAP role for each. |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Edit Template</td><td>Opens <a data-mention href="edit.md">edit.md</a> so you can rename it or change which role mappings it contains.</td><td>false</td></tr><tr><td>Delete Template</td><td>Removes the template from CIPP. The underlying role mappings and security groups are not deleted, and existing relationships built from the template are not changed.</td><td>true</td></tr></tbody></table>

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
