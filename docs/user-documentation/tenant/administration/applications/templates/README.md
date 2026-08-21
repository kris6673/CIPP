# Application Templates

Application templates capture how an application should be deployed to a tenant: which application, which kind of deployment, and which permissions to grant. They are stored in CIPP rather than in any tenant, so a template written once can be deployed to any number of tenants from [appapproval.md](../../../../tools/tenant-tools/appapproval.md "mention").

Templates are created by hand from this page, and also automatically by the **Create Template from App** actions on [enterprise-apps](../enterprise-apps/ "mention") and [app-registrations](../app-registrations/ "mention").

## Page Actions

**Add Template** opens the App Approval Template form, where you choose the application type and the application, and for enterprise app templates the permission set to grant.

**Deploy Template** opens [appapproval.md](../../../../tools/tenant-tools/appapproval.md "mention"), where a saved template can be deployed to one or more tenants.

## Table Details

| Column              | Description                                                                                                                                                                                                                                                                                                                                                                                                       |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Template Name       | The name given to the template, used when selecting it for deployment.                                                                                                                                                                                                                                                                                                                                            |
| App Type            | Which kind of deployment the template performs: `EnterpriseApp` consents a multi-tenant application by its application ID, `GalleryTemplate` instantiates an application from the Entra application gallery, and `ApplicationManifest` recreates a single-tenant application from a captured manifest. Templates saved before these types existed have no value here and are treated as enterprise app templates. |
| App Id              | The application (client) ID of the application the template deploys.                                                                                                                                                                                                                                                                                                                                              |
| App Name            | The display name of that application.                                                                                                                                                                                                                                                                                                                                                                             |
| Permission Set Name | The permission set whose permissions the template grants. Only enterprise app templates reference one, so the column is empty for gallery and manifest templates, whose permissions come from the gallery consent or from the manifest itself.                                                                                                                                                                    |
| Updated By          | The CIPP user who last edited the template. This is only stamped when an existing template is saved again, so a template that has never been edited since creation shows nothing here.                                                                                                                                                                                                                            |
| Timestamp           | When the template was last written.                                                                                                                                                                                                                                                                                                                                                                               |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Edit Template</td><td>Opens the selected template in <a data-mention href="edit.md">edit.md</a> so its application, type and permission set can be changed.</td><td>false</td></tr><tr><td>Copy Template</td><td>Opens <a data-mention href="add.md">add.md</a> with the selected template's settings pre-filled, ready to be saved as a new template.</td><td>false</td></tr><tr><td>Save to GitHub</td><td>Uploads the selected template(s) to a GitHub repository you have write access to, prompting for the repository and a commit message. Only available when the GitHub integration is enabled.</td><td>true</td></tr><tr><td>Delete Template</td><td>Deletes the selected template(s), after a confirmation prompt naming the template.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

## Extended Info Flyout

Alongside the usual row details, the flyout renders a preview of what the template will deploy, which differs by application type:

* **Permission Preview**, for enterprise app templates, listing the application and delegated permissions the template grants, grouped by the API that publishes them.
* **Gallery Template Info**, for gallery templates, showing the application's description, publisher, categories, and its supported single sign-on and provisioning modes.
* **Application Manifest**, for manifest templates, showing the captured sign-in audience, redirect URIs and requested permissions.

{% hint style="info" %}
Templates are held at partner level rather than per tenant, so this table shows the same rows whichever tenant is selected.
{% endhint %}

{% hint style="warning" %}
An enterprise app template references a permission set by ID rather than copying it, so editing that set changes what the template grants on its next deployment. Manifest templates cannot be saved while the captured manifest still contains secrets or certificates; remove those sections and save again.
{% endhint %}

***

{% include "../../../../../../.gitbook/includes/feature-request.md" %}
