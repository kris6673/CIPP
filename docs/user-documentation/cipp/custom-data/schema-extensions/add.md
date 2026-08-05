# Add Schema Extension

Create a new schema extension and define the properties it contains. At least one property is required before the schema can be saved.

## Schema Details

| Field        | Description                                                                                                                                                                                                            |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Schema ID    | A short identifier for the schema, for example `cippUser`. Microsoft Graph generates and prepends a prefix after creation, so the final identifier is longer than the value entered.                                   |
| Description  | A description of what the schema is for. This is shown on the Schema Extensions table.                                                                                                                                 |
| Status       | The initial lifecycle state. In Development allows the schema to be deleted and reworked. Available makes the schema and its properties permanent.                                                                     |
| Target Types | The directory object types the schema applies to. Choose one or more of User, Group, Administrative Unit, Contact, Device, Event (User and Group Calendars), Message, Organization, or Post. At least one is required. |

## Properties

Use **Add Property** to add a row, and the remove icon to take one away before saving. Each property needs both a name and a type.

| Field         | Description                                                                                                                                                             |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Property Name | The name of the property within the schema. Referenced elsewhere in CIPP as `<schemaId>.<propertyName>`.                                                                |
| Property Type | The type of value the property stores. Choose from Binary (256 bytes maximum), Boolean, DateTime (ISO 8601, UTC), Integer (32-bit), or String (256 characters maximum). |

{% hint style="danger" %}
Properties cannot be deleted once the schema is created, regardless of status. Removing a row here only works before you save.
{% endhint %}

{% hint style="info" %}
Schema extension properties are always single-valued. If you need to store a collection, use a multi-valued directory extension instead.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
