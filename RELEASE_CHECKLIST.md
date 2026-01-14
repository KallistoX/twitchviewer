# Release Checklist for OpenStore & GitHub

This document contains the final checklist before publishing TwitchViewer.

## Security Verification

### 1. Sensitive Data Check

- [x] `config.cpp` is in `.gitignore`
- [x] `config.cpp` has NEVER been committed to git history
- [x] `config.cpp.example` contains only placeholder values
- [x] No OAuth tokens in any committed files
- [x] No personal API keys in repository
- [x] Git history verified clean (no sensitive data)

**Verification Commands:**
```bash
# Check .gitignore
cat .gitignore | grep config.cpp

# Check git history
git log --all --full-history --oneline -- config.cpp
# Should be empty (only config.cpp.example commits are OK)

# Search for potential secrets
git grep -i "Bearer\|OAuth\|auth-token" $(git rev-list --all)
```

### 2. Configuration Files

- [x] `config.cpp.example` is committed
- [x] `config.cpp.example` contains placeholder for Client ID
- [x] `config.cpp.example` has clear setup instructions for developers
- [x] `config.cpp` (local file with your real Client ID) exists for OpenStore builds
- [x] Only you (maintainer) can build the official OpenStore version

## Documentation

### 3. README.md

- [x] Completely in English
- [x] Contains feature list
- [x] Installation instructions (OpenStore + manual)
- [x] Build instructions for developers
- [x] Clear explanation of Streamlink-inspired approach
- [x] Security warning about OAuth tokens
- [x] Proper GitHub URLs (KallistoX/twitchviewer)
- [x] Contact information included
- [x] License information included
- [x] Disclaimer about Twitch trademark

### 4. Contributing Guidelines

- [x] `CONTRIBUTING.md` created
- [x] Development setup instructions
- [x] Code style guidelines
- [x] Testing checklist
- [x] Pull request guidelines
- [x] Branch naming conventions

### 5. Code of Conduct

- [x] `CODE_OF_CONDUCT.md` created
- [x] Reporting mechanism included
- [x] Enforcement guidelines clear

### 6. GitHub Templates

- [x] Bug report template (`.github/ISSUE_TEMPLATE/bug_report.md`)
- [x] Feature request template (`.github/ISSUE_TEMPLATE/feature_request.md`)
- [x] Question template (`.github/ISSUE_TEMPLATE/question.md`)
- [x] Pull request template (`.github/PULL_REQUEST_TEMPLATE.md`)

### 7. License

- [x] `LICENSE` file exists
- [x] GNU GPL v3.0 correctly applied
- [x] Copyright 2025 Dominic Bussemas
- [x] License referenced in README

## Repository Setup

### 8. .gitignore

- [x] `config.cpp` excluded
- [x] `*.conf` excluded (user settings)
- [x] Build artifacts excluded
- [x] IDE files excluded
- [x] All sensitive patterns covered

### 9. Git Status

Check current status:
```bash
git status
```

Expected output:
- Modified: `.gitignore`, `README.md`, `config.cpp.example`
- New files: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `RELEASE_CHECKLIST.md`, `.github/` templates
- NOT listed: `config.cpp`, any `.conf` files

## Pre-Publication Build Test

### 10. Clean Build Test

```bash
# Clean everything
clickable clean

# Build from scratch
clickable build

# Should succeed without errors
```

### 11. Fresh Clone Test

Test that someone else can build the app:

```bash
# In a different directory
cd /tmp
git clone https://github.com/KallistoX/twitchviewer.git
cd twitchviewer

# Copy example config
cp config.cpp.example config.cpp

# Try to build
clickable build

# Should succeed
```

## GitHub Repository Settings

### 12. Repository Configuration

Before making the repository public:

1. **Description**: "Native Twitch client for Ubuntu Touch"

2. **Topics/Tags**:
   - ubuntu-touch
   - twitch
   - qml
   - qt
   - streaming
   - ubports
   - clickable
   - lomiri

3. **Features**:
   - [x] Issues enabled
   - [x] Wiki (optional)
   - [x] Discussions (optional)
   - [ ] Projects (optional)

4. **About Section**:
   - Website: (leave empty or add if you have one)
   - Topics: (add tags above)

### 13. Pre-Public Final Check

Run this complete security check:

```bash
# 1. No config.cpp in .gitignore
grep -q "config.cpp" .gitignore && echo "✓ config.cpp in gitignore" || echo "✗ MISSING"

# 2. No config.cpp in git history
[ -z "$(git log --all --full-history --oneline -- config.cpp)" ] && echo "✓ config.cpp never committed" || echo "✗ WARNING: Found in history!"

# 3. README exists and is in English
[ -f README.md ] && grep -q "TwitchViewer for Ubuntu Touch" README.md && echo "✓ README OK" || echo "✗ README needs work"

# 4. LICENSE exists
[ -f LICENSE ] && grep -q "GNU GENERAL PUBLIC LICENSE" LICENSE && echo "✓ LICENSE OK" || echo "✗ LICENSE missing"

# 5. Contributing guide exists
[ -f CONTRIBUTING.md ] && echo "✓ CONTRIBUTING.md exists" || echo "✗ CONTRIBUTING.md missing"

# 6. Clean build works
clickable clean && clickable build && echo "✓ Clean build works" || echo "✗ Build failed"
```

All checks should show ✓ before proceeding.

## Making Repository Public

### 14. GitHub: Make Public

1. Go to: https://github.com/KallistoX/twitchviewer/settings
2. Scroll to "Danger Zone"
3. Click "Change visibility"
4. Select "Make public"
5. Confirm by typing the repository name

**⚠️ WARNING**: Once public, assume everything is visible forever (even if you delete it later). Make sure all previous steps are completed!

## Post-Publication

### 15. Create First Release

After making the repository public:

```bash
# Tag the release
git tag -a v1.0.0 -m "Initial public release"
git push origin v1.0.0
```

Then on GitHub:
1. Go to Releases
2. Click "Create a new release"
3. Select tag `v1.0.0`
4. Title: "TwitchViewer 1.0.0 - Initial Release"
5. Description: Copy relevant parts from README
6. Attach `.click` file if available

### 16. OpenStore Submission

1. Visit: https://open-store.io/
2. Log in with Ubuntu One account
3. Click "Publish"
4. Fill in app details:
   - Name: TwitchViewer
   - Package name: twitchviewer.dominicbussemas
   - Category: Entertainment
   - License: GPL-3.0
   - Source code: https://github.com/KallistoX/twitchviewer
   - Changelog: Initial release
5. Upload `.click` file
6. Submit for review

### 17. Announce

After approval:
- Ubuntu Touch Telegram group
- UBports forum
- Reddit r/UbuntuTouch
- Social media (if desired)

## Maintenance Checklist

### For Future Releases

- [ ] Update version in `manifest.json.in`
- [ ] Update changelog
- [ ] Test on multiple devices
- [ ] Create git tag
- [ ] Create GitHub release
- [ ] Upload to OpenStore
- [ ] Announce updates

## Notes

- Keep `config.cpp` local and never commit it
- Always use `config.cpp.example` for changes to the config template
- Review this checklist before each release
- Keep security as top priority

## Status

**Current Status**: ✅ Ready for publication

**Completed**: All security checks passed, documentation complete, repository prepared.

**Next Step**: Make repository public and submit to OpenStore.

---

Last updated: 2025-01-14
