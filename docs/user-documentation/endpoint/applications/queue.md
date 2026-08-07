# Application Queue

Queued Applications lists the application deployments that CIPP has accepted but not yet pushed to Intune. Anything shown here is waiting to be created in the target tenant. The queue is not filtered by the tenant selector, so every pending deployment appears regardless of which tenant is chosen.

## Action Buttons

<details>

<summary>Run Queue now</summary>

Starts the application upload job immediately rather than waiting for the next scheduled run, and processes every item currently in the queue. The job runs in the background, so the queue will not empty the moment the dialog closes. Results are written to the logbook.

</details>

<details>

<summary>Add Application</summary>

Opens the same Application Deployment drawer as the Applications page, so a new deployment can be queued without navigating away. See [applications](../../tenant/administration/applications/ "mention") for the fields each application type requires.

</details>

## Table Details

| Column           | Description                                                                                                                                        |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Tenant Name      | The tenant the deployment is queued for, or AllTenants where it was queued for every customer.                                                     |
| Application Name | The name the application was given when it was queued.                                                                                             |
| Cmd Line         | The install command that will be run on the device. This is empty for application types that do not use one, such as Microsoft Office deployments. |
| Assign To        | The assignment chosen when the deployment was queued, which is applied once the application is created.                                            |

The Status column is also available from the column chooser. It is empty while an item is pending and shows Deployed for an All Tenants deployment that has already run at least once.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Delete Application</td><td>Removes the deployment from the queue so it will not be pushed to Intune. Applications that have already been created in a tenant are unaffected and must be removed from the Applications page instead.</td><td>true</td></tr></tbody></table>

{% hint style="info" %}
The queue is processed automatically every twelve hours, so items left alone will deploy without intervention. **Run Queue now** is for when you would rather not wait.
{% endhint %}

{% hint style="warning" %}
A deployment queued for a single tenant is removed from this list once it has been processed. A deployment queued for All Tenants stays in the list permanently with a status of Deployed, and is reprocessed on every run so that tenants added later also receive the application. Deleting it is the only way to stop that.
{% endhint %}

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
