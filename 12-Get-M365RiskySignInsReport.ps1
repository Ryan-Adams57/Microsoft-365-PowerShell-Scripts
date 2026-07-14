<#
.SYNOPSIS
    Reports on risky sign-ins from Microsoft Entra ID (Azure AD) Identity Protection.

.DESCRIPTION
    Connects to Microsoft Graph and retrieves risky sign-in events recorded by
    Entra ID Identity Protection for a given date range. Results can be filtered by
    risk level or by a specific user, are displayed in the console, and are exported
    to a timestamped CSV file. The report includes risk level, risk state, risk
    detail, risk event types, sign-in time, IP address, and location.

    Uses the Get-MgRiskySignIn cmdlet from the Microsoft.Graph.Identity.SignIns
    module (validated at runtime). Access to Identity Protection risk data requires
    the appropriate Microsoft Entra ID licensing (typically Entra ID Premium P2).

.PARAMETER StartDate
    Start of the date range to query. Defaults to 7 days ago.

.PARAMETER EndDate
    End of the date range to query. Defaults to the current date and time.

.PARAMETER RiskLevel
    Filters results by risk level. Valid values: low, medium, high, All. Defaults to All.

.PARAMETER UserPrincipalName
    Limits the report to a single user's sign-ins (e.g. user@contoso.com).

.PARAMETER ExportPath
    Path for the exported CSV report. Defaults to a timestamped file in the
    current directory (M365_Risky_SignIns_Report_yyyyMMdd_HHmmss.csv).

.EXAMPLE
    .\12-Get-M365RiskySignInsReport.ps1
    Generates a report of all risky sign-ins from the last 7 days.

.EXAMPLE
    .\12-Get-M365RiskySignInsReport.ps1 -RiskLevel high -StartDate (Get-Date).AddDays(-30)
    Reports only high-risk sign-ins from the last 30 days.

.EXAMPLE
    .\12-Get-M365RiskySignInsReport.ps1 -UserPrincipalName user@contoso.com
    Reports risky sign-ins for a single user.

.OUTPUTS
    None. The script exports a CSV report to the path specified by -ExportPath
    and writes status information to the console.

.NOTES
    Script Name : 12-Get-M365RiskySignInsReport.ps1
    Version     : 2.0
    Requires    : PowerShell 5.1+, Microsoft.Graph.Identity.SignIns module
    Permissions : User.Read.All, AuditLog.Read.All, Directory.Read.All
    Licensing   : Access to Identity Protection data requires appropriate
                  Microsoft Entra ID licensing (typically Entra ID Premium P2).

.LINK
    https://learn.microsoft.com/powershell/module/microsoft.graph.identity.signins/get-mgriskysignin
#>

#Requires -Version 5.1

[CmdletBinding()]

param(
    [Parameter(Mandatory=$false)]
    [datetime]$StartDate = (Get-Date).AddDays(-7),
    
    [Parameter(Mandatory=$false)]
    [datetime]$EndDate = (Get-Date),
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("low","medium","high","All")]
    [string]$RiskLevel = "All",
    
    [Parameter(Mandatory=$false)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory=$false)]
    [string]$ExportPath = ".\M365_Risky_SignIns_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Module validation and installation
Write-Host "`n====================================================================================`n" -ForegroundColor Cyan
Write-Host "Risky Sign-Ins and Identity Protection Report" -ForegroundColor Green
Write-Host "`n====================================================================================`n" -ForegroundColor Cyan

$requiredModule = "Microsoft.Graph.Identity.SignIns"

if (-not (Get-Module -ListAvailable -Name $requiredModule)) {
    Write-Host "Required module '$requiredModule' is not installed." -ForegroundColor Yellow
    $install = Read-Host "Would you like to install it now? (Y/N)"
    
    if ($install -eq 'Y' -or $install -eq 'y') {
        try {
            Write-Host "Installing $requiredModule..." -ForegroundColor Cyan
            Install-Module -Name $requiredModule -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
            Write-Host "$requiredModule installed successfully.`n" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to install $requiredModule. Error: $_" -ForegroundColor Red
            exit
        }
    }
    else {
        Write-Host "Module installation declined. Script cannot continue." -ForegroundColor Red
        exit
    }
}

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan

try {
    $scopes = @("User.Read.All", "AuditLog.Read.All", "Directory.Read.All")
    Connect-MgGraph -Scopes $scopes -NoWelcome -ErrorAction Stop
    Write-Host "Successfully connected to Microsoft Graph.`n" -ForegroundColor Green
}
catch {
    Write-Host "Failed to connect to Microsoft Graph. Error: $_" -ForegroundColor Red
    exit
}

Write-Host "Retrieving risky sign-ins from Azure AD Identity Protection..." -ForegroundColor Cyan
Write-Host "Date Range: $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))`n" -ForegroundColor Yellow

$results = @()
$highRiskCount = 0
$mediumRiskCount = 0
$lowRiskCount = 0

