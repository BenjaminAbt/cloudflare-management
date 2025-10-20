<#
.SYNOPSIS
    Deletes all Cloudflare Pages deployments for a specific project.

.DESCRIPTION
    This script deletes all deployments of a Cloudflare Pages project, 
    except for the live production deployment. Optionally, aliased deployments 
    (e.g., my-branch.exampleproj.pages.dev) can also be deleted.

.PARAMETER ApiToken
    Cloudflare API Token with the required permissions.
    Required: Yes

.PARAMETER AccountId
    Cloudflare Account ID.
    Required: Yes

.PARAMETER ProjectName
    Name of the Cloudflare Pages project.
    Required: Yes

.PARAMETER DeleteAliasedDeployments
    If set, aliased deployments (branch deployments) will also be deleted.
    Default: False

.PARAMETER DeploymentsPerPage
    Number of deployments per API request.
    Default: 10

.PARAMETER PaginationBatchSize
    Number of parallel page requests.
    Default: 3

.PARAMETER MaxRetries
    Maximum number of retry attempts on errors.
    Default: 5

.EXAMPLE
    .\Delete-CloudflareDeployments.ps1 -ApiToken "xxx" -AccountId "xxx" -ProjectName "my-project"
    
    Deletes all deployments (except production) without aliased deployments.

.EXAMPLE
    .\Delete-CloudflareDeployments.ps1 -ApiToken "xxx" -AccountId "xxx" -ProjectName "my-project" -DeleteAliasedDeployments
    
    Deletes all deployments including aliased deployments.

.EXAMPLE
    .\Delete-CloudflareDeployments.ps1 -ApiToken "xxx" -AccountId "xxx" -ProjectName "my-project" -DeploymentsPerPage 20 -MaxRetries 10
    
    Deletes deployments with custom pagination and retry settings.

.NOTES
    Filename:   Delete-CloudflareDeployments.ps1
    Author:     Migrated from Node.js to PowerShell
    Version:    2.0.0
    Date:       2025-10-20
    
    Required Permissions:
    - Cloudflare API Token with "Cloudflare Pages:Edit" permission
    - Access to the specific account and Pages project

.LINK
    https://developers.cloudflare.com/api/operations/pages-deployment-delete-deployment
    https://developers.cloudflare.com/api/operations/pages-project-get-project
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

    [Parameter(Mandatory = $false, HelpMessage = "Delete aliased deployments (branch deployments)")]
    [switch]$DeleteAliasedDeployments,

    [Parameter(Mandatory = $false, HelpMessage = "Number of deployments per API request")]
    [ValidateRange(1, 100)]
    [int]$DeploymentsPerPage = 10,

    [Parameter(Mandatory = $false, HelpMessage = "Number of parallel page requests")]
    [ValidateRange(1, 10)]
    [int]$PaginationBatchSize = 3,

    [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retry attempts")]
    [ValidateRange(1, 20)]
    [int]$MaxRetries = 5
)

# Strict error handling
$ErrorActionPreference = 'Stop'

# Constants
$Script:BatchMaxResults = $PaginationBatchSize * $DeploymentsPerPage
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
        [hashtable]$Body = $null,

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
                $params['Body'] = ($Body | ConvertTo-Json -Depth 10)
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
    Gets the production deployment ID.
#>
function Get-ProductionDeploymentId {
    Write-Verbose "Retrieving production deployment ID..."
    
    $uri = "$Script:BaseUrl/accounts/$AccountId/pages/projects/$ProjectName"
    $response = Invoke-CloudflareApiWithRetry -Uri $uri -ErrorContext "Retrieving project information"

    $prodDeploymentId = $response.result.canonical_deployment.id
    
    if ($prodDeploymentId) {
        Write-Host "Production deployment found (will not be deleted): $prodDeploymentId" -ForegroundColor Green
        return $prodDeploymentId
    }

    Write-Verbose "No production deployment found."
    return $null
}

<#
.SYNOPSIS
    Deletes a single deployment.
#>
function Remove-Deployment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DeploymentId
    )

    $params = if ($DeleteAliasedDeployments) { "?force=true" } else { "" }
    $uri = "$Script:BaseUrl/accounts/$AccountId/pages/projects/$ProjectName/deployments/$DeploymentId$params"

    try {
        $null = Invoke-CloudflareApiWithRetry -Uri $uri -Method 'DELETE' -ErrorContext "Deleting deployment $DeploymentId"
        Write-Host "✓ Deployment deleted: $DeploymentId" -ForegroundColor Cyan
        Start-Sleep -Milliseconds 500
    }
    catch {
        Write-Warning "Error deleting deployment ${DeploymentId}: $_"
    }
}

