<#
.SYNOPSIS
    Disables the Access Policy for a Cloudflare Pages project.

.DESCRIPTION
    This script disables Cloudflare Access protection for a specific Pages project,
    making it publicly accessible. The script can either disable the existing policy
    or remove it entirely based on the specified action.

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
    Action to perform: 'Disable' (keeps policy but disables it) or 'Remove' (deletes the policy).
    Default: Disable

.PARAMETER MaxRetries
    Maximum number of retry attempts on errors.
    Default: 5

.EXAMPLE
    .\cf-pages-disable-access-policy.ps1 -ApiToken "xxx" -AccountId "xxx" -ProjectName "my-project"
    
    Disables the Access Policy for the specified project.

.EXAMPLE
    .\cf-pages-disable-access-policy.ps1 -ApiToken "xxx" -AccountId "xxx" -ProjectName "my-project" -Action Remove
    
    Removes the Access Policy completely from the specified project.

.EXAMPLE
    .\cf-pages-disable-access-policy.ps1 -ApiToken "xxx" -AccountId "xxx" -ProjectName "my-project" -Verbose
    
    Disables the Access Policy with detailed verbose output.

.NOTES
    Filename:   cf-pages-disable-access-policy.ps1
    Author:     Created for Cloudflare Pages Management
    Version:    1.0.0
    Date:       2025-10-20
    
    Required Permissions:
    - Cloudflare API Token with "Cloudflare Pages:Edit" permission
    - Cloudflare API Token with "Access:Edit" permission (if using Access policies)
    - Access to the specific account and Pages project

.LINK
    https://developers.cloudflare.com/api/operations/pages-project-get-project
    https://developers.cloudflare.com/api/operations/pages-project-update-project
    https://developers.cloudflare.com/pages/configuration/preview-deployments/#customize-preview-deployments-access
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
    Disables the Access Policy for the project.
#>
function Disable-AccessPolicy {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [object]$ProjectConfig
    )

    Write-Host "`nDisabling Access Policy..." -ForegroundColor Yellow

    # Check current deployment configuration
    $currentConfig = $ProjectConfig.deployment_configs
    
    if (-not $currentConfig) {
        Write-Host "✓ No deployment configuration found. Project is already publicly accessible." -ForegroundColor Green
        return $false
    }

    # Check if Access is currently enabled
    $productionAccessEnabled = $currentConfig.production.compatibility_flags -contains "access_enabled" -or 
                                $currentConfig.production.access_policy_enabled -eq $true
    $previewAccessEnabled = $currentConfig.preview.compatibility_flags -contains "access_enabled" -or 
                             $currentConfig.preview.access_policy_enabled -eq $true

    if (-not $productionAccessEnabled -and -not $previewAccessEnabled) {
        Write-Host "✓ Access Policy is already disabled for this project." -ForegroundColor Green
        return $false
    }

    # Prepare updated configuration
    $updateBody = @{
        deployment_configs = @{
            production = @{
                compatibility_flags = @()
            }
            preview = @{
                compatibility_flags = @()
            }
        }
    }

    # Preserve existing compatibility flags except access-related ones
    if ($currentConfig.production.compatibility_flags) {
        $updateBody.deployment_configs.production.compatibility_flags = 
            $currentConfig.production.compatibility_flags | Where-Object { $_ -ne "access_enabled" }
    }

    if ($currentConfig.preview.compatibility_flags) {
        $updateBody.deployment_configs.preview.compatibility_flags = 
            $currentConfig.preview.compatibility_flags | Where-Object { $_ -ne "access_enabled" }
    }

    # Update the project
    $uri = "$Script:BaseUrl/accounts/$AccountId/pages/projects/$ProjectName"
    
    if ($PSCmdlet.ShouldProcess($ProjectName, "Disable Access Policy")) {
        try {
            $null = Invoke-CloudflareApiWithRetry `
                -Uri $uri `
                -Method 'PATCH' `
                -Body $updateBody `
                -ErrorContext "Disabling Access Policy"

            Write-Host "✓ Access Policy disabled successfully!" -ForegroundColor Green
            
            if ($productionAccessEnabled) {
                Write-Host "  - Production deployments are now publicly accessible" -ForegroundColor Cyan
            }
            if ($previewAccessEnabled) {
                Write-Host "  - Preview deployments are now publicly accessible" -ForegroundColor Cyan
            }
            
            return $true
        }
        catch {
            Write-Error "Failed to disable Access Policy: $_"
            throw
        }
    }

    return $false
}

<#
.SYNOPSIS
    Removes the Access Policy completely from the project.
#>
function Remove-AccessPolicy {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [object]$ProjectConfig
    )

    Write-Host "`nRemoving Access Policy configuration..." -ForegroundColor Yellow

    # Prepare minimal configuration (removes all Access-related settings)
    $updateBody = @{
        deployment_configs = @{
            production = @{}
            preview = @{}
        }
    }

    # Update the project
    $uri = "$Script:BaseUrl/accounts/$AccountId/pages/projects/$ProjectName"
    
    if ($PSCmdlet.ShouldProcess($ProjectName, "Remove Access Policy")) {
        try {
            $null = Invoke-CloudflareApiWithRetry `
                -Uri $uri `
                -Method 'PATCH' `
                -Body $updateBody `
                -ErrorContext "Removing Access Policy"

            Write-Host "✓ Access Policy removed successfully!" -ForegroundColor Green
            Write-Host "  - All Access-related configuration has been cleared" -ForegroundColor Cyan
            
            return $true
        }
        catch {
            Write-Error "Failed to remove Access Policy: $_"
            throw
        }
    }

    return $false
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
            $changed = Disable-AccessPolicy -ProjectConfig $projectConfig
        }
        'Remove' {
            $changed = Remove-AccessPolicy -ProjectConfig $projectConfig
        }
    }

    if ($changed) {
        Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host "  ✓ Access Policy $Action completed!" -ForegroundColor Green
        Write-Host "  Your Pages project is now publicly accessible" -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
    } else {
        Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "  ℹ No changes were made" -ForegroundColor Yellow
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
