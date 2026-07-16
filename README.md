# Microsoft 365 PowerShell Scripts

A collection of PowerShell scripts and tools, in varying stages of completion, for managing, auditing, and reporting on Microsoft 365 tenants. The collection spans Entra ID (Azure AD), Exchange Online, SharePoint/OneDrive, Teams, Intune, Microsoft Defender, Purview/compliance, and the Power Platform.

This collection is in active development, and the scripts are at different stages of completion. Some are functional reporting tools that query live Microsoft 365 data; some are partially implemented (they retrieve real data for parts of the report and use sample values for others); and some are placeholders whose reporting logic is scaffolded but not yet connected to live data (they currently emit sample output). The **Status** column in the Script Index shows where each script stands.

> Scripts are provided as-is. Review and test each one before running in production.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Authentication & Permissions](#authentication--permissions)
- [Installation](#installation)
- [Usage](#usage)
- [Script Index](#script-index)
- [Repository Structure](#repository-structure)
- [Known Issues](#known-issues)
- [Contributing](#contributing)
- [Acknowledgements](#acknowledgements)
- [License](#license)

## Overview

This repository provides 76 reporting and auditing scripts (numbered `00`-`75`) for Microsoft 365 administrators, in varying stages of completion. Completed scripts typically read tenant configuration or activity data and export a CSV report, making them suitable for scheduled reporting, security reviews, and compliance audits. Other scripts are partially implemented or are placeholders pending implementation.

The scripts are intended for M365 administrators, security/compliance teams, and consultants who want repeatable, script-based reporting. Because not every script is complete, review each script's status and source before use.

## Prerequisites

- **PowerShell 5.1** or **PowerShell 7+**. PowerShell 7+ is recommended.
- The relevant Microsoft modules installed, depending on which scripts you run:
  - **Microsoft Graph PowerShell SDK** (`Microsoft.Graph.*`) - used by many of the scripts.
  - **Exchange Online Management** (`ExchangeOnlineManagement`) - used by the Exchange and several compliance scripts (also provides `Connect-IPPSSession`).
  - **Microsoft Teams** (`MicrosoftTeams`), **SharePoint Online** (`Microsoft.Online.SharePoint.PowerShell`), **Power BI** (`MicrosoftPowerBIMgmt`), **Power Platform** (`Microsoft.PowerApps.Administration.PowerShell`), and Intune modules for the scripts that target those services.
- Appropriate Microsoft 365 administrative roles and, where noted, the required licensing (for example, some Identity Protection and Privileged Identity Management data requires the appropriate Microsoft Entra ID licensing).

Script `00-Install-M365Modules.ps1` is provided to help install required modules.

## Authentication & Permissions

Scripts authenticate using the connection method appropriate to the service they target - for example `Connect-MgGraph` (Microsoft Graph), `Connect-ExchangeOnline`, `Connect-IPPSSession` (Security & Compliance), `Connect-MicrosoftTeams`, `Connect-SPOService`, `Connect-PowerBIServiceAccount`, or `Add-PowerAppsAccount` (Power Platform). The Script Index lists the connection method observed in each script's source.

Where a script includes comment-based help, it documents the specific permissions it requests; run `Get-Help .\<script>.ps1 -Full` to review them. For scripts that do not yet have help, review the script source directly before running so you can confirm the requested access is appropriate for your environment.

## Installation

```powershell
# 1. Clone the repository
git clone https://github.com/Ryan-Adams57/Microsoft-365-PowerShell-Scripts.git
cd Microsoft-365-PowerShell-Scripts

# 2. Install the required modules
.\00-Install-M365Modules.ps1
```

## Usage

View a script's full help (where comment-based help is present):

```powershell
Get-Help .\01-Get-M365UserLicenseReport.ps1 -Full
```

Run a script (you will be prompted to sign in and consent to the requested scopes):

```powershell
.\01-Get-M365UserLicenseReport.ps1 -ExportPath "C:\Reports\UserLicenses.csv"
```

Parameter names may vary per script. Check `-Full` help where available, or the script source, for the exact parameters a given script supports.

## Script Index

The repository contains **76 scripts** (`00`-`75`). The **Status** column indicates each script's current stage of completion.

**Status legend:**

- **Functional** - queries live Microsoft 365 data and produces a real report.
- **Partial** - retrieves real data for part of the report; some fields use sample/placeholder values pending implementation.
- **Placeholder** - the script contains scaffolding or sample output, but the reporting logic is not currently retrieving the intended live data.
- **Utility** - helper script (e.g., module installer).

> Functional status is based on source-code review confirming live data-retrieval logic. Scripts have not been individually validated against every Microsoft 365 tenant configuration.

The "Connects via" values reflect the connection method observed in each script's source. For Placeholder scripts, this is the method the script is scaffolded to use once implemented.

| Script | Description | Connects via | Status |
| --- | --- | --- | --- |
| 00-Install-M365Modules | Installs the PowerShell modules required by the other scripts | - (module installer) | Utility |
| 01-Get-M365UserLicenseReport | User license assignment report | Microsoft Graph | Functional |
| 02-Get-M365InactiveUsersReport | Inactive users report | Microsoft Graph | Functional |
| 03-Get-M365ExternalForwardingReport | External mail forwarding report | Exchange Online | Functional |
| 04-Get-M365MailboxSizeReport | Mailbox size report | Exchange Online | Functional |
| 05-Get-M365GroupMembershipsReport | Group memberships report | Microsoft Graph | Functional |
| 06-Get-M365OneDriveUsageReport | OneDrive usage report | SharePoint Online + Microsoft Graph | Functional |
| 07-Get-M365SharePointExternalSharingReport | SharePoint external sharing report | SharePoint Online | Partial |
| 08-Search-M365UnifiedAuditLog | Unified audit log search | Exchange Online | Functional |
| 09-Get-M365RoomMailboxUsageReport | Room mailbox usage report | Exchange Online | Functional |
| 10-Get-M365TeamsMeetingAttendanceReport | Teams meeting attendance report | Microsoft Teams | Placeholder |
| 11-Get-M365MFAStatusReport | MFA status report | Microsoft Graph | Functional |
| 12-Get-M365RiskySignInsReport | Risky sign-ins report (Entra ID Identity Protection) | Microsoft Graph | Functional |
| 13-Get-M365GuestUsersAuditReport | Guest users audit report | Microsoft Graph | Placeholder |
| 14-Get-M365PrivilegedRoleAssignmentsReport | Privileged role assignments report | Microsoft Graph | Functional |
| 15-Get-M365ConditionalAccessPoliciesReport | Conditional Access policies report | Microsoft Graph | Functional |
| 16-Get-M365MailFlowRulesReport | Mail flow (transport) rules report | Exchange Online | Functional |
| 17-Get-M365SpamMalwareReport | Spam and malware detection report | Exchange Online | Functional |
| 18-Get-M365TeamsLifecycleReport | Teams lifecycle report | Microsoft Teams | Functional |
| 19-Get-M365TeamsExternalAccessReport | Teams external access report | Microsoft Teams | Functional |
| 20-Get-M365SharePointInactiveSitesReport | Inactive SharePoint sites report | SharePoint Online | Functional |
| 21-Audit-M365LicenseAssignmentChanges | License assignment change audit | Exchange Online | Functional |
| 22-Get-M365UnusedLicensesReport | Unused licenses report | Microsoft Graph | Functional |
| 23-Get-M365MailboxPermissionsReport | Mailbox permissions report | Exchange Online | Functional |
| 24-Audit-M365FileDeletionReport | File deletion audit report | Exchange Online | Functional |
| 25-Audit-M365AdminActivityReport | Admin activity audit report | Exchange Online | Functional |
| 26-Get-M365DefenderThreatProtectionReport | Defender threat protection report | Exchange Online | Functional |
| 27-Get-M365DLPPolicyReport | Data Loss Prevention policy report | Security & Compliance (IPPS) + Exchange Online | Functional |
| 28-Get-PowerPlatformEnvironmentReport | Power Platform environment report | Power Platform (Add-PowerAppsAccount) | Functional |
| 29-Get-PowerAutomateFlowsInventory | Power Automate flows inventory | Power Platform (Add-PowerAppsAccount) | Functional |
| 30-Get-PowerAppsUsageReport | Power Apps usage report | Power Platform (Add-PowerAppsAccount) | Functional |
| 31-Get-PowerBIWorkspaceReport | Power BI workspace report | Power BI | Functional |
| 32-Get-IntuneDeviceComplianceReport | Intune device compliance report | Intune (Connect-MSGraph) | Functional |
| 33-Get-IntuneAppProtectionPoliciesReport | Intune app protection policies report | Intune (Connect-MSGraph) | Functional |
| 34-Get-AzureADConditionalAccessSignInLogs | Entra ID Conditional Access sign-in logs | Microsoft Graph | Functional |
| 35-Get-M365RetentionPoliciesReport | Retention policies report | Security & Compliance (IPPS) | Functional |
| 36-Get-M365eDiscoveryCasesReport | eDiscovery cases report | Security & Compliance (IPPS) | Functional |
| 37-Get-M365SensitivityLabelsReport | Sensitivity labels report | Security & Compliance (IPPS) | Functional |
| 38-Get-ExchangeAdvancedMessageTrace | Advanced message trace | Exchange Online | Functional |
| 39-Get-ExchangeJournalingArchivingReport | Journaling and archiving report | Exchange Online | Functional |
| 40-Get-AzureADB2BCollaborationReport | Entra ID B2B collaboration report | Microsoft Graph | Functional |
| 41-Get-AzureADIdentityProtectionReport | Entra ID Identity Protection report | Microsoft Graph | Functional |
| 42-Get-TeamsChannelAnalyticsReport | Teams channel analytics report | Microsoft Teams + Graph + Exchange Online | Functional |
| 43-Get-TeamsVoiceCallingReport | Teams voice/calling report | Microsoft Teams + Graph + Exchange Online | Placeholder |
| 44-Get-IntuneConfigurationProfilesReport | Intune configuration profiles report | Microsoft Teams + Graph + Exchange Online | Placeholder |
| 45-Get-MobileDeviceManagementReport | Mobile device management report | Microsoft Teams + Graph + Exchange Online | Placeholder |
| 46-Get-CommunicationComplianceReport | Communication compliance report | Microsoft Teams + Graph + Exchange Online | Placeholder |
| 47-Get-InsiderRiskManagementReport | Insider risk management report | Microsoft Graph + Exchange Online | Placeholder |
| 48-Get-InformationBarriersReport | Information barriers report | Microsoft Graph + Exchange Online | Placeholder |
| 49-Get-AzureADPIMReport | Entra ID Privileged Identity Management report | Microsoft Graph + Exchange Online | Placeholder |
| 50-Get-MicrosoftSecureScoreReport | Microsoft Secure Score report | Microsoft Graph + Exchange Online | Placeholder |
| 51-Get-DefenderEndpointDeviceReport | Defender for Endpoint device report | Microsoft Graph | Partial |
| 52-Get-AzureADAppRegistrationsReport | Entra ID app registrations report | Microsoft Graph | Functional |
| 53-Get-ServiceHealthIncidentsReport | Service health incidents report | Microsoft Graph | Functional |
| 54-Get-HybridIdentityADConnectReport | Hybrid identity / AD Connect report | Microsoft Graph | Functional |
| 55-Get-ComplianceManagerAssessmentsReport | Compliance Manager assessments report | Microsoft Graph | Partial |
| 56-Get-VivaInsightsAdoptionReport | Viva Insights adoption report | Microsoft Graph | Partial |
| 57-Get-M365UsageAnalyticsReport | M365 usage analytics report | Microsoft Graph | Functional |
| 58-Get-NetworkConnectivityReport | Network connectivity report | Microsoft Graph | Placeholder |
| 59-Get-BackupPoliciesReport | Backup policies report | Microsoft Graph | Placeholder |
| 60-Get-ServicePrincipalPermissionsReport | Service principal permissions report | Microsoft Graph | Placeholder |
| 61-Get-EOPAdvancedConfigReport | Exchange Online Protection advanced config report | Exchange Online | Placeholder |
| 62-Get-PowerPlatformDLPPoliciesReport | Power Platform DLP policies report | Power Platform (Add-PowerAppsAccount) | Placeholder |
| 63-Get-AzureADAccessReviewsReport | Entra ID access reviews report | Microsoft Graph | Placeholder |
| 64-Get-TeamsAppPermissionsReport | Teams app permissions report | Microsoft Teams | Placeholder |
| 65-Get-SharePointSiteCollectionsReport | SharePoint site collections report | SharePoint Online | Placeholder |
| 66-Get-ExchangeMailboxDatabasesReport | Exchange mailbox databases report | Exchange Online | Placeholder |
| 67-Get-DefenderAttackSimulationReport | Defender attack simulation report | Microsoft Graph | Placeholder |
| 68-Get-AzureADEntitlementManagementReport | Entra ID entitlement management report | Microsoft Graph | Placeholder |
| 69-Get-M365GroupsExpirationReport | M365 groups expiration report | Microsoft Graph | Placeholder |
| 70-Get-IntuneAppInventoryReport | Intune app inventory report | Intune (Connect-MSGraph) | Placeholder |
| 71-Get-CloudAppSecurityReport | Cloud App Security (Defender for Cloud Apps) report | Microsoft Graph | Placeholder |
| 72-Get-M365LicenseUsageTrendsReport | License usage trends report | Microsoft Graph | Placeholder |
| 73-Get-SharePointHubSitesReport | SharePoint hub sites report | SharePoint Online | Placeholder |
| 74-Get-TeamsPoliciesInventoryReport | Teams policies inventory report | Microsoft Teams | Placeholder |
| 75-Get-AzureADAuthenticationMethodsReport | Entra ID authentication methods report | Microsoft Graph | Placeholder |

> For exact scopes/permissions and parameters, run `Get-Help .\<script>.ps1 -Full` where comment-based help is available, or review the script source.

## Repository Structure

Scripts are stored in the repository root and numbered `00`-`75` so they sort in a logical order. Numbers `1`-`9` are zero-padded (`01`-`09`) for correct sorting. The numbering roughly groups related areas together (identity and licensing early on, followed by Exchange, Teams, Intune, Defender, Purview/compliance, and Power Platform).

- `00-Install-M365Modules.ps1` - module installer helper.
- `01`-`75` - individual reporting/auditing scripts (see the Status column for completion state).
- `README.md` - this file.
- `LICENSE` - repository license.

## Known Issues

- **Resolved:** Duplicate/extra header comment lines ("extra slashes") in scripts 42-50 have been removed.
- **Resolved:** `12-Get-M365RiskySignInsReport.ps1` now includes full comment-based help.
- **In progress:** Several scripts are placeholders whose reporting logic is scaffolded but not yet connected to live data - they currently produce sample output. A few others are partially implemented. See the **Status** column in the Script Index for the current state of each script. Implementing these is the focus of the next phase of work.
- Comment-based help is still being added across the functional scripts (currently only script 12 has it).
- Validate each script in a non-production tenant before relying on it.

## Contributing

Contributions and feedback are welcome:

- Open an **issue** to report a bug, request a script, or suggest an improvement. Please include the script name and any error output.
- Submit a **pull request** for fixes or enhancements. Keep changes focused, and note any new permissions a script requires.

## Acknowledgements

This repository has benefited from thoughtful community feedback. Special thanks to:

**[Snickasaurus](https://github.com/Snickasaurus)** - provided multiple suggestions that directly improved the repository, including:

- Recommending the creation of `00-Install-M365Modules.ps1` to consolidate module installation across all scripts.
- Advising zero-padding of scripts 1-9 for proper sorting.
- Highlighting that `12-Get-M365RiskySignInsReport.ps1` was a template and suggesting clarification.
- Noting formatting issues (extra slashes) in scripts 42-50.

## License

This project is licensed under the terms of the [LICENSE](LICENSE) file included in this repository.
