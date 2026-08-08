# MDE Onboarding

The state of the connector between Microsoft Defender for Endpoint and Intune, which is what lets Defender feed device risk into compliance and app protection. Use it to confirm the connector is actually live in a tenant before relying on any of the Defender driven policies built on top of it.

The page shows one of two views depending on your tenant selection. On a single tenant you get the connector's status in detail. On All Tenants you get a table comparing every tenant at once.

## Action Buttons

<details>

<summary>Sync</summary>

Queues a refresh of the onboarding status behind the page and tracks the job's progress. Available in both views.

</details>

## Single Tenant View

The connector's **Status** is shown as a chip at the top, along with the connector's last heartbeat and when CIPP last collected the data. Where the connector is not yet working, a **Start Onboarding** button takes you straight to the endpoint onboarding page in the Microsoft Defender portal for that tenant.

Below that, three cards break the connector's configuration down.

### Platform Support

| Field | Description |
| ------- | --------------------------------------------------------- |
| Windows | Whether the connector is enabled for Windows devices.      |
| iOS     | Whether the connector is enabled for iOS devices.          |
| Android | Whether the connector is enabled for Android devices.      |
| macOS   | Whether the connector is enabled for macOS devices.        |

### App Management & Attach

| Field | Description |
| ----------- | ----------------------------------------------------------------------------------- |
| iOS MAM     | Whether app protection policy evaluation is enabled for iOS.                          |
| Android MAM | Whether app protection policy evaluation is enabled for Android.                      |
| Windows MAM | Whether app protection policy evaluation is enabled for Windows.                       |
| MDE Attach  | Whether Defender for Endpoint is attached, allowing it to feed device risk into Intune. |

### Data Collection & Compliance

| Field | Description |
| ------------------------------------------ | ------------------------------------------------------------------------------- |
| Block iOS on missing partner data           | Whether iOS devices are blocked when Defender has not reported on them.          |
| Block Android on missing partner data       | Whether Android devices are blocked when Defender has not reported on them.      |
| Block Windows on missing partner data       | Whether Windows devices are blocked when Defender has not reported on them.      |
| Block macOS on missing partner data         | Whether macOS devices are blocked when Defender has not reported on them.        |
| Block unsupported OS versions               | Whether devices on unsupported OS versions are blocked.                          |
| Unresponsiveness threshold (days)           | How many days of silence before the connector treats a device as unresponsive.   |
| Collect iOS app metadata                    | Whether Defender may collect application inventory from iOS devices.             |
| Collect iOS personal app metadata           | Whether that collection extends to personally owned iOS devices.                 |
| Collect iOS certificate metadata            | Whether Defender may collect certificate inventory from iOS devices.             |
| Collect iOS personal certificate metadata   | Whether that collection extends to personally owned iOS devices.                 |

## Table Details

Under All Tenants the page becomes a table, one row per tenant.

| Column | Description |
| ---------------------------------------------- | -------------------------------------------------------------------------- |
| Partner State                                   | The connector's status in that tenant. Values are listed below.             |
| Last Heartbeat Date Time                        | When the connector last checked in.                                         |
| Microsoft Defender For Endpoint Attach Enabled  | Whether Defender for Endpoint is attached in that tenant.                   |
| Windows Enabled                                 | Whether the connector is enabled for Windows devices.                       |
| Ios Enabled                                     | Whether the connector is enabled for iOS devices.                           |
| Android Enabled                                 | Whether the connector is enabled for Android devices.                       |
| Mac Enabled                                     | Whether the connector is enabled for macOS devices.                         |
| Ios Mobile Application Management Enabled       | Whether app protection policy evaluation is enabled for iOS.                |
| Android Mobile Application Management Enabled   | Whether app protection policy evaluation is enabled for Android.            |
| Windows Mobile Application Management Enabled   | Whether app protection policy evaluation is enabled for Windows.            |
| Partner Unresponsiveness Threshold In Days      | How many days of silence before a device is treated as unresponsive.        |

## Partner State

| Value | Meaning |
| ------------ | ------------------------------------------------------------------- |
| `enabled`    | The connector is set up and active.                                 |
| `available`  | The connector exists and is reachable but is not fully configured.   |
| `unavailable`| The connector cannot be reached or is not responding.                |
| `unresponsive`| The connector was set up but has stopped communicating.             |
| `notSetUp`   | No connector is configured.                                          |
| `error`      | Something went wrong retrieving the state.                           |

{% hint style="warning" %}
The connector being configured is a prerequisite, not a confirmation of full deployment. See [deployment.md](../defender/deployment.md "mention") for how to complete a full deployment.
{% endhint %}

***

{% include "../../../../.gitbook/includes/feature-request.md" %}
