# Cloudflare Management Scripts

A collection of PowerShell scripts for managing Cloudflare resources..

## 📋 Overview

This repository contains automation scripts to help manage and maintain Cloudflare resources efficiently. The scripts are designed to be modular, reliable, and easy to use with comprehensive error handling and retry mechanisms.

## 📁 Repository Structure

```
scripts/
└── pages/              # Cloudflare Pages management scripts
    └── cf-pages-delete-deployments.ps1
README.md
```

## 📚 Documentation

Detailed documentation for each script category:

- [**Pages Scripts**](./scripts/pages/README.md) - Cloudflare Pages deployment management

## 🔑 Authentication

All scripts require a Cloudflare API Token. To create one:

1. Log in to the [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Go to **My Profile** → **API Tokens**
3. Click **Create Token**
4. Use the appropriate template or create a custom token with required permissions
5. Copy the token securely

## License

This project is open source and available under the [MIT License](LICENSE).
