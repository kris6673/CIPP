# Add App Approval Template

This page creates an application deployment template: a saved definition of which application to deploy and what permissions to grant it, ready to be applied to any number of tenants. Arriving here through **Copy Template** loads an existing template's settings and titles the page Copy App Approval Template, saving as a new template rather than overwriting the original.

A preview panel sits alongside the form and updates as you fill it in, showing what the template will actually deploy.

{% stepper %}
{% step %}
### Name the Template

**Template Name** is required, and is the name you will pick from when deploying. Choosing an application in the next steps fills the name in for you as "\<application name> Template" if you have not typed one, so name the template last if you want CIPP's suggestion, or type your own at any point and it will be left alone.
{% endstep %}

{% step %}
### Choose the Application Type

**Application Type** determines everything that follows. There are three options:

* **Enterprise Application** deploys an existing multi-tenant application by its application ID, granting the permissions held in a permission set. The application must already be registered as multi-tenant.
* **Gallery Template** creates an application from Microsoft's Entra application gallery, with the permissions that gallery entry defines.
* **Application Manifest** recreates a single-tenant application in the target tenant from a manifest you supply, with the permissions the manifest itself requests.
{% endstep %}

{% step %}
### Select the Application

The fields shown here depend on the type chosen above.

**Enterprise Application** asks for two things. **Select Enterprise Application** lists the service principals in the current tenant, filtered to those whose sign-in audience is `AzureADMultipleOrgs` or `AzureADandPersonalMicrosoftAccount`, so single-tenant applications will not appear. **Select Permission Set** chooses which saved permission set to grant. If the set you need does not exist yet, **Create Permission Set** opens the permission set builder in a drawer without leaving this page.

{% hint style="info" %}
See [permission-sets.md](../permission-sets.md "mention") for building permission sets.
{% endhint %}

**Gallery Template** asks only for **Select Gallery Template**, listing the entries available in the Entra application gallery. The application's identifiers, description and supported sign-on modes are taken from the gallery entry and stored with the template.

**Application Manifest** asks for **Application Manifest (JSON)**, where you paste a manifest in the Microsoft Graph app manifest format. The manifest must be valid JSON, must include a `displayName`, and must either omit `signInAudience` or set it to `AzureADMyOrg`. It must also contain no `keyCredentials` or `passwordCredentials` sections; where it does, a **Remove Forbidden Sections** button appears that strips them out and reformats what remains.

{% hint style="warning" %}
Multi-tenant manifests are rejected on purpose. Deploying a manifest creates a new application in the target tenant, and a multi-tenant one created this way would be consentable from outside that tenant. Use an Enterprise Application template for multi-tenant applications instead.
{% endhint %}
{% endstep %}

{% step %}
### Create the Template

**Create Template** stays disabled until every required field is valid. Saving takes you to the edit view for the new template so you can adjust it straight away.
{% endstep %}
{% endstepper %}

## Preview

The panel beside the form shows what has been defined so far, and changes with the application type:

* **Permission Preview**, for enterprise app templates, listing the application and delegated permissions in the chosen permission set, grouped by the API that publishes them.
* **Gallery Template Info**, for gallery templates, showing the entry's description, publisher, categories, and supported single sign-on and provisioning modes.
* **Application Manifest**, for manifest templates, rendering the pasted manifest's sign-in audience, redirect URIs and requested permissions. The preview stays empty while the JSON is invalid, which makes it a quick check that the manifest parses.

{% hint style="success" %}
Saved templates can be deployed from [appapproval.md](../../../../tools/tenant-tools/appapproval.md "mention"), or applied continuously through the Deploy Application standard in [standards](../../../standards/ "mention").
{% endhint %}

***

{% include "../../../../../../.gitbook/includes/feature-request.md" %}
