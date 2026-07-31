# View Individual User

The View User page provides a comprehensive overview of user details and settings. It serves as the main landing page when viewing a user, with additional tabs available for more specific operations, such as Edit User, Compromise Remediation, etc.

## Overview

- Primary display of user information including a quick link to view the user in Entra
- Additional tabs at top for extended functionality (Edit, Compromise Remediation, etc.)
- Inherits Actions dropdown from list users page

## Actions

The actions dropdown carries forward the same [#table-actions](../#table-actions "mention") from the main Users page.

---

## User Information Fields

### Profile & Identity

| Field                        | Description                                                                                                                                     |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| User Photo                   | Displays user's Entra ID photo; shows initials if no photo is uploaded. Includes the ability to upload a new photo or delete the current photo. |
| Display Name                 | User's full display name as shown in the directory                                                                                              |
| User Principal Name          | Primary username/login identity for the user                                                                                                    |
| Account Enabled              | Boolean indicator showing if user can sign in (✓/✗)                                                                                             |
| Synced from Active Directory | Boolean indicator showing if account is AD-synced (✓/✗)                                                                                         |

### Licensing & Contact

| Field          | Description                                    |
| -------------- | ---------------------------------------------- |
| Licenses       | List of currently assigned M365/Azure licences |
| Email Address  | Primary and alternative email addresses        |
| Business Phone | Primary business contact number                |
| Mobile Phone   | User's mobile contact number                   |

### Professional Information

| Field           | Description                  |
| --------------- | ---------------------------- |
| Job Title       | User's current position/role |
| Department      | Organisational department    |
| Office Location | Physical office location     |

### Address Information

| Field       | Description             |
| ----------- | ----------------------- |
| Address     | Street address details  |
| Postal Code | ZIP/Postal code         |
| Country     | The country of the user |
| City        | The city of the user    |

### Security & Access

| Field                               | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Last Logon                          | <p>Most recent sign-in information<br>• Expandable for additional details (click arrow)</p>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| Applied Conditional Access Policies | <p>Active security policies<br>• Expandable for policy details (click arrow)</p>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| Multi-Factor Authentication Devices | <p>Registered MFA methods. Each card shows the method type and the identifier that distinguishes it (device name, phone number, security key model, email address), plus when the method was last used<br>• The method matching the user's preferred second factor is marked <strong>User default</strong><br>• The method Microsoft selects while system-preferred MFA is enabled is marked <strong>System-preferred</strong><br>• Remove an individual method with the bin icon<br>• <strong>Set Default MFA Method</strong> sets the preferred second factor, offering only methods the user has registered<br>• Expandable for method details (click arrow)</p> |

### Group & Role Memberships

| Field             | Description                                                                                                                                                                                          |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Group Memberships | <p>Table of all group associations<br>• Includes per-row actions<br>• Direct link to <a data-mention href="../../groups/edit.md">edit.md</a> page for the associated group to manage membership.</p> |
| Admin Roles       | Table of assigned administrative roles. The Actions column will allow you to remove the user from the assigned role.                                                                                 |

### Managed Devices

This card will display the devices the user is associated with.

## Notes

- Information is read-only in this view, apart from the user photo and the MFA method actions described above
- When system-preferred MFA is enabled, Microsoft selects the strongest registered method at sign-in and the user's default second factor is ignored
- Use Edit tab to modify information
- Expandable sections (▼) provide additional details
- Direct links to related management pages
- Real-time data from Entra ID

This view serves as the central hub for user information, providing quick access to both basic details and advanced management options through the tabbed interface.

---

{% include "../../../../../../.gitbook/includes/feature-request.md" %}
