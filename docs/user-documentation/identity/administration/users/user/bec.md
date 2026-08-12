---
description: Single pane of glass review of common Indicators of Compromise (IoC)
---

# Compromise Remediation

This page gathers the signals worth checking when a mailbox is suspected of being compromised, so an investigation does not mean opening the Entra, Exchange, and Purview portals in turn. Opening the page starts an analysis of the user, and each check appears as a collapsible card with a count of what it found. A count is a prompt to look, not a verdict.

{% hint style="warning" %}
Nothing on this page is proof of a compromise. The checks surface the information that usually matters during an investigation, and several of them return results on perfectly healthy accounts. Read the findings alongside what you already know about the user and the tenant.
{% endhint %}

## Running the Analysis

The analysis runs as a background job. The first visit queues it and the page polls until it finishes, which can take up to ten minutes on a tenant with a lot of log data. The result is then cached against the user, so returning to the page shows the earlier run rather than starting a new one.

The **Log information** card at the top of the checks reports whether the audit log extraction succeeded and when the data was pulled. It is the first thing to read, because the outcome shapes everything below it.

{% hint style="danger" %}
Most checks depend on the unified audit log. When it is disabled for the tenant, the Log information card says so and the checks that read from it come back empty rather than clean. An empty result in that state means nothing was available to search, not that nothing happened.
{% endhint %}

## Checks

Every check covers the seven days before the analysis ran, apart from the MFA device list, the Intune device list, and the trusted and blocked sender lists, which show the account's current state regardless of age, and the sign-in list, which is simply the last fifty sign-ins however old they are.

| Check                               | What it looks for                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Check 1: Mailbox Rules              | The inbox rules currently on the mailbox, and any rule created, changed, or removed in the last seven days. A rule that moves mail into an `RSS` folder raises a potential breach message, as it is a long-standing trick for hiding replies. Rules whose names match a recent audit event are marked as changed in the last seven days and sorted to the top. Each change lists the IP address it was made from and, where the IP can be located, the country.                    |
| Check 2: Recently added users       | Accounts created in the tenant during the window, listed with their creation date.                                                                                                                                                                                                                                                                                                                                                                                                 |
| Check 3: New Applications           | Service principals registered during the window, plus every application in the tenant, of any age, that matches CIPP's catalog of known-malicious applications. A catalog match is sorted to the top, named with its catalog entry, and raises a potential breach message, because consent-based access survives a password reset.                                                                                                                                                 |
| Check 4: Mailbox permission changes | Mailbox permission and delegation changes across the tenant, listed with who made the change, the operation, and the rights involved. Covers permissions being added or removed, calendar delegation updates, and folder permission grants. Changes that target the investigated mailbox are flagged and sorted to the top.                                                                                                                                                        |
| Check 5: Sent Messages              | Messages sent by the mailbox during the window, from the message trace, with the subject, recipient, delivery status, time received, the originating IP address, and the country that IP locates to. The check also looks for mass-mail patterns: a subject sent as five or more separate messages or reaching twenty or more recipients, and bursts of ten or more messages or thirty or more recipients inside ten minutes. Both are how a compromised mailbox spreads phishing. |
| Check 6: MFA Devices                | The authentication methods registered on the account, other than its password, listed with the method type, name, and registration date. Methods registered in the last seven days are flagged and sorted to the top, and an account with no methods at all is called out rather than shown as an empty list.                                                                                                                                                                      |
| Check 7: Password Changes           | Accounts across the tenant whose password changed during the window, listed with the change time.                                                                                                                                                                                                                                                                                                                                                                                  |
| Check 8: Trusted & Blocked Senders  | The mailbox's own trusted and blocked sender and domain lists, along with any changes to them in the last seven days. Each change lists the IP address it was made from and its country. If the lists cannot be read, the card says so in red instead of presenting an empty list as clean.                                                                                                                                                                                        |
| Check 9: Intune Devices             | Every Intune-managed device enrolled under the account, newest enrolment first. The card's count is the number enrolled in the last seven days rather than the total, so a zero here still leaves a device list worth reading. A device standing up during the window can mean an intruder enrolling a virtual machine or personal endpoint under the identity, which is also a route to registering Windows Hello for Business as a persistence mechanism.                        |
| Check 10: Sign-in Locations         | The user's last fifty sign-ins with the application, result, IP address, country, and city, compared against the account's assigned usage location. The card's count is the number of foreign data points found across sign-ins, rule changes, safelist changes, sharing changes, and sent mail. See [#location-analysis](bec.md#location-analysis "mention") below.                                                                                                               |
| Check 11: Sharing Links             | Every OneDrive and SharePoint sharing link the account created or changed during the window, with the file, who it was shared with, and the IP address it was done from. Anonymous links are called out separately, because anyone holding the URL can open them and they give an intruder a data feed that survives a password reset.                                                                                                                                             |

