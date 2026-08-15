# Schema Extensions

[Schema extensions](https://learn.microsoft.com/en-us/graph/extensibility-overview?tabs=http#schema-extensions) allow you to add custom properties to Microsoft Entra directory objects. Unlike directory extensions, a schema extension groups several related properties under one named schema, which is useful when you want a coherent set of attributes rather than scattered individual ones.

* Schema extensions can only be Deprecated once they are set to Available.
* Properties cannot be deleted once they are created.
* There is a limit of 100 extension values per resource instance (directory objects only).
* There is a limit of 5 total schema extensions.

## Action Buttons

{% content-ref url="add.md" %}
[add.md](add.md)
{% endcontent-ref %}

## Table Details

| Column       | Description                                                                                                                          |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| ID           | The full schema identifier, including the prefix Microsoft Graph generates when the schema is first created.                         |
| Status       | The lifecycle state of the schema: In Development, Available, or Deprecated. The status can only move forward through that sequence. |
| Description  | The description recorded for the schema.                                                                                             |
| Target Types | The directory object types the schema can be applied to.                                                                             |
| Properties   | The properties defined on the schema, each with its name and data type.                                                              |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Add Property</td><td>Opens a dialog to add a property name and data type to the schema. Available for schemas that are not Deprecated. Properties cannot be removed once added.</td><td>false</td></tr><tr><td>Set to Available</td><td>Promotes the schema so it can be used in production. Available for schemas that are In Development. Once Available, the schema and its properties can no longer be deleted.</td><td>true</td></tr><tr><td>Set to Deprecated</td><td>Retires the schema so it can no longer be used for new values. Available for schemas that are Available. This is permanent and cannot be undone.</td><td>true</td></tr><tr><td>Delete Schema</td><td>Removes the schema from Microsoft Graph and from CIPP after confirmation. Only available while the schema is In Development.</td><td>true</td></tr></tbody></table>

{% hint style="warning" %}
Plan your properties while the schema is still In Development. That is the only point at which the schema can be deleted and started again. After you set it to Available, both the schema and every property on it are permanent.
{% endhint %}

{% hint style="info" %}
CIPP maintains its own schema, `cippUser`, which stores JIT administrator state, mailbox type, archive settings, and per-user MFA state on the user object. It counts towards the limit of five schema extensions and should be left in place.
{% endhint %}

{% include "../../../../../.gitbook/includes/feature-request.md" %}
