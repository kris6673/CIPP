# Mappings

This tab shows how the roles approved on a GDAP relationship are actually assigned, listing each security group in your partner tenant that carries roles for the customer, and the users who are members of that group. This is where you confirm that a technician will genuinely receive the access the relationship allows, since an approved role grants nothing until it is assigned to a group and someone is a member of it.

## Table Details

| Column               | Description                                                                                        |
| -------------------- | -------------------------------------------------------------------------------------------------- |
| Group - Display Name | The security group in your partner tenant that the roles are assigned through.                     |
| Status               | The current state of the access assignment.                                                        |
| Created Date Time    | When the assignment was created.                                                                   |
| Roles                | The admin roles granted in the customer tenant to members of the group.                            |
| Members              | The users in your partner tenant who are members of the group, and who therefore hold this access. |

{% hint style="info" %}
An empty table on an active relationship means the roles have been approved but never assigned to a group, so nobody holds the access yet. Use the **Reset Role Mapping** action on the relationships list to apply a role template and create the assignments.
{% endhint %}

{% include "../../../../../../.gitbook/includes/feature-request.md" %}
