> **BETA:** These PowerShell scripts are currently in BETA. Please validate each script individually in a non-production tenant before deploying to production.

# Microsoft 365 PowerShell Scripts

A collection of PowerShell scripts and tools, in varying stages of completion, for managing, auditing, and reporting on Microsoft 365 tenants. The collection spans Entra ID (Azure AD), Exchange Online, SharePoint/OneDrive, Teams, Intune, Microsoft Defender, Purview/compliance, and the Power Platform.

Some scripts are complete reporting tools; others are placeholders or works in progress that are still being built out (these are identified in the Script Index below).

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

This repository provides 76 reporting and auditing scripts (numbered `00`-`75`) for Microsoft 365 administrators, in varying stages of completion. Completed scripts typically read tenant configuration or activity data and export a CSV report, making them suitable for scheduled reporting, security reviews, and compliance audits. Other scripts are placeholders pending implementation.

The scripts are intended for M365 administrators, security/compliance teams, and consultants who want repeatable, script-based reporting. Because the collection is in BETA and not every script is complete, review each script before use.

## Prerequisites

- **PowerShell 5.1** or **PowerShell 7+**. PowerShell 7+ is recommended.
- The relevant Microsoft modules installed, depending on which scripts you run:
  - **Microsoft Graph PowerShell SDK** (`Microsoft.Graph.*`) - used by many of the scripts.
  - **Exchange Online Management** (`ExchangeOnlineManagement`) - used by the Exchange and several compliance scripts (also provides `Connect-IPPSSession`).
  - **Microsoft Teams** (`MicrosoftTeams`), **SharePoint Online** (`Microsoft.Online.SharePoint.PowerShell`), **Power BI** (`MicrosoftPowerBIMgmt`), and Intune modules for the scripts that target those services.
- Appropriate Microsoft 365 administrative roles and, where noted, the required licensing (for example, some Identity Protection and Privileged Identity Management data requires the appropriate Microsoft Entra ID licensing).

Script `00-Install-M365Modules.ps1` is provided to help install required modules.

## Authentication & Permissions

Scripts authenticate using the connection method appropriate to the service they target - for example `Connect-MgGraph` (Microsoft Graph), `Connect-ExchangeOnline`, `Connect-IPPSSession` (Security & Compliance), `Connect-MicrosoftTeams`, `Connect-SPOService`, or `Connect-PowerBIServiceAccount`. The Script Index lists the connection method observed in each script's source.

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

The repository contains **76 scripts** (`00`-`75`). Some are complete reporting tools; others are placeholders or works in progress and are identified below in the "Connects via" column as *Not yet implemented*. The "Connects via" values reflect the connection method observed in each script's source code.

