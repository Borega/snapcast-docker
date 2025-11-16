# Snapcast Docker

A Docker image that builds and runs [Snapcast](https://github.com/badaix/snapcast) server with [Librespot](https://github.com/librespot-org/librespot) for Spotify Connect support.

## Features

- 🎵 **Snapcast Server 0.34.0** - Multi-room audio streaming
- 🎧 **Librespot** - Spotify Connect integration
- 🔄 **Auto-updates** - Automatically rebuilds when new releases are available
- 🐳 **Minimal Alpine-based image** - Small footprint, latest builds from source
- 🔊 **Avahi/mDNS support** - Automatic service discovery

## Docker Image

The Docker image is automatically built via GitHub Actions and published to GitHub Container Registry:

```
ghcr.io/borega/snapcast-docker:latest
```

### Pull the image

```bash
docker pull ghcr.io/borega/snapcast-docker:latest
```

## Usage

### Quick Start

Run Snapcast server only (without Spotify Connect):

```bash
docker run -d \
  --name snapcast \
  --network host \
  --restart unless-stopped \
  ghcr.io/borega/snapcast-docker:latest \
  /usr/local/bin/snapserver
```

### Docker Compose (Recommended)

#### Basic Snapcast Server

```yaml
version: "3"
services:
  snapcast:
    image: ghcr.io/borega/snapcast-docker:latest
    hostname: snapcast
    network_mode: host
    restart: unless-stopped
    command: /usr/local/bin/snapserver
```

#### With Spotify Connect (Librespot)

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
    command: /usr/local/bin/snapserver -s pipe:///tmp/snapfifo?name=Spotify
```

#### With Audio Files Directory

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
      - LIBRESPOT_NAME=My Snapcast Server
      - LIBRESPOT_BITRATE=320
    volumes:
      - /path/to/music:/audio:ro
    command: /usr/local/bin/snapserver -s pipe:///tmp/snapfifo?name=Spotify
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `START_LIBRESPOT` | Enable Spotify Connect via Librespot | `false` |
| `LIBRESPOT_NAME` | Name shown in Spotify Connect devices | `Snapcast` |
| `LIBRESPOT_BITRATE` | Audio bitrate (96, 160, 320) | `320` |

## Ports

When using `network_mode: host`, the following ports are used:

- **1704** - Snapcast audio streaming
- **1705** - Snapcast control (TCP JSON RPC)
- **1780** - Snapcast web interface

Access the web interface at: `http://<your-server-ip>:1780`

## Connecting Clients

### Snapcast Clients

Install Snapcast client on your playback devices:
- **Linux**: `apt install snapclient` or `yum install snapclient`
- **Android**: [Snapcast app on Google Play](https://play.google.com/store/apps/details?id=de.badaix.snapcast)
- **iOS**: [Snapcast app on App Store](https://apps.apple.com/app/snapcast/id1552559653)
- **Windows/macOS**: Download from [Snapcast releases](https://github.com/badaix/snapcast/releases)

Connect clients to your server:
```bash
snapclient -h <snapcast-server-ip>
```

### Spotify Connect

Once `START_LIBRESPOT=true` is set, your Snapcast server will appear as a Spotify Connect device in the Spotify app on your phone, desktop, or web player.

## Audio Input Sources

### FIFO Pipe

The server creates a FIFO pipe at `/tmp/snapfifo` for audio input. You can write audio to this pipe from:

- **Mopidy**: Configure output to pipe
- **MPD**: Configure audio output to FIFO
- **ffmpeg**: Stream audio files
  ```bash
  ffmpeg -i song.mp3 -f s16le -ar 48000 -ac 2 /tmp/snapfifo
  ```

## Building from Source

This image is automatically built from source when new releases are detected. The build process:

1. Builds Librespot from latest GitHub release
2. Builds Snapcast from latest GitHub release
3. Creates minimal Alpine-based runtime image

To build manually:
```bash
docker build -t snapcast-docker .
```

## Automatic Updates

A GitHub Actions workflow runs daily to check for new releases of Snapcast and Librespot. When updates are found, the image is automatically rebuilt and published.

## Troubleshooting

### Avahi/mDNS not working

Make sure you're using `network_mode: host` to allow proper mDNS/Avahi service discovery.

### No audio playing

1. Check that audio is being written to the FIFO pipe: `/tmp/snapfifo`
2. Verify clients are connected: Check web interface at `http://<server>:1780`
3. Check container logs: `docker logs snapcast`

### Spotify Connect not appearing

1. Ensure `START_LIBRESPOT=true` is set
2. Check logs for librespot errors: `docker logs snapcast`
3. Verify the container has network access

## License

- This Docker image: [GPL-3.0](LICENSE)
- Snapcast: [GPL-3.0](https://github.com/badaix/snapcast/blob/master/LICENSE)
- Librespot: [MIT](https://github.com/librespot-org/librespot/blob/dev/LICENSE)

## Contributing

Issues and pull requests are welcome at [https://github.com/Borega/snapcast-docker](https://github.com/Borega/snapcast-docker)
