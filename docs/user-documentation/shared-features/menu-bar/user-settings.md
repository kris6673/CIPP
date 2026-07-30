# User Preferences

The Preferences page holds the interface settings that control how CIPP looks and behaves for you, along with defaults used elsewhere in the application. Every setting on this page can be saved either for your own account or for all users of the instance, chosen from the Actions card before saving. Where a setting is saved for all users, an individual user's own preference takes precedence over it.

## General Settings

| Setting                                   | Description                                                                                                                                                                                                  |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Default usage location for users          | The country pre-selected as the usage location when creating a new user. Required.                                                                                                                           |
| Default Page Size                         | How many rows tables show per page by default, chosen from 25, 50, 100, or 250. Required.                                                                                                                    |
| Default test suite on the Home page       | The test suite whose results are shown on the Home page by default, chosen from your saved test reports.                                                                                                     |
| Added Attributes when creating a new user | Additional user attributes to make available on the new user form, such as employee ID, hire date, employee type, or office location. Anything selected here appears as an extra field when creating a user. |
| Save last used table filter               | When enabled, the filter you last applied to a table is remembered and re-applied the next time you open it.                                                                                                 |

## Navigation Settings

| Setting                | Description                                                           |
| ---------------------- | --------------------------------------------------------------------- |
| Show Sidebar Bookmarks | Shows your bookmarked pages in the sidebar.                           |
| Show Popover Bookmarks | Shows your bookmarked pages in a popover.                             |
| Bookmark Reorder Mode  | How bookmarks are reordered: with Arrow Buttons, or by Drag and Drop. |
| Compact Navigation     | Reduces the size of the navigation menu so more of it fits on screen. |

## Offboarding Default Settings

Sets which offboarding options are pre-selected when you offboard a user, so that routine offboardings do not have to be configured each time. These are defaults only and can still be changed for an individual offboarding.

A label on the card indicates which defaults are currently in effect — your own user defaults, the all-users defaults, defaults set for the tenant, or CIPP's built-in defaults where none have been saved.

| Setting                                       | Description                                                            |
| --------------------------------------------- | ---------------------------------------------------------------------- |
| Convert to Shared Mailbox                     | Converts the user's mailbox to a shared mailbox.                       |
| Remove from all groups                        | Removes the user from every group they belong to.                      |
| Hide from Global Address List                 | Hides the user's mailbox from the address list.                        |
| Remove Licenses                               | Removes all licences assigned to the user.                             |
| Cancel all calendar invites                   | Cancels the meetings the user has organised.                           |
| Revoke all sessions                           | Signs the user out of all active sessions.                             |
| Remove users mailbox permissions              | Removes the permissions the user holds on other mailboxes.             |
| Remove users calendar permissions             | Removes the permissions the user holds on other calendars.             |
| Remove all Rules                              | Removes the inbox rules on the user's mailbox.                         |
| Reset Password                                | Resets the user's password.                                            |
| Keep copy of forwarded mail in source mailbox | Where mail is being forwarded, retains a copy in the original mailbox. |
| Delete user                                   | Deletes the user account.                                              |
| Remove all Mobile Devices                     | Removes the user's registered mobile devices.                          |
| Disable Sign in                               | Blocks the user from signing in.                                       |
| Remove all MFA Devices                        | Removes the user's registered multi-factor authentication methods.     |
| Remove Teams Phone DID                        | Removes the phone number assigned to the user in Teams.                |
| Clear Immutable ID                            | Clears the user's immutable ID.                                        |
| Disable OneDrive Sharing Links                | Disables the sharing links the user created in OneDrive.               |

A **Send results to** section chooses where the outcome of an offboarding is reported, with options for Webhook, E-mail, and PSA.

## Portal Links Configuration

Chooses which Microsoft portal shortcuts appear in CIPP. All are enabled by default; switch off any you do not use to shorten the list.

The available portals are M365, Exchange, Entra, Teams, Azure, Intune, SharePoint, Security, Purview, Power Platform, and Power BI.

## Developer Options

Diagnostic options intended for troubleshooting and development. Both are specific to you and are stored in the browser you are using, so they do not follow you to another device and are not saved with the rest of the page.

| Option               | Description                                                                                                                                         |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| TanStack Query Tools | Enables or disables the query developer tools, used for inspecting how data is fetched and cached.                                                  |
| Advanced Views       | Enables or disables advanced views, which reveal diagnostic pages that are otherwise hidden from day-to-day use, such as audit-log Search Coverage. |

## CIPP Roles

A read-only card lists the CIPP roles held by the account you are signed in as, so you can confirm what your access allows. Roles cannot be changed here.

## Saving Your Preferences

The Actions card controls who your changes apply to and commits them.

| Control       | Description                                                                                                                                                                     |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| User selector | Chooses whether the settings are saved for Current User or for All Users. Selecting a different option reloads the page's values to show the settings that apply to that scope. |
| Save Changes  | Saves the settings for the selected scope. The button is unavailable until any required fields are filled in, and a message confirms the save or reports an error.              |

***

### Feature Requests / Ideas

We value your feedback and ideas. Please raise any [feature requests](https://github.com/KelvinTegelaar/CIPP/issues/new?assignees=\&labels=enhancement%2Cno-priority\&projects=\&template=feature.yml\&title=%5BFeature+Request%5D%3A+) on GitHub.
