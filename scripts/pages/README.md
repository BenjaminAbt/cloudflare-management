# Cloudflare Pages Scripts

PowerShell scripts for managing Cloudflare Pages projects, deployments, and related resources.

## 📋 Overview

This directory contains scripts to automate Cloudflare Pages management tasks, including bulk deployment cleanup, project configuration, and deployment lifecycle management.

## Delete Cloudflare Pages Deployments

File: `cf-pages-delete-deployments.ps1`

Bulk deletion tool for Cloudflare Pages deployments with intelligent safety features.

**Purpose**: Clean up old or unnecessary deployments while protecting your production environment.

### Key Features

- ✅ **Production Protection**: Automatically identifies and preserves production deployments
- ✅ **Batch Processing**: Efficiently handles large numbers of deployments with pagination
- ✅ **Retry Logic**: Built-in exponential backoff for API reliability
- ✅ **Aliased Deployments**: Optional deletion of branch preview deployments
- ✅ **Progress Tracking**: Real-time feedback on deletion progress
- ✅ **Comprehensive Logging**: Detailed output for auditing and troubleshooting

### Usage

#### Basic Usage

Delete all non-production deployments:

```powershell
.\cf-pages-delete-deployments.ps1 `
    -ApiToken "your-cloudflare-api-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-pages-project"
```

#### Delete Including Aliased Deployments

Remove branch preview deployments (e.g., `feature-branch.project.pages.dev`):

```powershell
.\cf-pages-delete-deployments.ps1 `
    -ApiToken "your-cloudflare-api-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-pages-project" `
    -DeleteAliasedDeployments
```

#### Custom Pagination and Retry Settings

For large projects or unreliable connections:

```powershell
.\cf-pages-delete-deployments.ps1 `
    -ApiToken "your-cloudflare-api-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-pages-project" `
    -DeploymentsPerPage 20 `
    -PaginationBatchSize 5 `
    -MaxRetries 10
```

#### Verbose Output

Enable detailed logging for troubleshooting:

```powershell
.\cf-pages-delete-deployments.ps1 `
    -ApiToken "your-cloudflare-api-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-pages-project" `
    -Verbose
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `ApiToken` | String | Yes | - | Cloudflare API Token with 'Cloudflare Pages:Edit' permission |
| `AccountId` | String | Yes | - | Your Cloudflare Account ID |
| `ProjectName` | String | Yes | - | Name of the Cloudflare Pages project |
| `DeleteAliasedDeployments` | Switch | No | False | Include branch preview deployments in deletion |
| `DeploymentsPerPage` | Int | No | 10 | Number of deployments per API request (1-100) |
| `PaginationBatchSize` | Int | No | 3 | Number of parallel page requests (1-10) |
| `MaxRetries` | Int | No | 5 | Maximum retry attempts on errors (1-20) |

### Example Output

Here's what you'll see when running the script:

```
═══════════════════════════════════════════════════════
  Cloudflare Pages Deployment Cleanup
═══════════════════════════════════════════════════════
Project:         my-project
Account ID:      abc123def456789
Delete aliased:  False
═══════════════════════════════════════════════════════

Production deployment found (will not be deleted): a1b2c3d4-e5f6-7890-abcd-ef1234567890

--- Iteration 1 ---

Retrieving next 30 deployments...
→ 30 deployments found in this batch

✓ Deployment deleted: b2c3d4e5-f6g7-8901-bcde-f12345678901
✓ Deployment deleted: c3d4e5f6-g7h8-9012-cdef-123456789012
.. more here..
✓ Deployment deleted: t0u1v2w3-x4y5-6789-tuvw-890123456789
✓ Deployment deleted: y5z6a7b8-c9d0-1234-yzab-345678901234
✓ Deployment deleted: z6a7b8c9-d0e1-2345-zabc-456789012345
○ Production deployment skipped: a1b2c3d4-e5f6-7890-abcd-ef1234567890
✓ Deployment deleted: d0e1f2g3-h4i5-6789-defg-890123456789

Batch summary: 29 deleted, 1 skipped

--- Iteration 2 ---

Retrieving next 30 deployments...
→ 15 deployments found in this batch

✓ Deployment deleted: e1f2g3h4-i5j6-7890-efgh-901234567890
✓ Deployment deleted: f2g3h4i5-j6k7-8901-fghi-012345678901
.. more here..
✓ Deployment deleted: s5t6u7v8-w9x0-1234-stuv-345678901234

Batch summary: 15 deleted, 0 skipped

--- Iteration 3 ---

Retrieving next 30 deployments...
→ 1 deployments found in this batch

✓ All deployments deleted! Only the production deployment remains.

═══════════════════════════════════════════════════════
  ✓ Cleanup completed!
  Total deployments deleted: 44
═══════════════════════════════════════════════════════
```
