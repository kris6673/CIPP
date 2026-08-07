# Exchange Cmdlets

This page lists the Exchange Online cmdlets CIPP is able to call for a given tenant, based on the permissions CIPP holds there. It also lets you look up which Exchange management roles grant access to a particular cmdlet, which is useful when working out why a CIPP feature cannot retrieve something.

{% hint style="info" %}
This is a diagnostic view rather than a console. It will not let you run every cmdlet through CIPP, but it is useful information when troubleshooting problems accessing information within CIPP.
{% endhint %}

## Cmdlet Search

| Field           | Description                                                                                                                                                                                                                                    |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Select a tenant | The tenant to query. Cmdlet availability varies between tenants depending on licensing and configuration, so results are specific to whichever tenant you choose.                                                                              |
| Compliance      | Queries the Security and Compliance PowerShell endpoint instead of Exchange Online, returning the cmdlets available there. Use this when investigating Purview and compliance features.                                                        |
| As App          | Connects using CIPP's application permissions rather than the delegated permissions of the service account. The two contexts can return different cmdlet sets, and comparing them is often the quickest way to identify a permissions problem. |

Selecting **Search** runs the query and populates the table below.

{% hint style="info" %}
If a cmdlet CIPP needs is missing, run the search again with **As App** toggled the other way before concluding it is a permissions problem. A cmdlet available in one context and not the other points at where the gap actually is.
{% endhint %}

## Table Details

| Column | Description                                                                                 |
| ------ | ------------------------------------------------------------------------------------------- |
| Cmdlet | The name of an Exchange cmdlet CIPP can call for the selected tenant in the chosen context. |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Check Roles</td><td>Looks up the Exchange management roles that permit the selected cmdlet, and shows them in a flyout titled Permitted Roles.</td><td>true</td></tr></tbody></table>

## Permitted Roles

The **Check Roles** action opens a dialog listing every management role that includes the chosen cmdlet.

| Column      | Description                                                                                          |
| ----------- | ---------------------------------------------------------------------------------------------------- |
| Error       | Populated only where the lookup failed, with the reason. An empty column means the lookup succeeded. |
| Name        | The name of the Exchange management role.                                                            |
| Description | What that role covers.                                                                               |

This is the practical answer to "which role does CIPP need in order to call this". Where a cmdlet CIPP relies on is unavailable, the roles listed here are what needs granting to the service account or the application, depending on which context you searched in.

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
