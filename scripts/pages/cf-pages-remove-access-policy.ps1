<#
.SYNOPSIS
    Disables or removes Access Policies and Applications for a Cloudflare Pages project.

.DESCRIPTION
    This script manages Cloudflare Access policies for a specific Pages project by:
    - Finding all Access Applications associated with the project
    - Disabling all Access Policies (Disable action) - policies remain but are inactive
    - Removing all Access Applications and Policies completely (Remove action)
    
    The script searches for Access Applications by matching the project name and domain,
    then processes all associated policies and applications accordingly.

.PARAMETER ApiToken
    Cloudflare API Token with the required permissions.
    Required: Yes

.PARAMETER AccountId
    Cloudflare Account ID.
    Required: Yes

.PARAMETER ProjectName
    Name of the Cloudflare Pages project.
    Required: Yes

.PARAMETER Action
    Action to perform:
    - 'Disable': Disables all Access Policies but keeps applications (policies show as disabled in dashboard)
    - 'Remove': Completely removes all Access Applications and their policies
    Default: Disable

.PARAMETER MaxRetries
    Maximum number of retry attempts on errors.
    Default: 5

.EXAMPLE
    .\cf-pages-remove-access-policy.ps1 -ApiToken "xxx" -AccountId "xxx" -ProjectName "my-project"
    
    Disables all Access Policies for the specified project. Policies will show as "Disabled" 
    in the Cloudflare dashboard but applications remain listed.

.EXAMPLE
    .\cf-pages-remove-access-policy.ps1 -ApiToken "xxx" -AccountId "xxx" -ProjectName "my-project" -Action Remove
    
    Completely removes all Access Applications and Policies for the specified project.
    Applications will be removed from the Access Apps list in Cloudflare.

.EXAMPLE
    .\cf-pages-remove-access-policy.ps1 -ApiToken "xxx" -AccountId "xxx" -ProjectName "my-project" -Verbose
    
    Disables Access Policies with detailed verbose output showing all API calls and decisions.

.EXAMPLE
    .\cf-pages-remove-access-policy.ps1 -ApiToken "xxx" -AccountId "xxx" -ProjectName "my-project" -Action Remove -WhatIf
    
    Shows what would be deleted without actually making any changes (dry-run mode).

.NOTES
    Filename:   cf-pages-remove-access-policy.ps1
    Author:     Created for Cloudflare Pages Management
    Version:    2.0.0
    Date:       2025-10-20
    
    Required Permissions:
    - Cloudflare API Token with "Cloudflare Pages:Read" permission
    - Cloudflare API Token with "Access:Edit" permission
    - Access to the specific account and Pages project
    
    Important:
    - The 'Disable' action sets policies to enabled=false (they show as disabled in dashboard)
    - The 'Remove' action completely deletes applications from the Access Apps list
    - Both actions make the Pages project publicly accessible

.LINK
    https://developers.cloudflare.com/api/operations/pages-project-get-project
    https://developers.cloudflare.com/api/operations/access-applications-list-access-applications
    https://developers.cloudflare.com/api/operations/access-policies-update-an-access-policy
    https://developers.cloudflare.com/api/operations/access-applications-delete-an-access-application
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Cloudflare API Token with 'Cloudflare Pages:Edit' permission")]
    [ValidateNotNullOrEmpty()]
    [string]$ApiToken,

    [Parameter(Mandatory = $true, HelpMessage = "Cloudflare Account ID")]
    [ValidateNotNullOrEmpty()]
    [string]$AccountId,

    [Parameter(Mandatory = $true, HelpMessage = "Cloudflare Pages project name")]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName,

    [Parameter(Mandatory = $false, HelpMessage = "Action to perform: Disable (default) or Remove")]
    [ValidateSet('Disable', 'Remove')]
    [string]$Action = 'Disable',

    [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retry attempts")]
    [ValidateRange(1, 20)]
    [int]$MaxRetries = 5
)

# Strict error handling
$ErrorActionPreference = 'Stop'

# Constants
$Script:BaseUrl = "https://api.cloudflare.com/client/v4"

# HTTP headers for API calls
$Script:Headers = @{
    'Authorization' = "Bearer $ApiToken"
    'Content-Type'  = 'application/json'
}

