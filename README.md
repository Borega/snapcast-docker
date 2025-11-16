# Snapcast Docker

A Docker image providing the Snapcast server plus optional Spotify Connect via Librespot.

## Features
- 🎵 **Snapcast Server 0.34.0** – Multi-room audio streaming
- 🎧 **Librespot 0.8.0** – Spotify Connect integration
- 🔄 **Auto-updates** – Rebuilds when upstream releases change
- 🐳 **Minimal Alpine image** – Built from source
- 🔊 **Avahi/mDNS support** – Client discovery on the LAN

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

## Updating Versions
Automated workflow replaces placeholders in this template and commits generated `README.md`.

## Troubleshooting
- Missing config warning: benign unless you supply `/etc/snapserver.conf`.
- No Spotify device: ensure START_LIBRESPOT=true.
- Avahi errors: host networking required; ensure `avahi-daemon` started by entrypoint.

## License
Upstream projects under their respective licenses; this repository under GPL-3.0.