try {
    # Build filter for risky sign-ins
    $filter = "createdDateTime ge $($StartDate.ToString('yyyy-MM-ddTHH:mm:ssZ')) and createdDateTime le $($EndDate.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
    
    if ($UserPrincipalName) {
        $filter += " and userPrincipalName eq '$UserPrincipalName'"
    }
    
    if ($RiskLevel -ne "All") {
        $filter += " and riskLevel eq '$RiskLevel'"
    }
    
    # Get risky sign-ins using Microsoft Graph
    $riskySignIns = Get-MgRiskySignIn -Filter $filter -All -ErrorAction Stop
    
    if ($riskySignIns.Count -eq 0) {
        Write-Host "No risky sign-ins found for the specified criteria.`n" -ForegroundColor Yellow
    }
    else {
        Write-Host "Found $($riskySignIns.Count) risky sign-in(s). Processing...`n" -ForegroundColor Green
        
        $progressCounter = 0
        
        foreach ($signIn in $riskySignIns) {
            $progressCounter++
            Write-Progress -Activity "Processing Risky Sign-Ins" -Status "Sign-in $progressCounter of $($riskySignIns.Count)" -PercentComplete (($progressCounter / $riskySignIns.Count) * 100)
            
            # Count by risk level
            switch ($signIn.RiskLevel) {
                "high" { $highRiskCount++ }
                "medium" { $mediumRiskCount++ }
                "low" { $lowRiskCount++ }
            }
            
            # Get user details
            $userDisplayName = "N/A"
            try {
                $user = Get-MgUser -UserId $signIn.UserId -ErrorAction SilentlyContinue
                if ($user) {
                    $userDisplayName = $user.DisplayName
                }
            }
            catch {
                # User may not exist or no permission
            }
            
            $obj = [PSCustomObject]@{
                UserPrincipalName = $signIn.UserPrincipalName
                UserDisplayName = $userDisplayName
                RiskLevel = $signIn.RiskLevel
                RiskState = $signIn.RiskState
                RiskDetail = $signIn.RiskDetail
                RiskEventTypes = ($signIn.RiskEventTypes -join ", ")
                CreatedDateTime = $signIn.CreatedDateTime
                LastUpdatedDateTime = $signIn.LastUpdatedDateTime
                IPAddress = $signIn.IpAddress
                Location = "$($signIn.Location.City), $($signIn.Location.CountryOrRegion)"
                IsInteractive = $signIn.IsInteractive
                CorrelationId = $signIn.CorrelationId
                UserId = $signIn.UserId
            }
            
            $results += $obj
        }
        
        Write-Progress -Activity "Processing Risky Sign-Ins" -Completed
    }
}
catch {
    Write-Host "Error retrieving risky sign-ins: $_" -ForegroundColor Red
    Write-Host "Note: This feature requires Azure AD Premium P2 licensing.`n" -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    exit
}

# Export and display results
if ($results.Count -gt 0) {
    Write-Host "`n====================================================================================`n" -ForegroundColor Cyan
    Write-Host "Risky Sign-Ins Report Summary:" -ForegroundColor Green
    Write-Host "  Total Risky Sign-Ins: $($results.Count)" -ForegroundColor White
    Write-Host "  High Risk: $highRiskCount" -ForegroundColor Red
    Write-Host "  Medium Risk: $mediumRiskCount" -ForegroundColor Yellow
    Write-Host "  Low Risk: $lowRiskCount" -ForegroundColor Green
    Write-Host "  Date Range: $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))" -ForegroundColor White
    
    # Group by risk state
    Write-Host "`n  Risk State Breakdown:" -ForegroundColor Cyan
    $results | Group-Object RiskState | ForEach-Object {
        Write-Host "    $($_.Name): $($_.Count)" -ForegroundColor White
    }
    
    # Top risky users
    if ($results.Count -gt 0) {
        Write-Host "`n  Top 5 Users with Risky Sign-Ins:" -ForegroundColor Cyan
        $results | Group-Object UserPrincipalName | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Count) risky sign-in(s)" -ForegroundColor Yellow
        }
    }
    
    $results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    
    Write-Host "`n  Report Location: $ExportPath" -ForegroundColor White
    Write-Host "`n====================================================================================`n" -ForegroundColor Cyan
    
    Write-Host "SECURITY ALERT:" -ForegroundColor Red
    Write-Host "Review high-risk sign-ins immediately and investigate compromised accounts.`n" -ForegroundColor Yellow
    
    Write-Host "Sample Results (First 10):" -ForegroundColor Yellow
    $results | Select-Object -First 10 | Format-Table UserPrincipalName, RiskLevel, RiskState, CreatedDateTime, Location -AutoSize
    
    $openFile = Read-Host "Would you like to open the CSV report? (Y/N)"
    if ($openFile -eq 'Y' -or $openFile -eq 'y') {
        Invoke-Item $ExportPath
    }
}
else {
    Write-Host "No risky sign-ins found matching the specified criteria." -ForegroundColor Green
    Write-Host "Date Range: $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))" -ForegroundColor White
    if ($RiskLevel -ne "All") {
        Write-Host "Risk Level Filter: $RiskLevel" -ForegroundColor White
    }
    if ($UserPrincipalName) {
        Write-Host "User Filter: $UserPrincipalName" -ForegroundColor White
    }
}

# Cleanup
Write-Host "Disconnecting from Microsoft Graph..." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
Write-Host "Script completed successfully.`n" -ForegroundColor Green
