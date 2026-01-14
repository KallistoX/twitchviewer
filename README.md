# TwitchViewer for Ubuntu Touch

A native Twitch client for Ubuntu Touch devices, allowing you to watch live streams and browse channels on your Ubuntu Touch phone or tablet.

![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)
![Ubuntu Touch](https://img.shields.io/badge/platform-Ubuntu%20Touch-orange.svg)

## Screenshots

<table>
  <tr>
    <td><img src="screenshots/01_browse_streams.png" width="280"/></td>
    <td><img src="screenshots/02_categories.png" width="280"/></td>
    <td><img src="screenshots/03_player_quality.png" width="280"/></td>
  </tr>
  <tr>
    <td align="center"><b>Browse Live Streams</b></td>
    <td align="center"><b>Game Categories</b></td>
    <td align="center"><b>Quality Selection</b></td>
  </tr>
  <tr>
    <td><img src="screenshots/04_browse_landscape.png" width="280"/></td>
    <td><img src="screenshots/05_settings.png" width="280"/></td>
    <td></td>
  </tr>
  <tr>
    <td align="center"><b>Landscape Mode</b></td>
    <td align="center"><b>Settings & Authentication</b></td>
    <td></td>
  </tr>
</table>

## Features

- Browse and search for live Twitch channels
- View your followed channels (with authentication)
- Watch live streams with quality selection
- Adaptive UI for both portrait and landscape modes
- Support for phones and tablets
- Pull-to-refresh for channel lists
- Native performance with Qt/QML

## How Stream Links Work

This app retrieves ad-free media links using a method inspired by the [Streamlink](https://github.com/streamlink/streamlink) library. Instead of using Twitch's official OAuth app authentication (which requires a registered developer application), the app:

1. Uses Twitch's public client ID to access basic API endpoints
2. For authenticated features, accepts user-provided OAuth tokens

### Important Security Notice

**If you choose to provide your own OAuth token:**

- You do so at your own risk
- The token provides full access to your Twitch account
- The app stores the token locally on your device
- Never share your token with others
- You can revoke tokens anytime at https://www.twitch.tv/settings/connections

**Why this approach?**

Twitch's OAuth system requires a registered redirect URL, which is challenging for native mobile apps without a backend service. Due to the lack of alternative solutions for native Ubuntu Touch apps, user-provided tokens remain the most practical option for authenticated features.

**Alternative:** You can use the app without authentication to browse and watch streams without logging in.

## Installation

### From OpenStore

1. Open the OpenStore app on your Ubuntu Touch device
2. Search for "TwitchViewer"
3. Install the app

### Manual Installation (Development)

```bash
# Install Clickable (if not already installed)
pip3 install --user clickable-ut

# Clone the repository
git clone https://github.com/KallistoX/twitchviewer.git
cd twitchviewer

# Build and deploy to device
clickable
```

## Building from Source

### Prerequisites

- Ubuntu (18.04 or later) or compatible Linux distribution
- Docker (for containerized builds)
- Clickable: `pip3 install --user clickable-ut`
- An Ubuntu Touch device with developer mode enabled

### Build Instructions

```bash
# Clone the repository
git clone https://github.com/KallistoX/twitchviewer.git
cd twitchviewer

# Build the app
clickable build

# Install to connected device
clickable install

# Build and install in one step
clickable
```

### Configuration (For Developers)

**Note for Users:** If you install from OpenStore, the app is pre-configured and ready to use. No configuration needed!

**For developers** building from source, you need your own Twitch Client ID:

```bash
# Copy the example config
cp config.cpp.example config.cpp

# Create a Twitch Developer Application:
# 1. Go to: https://dev.twitch.tv/console/apps
# 2. Register a new application
# 3. Copy your Client ID and paste it into config.cpp
```

**Important:** `config.cpp` is in `.gitignore` and should never be committed. Only commit changes to `config.cpp.example`.

## Usage

### Browsing Streams

1. Open the app
2. Browse popular streams or search for channels
3. Pull down to refresh the stream list
4. Tap on any stream to watch

### Quality Selection

- Tap the settings icon in the video player
- Choose from available quality options (Auto, 1080p60, 720p60, 480p, 360p, 160p)
- The player will switch quality without interrupting playback

### Authentication (Optional)

To access your followed channels:

1. Get your OAuth token from Twitch
2. Go to Settings in the app
3. Enter your OAuth token
4. Access the "Followed" tab

**Obtaining an OAuth Token:**
- Visit https://twitchtokengenerator.com or similar services
- Generate a token with `user:read:follows` scope
- Copy and paste into the app settings

**Revoking Access:**
- Visit https://www.twitch.tv/settings/connections
- Remove "TwitchViewer" from authorized apps

## Technology Stack

- **Qt 5.12** - Application framework
- **QML** - User interface
- **C++** - Backend logic and API integration
- **QtMultimedia** - Video playback
- **QtNetwork** - HTTP requests and API calls

## Known Issues

- Chat integration is not yet implemented
- Some streams may require specific quality settings on older devices
- OAuth token must be manually entered (no automatic login flow)

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Reporting Issues

If you encounter bugs or have feature requests:

1. Check if the issue already exists in [GitHub Issues](https://github.com/KallistoX/twitchviewer/issues)
2. If not, create a new issue with:
   - Device model and Ubuntu Touch version
   - App version
   - Steps to reproduce the problem
   - Expected vs actual behavior

## License

Copyright (C) 2025 Dominic Bussemas

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 3, as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranties of MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

## Contact

- Developer: Dominic Bussemas
- Email: dev@bussemas.me
- GitHub Issues: https://github.com/KallistoX/twitchviewer/issues

## Acknowledgments

- Inspired by [Streamlink](https://github.com/streamlink/streamlink)
- Built with [Clickable](https://clickable-ut.dev/)
- Thanks to the Ubuntu Touch community

## Disclaimer

This app is not affiliated with, endorsed by, or sponsored by Twitch Interactive, Inc. Twitch and the Twitch logo are trademarks of Twitch Interactive, Inc.
