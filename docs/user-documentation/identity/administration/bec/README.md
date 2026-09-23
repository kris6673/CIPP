---
description: Every Business Email Compromise run, for every user and every tenant, in one place.
---

# Business Email Compromise

The Business Email Compromise page lists every [Compromise Remediation](case.md) run CIPP has kept, for every user in the selected tenant, or across all tenants when **All Tenants** is selected. Each run is a case. Use this page to start investigations, to go back to one after the fact, to pull the report or the evidence package for a run completed weeks ago, or to see which queued runs have finished.

Runs are never expired automatically. A run stays, with its results, until it is deleted here or from the user's run history.

## Starting an Investigation

Select **Start investigation** and pick the users to investigate.

* **One user** opens that user's case page and starts the run there, so you can watch it progress.
* **Several users** queues one run per user, as a single job tracked on the Queue page. The runs appear in the table as they finish.

Runs can also be queued with **Run BEC investigation** on the [Users](../users/README.md) page, or started by an alert.

## Views

The toggle next to **Start investigation** switches between two views of the same runs.

| View     | Description                                                                                                                                                                                                  |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| All runs | One row per run.                                                                                                                                                                                             |
| By user  | One row per user, sorted with the most serious first. **Level** is the worst level of any of the user's runs; the score, status and date come from the latest run. **View runs** lists every run for that user. |

## Columns

| Column            | Description                                                                                                                                       |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Tenant            | The tenant the run belongs to.                                                                                                                    |
| UserPrincipalName | The investigated user.                                                                                                                            |
| Level             | The threat level the server assigned: High, Medium or Low. Empty while the run is waiting or when it failed.                                      |
| RunCount          | **By user** only. How many runs the user has.                                                                                                     |
| Score             | The threat score behind the level. The breakdown is on the run itself.                                                                            |
| Status            | **Waiting** while queued or running, **Completed**, or **Error** with the reason in the details panel.                                            |
| ExtractedAt       | When the data was collected.                                                                                                                      |
| RequestedBy       | **All runs** only. Who queued the run, or the alert engine when an alert started it.                                                              |
| ContainmentRuns   | **All runs** only. How many times containment was run against the case.                                                                           |
| CaseId            | **All runs** only. The case id. It appears on every logbook line the run, its containment and its exports produced, so the Logbook can be filtered to a single case. |

The details panel also shows the user's display name, when the run was requested, the error message for a failed run and, in **All runs**, **IncompleteCount**: the number of data sources that did not collect in full, for example because a licence was missing or a cap was reached. The case page shows which ones.

The **High threat level** and **Completed runs** filters work in both views. In **By user**, **High threat level** finds every user with at least one High run.

## Actions

In **All runs**, and on each row under **View runs**:

| Action                             | Description                                                                                                                                                                                  |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Open case                          | Opens the run on the [Compromise Remediation](case.md) page, exactly as it was collected. A queued or running case shows its live progress, and a failed one its error. From there the PDF report, the JSON and the evidence package can be produced, and containment run, for that case. |
| Download evidence (ZIP, with PDFs) | Renders both report PDFs in the browser, builds a fresh evidence package from the stored run around them and downloads it, without opening the case. Only offered for completed runs.      |
| Delete run                         | Removes the run, its results and its evidence package permanently. The logbook entries stamped with the case id are not removed.                                                             |

In **By user**:

| Action                                    | Description                                                                              |
| ----------------------------------------- | ---------------------------------------------------------------------------------------- |
| View runs                                 | Lists every run for the user, newest first, each with the actions above.                 |
| Open latest case                          | Opens the user's latest run on the [Compromise Remediation](case.md) page.               |
| Download latest evidence (ZIP, with PDFs) | Downloads the evidence package for the user's latest run. Only offered when it completed. |

{% hint style="info" %}
Everything a run holds is metadata: audit records, sign-ins, directory audits, message-trace headers, permissions, consents, rules and devices. No message body, attachment or file content is collected, stored or exported.
{% endhint %}