| Script | Description | Connects via |
| --- | --- | --- |
| 00-Install-M365Modules | Installs the PowerShell modules required by the other scripts | — (module installer) |
| 01-Get-M365UserLicenseReport | User license assignment report | Microsoft Graph |
| 02-Get-M365InactiveUsersReport | Inactive users report | Microsoft Graph |
| 03-Get-M365ExternalForwardingReport | External mail forwarding report | Exchange Online |
| 04-Get-M365MailboxSizeReport | Mailbox size report | Exchange Online |
| 05-Get-M365GroupMembershipsReport | Group memberships report | Microsoft Graph |
| 06-Get-M365OneDriveUsageReport | OneDrive usage report | SharePoint Online + Microsoft Graph |
| 07-Get-M365SharePointExternalSharingReport | SharePoint external sharing report | SharePoint Online |
| 08-Search-M365UnifiedAuditLog | Unified audit log search | Exchange Online |
| 09-Get-M365RoomMailboxUsageReport | Room mailbox usage report | Exchange Online |
| 10-Get-M365TeamsMeetingAttendanceReport | Teams meeting attendance report | Microsoft Graph |
| 11-Get-M365MFAStatusReport | MFA status report | Microsoft Graph |
| 12-Get-M365RiskySignInsReport | Risky sign-ins report (Entra ID Identity Protection) | Microsoft Graph |
| 13-Get-M365GuestUsersAuditReport | Guest users audit report | Microsoft Graph |
| 14-Get-M365PrivilegedRoleAssignmentsReport | Privileged role assignments report | Microsoft Graph |
| 15-Get-M365ConditionalAccessPoliciesReport | Conditional Access policies report | Microsoft Graph |
| 16-Get-M365MailFlowRulesReport | Mail flow (transport) rules report | Exchange Online |
| 17-Get-M365SpamMalwareReport | Spam and malware detection report | Exchange Online |
| 18-Get-M365TeamsLifecycleReport | Teams lifecycle report | Microsoft Teams |
| 19-Get-M365TeamsExternalAccessReport | Teams external access report | Microsoft Teams |
| 20-Get-M365SharePointInactiveSitesReport | Inactive SharePoint sites report | SharePoint Online |
| 21-Audit-M365LicenseAssignmentChanges | License assignment change audit | Exchange Online |
| 22-Get-M365UnusedLicensesReport | Unused licenses report | Microsoft Graph |
| 23-Get-M365MailboxPermissionsReport | Mailbox permissions report | Exchange Online |
| 24-Audit-M365FileDeletionReport | File deletion audit report | Exchange Online |
| 25-Audit-M365AdminActivityReport | Admin activity audit report | Exchange Online |
| 26-Get-M365DefenderThreatProtectionReport | Defender threat protection report | Exchange Online |
| 27-Get-M365DLPPolicyReport | Data Loss Prevention policy report | Purview / Security & Compliance (IPPS + Exchange Online) |
| 28-Get-PowerPlatformEnvironmentReport | Power Platform environment report | Not yet implemented (no connection command present) |
| 29-Get-PowerAutomateFlowsInventory | Power Automate flows inventory | Not yet implemented (no connection command present) |
| 30-Get-PowerAppsUsageReport | Power Apps usage report | Not yet implemented (no connection command present) |
| 31-Get-PowerBIWorkspaceReport | Power BI workspace report | Power BI |
| 32-Get-IntuneDeviceComplianceReport | Intune device compliance report | Intune (legacy Connect-MSGraph) |
| 33-Get-IntuneAppProtectionPoliciesReport | Intune app protection policies report | Intune (legacy Connect-MSGraph) |
| 34-Get-AzureADConditionalAccessSignInLogs | Entra ID Conditional Access sign-in logs | Microsoft Graph |
| 35-Get-M365RetentionPoliciesReport | Retention policies report | Purview / Security & Compliance (IPPS) |
| 36-Get-M365eDiscoveryCasesReport | eDiscovery cases report | Purview / Security & Compliance (IPPS) |
| 37-Get-M365SensitivityLabelsReport | Sensitivity labels report | Purview / Security & Compliance (IPPS) |
| 38-Get-ExchangeAdvancedMessageTrace | Advanced message trace | Exchange Online |
| 39-Get-ExchangeJournalingArchivingReport | Journaling and archiving report | Exchange Online |
| 40-Get-AzureADB2BCollaborationReport | Entra ID B2B collaboration report | Microsoft Graph |
| 41-Get-AzureADIdentityProtectionReport | Entra ID Identity Protection report | Microsoft Graph |
| 42-Get-TeamsChannelAnalyticsReport | Teams channel analytics report | Microsoft Teams + Graph + Exchange Online |
| 43-Get-TeamsVoiceCallingReport | Teams voice/calling report | Microsoft Teams + Graph + Exchange Online |
| 44-Get-IntuneConfigurationProfilesReport | Intune configuration profiles report | Microsoft Teams + Graph + Exchange Online |
| 45-Get-MobileDeviceManagementReport | Mobile device management report | Microsoft Teams + Graph + Exchange Online |
| 46-Get-CommunicationComplianceReport | Communication compliance report | Microsoft Teams + Graph + Exchange Online |
| 47-Get-InsiderRiskManagementReport | Insider risk management report | Microsoft Graph + Exchange Online |
| 48-Get-InformationBarriersReport | Information barriers report | Microsoft Graph + Exchange Online |
| 49-Get-AzureADPIMReport | Entra ID Privileged Identity Management report | Microsoft Graph + Exchange Online |
| 50-Get-MicrosoftSecureScoreReport | Microsoft Secure Score report | Microsoft Graph + Exchange Online |
| 51-Get-DefenderEndpointDeviceReport | Defender for Endpoint device report | Microsoft Graph |
| 52-Get-AzureADAppRegistrationsReport | Entra ID app registrations report | Microsoft Graph |
| 53-Get-ServiceHealthIncidentsReport | Service health incidents report | Microsoft Graph |
| 54-Get-HybridIdentityADConnectReport | Hybrid identity / AD Connect report | Microsoft Graph |
| 55-Get-ComplianceManagerAssessmentsReport | Compliance Manager assessments report | Microsoft Graph |
| 56-Get-VivaInsightsAdoptionReport | Viva Insights adoption report | Microsoft Graph |
| 57-Get-M365UsageAnalyticsReport | M365 usage analytics report | Microsoft Graph |
| 58-Get-NetworkConnectivityReport | Network connectivity report | Microsoft Graph + Exchange + SharePoint |
| 59-Get-BackupPoliciesReport | Backup policies report | Not yet implemented (no connection command present) |
| 60-Get-ServicePrincipalPermissionsReport | Service principal permissions report | Not yet implemented (no connection command present) |
| 61-Get-EOPAdvancedConfigReport | Exchange Online Protection advanced config report | Not yet implemented (no connection command present) |
| 62-Get-PowerPlatformDLPPoliciesReport | Power Platform DLP policies report | Not yet implemented (no connection command present) |
| 63-Get-AzureADAccessReviewsReport | Entra ID access reviews report | Not yet implemented (no connection command present) |
| 64-Get-TeamsAppPermissionsReport | Teams app permissions report | Not yet implemented (no connection command present) |
| 65-Get-SharePointSiteCollectionsReport | SharePoint site collections report | Not yet implemented (no connection command present) |
| 66-Get-ExchangeMailboxDatabasesReport | Exchange mailbox databases report | Not yet implemented (no connection command present) |
| 67-Get-DefenderAttackSimulationReport | Defender attack simulation report | Not yet implemented (no connection command present) |
| 68-Get-AzureADEntitlementManagementReport | Entra ID entitlement management report | Not yet implemented (no connection command present) |
| 69-Get-M365GroupsExpirationReport | M365 groups expiration report | Not yet implemented (no connection command present) |
| 70-Get-IntuneAppInventoryReport | Intune app inventory report | Not yet implemented (no connection command present) |
| 71-Get-CloudAppSecurityReport | Cloud App Security (Defender for Cloud Apps) report | Not yet implemented (no connection command present) |
| 72-Get-M365LicenseUsageTrendsReport | License usage trends report | Not yet implemented (no connection command present) |
| 73-Get-SharePointHubSitesReport | SharePoint hub sites report | Not yet implemented (no connection command present) |
| 74-Get-TeamsPoliciesInventoryReport | Teams policies inventory report | Not yet implemented (no connection command present) |
| 75-Get-AzureADAuthenticationMethodsReport | Entra ID authentication methods report | Not yet implemented (no connection command present) |

> For exact scopes/permissions and parameters, run `Get-Help .\<script>.ps1 -Full` where comment-based help is available, or review the script source.

## Repository Structure

Scripts are stored in the repository root and numbered `00`-`75` so they sort in a logical order. Numbers `1`-`9` are zero-padded (`01`-`09`) for correct sorting. The numbering roughly groups related areas together (identity and licensing early on, followed by Exchange, Teams, Intune, Defender, Purview/compliance, and Power Platform).

- `00-Install-M365Modules.ps1` - module installer helper.
- `01`-`75` - individual reporting/auditing scripts (some complete, some placeholders).
- `README.md` - this file.
- `LICENSE` - repository license.

## Known Issues

- **Resolved:** Duplicate/extra header comment lines ("extra slashes") in scripts 42-50 have been removed.
- **Resolved:** `12-Get-M365RiskySignInsReport.ps1` now includes full comment-based help clarifying its purpose, parameters, permissions, and output.
- Several scripts are placeholders or works in progress (see the Script Index) and do not yet contain working connection logic.
- Comment-based help is still being added across the collection.
- Scripts remain in BETA - validate each one in a non-production tenant before relying on it.

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