<#
.SYNOPSIS
    Executes an HTTP request with exponential backoff retry.
#>
function Invoke-CloudflareApiWithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $false)]
        [string]$Method = 'GET',

        [Parameter(Mandatory = $false)]
        [object]$Body = $null,

        [Parameter(Mandatory = $false)]
        [int]$MaxAttempts = $MaxRetries,

        [Parameter(Mandatory = $false)]
        [string]$ErrorContext = "API call"
    )

    $attempt = 1
    $delay = 1000 # Starting delay in milliseconds

    while ($attempt -le $MaxAttempts) {
        try {
            $params = @{
                Uri         = $Uri
                Method      = $Method
                Headers     = $Script:Headers
                ErrorAction = 'Stop'
            }

            if ($Body) {
                if ($Body -is [string]) {
                    $params['Body'] = $Body
                } else {
                    $params['Body'] = ($Body | ConvertTo-Json -Depth 10)
                }
            }

            $response = Invoke-RestMethod @params
            
            if ($response.success -eq $false) {
                $errorMessage = if ($response.errors -and $response.errors.Count -gt 0) {
                    $response.errors[0].message
                } else {
                    "Unknown API error"
                }
                throw $errorMessage
            }

            return $response
        }
        catch {
            if ($attempt -eq $MaxAttempts) {
                Write-Error "$ErrorContext failed after $MaxAttempts attempts: $_"
                throw
            }

            Write-Warning "$ErrorContext failed (attempt $attempt/$MaxAttempts). Retrying in $($delay/1000) seconds..."
            Start-Sleep -Milliseconds $delay
            
            # Exponential backoff
            $delay = $delay * 2
            $attempt++
        }
    }
}

<#
.SYNOPSIS
    Gets the current project configuration.
#>
function Get-ProjectConfiguration {
    Write-Verbose "Retrieving project configuration for '$ProjectName'..."
    
    $uri = "$Script:BaseUrl/accounts/$AccountId/pages/projects/$ProjectName"
    $response = Invoke-CloudflareApiWithRetry -Uri $uri -ErrorContext "Retrieving project configuration"

    if ($response.result) {
        Write-Verbose "Project configuration retrieved successfully."
        return $response.result
    }

    throw "Project '$ProjectName' not found or inaccessible."
}

<#
.SYNOPSIS
    Gets all Access Applications.
#>
function Get-AccessApplications {
    Write-Verbose "Retrieving Access Applications..."
    
    $uri = "$Script:BaseUrl/accounts/$AccountId/access/apps"
    $response = Invoke-CloudflareApiWithRetry -Uri $uri -ErrorContext "Retrieving Access Applications"

    if ($response.result) {
        Write-Verbose "Found $($response.result.Count) Access Applications."
        return $response.result
    }

    return @()
}

<#
.SYNOPSIS
    Gets all Access Policies for a specific application.
#>
function Get-AccessPolicies {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApplicationId
    )

    Write-Verbose "Retrieving Access Policies for application '$ApplicationId'..."
    
    $uri = "$Script:BaseUrl/accounts/$AccountId/access/apps/$ApplicationId/policies"
    
    try {
        $response = Invoke-CloudflareApiWithRetry -Uri $uri -ErrorContext "Retrieving Access Policies"
        
        if ($response.result) {
            Write-Verbose "Found $($response.result.Count) Access Policies."
            return $response.result
        }
    }
    catch {
        Write-Verbose "Could not retrieve policies for application: $_"
    }

    return @()
}

<#
.SYNOPSIS
    Updates an Access Policy to disable it.
#>
function Update-AccessPolicy {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApplicationId,

        [Parameter(Mandatory = $true)]
        [object]$Policy
    )

    $uri = "$Script:BaseUrl/accounts/$AccountId/access/apps/$ApplicationId/policies/$($Policy.id)"
    
    # Create updated policy with enabled = false
    $updateBody = @{
        name = $Policy.name
        decision = $Policy.decision
        include = $Policy.include
        enabled = $false
    }

    # Add optional fields if they exist
    if ($Policy.exclude) { $updateBody.exclude = $Policy.exclude }
    if ($Policy.require) { $updateBody.require = $Policy.require }
    if ($Policy.precedence) { $updateBody.precedence = $Policy.precedence }

    if ($PSCmdlet.ShouldProcess("Policy: $($Policy.name)", "Disable Access Policy")) {
        try {
            $null = Invoke-CloudflareApiWithRetry `
                -Uri $uri `
                -Method 'PUT' `
                -Body $updateBody `
                -ErrorContext "Disabling Access Policy '$($Policy.name)'"

            Write-Host "  ✓ Policy disabled: $($Policy.name)" -ForegroundColor Cyan
            return $true
        }
        catch {
            Write-Warning "Failed to disable policy '$($Policy.name)': $_"
            return $false
        }
    }

    return $false
}

