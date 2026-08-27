# Consented Applications

This report lists the applications that have been granted delegated permissions in the selected tenant, along with the scopes each one holds. It is the quickest way to review what third-party applications users have consented to, and to spot anything holding broader permissions than it should.

## Table Details

Each row combines the details of a single consent with information about the application it was granted to.

| Column          | Description                                                                                 |
| --------------- | ------------------------------------------------------------------------------------------- |
| Tenant          | The tenant the consent belongs to. Shown in the All Tenants view only.                      |
| Name            | The display name of the application the permissions were granted to.                        |
| Application ID  | The application's client identifier, shared across every tenant the application appears in. |
| Object ID       | The identifier of the application's service principal in this tenant.                       |
| Scope           | The delegated permissions the application has been granted.                                 |
| Start Time      | When the consent was granted.                                                               |
| Cache Timestamp | When the cached record was last refreshed. Shown in cached mode only.                       |

{% include "../../../../.gitbook/includes/feature-request.md" %}
