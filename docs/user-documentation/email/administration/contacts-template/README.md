# Contact Templates

Contact templates hold the details of a mail contact so the same contact can be created in many tenants without retyping it. Templates are not tied to a tenant. They are applied either from the **Deploy Contact Template** drawer or through the **Deploy Mail Contact Template** standard.

{% hint style="success" %}
Contact templates can be deployed via Standards to streamline the addition of basic contact information for all of your clients, for example you want to deploy helpdesk@mymsp.com to all of your clients to make it easier for them to have the correct email for your support. Use the standard "Deploy Mail Contact Template".
{% endhint %}

## Action Buttons

<details>

<summary>Deploy Contact Template</summary>

Opens a drawer that creates mail contacts from one or more saved templates across one or more tenants. The same drawer is available from [README.md](../contacts/README.md "mention").

| Field             | Description                                                                                                                         |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Select Tenants    | The tenants the contacts are created in. More than one can be chosen, and the tenant you are currently on is preselected. Required. |
| Select a template | The templates to deploy. More than one can be chosen, and every selected template is created in every selected tenant. Required.    |

**Deploy Templates** submits the form. Once a deployment has run the button changes to **Deploy Another** and the selections clear, so a second batch can be sent without reopening the drawer.

If a mail contact with the same external email address already exists in a tenant, the template is skipped for that tenant and the results panel says so, so re-running a deployment does not create duplicates.

{% hint style="warning" %}
A contact that already exists is skipped, not updated. Changing a template and deploying it again does not correct contacts that were created from the earlier version.
{% endhint %}

</details>

{% content-ref url="add.md" %}
[add.md](add.md)
{% endcontent-ref %}

## Table Details

| Column       | Description                                                                                                                 |
| ------------ | --------------------------------------------------------------------------------------------------------------------------- |
| Display Name | The name the contact is created with. This is also the name the template is listed under when you select it for deployment. |
| Email        | The external address the contact routes to.                                                                                 |
| Company Name | The company recorded on the contact.                                                                                        |
| Job Title    | The job title recorded on the contact.                                                                                      |
| Hidefrom GAL | Whether the contact is hidden from the Global Address List when it is created.                                              |
| GUID         | The identifier CIPP stores the template under. Standards reference the template by this value.                              |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Save to GitHub</td><td>Saves the selected template(s) to a GitHub repository you have write access to, under a commit message you supply. Greyed out unless the GitHub integration is enabled.</td><td>true</td></tr><tr><td>Delete Template</td><td>Deletes the selected contact template(s). Contacts already created from the template are left in place in their tenants.</td><td>true</td></tr><tr><td>Edit Contact Template</td><td>Opens the <a data-mention href="edit.md">edit.md</a> page to allow you to adjust the template settings.</td><td>false</td></tr></tbody></table>

{% include "../../../../../.gitbook/includes/feature-request.md" %}