{% hint style="info" %}
Checks 2, 4, and 7 are tenant-wide rather than scoped to this user, and Check 3 sweeps the whole tenant for catalog matches. That is deliberate: an intruder who has taken one mailbox often leaves traces elsewhere, so a new account or an unfamiliar application appearing in the same window is worth knowing about even though it has nothing to do with the mailbox in front of you.
{% endhint %}

{% hint style="info" %}
Inbox rules carry no timestamp of their own, so a rule is marked as recently changed by matching its name against audit events from the last seven days. Rules changed from the Outlook client are recorded without a rule name, so a rule altered that way stays unmarked even though the change appears under the rule change entries.
{% endhint %}

### Location Analysis

Check 10 and the flags scattered through the other checks come from one comparison: the account's **usage location** (the two-letter country code assigned in Entra ID, usually for licensing) held against where activity actually came from.

* Sign-ins carry their own location in the sign-in log, so those need no lookup.
* The client IPs behind inbox rule changes, safelist changes, sharing changes, and sent messages are geo-located through CIPP's GeoIP service, which caches results, so repeated runs do not repeat lookups.
* A row only counts as foreign when both sides are known. No assigned usage location, an IP that cannot be located, or a private address means the row is left unflagged, not counted against the user.
* Foreign sign-ins are split into successful and failed. Failed attempts from other countries are the constant background of password spray and are listed for context only; a successful foreign sign-in is the one that proves access and feeds the threat score.

When the account has no usage location assigned, the card says the comparison is unavailable and still lists the countries seen, for manual review.

{% hint style="warning" %}
Usage location is an administrative setting, not a statement of where the user works. Travel, VPN egress points, and mobile carrier routing all produce foreign rows on healthy accounts, and a usage location that was never set correctly produces them permanently. A foreign sign-in is a prompt to check with the user; a rule or safelist change from a foreign IP is much harder to explain innocently.
{% endhint %}

### Intune Device Actions

Each row in Check 9 carries its own actions, so a suspect device can be dealt with without leaving the investigation.

| Action                          | Description                                                                             |
| ------------------------------- | --------------------------------------------------------------------------------------- |
| View Device                     | Opens the device's page within CIPP.                                                    |
| View in Intune                  | Opens the device in the Microsoft Intune admin center in a new tab.                     |
| Retire device                   | Removes company data and the Intune management profile, leaving personal data in place. |
| Wipe device (remove enrollment) | Returns the device to factory settings, removing all data and the Intune enrolment.     |

{% hint style="danger" %}
**Wipe device (remove enrollment)** is a full factory wipe, not the lighter wipe that keeps user or enrolment data. It cannot be undone, and it will take the device out of service for whoever is holding it. Confirm the device is genuinely the intruder's before running it.
{% endhint %}

**Retire device** and **Wipe device (remove enrollment)** both ask for confirmation first and need write permission for device management. Neither updates the list afterwards, so use **Refresh Data** to see the result.

{% hint style="warning" %}
If CIPP cannot read the tenant's Intune devices, the card says so in red and shows no count. That is not the same as the user having no devices, and it usually points at missing permissions or licensing rather than a clean result. Fix the underlying problem and refresh rather than reading the empty card as an all-clear. The sign-in and sender-list checks behave the same way when their sources cannot be read.
{% endhint %}

## Actions

