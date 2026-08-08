# Shadow AI Discovery

This page lists the AI tools in use in a tenant, so you can discover unapproved tools known as shadow AI.

The report is compiled from cached Intune and Entra data rather than live Graph queries, with the last data refresh time shown at the top of the page (the oldest of the cached datasets, so it reflects the stalest data on the page). If no cached data exists for the tenant yet, the page prompts you to run **Sync data** first.

{% hint style="info" %}
Shadow AI Discovery requires a single tenant to be selected. It is not available in the All Tenants view.
{% endhint %}

## Action Buttons

<details>

<summary>Executive Shadow AI Report</summary>

Generates an executive summary of the shadow AI in the tenant, for ease of sharing with client management. Optionally select the sections you wish to include before clicking the download PDF button; a live preview of the branded PDF updates as you toggle them. The available sections are Cover Page, Executive Summary, Infographic Pages, Understanding Shadow AI, Risk Levels & Distribution, Sanctioned Tools, AI Software (Intune), AI Applications (Entra), and Recommendations; at least one section must remain enabled. The button is unavailable until the tenant's data has been synced.

</details>

<details>

<summary>Sync data</summary>

Queues a refresh of the cached datasets the report is compiled from (Intune detected apps, Entra service principals, and OAuth2 permission grants) for the selected tenant. The report updates once the sync completes.

</details>

## Overview

The overview contains several information cards that you can use to get a view of the tenant's shadow AI.

### Info Cards

* **AI Tools Detected**: The number of distinct AI tools found in the tenant across both the device (Intune) and identity (Entra) sources.
* **Device Installs**: The number of device installs for AI tools. This is total installs across the Intune fleet so one app can be installed multiple times.
* **AI Apps in Entra**: The number of AI applications seen in Entra.
* **High-Risk AI Tools**: The number of distinct tools rated High risk, after sanction adjustment.

### Data Cards

#### AI Tools by Category

Shows the tools by category. The categories are:

* **AI Assistant**: general-purpose chat (ChatGPT, Claude, Gemini, Copilot, Perplexity, DeepSeek, Grok). The "paste anything into a box" tools.
* **AI Coding**: assistants and agentic editors (Copilot, Cursor, Cline, Devin, Replit, v0, Bolt, Lovable, Aider).
* **AI Agent & Automation**: autonomous agents and LLM-wired workflow platforms (AutoGPT, CrewAI, Manus, Lindy, n8n, Zapier, Make). Often carry standing OAuth grants into mailboxes/CRMs.
* **AI Image & Design**: generation/editing (Midjourney, Stable Diffusion, DALL-E, Firefly, Canva, ComfyUI, Remove.bg).
* **AI Video & Audio**: video, TTS, and voice cloning (Sora, Synthesia, HeyGen, Runway, Descript, ElevenLabs, CapCut, Suno).
* **AI Meeting Notetaker**: recorders/transcribers with auto-join bots (Otter, Fireflies, Fathom, tl;dv, Granola). Heavy recording-consent angle.
* **AI Writing & Translation**: writing aids, paraphrasers, translation (Grammarly, Jasper, QuillBot, Wordtune, DeepL, Writer).
* **AI Email**: AI email clients/assistants that take mailbox access (Fyxer, Superhuman, Shortwave, Lavender).
* **AI Search & Research**: answer engines and document Q\&A (NotebookLM, Glean, Phind, ChatPDF, AskYourPDF).
* **AI Presentation & Productivity**: deck/note builders plus AI browser sidebar extensions (Gamma, Tome, Notion, Mem, Monica, Sider, Merlin, MaxAI).
* **Local AI Runtime**: locally-run/self-hosted model tooling (Ollama, LM Studio, GPT4All, Jan, Open WebUI, LocalAI). On-device data but ungoverned.
* **AI Platform & API**: model providers, API aggregators, dev frameworks, cloud ML (Azure OpenAI, Vertex, Bedrock, Hugging Face, OpenRouter, Groq, LangChain).
* **AI Business Apps**: vertical SaaS with embedded AI for sales/HR/legal/support/data (Gong, Apollo, Harvey, Spellbook, HireVue, Julius, Chatbase).
* **AI Companion Chatbot**: persona/roleplay/adult chat (Character.AI, Candy.AI, Janitor AI, Crushon, FlowGPT). No business use; these are HR/policy findings.
* **AI-Capable Editor**: not AI itself, listed for visibility as the host for AI extensions (VS Code, JetBrains AI).

