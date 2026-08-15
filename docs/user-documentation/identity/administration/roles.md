---
description: Explore and review members for M365 roles
---

# Roles

This page lists every Entra ID role definition in the tenant along with who currently holds each one, so role assignments can be reviewed in one place rather than role by role in the portal. Roles with no members are listed too, which makes it useful for confirming that a sensitive role is genuinely empty.

## Table Details

CIPP builds this table by combining the tenant's role definitions with its role assignments and resolving each assigned principal, so the members appear alongside the role rather than as a separate lookup.

| Column       | Description                                                                                                                                        |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Display Name | The name of the role.                                                                                                                              |
| Description  | What the role grants, as described by Microsoft for built-in roles.                                                                                |
| Members      | The users and other principals currently assigned the role, each shown with their sign-in name where they have one. Empty for a role nobody holds. |
| Is Built In  | Whether the role is one of Microsoft's built-in definitions or a custom role created in the tenant.                                                |

{% hint style="info" %}
A principal assigned the same role at more than one scope, for example at tenant level and again over an administrative unit, is listed once rather than repeatedly.
{% endhint %}

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Remove Members</td><td>Opens a dialog listing the role's current members so one or more can be selected and removed. Greyed out for a role with no members, for custom roles, and without role write permissions.</td><td>false</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

{% hint style="info" %}
Custom roles cannot have their members removed from this page, because the removal runs against the built-in role definitions and a custom role has no matching template to act on. Manage those assignments in the Microsoft Entra admin center.
{% endhint %}

{% hint style="warning" %}
This page covers Entra ID directory roles. Permissions granted through Exchange Online role groups, Azure resource roles, or Microsoft Purview are held elsewhere and do not appear here, so a review of who holds administrative access needs to take in those as well.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}
