# Cloudflare Pages Scripts

PowerShell scripts for managing Cloudflare Pages projects, deployments, and related resources.

## 📋 Overview

This directory contains scripts to automate Cloudflare Pages management tasks, including bulk deployment cleanup, project configuration, and deployment lifecycle management.

## Delete Cloudflare Pages Deployments

File: `cf-pages-delete-deployments.ps1`

Bulk deletion tool for Cloudflare Pages deployments with intelligent safety features.

**Purpose**: Clean up old or unnecessary deployments while protecting your production environment.

### Authentication

This script requires a Cloudflare API Token with the `Cloudflare Pages:Edit` permission.

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

---

## Disable Cloudflare Pages Access Policy

File: `cf-pages-disable-access-policy.ps1`

Disable or remove Cloudflare Access protection from Pages projects to make them publicly accessible.

**Purpose**: Remove access restrictions from Cloudflare Pages projects, allowing public access to production and preview deployments.

### Authentication

This script requires a Cloudflare API Token with the following permissions:
- `Cloudflare Pages:Edit` permission
- `Access:Edit` permission (if using Access policies)

### Key Features

- ✅ **Safe Configuration**: Preserves other deployment settings
- ✅ **Flexible Actions**: Choose to disable or completely remove Access policies
- ✅ **Current Status Display**: Shows project information before making changes
- ✅ **Retry Logic**: Built-in exponential backoff for API reliability
- ✅ **WhatIf Support**: Test changes before applying with `-WhatIf`
- ✅ **Comprehensive Logging**: Detailed output for auditing

### Usage

#### Basic Usage - Disable Access Policy

Disable the Access Policy (keeps configuration but makes project public):

```powershell
.\cf-pages-disable-access-policy.ps1 `
    -ApiToken "your-cloudflare-api-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-pages-project"
```

#### Remove Access Policy Completely

Remove all Access-related configuration:

```powershell
.\cf-pages-disable-access-policy.ps1 `
    -ApiToken "your-cloudflare-api-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-pages-project" `
    -Action Remove
```

#### Test Changes with WhatIf

Preview what would happen without making actual changes:

```powershell
.\cf-pages-disable-access-policy.ps1 `
    -ApiToken "your-cloudflare-api-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-pages-project" `
    -WhatIf
```

#### Verbose Output

Enable detailed logging:

```powershell
.\cf-pages-disable-access-policy.ps1 `
    -ApiToken "your-cloudflare-api-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-pages-project" `
    -Verbose
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `ApiToken` | String | Yes | - | Cloudflare API Token with required permissions |
| `AccountId` | String | Yes | - | Your Cloudflare Account ID |
| `ProjectName` | String | Yes | - | Name of the Cloudflare Pages project |
| `Action` | String | No | Disable | Action to perform: 'Disable' or 'Remove' |
| `MaxRetries` | Int | No | 5 | Maximum retry attempts on errors (1-20) |

### Example Output

```
═══════════════════════════════════════════════════════
  Cloudflare Pages Access Policy Management
═══════════════════════════════════════════════════════
Project:         my-project
Account ID:      abc123def456789
Action:          Disable
═══════════════════════════════════════════════════════

Current project status:
  Name:              my-project
  Created:           2024-08-15T10:30:00Z
  Subdomain:         my-project
  Production URL:    https://my-project.pages.dev

Disabling Access Policy...
✓ Access Policy disabled successfully!
  - Production deployments are now publicly accessible
  - Preview deployments are now publicly accessible

═══════════════════════════════════════════════════════
  ✓ Access Policy Disable completed!
  Your Pages project is now publicly accessible
═══════════════════════════════════════════════════════
```

### How It Works

```
┌─────────────────────────────────────┐
│  1. Retrieve Project Configuration  │
│     (Get current Access settings)   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  2. Display Current Status          │
│     (Show project info)             │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  3. Check Access Policy Status      │
│     (Is it already disabled?)       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  4. Perform Action                  │
│     (Disable or Remove)             │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  5. Confirm Success                 │
│     (Display result)                │
└─────────────────────────────────────┘
```

### Actions Explained

#### Disable Action (Default)
- Removes access-enabled flags from deployment configurations
- Preserves other compatibility flags and settings
- Makes both production and preview deployments publicly accessible
- Can be reversed by re-enabling Access

#### Remove Action
- Clears all deployment configuration settings
- Removes all Access-related configuration
- Results in default public access settings
- More thorough cleanup than Disable

### Prerequisites

#### 1. Cloudflare API Token

Create an API token with the following permissions:

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/) → **My Profile** → **API Tokens**
2. Click **Create Token**
3. Required Permissions:
   - **Cloudflare Pages:Edit**
   - **Access:Edit** (if using Access policies)
4. Set appropriate Account Resources scope
5. Copy and securely store the token

#### 2. Find Your Account ID

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Select your account
3. Go to **Workers & Pages**
4. Copy the Account ID from the right sidebar or URL

#### 3. Identify Your Project Name

1. Go to **Workers & Pages** in Cloudflare Dashboard
2. Click on the **Pages** tab
3. Find your project name in the list

### Use Cases

#### Make Preview Deployments Public

If preview deployments are behind Access and you want to share them:

```powershell
.\cf-pages-disable-access-policy.ps1 `
    -ApiToken $env:CF_API_TOKEN `
    -AccountId $env:CF_ACCOUNT_ID `
    -ProjectName "my-project"
```

#### Complete Access Removal

Remove all Access configuration before deleting a project:

```powershell
.\cf-pages-disable-access-policy.ps1 `
    -ApiToken $env:CF_API_TOKEN `
    -AccountId $env:CF_ACCOUNT_ID `
    -ProjectName "old-project" `
    -Action Remove
```

#### Batch Processing Multiple Projects

Disable Access for multiple projects:

```powershell
$projects = @("project1", "project2", "project3")

foreach ($project in $projects) {
    .\cf-pages-disable-access-policy.ps1 `
        -ApiToken $env:CF_API_TOKEN `
        -AccountId $env:CF_ACCOUNT_ID `
        -ProjectName $project
}
```

### Error Handling

The script includes robust error handling:

- **Exponential Backoff**: Automatically retries failed API calls
- **API Error Messages**: Displays Cloudflare API error details
- **Configuration Validation**: Checks current status before making changes
- **Connection Issues**: Retries on network timeouts