| Action              | Description                                                                                                                                                                                                                                                                                                       |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Refresh Data        | Discards the cached result and runs the analysis again. Use it when the cached data predates something you need to see, such as a rule created in the last few minutes or a device you have just retired. The page returns to its waiting state while the new run completes.                                      |
| Remediate User      | Runs the containment steps listed on the overview card in one go: blocks sign-in, resets the password, disconnects all current sessions, removes every MFA method, disables all inbox rules, and disables OneDrive sharing. A confirmation dialog appears first.                                                  |
| Generate PDF Report | Opens a preview of a formatted report covering the findings, written to be readable by managers and end users as well as technicians, and suitable for attaching to a compliance record. **Download PDF** saves it. What the report contains is covered under [#pdf-report](bec.md#pdf-report "mention") below. |
| Download JSON       | Saves the complete analysis as a JSON file, including data the cards do not display.                                                                                                                                                                                                                              |

{% hint style="warning" %}
Removing every MFA method leaves the account with no second factor registered. Once sign-in is unblocked and the password reset, the user has to register a method again, so plan how they will do that before running the remediation on someone who is not sitting next to you.
{% endhint %}

{% hint style="info" %}
**Remediate User** does not touch the user's devices or remove applications, and while it disables OneDrive sharing it does not review links that were already created. If Check 9 has turned up an enrolment you do not recognise, Check 3 a malicious application, or Check 11 a sharing link you cannot explain, dealing with those is a separate decision and a separate action.
{% endhint %}

{% hint style="info" %}
The JSON export carries three data sets that no card displays: the last fifty sign-ins for the tenant as a whole (`TenantLastSignIns`), the user's single most recent sign-in, and the mobile devices attached to the mailbox. If the investigation turns on tenant-wide sign-in activity or an unrecognised mobile device, that is where to look. The Intune device list in the export also holds the manufacturer, model, owner type, and assigned user, none of which the card shows.
{% endhint %}

## PDF Report

The report is built from the analysis already on screen, so it never starts a fresh run and always reflects the same cached result the cards are showing. Its cover names the user rather than the tenant, and the logo, cover image, colours, footer and watermark come from your instance branding, described in [branding.md](../../../../cipp/settings/branding.md "mention"). Its detailed findings use the same check numbers as the page, 1 through 11.

| Page                                    | What it contains                                                                                                                                                                                                                                                                       |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Executive Summary                       | A narrative introduction naming the user and the tenant, four headline counts (mailbox rules, permission changes, foreign sign-ins, known-malicious applications), the threat assessment, and the audit log status, analysis period, and assigned usage location.                      |
| Understanding Business Email Compromise | A plain-language explanation of what a compromise is, how accounts are usually taken, and why the investigation was run. Written for the user or their manager rather than the technician.                                                                                             |
| Detailed Findings                       | The page's checks 1 through 11 (rules, users, applications, permission changes, sent messages, authentication methods, password changes, trusted and blocked senders, Intune devices, sign-in locations, and sharing links), each under a short explanation of why that check matters. |
| Recommendations                         | Six immediate containment steps, six longer-term prevention measures, and five points to pass to the user.                                                                                                                                                                             |
| Compliance & Documentation              | How the investigation maps onto ISO 27001, CMMC Level 2, SOC 2 Type II, NIST CSF and GDPR, an audit trail block with the investigation details, a **Findings Summary** listing every count, and retention guidance.                                                                    |

### Threat Assessment

The **Threat Assessment** banner on the executive summary is a total of fixed points, one contribution per finding, regardless of how many results that finding returned.

| Finding                                                          | Points |
| ---------------------------------------------------------------- | ------ |
| A rule that moves mail to an RSS folder                          | 5      |
| An application matching the known-malicious catalog              | 5      |
| One or more inbox rules on the mailbox                           | 3      |
| One or more inbox rule changes in the window                     | 3      |
| A successful sign-in from outside the usage location             | 3      |
| A rule, safelist, sharing, or sent-mail action from a foreign IP | 3      |
| An anonymous sharing link created or changed in the window       | 3      |
| A mass-mail pattern (repeated subjects or send bursts)           | 3      |
| A permission change targeting the investigated mailbox           | 2      |
| One or more changes to the trusted or blocked senders list       | 2      |
| An MFA method registered in the window                           | 2      |
| An Intune device enrolled in the window                          | 2      |
| Permission changes elsewhere in the tenant only                  | 1      |
| One or more new applications                                     | 1      |
| More than five new users                                         | 1      |

Seven points or more reads as **High**, four to six as **Medium**, and anything below that as **Low**.

{% hint style="warning" %}
Scoring counts findings, not volume. A mailbox holding a single ordinary inbox rule already scores three, one point short of Medium, so a single unrelated finding tips it over. Forty rules score the same three points as one.
{% endhint %}

{% hint style="warning" %}
New users, new applications, and permission changes are tenant-wide checks, but each carries a single point unless a permission change targets the investigated mailbox. Tenant churn nudges the score rather than driving it. A wrongly-set usage location, on the other hand, can add three points through a perfectly normal successful sign-in, so check the assigned location before trusting a foreign-sign-in score.
{% endhint %}

{% hint style="danger" %}
Password changes carry no weight, and the MFA and Intune lists only score for registrations and enrolments inside the window; long-standing methods and devices do not move the banner however unfamiliar they look. Sent messages score only for a foreign-IP send or a mass-mail pattern. Failed sign-ins from foreign countries score nothing either: password spray hits every internet-facing tenant, so only a successful foreign sign-in counts, though the failures still show in Check 10. A Low is a summary of what scored, not an all-clear; read the checks.
{% endhint %}

### What the Report Leaves Out

Each section stops at a fixed number of rows and says how many were left off, so a truncated section is visible as truncated. The counts in **Findings Summary** on the last page always carry the full totals, and **Download JSON** has the complete set.

| Section                                    | Rows shown                |
| ------------------------------------------ | ------------------------- |
| Mailbox rules                              | 10                        |
| Rule changes                               | 10                        |
| Recently created users                     | 8                         |
| New applications                           | 6                         |
| Known-malicious applications in the tenant | 6                         |
| Mailbox permission changes                 | 5                         |
| Sent messages                              | 10                        |
| Repeated subjects                          | 5 (analysis keeps 10)     |
| Send bursts                                | 5 (analysis keeps 10)     |
| MFA devices                                | 5, newest first           |
| Password changes                           | 5                         |
| Trusted and blocked senders                | 15 of each                |
| Safelist changes                           | 10                        |
| Sharing changes                            | 10                        |
| Intune devices                             | 5, newest enrolment first |
| Foreign sign-ins                           | 10                        |

{% include "../../../../../../.gitbook/includes/feature-request.md" %}
