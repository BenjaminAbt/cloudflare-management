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

File: `cf-pages-remove-access-policy.ps1`

Disable or remove Cloudflare Access protection from Pages projects to make them publicly accessible.

**Purpose**: Manage Cloudflare Access Applications and Policies for Pages projects by either disabling policies (they remain visible but inactive) or completely removing applications from the Access dashboard.

### Authentication

This script requires a Cloudflare API Token with the following permissions:
- `Cloudflare Pages:Read` permission (to read project information)
- `Access:Edit` permission (to manage Access Applications and Policies)

### Key Features

- ✅ **Automatic Discovery**: Finds all Access Applications related to the Pages project
- ✅ **Policy Management**: Disables or removes Access Policies
- ✅ **Application Management**: Optionally removes Access Applications completely
- ✅ **Flexible Actions**: Choose to disable policies or remove everything
- ✅ **Current Status Display**: Shows all found applications and policies before making changes
- ✅ **Retry Logic**: Built-in exponential backoff for API reliability
- ✅ **WhatIf Support**: Test changes before applying with `-WhatIf`
- ✅ **Comprehensive Logging**: Detailed output for auditing

### How It Works

The script uses the Cloudflare Access API to:

1. **Retrieve the Pages project** configuration to get the subdomain
2. **Search for Access Applications** that match the project (by name or domain)
3. **List all Access Policies** for each found application
4. **Disable or Remove**: 
   - **Disable mode**: Sets each policy's `enabled` property to `false` (policies show as "Disabled" in dashboard)
   - **Remove mode**: Deletes all policies and then removes the Access Application entirely (app disappears from dashboard)

### Usage

#### Basic Usage - Disable Access Policy

Disable the Access Policy (keeps configuration but makes project public):

```powershell
.\cf-pages-remove-access-policy.ps1 `
    -ApiToken "your-cloudflare-api-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-pages-project"
```

#### Remove Access Policy Completely

Remove all Access-related configuration:

```powershell
.\cf-pages-remove-access-policy.ps1 `
    -ApiToken "your-cloudflare-api-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-pages-project" `
    -Action Remove
```

#### Test Changes with WhatIf

Preview what would happen without making actual changes:

```powershell
.\cf-pages-remove-access-policy.ps1 `
    -ApiToken "your-cloudflare-api-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-pages-project" `
    -WhatIf
```

#### Verbose Output

Enable detailed logging:

```powershell
.\cf-pages-remove-access-policy.ps1 `
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
| `Action` | String | No | Disable | Action to perform: 'Disable' (set policies to inactive) or 'Remove' (delete applications) |
| `MaxRetries` | Int | No | 5 | Maximum retry attempts on errors (1-20) |

### Example Output

#### Disable Action Output

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

Searching for Access Applications related to 'my-project'...
Found 1 Access Application(s) for project:
  - my-project (Domain: my-project.pages.dev)

Processing Access Application: my-project
  Found 2 Access Policy/Policies:
    - Allow Team [Enabled]
  ✓ Policy disabled: Allow Team
    - Block External [Enabled]
  ✓ Policy disabled: Block External

═══════════════════════════════════════════════════════
  ✓ Access Policy management completed!
  All Access Policies have been disabled
  Note: Applications still exist but policies are inactive
═══════════════════════════════════════════════════════
```

#### Remove Action Output

```
═══════════════════════════════════════════════════════
  Cloudflare Pages Access Policy Management
═══════════════════════════════════════════════════════
Project:         my-project
Account ID:      abc123def456789
Action:          Remove
═══════════════════════════════════════════════════════

Current project status:
  Name:              my-project
  Created:           2024-08-15T10:30:00Z
  Subdomain:         my-project
  Production URL:    https://my-project.pages.dev

Searching for Access Applications related to 'my-project'...
Found 1 Access Application(s) for project:
  - my-project (Domain: my-project.pages.dev)

Processing Access Application: my-project
  Deleting 2 Access Policy/Policies...
  ✓ Policy deleted: Allow Team
  ✓ Policy deleted: Block External
  Deleting Access Application...
✓ Access Application deleted: my-project

═══════════════════════════════════════════════════════
  ✓ Access Policy management completed!
  All Access Applications and Policies have been removed
  Your Pages project is now publicly accessible
═══════════════════════════════════════════════════════
```

