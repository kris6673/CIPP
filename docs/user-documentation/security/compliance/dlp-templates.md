# DLP Policy Templates

DLP policy templates are saved DLP configurations held in CIPP rather than in a tenant, so a policy you have settled on can be deployed to any number of customers without rebuilding it each time. Templates get here in three ways: capture one from a live policy with **Create template based on policy** on the DLP Policies page, author one from JSON in the deploy drawer, or import one from a community repository.

## Action Buttons

<details>

<summary>Deploy DLP Policy</summary>

Opens a drawer that creates a DLP policy in one or more tenants from a template or from parameters you supply yourself.

| Field | Description |
| ----- | ----------- |
| Select Tenants | The tenants to create the policy in. At least one is required, and you can pick several to deploy the same policy across a group of customers in one go. |
| Select a template (optional) | Picks a saved DLP policy template. Choosing one fills **Parameters (JSON)** with that template's stored settings, which you can then edit before deploying. |
| Parameters (JSON) | The policy settings as JSON. Required. A worked example is shown in the field until you type into it, covering the policy name, mode, workload locations and a nested `RuleParams` block for the rule created alongside the policy. |

</details>

<details>

<summary>Browse Catalog</summary>

Opens a drawer listing the DLP policy templates published in the community repositories you have configured, so you can bring one into CIPP.

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
| -------- | -------------------------------------------------------------------------------------------------------- |
| Name     | The template name, taken from the policy it was captured from or the name in the JSON it was authored with. |
| Comments | The description saved with the template.                                                                  |
| Mode     | The enforcement mode the policy will be created in.                                                        |
| Workload | The Microsoft 365 workloads the policy will cover.                                                         |
| Enabled  | Whether the policy will be created switched on.                                                            |
| GUID     | CIPP's identifier for the template. Quote it when raising a support request about a specific template.      |

{% hint style="info" %}
A DLP policy that is pending deletion cannot be saved as a template, because the snapshot would not be deployable. Capturing one is rejected with an explanatory message rather than storing a broken template.
{% endhint %}

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Save to GitHub</td><td>Publishes the selected template to a repository you have write access to, prompting for the repository and a commit message. Greyed out unless the GitHub integration is enabled.</td><td>true</td></tr><tr><td>Delete Template</td><td>Removes the selected template from CIPP. Policies already deployed from it are unaffected.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
