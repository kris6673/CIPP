# Business Voice

The Business Voice page gives an overview of all the numbers on the selected tenant. Detailed information includes who they're assigned to, the number itself, its emergency location, activation state, date purchased, and a number of other fields.

## Table Details <a href="#businessvoice-details" id="businessvoice-details"></a>

| Field                             | Description                                                                                                                                |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Assigned To - User Principal Name | The user principal name of the user or resource account the number is assigned to.                                                         |
| Phone Number                      | The phone number.                                                                                                                          |
| Assignment Status                 | Whether the number is currently assigned to a user or resource account, or unassigned.                                                     |
| Number Type                       | The type of phone number, such as Calling Plan, Direct Routing, or Operator Connect.                                                       |
| Emergency Location                | The emergency location associated with the number, shown as its description, place name, or street address. Blank when no location is set. |
| Acquired Capabilities             | What the number can be assigned to, such as a user, a conference bridge, or a voice application.                                           |
| Country Code                      | The country of the phone number.                                                                                                           |
| Place Name                        | The location of the phone number.                                                                                                          |
| Activation State                  | The activation state of the phone number.                                                                                                  |
| Operator Connect                  | A Boolean field indicating whether the phone number is an operator connect number.                                                         |
| Acquisition Date                  | The purchased date and time of the number.                                                                                                 |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Assign User</td><td>Opens a modal to assign a user or resource account to the phone number. The assignment is submitted for processing and may take a moment to complete; re-sync the report to see the updated status.</td><td>true</td></tr><tr><td>Unassign User</td><td>Opens a modal to remove the assignment from the phone number. The change is submitted for processing and may take a moment to complete; re-sync the report to see the updated status.</td><td>true</td></tr><tr><td>Set Emergency Location</td><td>Opens a modal to set the emergency location for the number. Locations are listed by description, place name, or street address.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