#### Top AI Tools

This chart shows you the top eight AI tools in use, ranked by combined footprint (device installs plus 7-day active users). There are two ways to view this chart:

* **By installations**: The summed Intune device count per tool.
* **By users**: The summed 7-day sign-in activity count per tool.

#### AI Tool Risk Distribution

Shows the risk distribution of the AI tools in the tenant.

{% hint style="info" %}
Note that this risk distribution is adjusted for sanctioning. See the sanctioning action in the [#ai-applications-in-entra-table](shadow-ai.md#ai-applications-in-entra-table "mention") section.
{% endhint %}

Risk Categorisation:

* **High** (red, 36 tools): Default/common usage exfiltrates sensitive data with no contractual protection or is inherently disqualifying. Four rough sub-patterns: consumer accounts that train on input (ChatGPT free/Plus, Grok); foreign-jurisdiction data residency (DeepSeek, Qwen, Kimi, CapCut, and Manus, all China-based); autonomous agents with broad standing access (AutoGPT, Devin, CrewAI, Lindy, Fyxer's full-mailbox grant); exfiltration-as-the-product or policy violations (ChatPDF, Julius, Chatbase, Otter/Fireflies meeting bots, Character.AI and other companion chatbots, public-by-default builders like Replit/Lovable/Bolt/v0, and broad page-reading extensions like Monica/Sider/Merlin/MaxAI).
* **Medium** (amber, 118 tools): The default bucket. Legitimate tools that are fine on business/enterprise tiers but land here because discovery typically finds the free/personal-account version, sending data to a vendor cloud under consumer terms without the catastrophic exposure of the High patterns. Most coding assistants, notetakers, creative tools, and API platforms sit here.
* **Low** (blue, 12 tools): contractually safe by design. Enterprise services governed by the org's own tenant/subscription/terms (Azure OpenAI, Vertex, Microsoft Copilot with commercial data protection, NotebookLM under Workspace, Adobe Firefly, JetBrains AI, Writer, Hugging Face, Moveworks, Jan). Worth visibility, low data risk.
* **Informational** (green, 8 tools in-catalogue, plus any sanctioned): not really shadow AI: mainstream business software listed only because it has embedded AI (Canva, Notion, Coda, Databricks, Salesforce Einstein, ServiceNow Now Assist, Atlassian Rovo), AI-capable editors (VS Code), and anything you've marked Company Sanctioned for the tenant, since that override forces this level.

## AI Software on Managed Devices (Intune) Table

Lists AI-related software installed on the tenant's Intune-managed devices. Each row is a catalogue tool whose name or publisher matched the detected-apps inventory, showing which tool it maps to, its category and risk, and the devices it's installed on. The inventory reports a separate entry per version and install flavour, so everything matching the same tool is merged into a single row. This is the device-installed view of Shadow AI: what's physically running on endpoints. It draws from the cached Intune detected-apps data, so it's empty when no installed software matches the catalogue or the Intune cache hasn't been synced.

Preset filters are available from the **Filters** button for **Sanctioned**, **Unsanctioned**, and **High Risk** rows. Clicking a row (or using the More Info action) opens a detail panel for the matched tool, showing its description, an explanation of why it carries its catalogue risk rating, its sanction status, its key properties, and the list of devices it is installed on.

### Table Details

| Column      | Description                                                                                                                                                                                      |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Application | The installed application names exactly as Intune reports them, combined across the merged inventory entries, for example "Copilot, Microsoft.Copilot".                                          |
| AI Tool     | The normalised catalogue tool name the application matched to, for example "Cursor (User)" becomes Cursor. This is the deduplication key used across the rest of the page.                       |
| Category    | The catalogue category of the matched tool, for example AI Coding, AI Assistant, or AI Meeting Notetaker.                                                                                        |
| Risk        | The effective, sanction-aware risk level. Shows the catalogue risk normally, or `Informational` when the tool is Company Sanctioned for the tenant.                                              |
| Status      | `Sanctioned` or `Unsanctioned`, driven by the per-tenant sanction list.                                                                                                                          |
| Publisher   | The software publisher reported by Intune. Where the inventory mixes clean names with full certificate subjects, the shortest is shown. Also one of the two fields fed into the catalogue match. |
| Platform    | The distinct operating systems Intune reported across the merged entries, defaulting to `Unknown` when blank.                                                                                    |
| Version     | The distinct application versions detected across the merged inventory entries, combined.                                                                                                        |
| Devices     | The distinct devices backing the install across all merged entries, each carrying the device name, assigned user, platform, and OS version. Feeds the device list in the row flyout.             |

### Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Mark as Company Sanctioned</td><td>Shown when the row's <strong>Status</strong> is not <code>Sanctioned</code>. Marks the tool sanctioned for the tenant so <strong>Risk</strong> reports as <code>Informational</code> and <strong>Status</strong> becomes <code>Sanctioned</code>. Refetches the report so cards, charts, and both tables update.</td><td>true</td></tr><tr><td>Remove Company Sanctioned Status</td><td>Shown when the row's <strong>Status</strong> is <code>Sanctioned</code>. Removes the sanction so the catalogue risk level applies again and <strong>Status</strong> returns to <code>Unsanctioned</code>. Refetches the report so cards, charts, and both tables update.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

## AI Applications in Entra Table

Lists AI-related applications that have been consented into the tenant in Entra ID. Each row is a matched service principal, showing the tool it maps to, its category and risk, the OAuth permissions it was granted, and recent sign-in activity. This is the identity/consent view of Shadow AI: what's been authorised to access tenant data via OAuth, independent of any device install. It draws from the cached service principal and OAuth grant data: every cached service principal is matched by display name, not only those holding OAuth grants, with duplicates collapsed by application ID. A best-effort 7-day sign-in enrichment (a single bounded query covering up to 15 matched applications) requires Entra ID P1.

Preset filters are available from the **Filters** button for **Sanctioned**, **Unsanctioned**, and **High Risk** rows. Clicking a row (or using the More Info action) opens a detail panel for the matched tool, showing its description, an explanation of why it carries its catalogue risk rating, its sanction status, its key properties, the OAuth permissions granted, and the per-user sign-in activity from the last 7 days.

### Table Details

| Column                | Description                                                                                                                                          |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Application           | The Entra service principal's display name, the enterprise application as it appears consented in the tenant.                                        |
| AI Tool               | The normalised catalogue tool name matched from the service principal's display name. Shares the deduplication key used across the rest of the page. |
| Category              | The catalogue category of the matched tool, for example AI Assistant, AI Agent & Automation, or AI Email.                                            |
| Risk                  | The effective, sanction-aware risk level. Shows the catalogue risk normally, or `Informational` when the tool is Company Sanctioned for the tenant.  |
| Status                | `Sanctioned` or `Unsanctioned`, driven by the per-tenant sanction list.                                                                              |
| Application ID        | The application's client ID, taken from the service principal.                                                                                       |
| Approved Permissions  | The individual delegated OAuth scopes granted to the application, derived from the tenant's OAuth2 permission grants and shown as chips.             |
| Sign-ins (7 Days)     | Count of sign-ins to the application over the last 7 days. A best-effort enrichment that requires Entra ID P1, reporting `0` when unavailable.       |
| Active Users (7 Days) | Distinct users who signed in to the application over the last 7 days. Carries the same P1 dependency and reports `0` when unavailable.               |
| First Consented       | When the service principal was created in the tenant, used as a proxy for first consent because the OAuth grant start time is unreliable.            |

### Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Mark as Company Sanctioned</td><td>Shown when the row's <strong>Status</strong> is not <code>Sanctioned</code>. Marks the tool sanctioned for the tenant so <strong>Risk</strong> reports as <code>Informational</code> and <strong>Status</strong> becomes <code>Sanctioned</code>. Refetches the report so cards, charts, and both tables update.</td><td>true</td></tr><tr><td>Remove Company Sanctioned Status</td><td>Shown when the row's <strong>Status</strong> is <code>Sanctioned</code>. Removes the sanction so the catalogue risk level applies again and <strong>Status</strong> returns to <code>Unsanctioned</code>. Refetches the report.</td><td>true</td></tr><tr><td>Application Users</td><td>Opens a side drawer listing the application's per-user sign-in activity over the last 7 days: user principal name, display name, sign-in count, and last sign-in time. The data depends on the same Entra ID P1 sign-in enrichment.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../.gitbook/includes/feature-request.md" %}
