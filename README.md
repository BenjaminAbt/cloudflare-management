# Cloudflare Management Scripts

A collection of PowerShell scripts for managing Cloudflare resources, including Pages deployments and Access policies.

## 📋 Overview

This repository contains automation scripts to help manage and maintain Cloudflare resources efficiently. The scripts are designed to be modular, reliable, and easy to use with comprehensive error handling and retry mechanisms.

## 🚀 Features

- **Batch Operations**: Process large numbers of resources efficiently with pagination
- **Retry Logic**: Built-in exponential backoff for API reliability
- **Safety Features**: Protection for production deployments
- **Access Management**: Direct integration with Cloudflare Access API
- **Detailed Logging**: Verbose output options for troubleshooting
- **PowerShell 7+ Compatible**: Modern PowerShell syntax and features
- **WhatIf Support**: Test changes before applying them

## 📜 Available Scripts

### Cloudflare Pages Management

#### 1. **cf-pages-delete-deployments.ps1**
Bulk deletion tool for Cloudflare Pages deployments with intelligent safety features.

**Key Features:**
- ✅ Production deployment protection
- ✅ Batch processing with pagination
- ✅ Optional aliased deployment deletion
- ✅ Progress tracking and detailed logging

**Quick Example:**
```powershell
.\scripts\pages\cf-pages-delete-deployments.ps1 `
    -ApiToken "your-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-project"
```

#### 2. **cf-pages-remove-access-policy.ps1**
Manage Cloudflare Access Applications and Policies for Pages projects.

**Key Features:**
- ✅ Automatic discovery of Access Applications
- ✅ Disable policies (set to inactive, keep configuration)
- ✅ Remove applications completely (delete from dashboard)
- ✅ Works directly with Cloudflare Access API

**Quick Example (Disable):**
```powershell
.\scripts\pages\cf-pages-remove-access-policy.ps1 `
    -ApiToken "your-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-project"
```

**Quick Example (Remove):**
```powershell
.\scripts\pages\cf-pages-remove-access-policy.ps1 `
    -ApiToken "your-token" `
    -AccountId "your-account-id" `
    -ProjectName "my-project" `
    -Action Remove
```

## 🔧 Prerequisites

- **PowerShell 7.0 or later** (recommended)
- **Cloudflare API Token** with appropriate permissions
- **Cloudflare Account ID**
- Internet connection for API calls

### PowerShell Installation

If you don't have PowerShell 7+, install it from:
- **Windows**: `winget install Microsoft.PowerShell`
- **macOS**: `brew install powershell`
- **Linux**: Follow [Microsoft's instructions](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)

## 📚 Documentation

Detailed documentation for each script category:

- [**Pages Scripts**](./scripts/pages/README.md) - Cloudflare Pages deployment and Access management

## Contents

- [Cloudflare Pages](./scripts/pages/README.md) - Scripts for managing Cloudflare Pages projects and deployments.

## � Authentication

All scripts require a Cloudflare API Token. To create one:

1. Log in to the [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Go to **My Profile** → **API Tokens**
3. Click **Create Token**
4. Select appropriate permissions (see table below)
5. Copy the token securely

### Required Permissions by Script

| Script | Required Permissions |
|--------|---------------------|
| `cf-pages-delete-deployments.ps1` | Cloudflare Pages:Edit |
| `cf-pages-remove-access-policy.ps1` | Cloudflare Pages:Read, Access:Edit |

### Security Best Practices

- **Never commit API tokens** to version control
- Store tokens in environment variables or secure vaults
- Use tokens with minimum required permissions
- Rotate tokens regularly

**Example using environment variables:**
```powershell
# Set environment variables (PowerShell)
$env:CF_API_TOKEN = "your-cloudflare-api-token"
$env:CF_ACCOUNT_ID = "your-account-id"

# Use in scripts
.\scripts\pages\cf-pages-delete-deployments.ps1 `
    -ApiToken $env:CF_API_TOKEN `
    -AccountId $env:CF_ACCOUNT_ID `
    -ProjectName "my-project"
```

## 💡 Common Use Cases

### Cleanup Old Deployments

Remove old preview deployments to reduce clutter and storage:

```powershell
.\scripts\pages\cf-pages-delete-deployments.ps1 `
    -ApiToken $env:CF_API_TOKEN `
    -AccountId $env:CF_ACCOUNT_ID `
    -ProjectName "production-site"
```

### Disable Access Protection Temporarily

Keep Access configuration but disable policies:

```powershell
.\scripts\pages\cf-pages-remove-access-policy.ps1 `
    -ApiToken $env:CF_API_TOKEN `
    -AccountId $env:CF_ACCOUNT_ID `
    -ProjectName "my-project"
```

**Result**: Policies show as "Disabled" in Cloudflare, can be re-enabled later.

### Remove Access Protection Completely

Delete Access Applications and all policies:

```powershell
.\scripts\pages\cf-pages-remove-access-policy.ps1 `
    -ApiToken $env:CF_API_TOKEN `
    -AccountId $env:CF_ACCOUNT_ID `
    -ProjectName "my-project" `
    -Action Remove
```

**Result**: Access Applications disappear from Cloudflare Access dashboard.

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 🔗 Useful Links

- [Cloudflare API Documentation](https://developers.cloudflare.com/api/)
- [Cloudflare Pages Documentation](https://developers.cloudflare.com/pages/)
- [Cloudflare Access Documentation](https://developers.cloudflare.com/cloudflare-one/policies/access/)
- [PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)

## �📝 License

This project is open source and available under the [MIT License](LICENSE).

---

**⚠️ Note**: These scripts interact with live Cloudflare resources. Always test in a non-production environment first.