### Workflow Diagram

```
┌─────────────────────────────────────┐
│  1. Retrieve Project Configuration  │
│     (Get subdomain and basic info)  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  2. Search Access Applications      │
│     (Match by domain/name)          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  3. List Found Applications         │
│     (Show all matches)              │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  4. Get Policies for Each App       │
│     (List all policies with status) │
└──────────────┬──────────────────────┘
               │
               ▼
       ┌───────┴───────┐
       │               │
       ▼               ▼
┌─────────────┐ ┌─────────────┐
│   DISABLE   │ │   REMOVE    │
│             │ │             │
│ Set enabled │ │ Delete all  │
│ = false for │ │ policies,   │
│ each policy │ │ then delete │
│             │ │ application │
└─────────────┘ └─────────────┘
       │               │
       └───────┬───────┘
               │
               ▼
┌─────────────────────────────────────┐
│  5. Confirm Success                 │
│     (Display summary)               │
└─────────────────────────────────────┘
```

### Actions Explained

#### Disable Action (Default)
- **Searches** for all Access Applications matching the Pages project
- **Updates** each Access Policy to set `enabled = false`
- **Preserves** the Access Applications in the dashboard
- **Result**: Policies show as "Disabled" in Cloudflare Access dashboard
- **Effect**: Project becomes publicly accessible, but Access config remains for easy re-enabling

**When to use:**
- You want to temporarily make the project public
- You might want to re-enable Access later
- You want to keep the Access configuration for reference

#### Remove Action
- **Searches** for all Access Applications matching the Pages project
- **Deletes** all Access Policies for each application
- **Deletes** the Access Applications completely
- **Result**: Applications disappear from Cloudflare Access Apps list
- **Effect**: Project becomes publicly accessible, all Access config is removed

**When to use:**
- You want to permanently remove Access protection
- You're decommissioning the Access setup
- You want a clean slate without any Access configuration

### Prerequisites

#### 1. Cloudflare API Token

Create an API token with the following permissions:

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/) → **My Profile** → **API Tokens**
2. Click **Create Token**
3. Required Permissions:
   - **Cloudflare Pages:Read** (to read project information)
   - **Access:Edit** (to manage Access Applications and Policies)
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

#### Temporarily Make a Project Public

Disable Access policies while keeping the configuration for later:

```powershell
.\cf-pages-remove-access-policy.ps1 `
    -ApiToken $env:CF_API_TOKEN `
    -AccountId $env:CF_ACCOUNT_ID `
    -ProjectName "my-project"
```

**Result**: Policies show as "Disabled" in dashboard, can be re-enabled later.

#### Permanently Remove Access Protection

Remove all Access configuration completely:

```powershell
.\cf-pages-remove-access-policy.ps1 `
    -ApiToken $env:CF_API_TOKEN `
    -AccountId $env:CF_ACCOUNT_ID `
    -ProjectName "my-project" `
    -Action Remove
```

**Result**: Access Applications disappear from Access Apps list.

#### Batch Processing Multiple Projects

Process multiple projects at once:

```powershell
$projects = @("project1", "project2", "project3")

foreach ($project in $projects) {
    Write-Host "`nProcessing: $project" -ForegroundColor Cyan
    .\cf-pages-remove-access-policy.ps1 `
        -ApiToken $env:CF_API_TOKEN `
        -AccountId $env:CF_ACCOUNT_ID `
        -ProjectName $project `
        -Action Remove
}
```

### Error Handling

The script includes robust error handling:

- **Exponential Backoff**: Automatically retries failed API calls with increasing delays
- **API Error Messages**: Displays detailed Cloudflare API error information
- **Application Discovery**: Searches for Access Applications by project name and domain
- **Policy Enumeration**: Lists all policies before making changes
- **Graceful Failures**: Continues processing even if individual policy updates fail
- **Connection Issues**: Retries on network timeouts and transient errors
