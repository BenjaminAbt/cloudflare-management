## 📝 Description

<!-- Provide a clear and concise description of your changes -->

## 🎯 Related Issue

<!-- Link to the issue this PR addresses -->
Fixes #(issue number)

## 🔄 Type of Change

<!-- Check all that apply -->

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🎨 Code style update (formatting, renaming)
- [ ] ♻️ Refactoring (no functional changes)
- [ ] ⚡ Performance improvement
- [ ] ✅ Test update
- [ ] 🔧 Maintenance / chore

## 🧪 Testing

<!-- Describe the tests you ran and how to reproduce them -->

### Test Environment
- **OS**: [e.g., Windows 11, macOS 14, Ubuntu 22.04]
- **PowerShell Version**: [e.g., 7.4.0]
- **Test Project**: [e.g., test-pages-project]

### Test Cases
<!-- Check all that were tested -->

- [ ] Basic functionality works as expected
- [ ] All parameters validated
- [ ] Error handling tested
- [ ] Edge cases covered
- [ ] Verbose output verified
- [ ] Help documentation accurate (`Get-Help` tested)
- [ ] No sensitive data in code

### Test Results

```powershell
# Paste test commands and results here
.\script.ps1 -Parameter "value" -Verbose
```

## 📋 Checklist

<!-- Ensure all items are completed before requesting review -->

### Code Quality
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] My changes generate no new warnings or errors
- [ ] I have used approved PowerShell verbs for functions

### Documentation
- [ ] I have updated the relevant README files
- [ ] I have updated inline documentation (comment-based help)
- [ ] I have added usage examples
- [ ] I have documented all parameters

### Testing
- [ ] I have tested my changes in a non-production environment
- [ ] I have tested with various parameter combinations
- [ ] I have tested error conditions
- [ ] New and existing tests pass locally

### Security
- [ ] I have removed any hardcoded credentials or secrets
- [ ] I have validated all user inputs
- [ ] I have ensured error messages don't leak sensitive data
- [ ] I have reviewed API call security

## 📸 Screenshots

<!-- If applicable, add screenshots to demonstrate changes -->

## 🔗 Dependencies

<!-- List any dependencies this PR introduces or requires -->

- None
<!-- OR -->
- Requires PowerShell 7.2+
- Requires new API permission: ...
- Depends on PR #...

## 💡 Implementation Notes

<!-- Explain any significant implementation decisions or technical details -->

### Approach
<!-- Describe your implementation approach -->

### Challenges
<!-- Describe any challenges you faced and how you solved them -->

### Alternatives Considered
<!-- Describe alternative approaches you considered -->

## 📊 Performance Impact

<!-- If applicable, describe any performance implications -->

- [ ] No performance impact
- [ ] Performance improved
- [ ] Performance may be affected (explain below)

## ⚠️ Breaking Changes

<!-- If this is a breaking change, describe the impact and migration path -->

**Breaking changes:**
- None
<!-- OR -->
- Parameter `OldParam` renamed to `NewParam`
- Function `Old-Function` removed, use `New-Function` instead

**Migration guide:**
<!-- Provide examples of how to update existing usage -->

```powershell
# Old way
.\script.ps1 -OldParam "value"

# New way
.\script.ps1 -NewParam "value"
```

## 📝 Additional Notes

<!-- Any additional information that reviewers should know -->

## 👀 Reviewers

<!-- Tag specific people if needed -->

@reviewername - Please review the [specific aspect] of this PR

---

<!-- Thank you for contributing! -->