<#
.SYNOPSIS
    Lists deployments for a specific page.
#>
function Get-DeploymentsPage {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Page
    )

    $uri = "$Script:BaseUrl/accounts/$AccountId/pages/projects/$ProjectName/deployments?per_page=$DeploymentsPerPage&page=$Page"
    $response = Invoke-CloudflareApiWithRetry -Uri $uri -ErrorContext "Retrieving deployments (page $Page)"

    if ($response.result -and $response.result.Count -gt 0) {
        $totalFound = ($Page - 1) * $DeploymentsPerPage + $response.result.Count
        Write-Verbose "Deployments retrieved: $totalFound deployments found"
    }

    return $response.result
}

<#
.SYNOPSIS
    Lists the next batch of deployments.
#>
function Get-NextDeploymentBatch {
    Write-Host "`nRetrieving next $Script:BatchMaxResults deployments..." -ForegroundColor Yellow
    
    $page = 1
    $deploymentIds = @()

    while ($true) {
        try {
            $result = Get-DeploymentsPage -Page $page

            foreach ($deployment in $result) {
                $deploymentIds += $deployment.id
            }

            $shouldContinue = $result.Count -gt 0 -and ($Script:BatchMaxResults -gt ($page * $DeploymentsPerPage))

            if ($shouldContinue) {
                $page++
                Start-Sleep -Milliseconds 500
            }
            else {
                Write-Host "→ $($deploymentIds.Count) deployments found in this batch" -ForegroundColor Yellow
                return $deploymentIds
            }
        }
        catch {
            Write-Error "Error retrieving deployments on page ${Page}: $_"
            throw
        }
    }
}

<#
.SYNOPSIS
    Deletes a batch of deployments.
#>
function Remove-DeploymentBatch {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$DeploymentIds,

        [Parameter(Mandatory = $false)]
        [string]$ProductionDeploymentId
    )

    $deletedCount = 0
    $skippedCount = 0

    foreach ($id in $DeploymentIds) {
        if ($ProductionDeploymentId -and $id -eq $ProductionDeploymentId) {
            Write-Host "○ Production deployment skipped: $id" -ForegroundColor DarkGray
            $skippedCount++
        }
        else {
            Remove-Deployment -DeploymentId $id
            $deletedCount++
        }
    }

    Write-Host "`nBatch summary: $deletedCount deleted, $skippedCount skipped" -ForegroundColor Magenta
}

<#
.SYNOPSIS
    Main function to delete all deployments.
#>
function Start-DeploymentCleanup {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "  Cloudflare Pages Deployment Cleanup" -ForegroundColor Blue
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "Project:         $ProjectName" -ForegroundColor White
    Write-Host "Account ID:      $AccountId" -ForegroundColor White
    Write-Host "Delete aliased:  $DeleteAliasedDeployments" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Blue

    # Retrieve production deployment
    $productionDeploymentId = Get-ProductionDeploymentId

    # Process deployments in batches
    $totalDeleted = 0
    $iteration = 1

    do {
        Write-Host "`n--- Iteration $iteration ---" -ForegroundColor Blue
        
        $deploymentIds = Get-NextDeploymentBatch

        # If only 1 deployment remains (the production deployment), stop
        if ($deploymentIds.Count -le 1 -and $productionDeploymentId) {
            Write-Host "`n✓ All deployments deleted! Only the production deployment remains." -ForegroundColor Green
            break
        }

        if ($deploymentIds.Count -eq 0) {
            Write-Host "`n✓ No more deployments to delete." -ForegroundColor Green
            break
        }

        Remove-DeploymentBatch -DeploymentIds $deploymentIds -ProductionDeploymentId $productionDeploymentId
        
        $batchDeleteCount = $deploymentIds.Count
        if ($productionDeploymentId -and $deploymentIds -contains $productionDeploymentId) {
            $batchDeleteCount--
        }
        $totalDeleted += $batchDeleteCount

        $iteration++
        Start-Sleep -Milliseconds 1000

    } while ($deploymentIds.Count -gt 1 -or ($deploymentIds.Count -eq 1 -and -not $productionDeploymentId))

    Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  ✓ Cleanup completed!" -ForegroundColor Green
    Write-Host "  Total deployments deleted: $totalDeleted" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
}

# Execute script
try {
    Start-DeploymentCleanup
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}
