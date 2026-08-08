# Sensitive Info Type Templates

Sensitive Information Type templates are saved detection patterns held in CIPP rather than in a tenant, so a custom type you have settled on can be deployed to any number of customers without rebuilding it each time. Templates get here in three ways: capture one from a live type with **Create template based on SIT** on the Sensitive Information Types page, author one from JSON in the deploy drawer, or import one from a community repository.

## Action Buttons

<details>

<summary>Deploy SIT</summary>

Opens a drawer that creates a Sensitive Information Type in one or more tenants from a template or from parameters you supply yourself.

| Field | Description |
| ----- | ----------- |
| Select Tenants | The tenants to create the type in. At least one is required, and you can pick several to deploy the same type across a group of customers in one go. |
| Select a template (optional) | Picks a saved Sensitive Information Type template. Choosing one fills **Parameters (JSON)** with that template's stored settings, which you can then edit before deploying. |
| Parameters (JSON) | The type's settings as JSON. Required. Two worked examples are shown in the field until you type into it: a simple form giving a name, description, regular expression, confidence level and proximity, where the rule pack is built for you, and an advanced form where you supply your own rule pack XML as base64. |

</details>

<details>

<summary>Browse Catalog</summary>

Opens a drawer listing the Sensitive Information Type templates published in the community repositories you have configured, so you can bring one into CIPP.

| Field | Description |
| ----- | ----------- |
| Search Templates | Narrows the list by template name, category or repository. |
| Repository | Restricts the list to chosen repositories. Shown once you have more than one repository configured. |
| Category | Restricts the list to chosen categories. Shown once the available templates span more than one category. |
| Card and list view | Switches between template cards and a compact list. |
| All, Not Imported, Imported, Updates | Filters by import state. **Updates** narrows to templates you already imported that have since changed upstream. |
| Select all | Selects every template currently listed, for importing in one go. |
| Force re-import | Imports a template again even when CIPP already holds it, overwriting the copy you have. |
| Import Selected | Imports everything you have ticked. |

Each template also carries its own **Preview** and **Import** buttons, and is chipped **Imported** or **Update Available** so you can see its state at a glance.

{% hint style="info" %}
Be sure to check out [community-repos](../../tools/community-repos/ "mention") for more on setting up repositories.
{% endhint %}

</details>

## Table Details

| Column | Description |
| ----------- | ------------------------------------------------------------------------------------------------------- |
| Name        | The template name, taken from the type it was captured from or the name in the JSON it was authored with. |
| Comments    | The description saved with the template.                                                                 |
| Description | The description the type will be created with in the tenant.                                             |
| GUID        | CIPP's identifier for the template. Quote it when raising a support request about a specific template.    |

The Extended Info flyout tells you which of the two kinds of template you are looking at, and shows what it will actually detect. A simple template shows the pattern, confidence and proximity it was authored with, and has its rule pack built at deploy time. An advanced template carries a captured rule pack, and the flyout decodes it to show both a readable detection configuration and the rule pack XML that will be deployed.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Save to GitHub</td><td>Publishes the selected template to a repository you have write access to, prompting for the repository and a commit message. Greyed out unless the GitHub integration is enabled.</td><td>true</td></tr><tr><td>Delete Template</td><td>Removes the selected template from CIPP. Types already deployed from it are unaffected.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
