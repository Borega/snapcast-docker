# Snapcast Docker

A Docker image providing the Snapcast server plus optional Spotify Connect via Librespot.

## Features
- 🎵 **Snapcast Server null** – Multi-room audio streaming
- 🎧 **Librespot null** – Spotify Connect integration
- 🔄 **Automated updates** – Daily checks for new releases with automatic rebuilds
- 🏗️ **Multi-stage build** – Optimized Docker image built from source
- 🐳 **Minimal Alpine 3.19 base** – Small footprint, secure foundation
- 🔊 **Avahi/mDNS support** – Automatic client discovery on the LAN
- 🤖 **CI/CD automation** – Nightly builds, Alpine auto-bumping, and automated PRs

## Image
`ghcr.io/borega/snapcast-docker:latest`

Pull:
```bash
docker pull ghcr.io/borega/snapcast-docker:latest
```

## Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| START_LIBRESPOT | Enable Librespot pipeline | false |
| LIBRESPOT_NAME | Spotify Connect device name | Snapcast |
| LIBRESPOT_BITRATE | 96 / 160 / 320 (320 requires Premium) | 320 |

## Quick Run (Server only)
```bash
docker run -d --name snapcast --network host ghcr.io/borega/snapcast-docker:latest \
  /usr/local/bin/snapserver -s pipe:///tmp/snapfifo?name=default
```

## Docker Compose (with Librespot)
```yaml
version: "3"
services:
  snapcast:
    image: ghcr.io/borega/snapcast-docker:latest
    network_mode: host
    restart: unless-stopped
    environment:
      - START_LIBRESPOT=true
      - LIBRESPOT_NAME=Snapcast
      - LIBRESPOT_BITRATE=320
    command: /usr/local/bin/snapserver -s pipe:///tmp/snapfifo?name=Spotify
```

## Supplying Audio
Write PCM/FLAC-compatible data into `/tmp/snapfifo` (created automatically when Librespot starts). Example:
```bash
cat track.wav > /tmp/snapfifo
```

## Build Process
This image uses a **multi-stage Docker build**:
1. **Stage 1**: Builds Librespot from source with latest Rust toolchain
2. **Stage 2**: Builds Snapcast from source with all dependencies
3. **Stage 3**: Creates minimal runtime image with only necessary libraries

Both Snapcast and Librespot are compiled from their latest releases, ensuring you always get the newest features and fixes.

## Automated Workflows
This project includes several GitHub Actions workflows:
- **Daily version checks** – Monitors upstream releases and triggers rebuilds
- **Nightly builds** – Validates the build daily and creates issues on failure
- **Alpine auto-bump** – Tests newer Alpine versions and creates PRs automatically
- **README updates** – Keeps version numbers current in documentation
- **Docker image publishing** – Builds and pushes to GitHub Container Registry on changes

## Architecture
- **Base**: Alpine Linux 3.19
- **Build method**: Multi-stage Docker build from source
- **Platforms**: Built for amd64 (additional architectures can be added)
- **Entrypoint**: Custom script that manages D-Bus, Avahi, and optional Librespot startup

## Troubleshooting
- **Missing config warning**: Benign unless you supply `/etc/snapserver.conf`
- **No Spotify device**: Ensure `START_LIBRESPOT=true` is set
- **Avahi errors**: Host networking required; `avahi-daemon` is started automatically by entrypoint
- **Build failures**: Check the Issues tab; nightly builds create issues automatically on failure
- **Outdated versions**: The image rebuilds automatically when new releases are detected

## Contributing
This project is fully automated:
- Version updates are detected and applied automatically
- Alpine base image updates are tested and proposed via PR
- Build failures trigger issue creation for investigation
- Manual workflow triggers are available via GitHub Actions for all processes

## License
Upstream projects under their respective licenses; this repository under GPL-3.0.