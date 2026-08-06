# Map GDAP Roles

This page maps GDAP roles to security groups in your partner tenant. Adding a technician to one of these groups is what grants them the corresponding delegated access in your customer tenants. The page has two modes: the default mode creates groups for you, while Advanced Mode maps roles to groups that already exist.

## Standard Mode

For each role you select, CIPP creates a new security group in your partner tenant named `M365 GDAP RoleName`. Add your users to these groups to set their GDAP permissions.

| Field                    | Description                                                                                                                                                                                                              |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Custom Suffix (optional) | Appends a suffix to the generated group names, producing `M365 GDAP RoleName - Suffix`. Use this when you need to map the same role to more than one group, for example to grant different access by team or department. |
| Select GDAP Roles        | The roles to map. At least one role is required.                                                                                                                                                                         |

Click **Add CIPP Default Roles** to automatically add the 15 recommended roles from the recommended-roles.md page. Once roles are selected, CIPP lists the groups it will create along with a description of what each role allows.

{% hint style="danger" %}
Certain roles may not be compatible with GDAP. See the [Microsoft documentation](https://learn.microsoft.com/en-us/partner-center/customers/gdap-least-privileged-roles-by-task) on GDAP role guidance. Unsupported roles are not available in CIPP to prevent random errors due to these roles being added to relationships.
{% endhint %}

{% hint style="danger" %}
The Company Administrator role is a highly privileged role that should be used with caution. GDAP Relationships with this role will not be eligible for auto-extend.
{% endhint %}

## Advanced Mode

Advanced Mode maps roles to security groups that already exist in your partner tenant, rather than creating new ones. Use it when your groups do not follow the default naming convention, for example when bringing an existing GDAP setup into CIPP.

Select a group and a role, then use the add button to build up the list of mappings. Each pairing appears in the Role Mappings table below, where it can be removed again before you submit.

| Field            | Description                                        |
| ---------------- | -------------------------------------------------- |
| Select Group     | An existing security group in your partner tenant. |
| Select GDAP Role | The role to assign through that group.             |

{% hint style="warning" %}
Use extreme caution in this mode. The following limitations apply:

* Reserved groups and roles are unavailable for mapping, to prevent misconfigurations due to permission overlap.
* Only one role can be mapped per group. If your current configuration maps more than one, use the **Reset Role Mapping** action on the relationship.
* Certain roles may not be compatible with GDAP. See the [Microsoft documentation](https://learn.microsoft.com/en-us/partner-center/customers/gdap-least-privileged-roles-by-task) on GDAP role guidance.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
