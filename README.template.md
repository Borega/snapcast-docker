# Snapcast Docker

A Docker image providing the Snapcast server plus optional Spotify Connect via Librespot.

## Features
- 🎵 **Snapcast Server {{SNAPCAST_VERSION}}** – Multi-room audio streaming
- 🎧 **Librespot {{LIBRESPOT_VERSION}}** – Spotify Connect integration
- 🔄 **Automated updates** – Daily checks for new releases with automatic rebuilds
- 🏗️ **Multi-stage build** – Optimized Docker image built from source
- 🐳 **Minimal Alpine {{ALPINE_VERSION}} base** – Small footprint, secure foundation
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
    hostname: snapcast
    network_mode: host
    restart: unless-stopped
    environment:
      - START_LIBRESPOT=true
      - LIBRESPOT_NAME=Snapcast
      - LIBRESPOT_BITRATE=320
    volumes:
      - snapserver-conf:/config
    command: ["/usr/local/bin/snapserver", "-c", "/config/snapserver.conf"]

volumes:
  snapserver-conf:
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

## Configuration File
Create `/config/snapserver.conf` (mounted via the named volume) to set stream defaults and avoid shell quoting issues:
```ini
[stream]
sampleformat = 44100:16:2
codec = flac
chunk_ms = 20
buffer = 1000
send_to_muted = false

source = pipe:///tmp/snapfifo?name=Spotify&mode=create

[streaming_client]
initial_volume = 100

[http]
enabled = true
bind = 0.0.0.0
port = 1780
```

Initialize the config volume on Windows (PowerShell):
```powershell
docker volume create snapserver-conf
$conf = @"
[stream]
sampleformat = 44100:16:2
codec = flac
chunk_ms = 20
buffer = 1000
send_to_muted = false
source = pipe:///tmp/snapfifo?name=Spotify&mode=create

[streaming_client]
initial_volume = 100

[http]
enabled = true
bind = 0.0.0.0
port = 1780
"@
docker run --rm -v snapserver-conf:/config alpine sh -c "cat > /config/snapserver.conf" <<< $conf
```

## Audio Settings
- Sample rate controls PCM format (e.g., `44100:16:2`); bitrate controls Spotify stream quality (`LIBRESPOT_BITRATE`, e.g., 320 kbps).
- Librespot outputs 44.1 kHz; matching Snapserver to `44100:16:2` avoids resampling and “too fast” playback.
- If not using a config file, pass the stream inline and quote `&`:
```bash
/usr/local/bin/snapserver -s "pipe:///tmp/snapfifo?name=Spotify&sampleformat=44100:16:2"
```

## Automated Workflows
This project includes several GitHub Actions workflows:
- **Daily version checks** – Monitors upstream releases and triggers rebuilds
- **Nightly builds** – Validates the build daily and creates issues on failure
- **Alpine auto-bump** – Tests newer Alpine versions and creates PRs automatically
- **README updates** – Keeps version numbers current in documentation
- **Docker image publishing** – Builds and pushes to GitHub Container Registry on changes

## Architecture
- **Base**: Alpine Linux {{ALPINE_VERSION}}
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