# Contributing to TwitchViewer

Thank you for your interest in contributing to TwitchViewer for Ubuntu Touch!

## Ways to Contribute

- Report bugs and issues
- Suggest new features
- Improve documentation
- Submit code improvements
- Test on different Ubuntu Touch devices
- Translate the app to other languages

## Getting Started

### Prerequisites

1. Ubuntu (18.04 or later) or compatible Linux distribution
2. Docker installed and running
3. Clickable: `pip3 install --user clickable-ut`
4. An Ubuntu Touch device with developer mode enabled
5. Basic knowledge of Qt/QML and C++

### Setting Up Development Environment

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/twitchviewer.git
cd twitchviewer

# Copy example config
cp config.cpp.example config.cpp

# REQUIRED: Create your own Twitch Developer Application and add your Client ID
# 1. Go to: https://dev.twitch.tv/console/apps
# 2. Click "Register Your Application"
# 3. Name: "TwitchViewer Dev" (or similar)
# 4. OAuth Redirect URLs: http://localhost
# 5. Category: Application Integration
# 6. Copy your Client ID and paste it into config.cpp

# Build and test
clickable
```

## How to Contribute

### 1. Fork the Repository

Click the "Fork" button on GitHub to create your own copy of the repository.

### 2. Create a Feature Branch

```bash
git checkout -b feature/amazing-feature
```

Branch naming conventions:
- `feature/feature-name` for new features
- `fix/bug-description` for bug fixes
- `docs/what-changed` for documentation
- `refactor/what-changed` for refactoring

### 3. Make Your Changes

- Write clean, readable code
- Follow the existing code style
- Add comments for complex logic
- Test on actual Ubuntu Touch hardware if possible

### 4. Test Your Changes

```bash
# Build the app
clickable build

# Deploy to device
clickable install

# Check logs
clickable logs
```

Test checklist:
- App builds without errors
- App installs on device
- No crashes or freezes
- Feature works as intended
- No regression in existing features

### 5. Commit Your Changes

```bash
git add .
git commit -m "Add amazing feature"
```

Commit message guidelines:
- Use present tense ("Add feature" not "Added feature")
- First line should be concise (50 chars or less)
- Add detailed description if needed
- Reference issue numbers when applicable

Examples:
```
Add support for clip playback (#42)

- Implement clip fetching from Twitch API
- Add clip player UI component
- Update navigation to include clips tab
```

### 6. Push to Your Fork

```bash
git push origin feature/amazing-feature
```

### 7. Open a Pull Request

1. Go to the original repository on GitHub
2. Click "New Pull Request"
3. Select your fork and branch
4. Fill in the PR template with:
   - Description of changes
   - Testing steps
   - Device(s) tested on
   - Screenshots (if UI changes)
   - Related issue numbers

## Code Style Guidelines

### C++

- Use meaningful variable and function names
- Follow Qt naming conventions (camelCase for functions, m_ prefix for member variables)
- Add header comments for public methods
- Use const correctness
- Prefer smart pointers over raw pointers

Example:
```cpp
// Good
QString TwitchHelixAPI::getUserName() const {
    return m_userName;
}

// Avoid
QString TwitchHelixAPI::getname() {
    return userName;
}
```

### QML

- 4-space indentation
- Use Lomiri Components where applicable
- Keep components small and focused
- Name files with PascalCase (e.g., `StreamList.qml`)
- Use meaningful property names

Example:
```qml
// Good
Rectangle {
    id: streamCard
    width: parent.width
    height: units.gu(12)

    Column {
        spacing: units.gu(1)
        // ...
    }
}

// Avoid
Rectangle {
    width: 400
    height: 100
    // ...
}
```

### Comments

- Explain WHY, not WHAT
- Document complex algorithms
- Add TODO comments for future improvements

```cpp
// Good
// Use cached data to avoid API rate limits
if (m_cacheValid) {
    return m_cachedData;
}

// Avoid
// Return cached data
return m_cachedData;
```

## Testing Guidelines

### Manual Testing

Test on Ubuntu Touch device:
1. Install the app
2. Test all navigation paths
3. Test with and without authentication
4. Test different screen orientations
5. Test on both phone and tablet form factors
6. Check for memory leaks (long usage)

### Testing Checklist

- [ ] App builds successfully
- [ ] App starts without crashes
- [ ] Stream list loads correctly
- [ ] Stream playback works
- [ ] Quality selection works
- [ ] Settings page functions properly
- [ ] Authentication works (if implemented)
- [ ] No UI glitches or overlaps
- [ ] Works in portrait and landscape
- [ ] Pull-to-refresh functions correctly

## Reporting Bugs

When reporting bugs, include:

1. **Device Information**
   - Device model (e.g., Volla Phone, Pixel 3a)
   - Ubuntu Touch version (e.g., OTA-24)
   - App version

2. **Description**
   - What happened
   - What you expected to happen
   - Steps to reproduce

3. **Logs** (if applicable)
   ```bash
   clickable logs
   ```

4. **Screenshots** (if UI issue)

## Feature Requests

When suggesting features:

1. Describe the feature and its use case
2. Explain why it would be valuable
3. Provide examples of similar implementations (if any)
4. Consider technical feasibility for Ubuntu Touch

## Questions?

If you have questions about contributing:

1. Check existing issues and discussions
2. Open a new issue with the "question" label
3. Contact the maintainer at dev@bussemas.me

## Code of Conduct

Please be respectful and constructive in all interactions. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details.

## License

By contributing, you agree that your contributions will be licensed under the GNU General Public License v3.0.

## Recognition

Contributors will be recognized in the project documentation and release notes.

Thank you for making TwitchViewer better!
