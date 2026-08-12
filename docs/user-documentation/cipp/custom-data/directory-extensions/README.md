# Directory Extensions

[Directory extensions](https://learn.microsoft.com/en-us/graph/extensibility-overview?tabs=http#directory-microsoft-entra-id-extensions) allow you to add custom properties to Microsoft Entra directory objects. Each extension is a single standalone property registered against the CIPP application registration, which makes it available in every tenant CIPP is consented to.

* Directory extensions must have unique names.
* There is a limit of 100 extension values per resource instance.
* [Considerations for using directory extensions](https://learn.microsoft.com/en-us/graph/extensibility-overview?tabs=http#considerations-for-using-directory-extensions)

## Action Buttons

{% content-ref url="add.md" %}
[add.md](add.md)
{% endcontent-ref %}

## Table Details

| Column          | Description                                                                                                                                                             |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Name            | The fully qualified extension name, in the form `extension_<applicationId>_<yourName>`. This is the property name used when reading or writing the value through Graph. |
| Data Type       | The type of value the extension stores.                                                                                                                                 |
| Is Multi Valued | Whether the extension holds a collection of values rather than a single value.                                                                                          |
| Target Objects  | The directory object types the extension can be set on.                                                                                                                 |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Delete Directory Extension</td><td>Removes the extension from the CIPP application registration after confirmation. Values already written to directory objects are no longer readable through the extension.</td><td>true</td></tr></tbody></table>

{% hint style="danger" %}
Deleting a directory extension is permanent and affects every tenant, not just the one you are currently viewing. Check for mappings that reference the extension before removing it.
{% endhint %}

{% include "../../../../../.gitbook/includes/feature-request.md" %}
