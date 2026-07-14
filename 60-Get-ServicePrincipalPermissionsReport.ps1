<#
.SYNOPSIS
    Generates a report of application (app role) and delegated (OAuth2) permission grants
    held by service principals in Microsoft Entra ID (Azure AD).

.DESCRIPTION
    Connects to Microsoft Graph and enumerates all service principals in the tenant.
    For each service principal it collects:
      - Application permissions granted to it via app role assignments
        (Get-MgServicePrincipalAppRoleAssignment).
      - Delegated permissions granted to it via OAuth2 permission grants
        (Get-MgOauth2PermissionGrant).
    Each granted permission is emitted as one row and the combined result set is
    exported to a timestamped CSV file. Service principals that have no permission
    grants produce no rows.

    Errors encountered while processing an individual service principal are reported
    and skipped so that one problematic object does not abort the entire report.

.PARAMETER ExportPath
    Path to the CSV file that will be created. Defaults to a timestamped file name
    in the current directory (Report_60_yyyyMMdd_HHmmss.csv).

.EXAMPLE
    .\60-Get-ServicePrincipalPermissionsReport.ps1
    Generates the report using the default timestamped output path.

.EXAMPLE
    .\60-Get-ServicePrincipalPermissionsReport.ps1 -ExportPath 'C:\Reports\SPPerms.csv'
    Generates the report and writes it to the specified path.

.NOTES
    Author:        Ryan Adams
    Version:       3.0
    Last Updated:  2026-07-13
    Requires:      Microsoft.Graph.Applications, Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Authentication
    Permissions:   Application.Read.All, Directory.Read.All (delegated, admin-consented)

.OUTPUTS
    None. This script writes a CSV file to disk and displays progress to the host.
#>

#Requires -Version 5.1

[CmdletBinding()]
param([string]$ExportPath = ".\Report_60_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv")

Write-Host "`n================================================================================`n" -ForegroundColor Cyan
Write-Host "Service Principal Permissions Report" -ForegroundColor Green
Write-Host "================================================================================`n" -ForegroundColor Cyan

# Ensure the required Microsoft Graph modules are available
$requiredModules = @('Microsoft.Graph.Applications','Microsoft.Graph.Identity.SignIns','Microsoft.Graph.Authentication')
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
    Connect-MgGraph -Scopes "Application.Read.All","Directory.Read.All" -NoWelcome -ErrorAction Stop
    Write-Host "Connected.`n" -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
    exit
}

Write-Host "Retrieving service principals..." -ForegroundColor Cyan
$script:Results = @()

try {
    $servicePrincipals = Get-MgServicePrincipal -All -ErrorAction Stop
    Write-Host "Found $($servicePrincipals.Count) service principal(s). Evaluating permission grants...`n" -ForegroundColor Green

    # Cache resource service principals (the API/resource being granted access to)
    # so we can resolve app role and scope names without repeated lookups.
    $resourceCache = @{}
    function Get-ResourceSp {
        param([string]$ResourceId)
        if ([string]::IsNullOrEmpty($ResourceId)) { return $null }
        if ($resourceCache.ContainsKey($ResourceId)) { return $resourceCache[$ResourceId] }
        try {
            $sp = Get-MgServicePrincipal -ServicePrincipalId $ResourceId -ErrorAction Stop
        } catch {
            $sp = $null
        }
        $resourceCache[$ResourceId] = $sp
        return $sp
    }

    $total = $servicePrincipals.Count
    $index = 0
    foreach ($sp in $servicePrincipals) {
        $index++
        Write-Progress -Activity "Evaluating service principal permissions" -Status "$($sp.DisplayName) ($index of $total)" -PercentComplete (($index / [math]::Max($total,1)) * 100)

        try {
            # --- Application permissions (app role assignments) ---
            $appRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction Stop
            foreach ($assignment in $appRoleAssignments) {
                $resourceSp = Get-ResourceSp -ResourceId $assignment.ResourceId
                $permissionValue = $null
                if ($resourceSp) {
                    $role = $resourceSp.AppRoles | Where-Object { $_.Id -eq $assignment.AppRoleId }
                    if ($role) { $permissionValue = $role.Value }
                }

                $script:Results += [PSCustomObject]@{
                    ServicePrincipalDisplayName = $sp.DisplayName
                    ServicePrincipalId          = $sp.Id
                    AppId                       = $sp.AppId
                    ServicePrincipalType        = $sp.ServicePrincipalType
                    PermissionType              = 'Application'
                    ResourceDisplayName         = $assignment.ResourceDisplayName
                    ResourceId                  = $assignment.ResourceId
                    Permission                  = $permissionValue
                    ConsentType                 = 'AdminConsent'
                    PrincipalId                 = $null
                    GrantId                     = $assignment.Id
                }
            }

            # --- Delegated permissions (OAuth2 permission grants) ---
            $oauthGrants = Get-MgOauth2PermissionGrant -Filter "clientId eq '$($sp.Id)'" -All -ErrorAction Stop
            foreach ($grant in $oauthGrants) {
                $resourceSp = Get-ResourceSp -ResourceId $grant.ResourceId
                $resourceName = if ($resourceSp) { $resourceSp.DisplayName } else { $null }
                $scopes = @()
                if (-not [string]::IsNullOrWhiteSpace($grant.Scope)) {
                    $scopes = $grant.Scope.Trim() -split '\s+'
                }
                foreach ($scope in $scopes) {
                    $script:Results += [PSCustomObject]@{
                        ServicePrincipalDisplayName = $sp.DisplayName
                        ServicePrincipalId          = $sp.Id
                        AppId                       = $sp.AppId
                        ServicePrincipalType        = $sp.ServicePrincipalType
                        PermissionType              = 'Delegated'
                        ResourceDisplayName         = $resourceName
                        ResourceId                  = $grant.ResourceId
                        Permission                  = $scope
                        ConsentType                 = $grant.ConsentType
                        PrincipalId                 = $grant.PrincipalId
                        GrantId                     = $grant.Id
                    }
                }
            }
        } catch {
            Write-Warning "Failed to process service principal '$($sp.DisplayName)' ($($sp.Id)): $_"
            continue
        }
    }
    Write-Progress -Activity "Evaluating service principal permissions" -Completed
    Write-Host "Permission grant evaluation complete.`n" -ForegroundColor Green
} catch {
    Write-Host "Error retrieving service principal data: $_" -ForegroundColor Red
    Disconnect-MgGraph | Out-Null
    exit
}

if ($script:Results.Count -gt 0) {
    Write-Host "`n================================================================================`n" -ForegroundColor Cyan
    Write-Host "Summary: $($script:Results.Count) permission grant record(s)" -ForegroundColor Green
    $script:Results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Report: $ExportPath" -ForegroundColor White
    Write-Host "================================================================================`n" -ForegroundColor Cyan
    $script:Results | Format-Table -AutoSize
    $open = Read-Host "Open CSV? (Y/N)"
    if ($open -match '^[Yy]$') { Invoke-Item $ExportPath }
} else {
    Write-Host "No service principal permission grants were found." -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
