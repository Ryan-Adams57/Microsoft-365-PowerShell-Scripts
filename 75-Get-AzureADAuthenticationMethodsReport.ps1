<#
.SYNOPSIS
    Generates a per-user authentication method registration report for the tenant
    from Microsoft Entra ID (Azure AD).

.DESCRIPTION
    Connects to Microsoft Graph and retrieves authentication method registration
    details for every user via Get-MgReportAuthenticationMethodUserRegistrationDetail.
    Each user becomes one row describing their SSPR and MFA registration/capability
    status, passwordless capability, the authentication methods they have registered,
    and their system-preferred / user-preferred method settings. The result set is
    exported to a timestamped CSV file.

    This report reflects the tenant's registration data as last aggregated by
    Microsoft Entra; values may lag real-time changes by up to a few hours.

.PARAMETER ExportPath
    Path to the CSV file that will be created. Defaults to a timestamped file name
    in the current directory (Report_75_yyyyMMdd_HHmmss.csv).

.EXAMPLE
    .\75-Get-AzureADAuthenticationMethodsReport.ps1
    Generates the report using the default timestamped output path.

.EXAMPLE
    .\75-Get-AzureADAuthenticationMethodsReport.ps1 -ExportPath 'C:\Reports\AuthMethods.csv'
    Generates the report and writes it to the specified path.

.NOTES
    Author:        Ryan Adams
    Version:       3.0
    Last Updated:  2026-07-13
    Requires:      Microsoft.Graph.Reports, Microsoft.Graph.Authentication
    Permissions:   AuditLog.Read.All (delegated, admin-consented)
    Note:          The signed-in account must also hold a supported Microsoft Entra
                   role (for example Reports Reader, Security Reader, or Global Reader)
                   to read authentication method registration details.

.OUTPUTS
    None. This script writes a CSV file to disk and displays progress to the host.
#>

#Requires -Version 5.1

[CmdletBinding()]
param([string]$ExportPath = ".\Report_75_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv")

Write-Host "`n================================================================================`n" -ForegroundColor Cyan
Write-Host "Azure AD Authentication Methods Report" -ForegroundColor Green
Write-Host "================================================================================`n" -ForegroundColor Cyan

# Ensure the required Microsoft Graph modules are available
$requiredModules = @('Microsoft.Graph.Reports','Microsoft.Graph.Authentication')
foreach ($requiredModule in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $requiredModule)) {
        $install = Read-Host "Required module '$requiredModule' is not installed. Install it now? (Y/N)"
        if ($install -match '^[Yy]$') {
            Install-Module -Name $requiredModule -Scope CurrentUser -Force -AllowClobber
            Write-Host "Installed $requiredModule.`n" -ForegroundColor Green
        } else {
            Write-Host "Cannot continue without $requiredModule. Exiting." -ForegroundColor Red
            exit
        }
    }
}

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
try {
    Connect-MgGraph -Scopes "AuditLog.Read.All" -NoWelcome -ErrorAction Stop
    Write-Host "Connected.`n" -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
    exit
}

Write-Host "Retrieving authentication method registration details..." -ForegroundColor Cyan
$script:Results = @()

try {
    $registrationDetails = Get-MgReportAuthenticationMethodUserRegistrationDetail -All -ErrorAction Stop
    Write-Host "Retrieved $($registrationDetails.Count) user registration record(s).`n" -ForegroundColor Green

    foreach ($detail in $registrationDetails) {
        $methods = if ($detail.MethodsRegistered) { ($detail.MethodsRegistered -join '; ') } else { '' }
        $systemPreferred = if ($detail.SystemPreferredAuthenticationMethods) { ($detail.SystemPreferredAuthenticationMethods -join '; ') } else { '' }

        $script:Results += [PSCustomObject]@{
            UserPrincipalName                             = $detail.UserPrincipalName
            UserDisplayName                               = $detail.UserDisplayName
            UserType                                      = $detail.UserType
            IsAdmin                                       = $detail.IsAdmin
            IsSsprRegistered                              = $detail.IsSsprRegistered
            IsSsprEnabled                                 = $detail.IsSsprEnabled
            IsSsprCapable                                 = $detail.IsSsprCapable
            IsMfaRegistered                               = $detail.IsMfaRegistered
            IsMfaCapable                                  = $detail.IsMfaCapable
            IsPasswordlessCapable                         = $detail.IsPasswordlessCapable
            MethodsRegistered                             = $methods
            IsSystemPreferredAuthenticationMethodEnabled  = $detail.IsSystemPreferredAuthenticationMethodEnabled
            SystemPreferredAuthenticationMethods          = $systemPreferred
            UserPreferredMethodForSecondaryAuthentication = $detail.UserPreferredMethodForSecondaryAuthentication
            LastUpdatedDateTime                           = $detail.LastUpdatedDateTime
        }
    }
    Write-Host "Processing complete.`n" -ForegroundColor Green
} catch {
    Write-Host "Error retrieving authentication method registration details: $_" -ForegroundColor Red
    Write-Host "Ensure the account has AuditLog.Read.All consent and a supported Entra role (e.g. Reports Reader)." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    exit
}

if ($script:Results.Count -gt 0) {
    Write-Host "`n================================================================================`n" -ForegroundColor Cyan
    Write-Host "Summary: $($script:Results.Count) user record(s)" -ForegroundColor Green
    $script:Results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Report: $ExportPath" -ForegroundColor White
    Write-Host "================================================================================`n" -ForegroundColor Cyan
    $script:Results | Format-Table -AutoSize
    $open = Read-Host "Open CSV? (Y/N)"
    if ($open -match '^[Yy]$') { Invoke-Item $ExportPath }
} else {
    Write-Host "No authentication method registration details were returned." -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
