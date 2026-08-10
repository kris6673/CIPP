# Vulnerabilities

Software vulnerabilities found by Microsoft Defender across the selected tenant's onboarded devices, grouped so that each CVE appears once with a count of the devices it affects rather than once per device. Use it to see which vulnerabilities are worth chasing in a tenant and how far each one has spread.

## Table Details

| Column | Description |
| ---------------------------- | ------------------------------------------------------------------------------------------------------ |
| Affected Devices Count       | How many device findings were rolled up into this CVE. Counted by CIPP when the findings are grouped.     |
| Affected Devices             | The devices the CVE was found on. Expand the cell to see the full list.                                  |
| Os Platform                  | The operating system platform the finding was reported against.                                          |
| Software Vendor              | The vendor of the vulnerable software.                                                                   |
| Software Name                | The vulnerable software.                                                                                 |
| Vulnerability Severity Level | Microsoft's severity rating for the vulnerability.                                                       |
| Cvss Score                   | The CVSS score for the vulnerability.                                                                    |
| Security Update Available    | Whether a security update that addresses the vulnerability is available.                                  |
| Exploitability Level         | Microsoft's assessment of how exploitable the vulnerability is.                                          |
| Cve Id                       | The CVE identifier, and the value the findings are grouped on.                                            |

{% hint style="warning" %}
Only **Affected Devices Count** and **Affected Devices** reflect every device behind a row. The remaining columns are taken from a single one of the grouped findings, so where a CVE spans more than one platform, vendor or software version, this table shows one of them rather than all of them. Treat those columns as an example of what the CVE was found on, not a complete picture.
{% endhint %}

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
