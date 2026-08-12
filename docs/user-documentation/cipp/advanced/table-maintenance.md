# Table Maintenance

Table Maintenance provides direct read and write access to the Azure Storage tables underneath your CIPP instance. It exists so that support can inspect or correct stored data that has no dedicated interface elsewhere in CIPP, and it operates on the raw storage layer with no validation of what the application expects to find there.

{% hint style="danger" %}
This is advanced functionality that should only be used when directed by CyberDrain support. Changes made here bypass every safeguard in CIPP, take effect immediately, and cannot be undone. Deleting the wrong row or table can break tenant access, scheduled tasks, or your instance's configuration.
{% endhint %}

## Selecting a Table

The panel on the left lists every table in the storage account. Select a table name to load its contents.

| Control        | Description                                                                                        |
| -------------- | -------------------------------------------------------------------------------------------------- |
| Search box     | Filters the table list as you type. Matching is case-insensitive and matches anywhere in the name. |
| Add Table      | Creates a new empty table. You are prompted for a **Table Name**.                                  |
| Refresh Tables | Reloads the list of tables from the storage account.                                               |

## Table Filters

Once a table is selected, the **Table Filters** section controls what is retrieved. Selecting **Apply Filters** re-runs the query and collapses the section.

| Field        | Description                                                                                                                                                                            |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OData Filter | An OData filter expression applied server side, for example `PartitionKey eq 'License'`. Leave empty to return everything within the row limit.                                        |
| Property     | The properties to return. Restricting this reduces the amount of data retrieved on wide tables. `PartitionKey`, `RowKey` and `ETag` are always included regardless of what you select. |
| First        | The maximum number of rows to return. Defaults to 1000.                                                                                                                                |
| Skip         | The number of rows to skip before returning results, which allows you to page through a large table alongside **First**.                                                               |

{% hint style="warning" %}
Without an OData filter, Azure Table Storage performs a full table scan. On large tables such as the log table this is slow and expensive, so filter on `PartitionKey` wherever you can.
{% endhint %}

## Table Contents

The selected table's rows are shown on the right. Columns are derived from the data itself, so they vary from table to table, and the properties present may differ between rows within the same table.

| Button       | Description                                                                                                            |
| ------------ | ---------------------------------------------------------------------------------------------------------------------- |
| Add Row      | Opens the row editor pre-populated with the property names found in the current table, ready for you to supply values. |
| Delete Table | Deletes the entire table and everything in it, after a confirmation prompt.                                            |

{% hint style="danger" %}
Deleting a table removes every row it contains and cannot be undone. CIPP recreates some tables automatically with default contents, but any data you have accumulated in them is lost.
{% endhint %}

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Edit</td><td>Opens the row editor populated with the selected row's current properties and values.</td><td>false</td></tr><tr><td>Delete</td><td>Deletes the selected rows. Confirmation is required and the action cannot be undone.</td><td>true</td></tr></tbody></table>

## Adding and Editing Rows

Both **Add Row** and the **Edit** action open the same editor. Each property is a row in the dialog with three parts.

| Field | Description                                                                                                                                                     |
| ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Name  | The property name as stored in the table.                                                                                                                       |
| Type  | How the value is stored: Text, Number or Boolean. Choose the type the application expects, since a value stored under the wrong type may not be read correctly. |
| Value | The value itself. The input changes to match the selected type.                                                                                                 |

**Add Property** appends a further property, and the minus icon beside a property removes it. **Save** writes the row and **Cancel** discards the changes.

{% hint style="warning" %}
Saving writes the row using its `PartitionKey` and `RowKey`, replacing any existing row with the same pair. Editing one of those two values therefore creates a new row rather than renaming the existing one, leaving the original in place.
{% endhint %}

{% hint style="info" %}
The `ETag` and `Timestamp` properties are managed by Azure Storage and are deliberately excluded from the editor. They cannot be set by hand.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}