<#
.SYNOPSIS
    Deletes an Access Policy.
#>
function Remove-AccessPolicyItem {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApplicationId,

        [Parameter(Mandatory = $true)]
        [object]$Policy
    )

    $uri = "$Script:BaseUrl/accounts/$AccountId/access/apps/$ApplicationId/policies/$($Policy.id)"
    
    if ($PSCmdlet.ShouldProcess("Policy: $($Policy.name)", "Delete Access Policy")) {
        try {
            $null = Invoke-CloudflareApiWithRetry `
                -Uri $uri `
                -Method 'DELETE' `
                -ErrorContext "Deleting Access Policy '$($Policy.name)'"

            Write-Host "  ✓ Policy deleted: $($Policy.name)" -ForegroundColor Cyan
            return $true
        }
        catch {
            Write-Warning "Failed to delete policy '$($Policy.name)': $_"
            return $false
        }
    }

    return $false
}

<#
.SYNOPSIS
    Deletes an Access Application.
#>
function Remove-AccessApplication {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApplicationId,

        [Parameter(Mandatory = $true)]
        [string]$ApplicationName
    )

    $uri = "$Script:BaseUrl/accounts/$AccountId/access/apps/$ApplicationId"
    
    if ($PSCmdlet.ShouldProcess("Application: $ApplicationName", "Delete Access Application")) {
        try {
            $null = Invoke-CloudflareApiWithRetry `
                -Uri $uri `
                -Method 'DELETE' `
                -ErrorContext "Deleting Access Application '$ApplicationName'"

            Write-Host "✓ Access Application deleted: $ApplicationName" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Warning "Failed to delete Access Application '$ApplicationName': $_"
            return $false
        }
    }

    return $false
}

<#
.SYNOPSIS
    Disables all Access Policies for the project.
#>
function Disable-AccessPoliciesForProject {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [object]$ProjectConfig
    )

    Write-Host "`nSearching for Access Applications related to '$ProjectName'..." -ForegroundColor Yellow

    # Get all Access Applications
    $allApps = Get-AccessApplications

    if ($allApps.Count -eq 0) {
        Write-Host "✓ No Access Applications found in account." -ForegroundColor Green
        return $false
    }

    # Find applications related to this Pages project
    $projectDomain = "$($ProjectConfig.subdomain).pages.dev"
    $relatedApps = $allApps | Where-Object { 
        $_.domain -like "*$projectDomain*" -or 
        $_.name -like "*$ProjectName*"
    }

    if ($relatedApps.Count -eq 0) {
        Write-Host "✓ No Access Applications found for project '$ProjectName'." -ForegroundColor Green
        return $false
    }

    Write-Host "Found $($relatedApps.Count) Access Application(s) for project:" -ForegroundColor Cyan
    foreach ($app in $relatedApps) {
        Write-Host "  - $($app.name) (Domain: $($app.domain))" -ForegroundColor White
    }

    $changed = $false

    foreach ($app in $relatedApps) {
        Write-Host "`nProcessing Access Application: $($app.name)" -ForegroundColor Yellow

        # Get policies for this application
        $policies = Get-AccessPolicies -ApplicationId $app.id

        if ($policies.Count -eq 0) {
            Write-Host "  No policies found for this application." -ForegroundColor Gray
            continue
        }

        Write-Host "  Found $($policies.Count) Access Policy/Policies:" -ForegroundColor Cyan

        foreach ($policy in $policies) {
            $status = if ($policy.enabled) { "Enabled" } else { "Disabled" }
            Write-Host "    - $($policy.name) [$status]" -ForegroundColor White

            if ($policy.enabled) {
                $result = Update-AccessPolicy -ApplicationId $app.id -Policy $policy
                if ($result) {
                    $changed = $true
                }
            }
            else {
                Write-Host "    ○ Policy is already disabled" -ForegroundColor DarkGray
            }
        }
    }

    return $changed
}

