<#
.SYNOPSIS
    Generates a Microsoft 365 group expiration report for all Unified (Microsoft 365) groups in the tenant.

.DESCRIPTION
    Connects to Microsoft Graph and retrieves every Microsoft 365 (Unified) group along with the
    tenant's group lifecycle (expiration) policy, if one is configured. For each group the report
    includes creation, renewal, and expiration dates, the number of days until expiration, and an
    expiration status. If no group expiration policy is configured in the tenant, all groups are still
    listed and the expiration-related columns are reported as not applicable. Results are written to a
    timestamped CSV file.

.PARAMETER ExportPath
    Path to the CSV file that will be created. Defaults to a timestamped file in the current directory.

.EXAMPLE
    .\69-Get-M365GroupsExpirationReport.ps1
    Runs the report using the default timestamped export path in the current directory.

.EXAMPLE
    .\69-Get-M365GroupsExpirationReport.ps1 -ExportPath 'C:\Reports\GroupExpiration.csv'
    Runs the report and writes the results to the specified CSV file.

.OUTPUTS
    None. This script writes results to a CSV file and to the host; it does not emit objects to the pipeline.

.NOTES
    Required Microsoft Graph module : Microsoft.Graph.Groups (Connect-MgGraph is provided by Microsoft.Graph.Authentication).
    Required Microsoft Graph scopes : Group.Read.All, Directory.Read.All
    Authentication supports MFA via the interactive Connect-MgGraph flow.

.LINK
    https://learn.microsoft.com/graph/api/resources/grouplifecyclepolicy
#>
param([string]$ExportPath = ".\Report_69_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv")

Write-Host "`n==================================================================================`n" -ForegroundColor Cyan
Write-Host "M365 Groups Expiration Report" -ForegroundColor Green
Write-Host "==================================================================================`n" -ForegroundColor Cyan

$requiredModule = "Microsoft.Graph.Groups"
if (-not (Get-Module -ListAvailable -Name $requiredModule)) {
    $install = Read-Host "Install $requiredModule? (Y/N)"
    if ($install -match '^[Yy]$') {
        Install-Module -Name $requiredModule -Scope CurrentUser -Force -AllowClobber
        Write-Host "Installed.`n" -ForegroundColor Green
    } else { exit }
}

Write-Host "Connecting..." -ForegroundColor Cyan
try {
    Connect-MgGraph -Scopes "Group.Read.All","Directory.Read.All" -NoWelcome -ErrorAction Stop
    Write-Host "Connected.`n" -ForegroundColor Green
} catch {
    Write-Host "Failed: $_" -ForegroundColor Red
    exit
}

Write-Host "Retrieving group expiration policy..." -ForegroundColor Cyan
$script:PolicyConfigured = $false
$script:PolicyLifetimeDays = "N/A"
$script:PolicyManagedGroupTypes = "N/A"
try {
    $lifecyclePolicy = Get-MgGroupLifecyclePolicy -ErrorAction Stop | Select-Object -First 1
    if ($lifecyclePolicy) {
        $script:PolicyConfigured = $true
        $script:PolicyLifetimeDays = $lifecyclePolicy.GroupLifetimeInDays
        $script:PolicyManagedGroupTypes = $lifecyclePolicy.ManagedGroupTypes
        Write-Host "Expiration policy found (lifetime: $script:PolicyLifetimeDays days, managed: $script:PolicyManagedGroupTypes).`n" -ForegroundColor Green
    } else {
        Write-Host "No group expiration policy is configured in this tenant; expiration dates will be blank.`n" -ForegroundColor Yellow
    }
} catch {
    Write-Host "No group expiration policy is configured in this tenant; expiration dates will be blank.`n" -ForegroundColor Yellow
}

Write-Host "Retrieving Microsoft 365 groups..." -ForegroundColor Cyan
$script:Results = @()
try {
    $groups = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName,Mail,Visibility,CreatedDateTime,RenewedDateTime,ExpirationDateTime -ErrorAction Stop
    $now = Get-Date
    foreach ($group in $groups) {
        if ($group.ExpirationDateTime) {
            $daysUntil = [math]::Round((New-TimeSpan -Start $now -End $group.ExpirationDateTime).TotalDays)
            if ($daysUntil -lt 0) {
                $status = "Expired"
            } elseif ($daysUntil -le 30) {
                $status = "Expiring soon (<=30d)"
            } else {
                $status = "Active"
            }
            $expDate = $group.ExpirationDateTime
            $daysValue = $daysUntil
        } else {
            $status = "No policy"
            $expDate = "N/A"
            $daysValue = "N/A"
        }
        $script:Results += [PSCustomObject]@{
            DisplayName             = $group.DisplayName
            Mail                    = $group.Mail
            Visibility              = $group.Visibility
            CreatedDateTime         = $group.CreatedDateTime
            RenewedDateTime         = $group.RenewedDateTime
            ExpirationDateTime      = $expDate
            DaysUntilExpiration     = $daysValue
            ExpirationStatus        = $status
            PolicyConfigured        = $script:PolicyConfigured
            PolicyLifetimeDays      = $script:PolicyLifetimeDays
            PolicyManagedGroupTypes = $script:PolicyManagedGroupTypes
        }
    }
    Write-Host "Retrieved $($script:Results.Count) Microsoft 365 group(s).`n" -ForegroundColor Green
} catch {
    Write-Host "Error retrieving groups: $_" -ForegroundColor Red
    Disconnect-MgGraph | Out-Null
    exit 1
}

Write-Host "`n==================================================================================`n" -ForegroundColor Cyan
Write-Host "Summary: $($script:Results.Count) group(s)" -ForegroundColor Green
$script:Results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
Write-Host "Report: $ExportPath" -ForegroundColor White
Write-Host "==================================================================================`n" -ForegroundColor Cyan
if ($script:Results.Count -gt 0) {
    $script:Results | Format-Table -AutoSize
    $open = Read-Host "Open CSV? (Y/N)"
    if ($open -match '^[Yy]$') { Invoke-Item $ExportPath }
}

Disconnect-MgGraph | Out-Null
