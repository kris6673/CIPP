# Role Mappings

This page lists the GDAP roles that have been mapped to security groups in your partner tenant. Each mapping tells CIPP which group to assign a role through when it sets up a relationship, so a technician gains delegated access by being a member of the mapped group. Mappings created here are the building blocks for role-templates, which in turn drive invites and onboarding.

Use the **Map GDAP Roles** button to create new mappings via [add.md](add.md "mention").

## Table Details

| Column     | Description                                                                                       |
| ---------- | ------------------------------------------------------------------------------------------------- |
| Role Name  | The name of the GDAP role associated with the mapping.                                            |
| Group Name | The name of the Entra ID security group in your partner tenant that the role is assigned through. |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Add to Template</td><td>Adds the selected mapping to a role template. You can pick an existing template or type a new name to create one.</td><td>true</td></tr><tr><td>Delete Mapping</td><td>Removes the mapping from CIPP. The security group itself is not deleted and existing GDAP relationships are not changed.</td><td>true</td></tr></tbody></table>

{% include "../../../../../.gitbook/includes/feature-request.md" %}
