# Copilot User Activity

The Copilot User Activity report is the per-person view of Copilot usage in the selected tenant, with one row for each user. It shows when someone last used Copilot and which apps they've been active in (Copilot Chat, Teams, Word, Excel, PowerPoint, Outlook, OneNote, and Loop), so you can see individual adoption and identify who is or isn't actually using Copilot.

The figures come from the Microsoft 365 Copilot usage reports in Microsoft Graph and cover the last 30 days. Each per-app column holds the date of the user's most recent Copilot activity in that app, and stays empty when they have never used Copilot there.

## Table Details

| Column              | Description                                                                                                                                        |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| User Principal Name | The user's sign-in address, identifying whose Copilot activity the row represents.                                                                 |
| Display Name        | The user's friendly name for easier identification.                                                                                                |
| Last Activity Date  | The most recent date this person used Copilot in any app, giving a quick way to spot active users versus those who've gone quiet or never started. |
| Copilot Chat        | Whether/when the user has been active with Copilot Chat.                                                                                           |
| Teams               | Whether/when the user has been active with Copilot in Microsoft Teams.                                                                             |
| Word                | Whether/when the user has been active with Copilot in Word.                                                                                        |
| Excel               | Whether/when the user has been active with Copilot in Excel.                                                                                       |
| PowerPoint          | Whether/when the user has been active with Copilot in PowerPoint.                                                                                  |
| Outlook             | Whether/when the user has been active with Copilot in Outlook.                                                                                     |
| OneNote             | Whether/when the user has been active with Copilot in OneNote.                                                                                     |
| Loop                | Whether/when the user has been active with Copilot in Loop.                                                                                        |

## Anonymised Reports

Microsoft 365 has a tenant-wide setting that conceals user names in usage reports, replacing them with hashes rather than user principal names. Where CIPP detects that this report has come back anonymised, it shows a warning above the results.

The fix is on the tenant, not in CIPP. Enabling the **Enable Usernames instead of pseudo anonymised names in reports** standard turns the setting off, after which the report needs running again to pick up real names.

{% include "../../../../.gitbook/includes/feature-request.md" %}