<#
.SYNOPSIS
    Removes all Access Policies and Applications for the project.
#>
function Remove-AccessPoliciesForProject {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [object]$ProjectConfig
    )

    Write-Host "`nSearching for Access Applications related to '$ProjectName'..." -ForegroundColor Yellow

    # Get all Access Applications
    $allApps = Get-AccessApplications

    if ($allApps.Count -eq 0) {
        Write-Host "✓ No Access Applications found in account." -ForegroundColor Green
        return $false
    }

    # Find applications related to this Pages project
    $projectDomain = "$($ProjectConfig.subdomain).pages.dev"
    $relatedApps = $allApps | Where-Object { 
        $_.domain -like "*$projectDomain*" -or 
        $_.name -like "*$ProjectName*"
    }

    if ($relatedApps.Count -eq 0) {
        Write-Host "✓ No Access Applications found for project '$ProjectName'." -ForegroundColor Green
        return $false
    }

    Write-Host "Found $($relatedApps.Count) Access Application(s) for project:" -ForegroundColor Cyan
    foreach ($app in $relatedApps) {
        Write-Host "  - $($app.name) (Domain: $($app.domain))" -ForegroundColor White
    }

    $changed = $false

    foreach ($app in $relatedApps) {
        Write-Host "`nProcessing Access Application: $($app.name)" -ForegroundColor Yellow

        # Get policies for this application
        $policies = Get-AccessPolicies -ApplicationId $app.id

        if ($policies.Count -gt 0) {
            Write-Host "  Deleting $($policies.Count) Access Policy/Policies..." -ForegroundColor Cyan

            foreach ($policy in $policies) {
                $result = Remove-AccessPolicyItem -ApplicationId $app.id -Policy $policy
                if ($result) {
                    $changed = $true
                }
            }
        }

        # Delete the Access Application itself
        Write-Host "  Deleting Access Application..." -ForegroundColor Yellow
        $result = Remove-AccessApplication -ApplicationId $app.id -ApplicationName $app.name
        if ($result) {
            $changed = $true
        }
    }

    return $changed
}

<#
.SYNOPSIS
    Main function to manage Access Policy.
#>
function Start-AccessPolicyManagement {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "  Cloudflare Pages Access Policy Management" -ForegroundColor Blue
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "Project:         $ProjectName" -ForegroundColor White
    Write-Host "Account ID:      $AccountId" -ForegroundColor White
    Write-Host "Action:          $Action" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Blue

    # Get current project configuration
    $projectConfig = Get-ProjectConfiguration

    Write-Host "Current project status:" -ForegroundColor Cyan
    Write-Host "  Name:              $($projectConfig.name)" -ForegroundColor White
    Write-Host "  Created:           $($projectConfig.created_on)" -ForegroundColor White
    Write-Host "  Subdomain:         $($projectConfig.subdomain)" -ForegroundColor White
    Write-Host "  Production URL:    https://$($projectConfig.subdomain).pages.dev" -ForegroundColor White

    # Perform the requested action
    $changed = $false
    switch ($Action) {
        'Disable' {
            $changed = Disable-AccessPoliciesForProject -ProjectConfig $projectConfig
        }
        'Remove' {
            $changed = Remove-AccessPoliciesForProject -ProjectConfig $projectConfig
        }
    }

    if ($changed) {
        Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host "  ✓ Access Policy management completed!" -ForegroundColor Green
        
        if ($Action -eq 'Disable') {
            Write-Host "  All Access Policies have been disabled" -ForegroundColor Green
            Write-Host "  Note: Applications still exist but policies are inactive" -ForegroundColor Yellow
        }
        else {
            Write-Host "  All Access Applications and Policies have been removed" -ForegroundColor Green
            Write-Host "  Your Pages project is now publicly accessible" -ForegroundColor Green
        }
        
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
    } else {
        Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "  ℹ No changes were made" -ForegroundColor Yellow
        Write-Host "  Either no Access configuration exists or it's already in the desired state" -ForegroundColor Yellow
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
    }
}

# Execute script
try {
    Start-AccessPolicyManagement
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}
