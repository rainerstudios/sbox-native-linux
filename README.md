# s&box Native Linux Dedicated Server

Docker image for running s&box dedicated servers natively on Linux — no Wine required.

Built on **Ubuntu 24.04 (Noble)** which ships glibc 2.39, satisfying the Source 2 engine's requirement for glibc >= 2.38 and GLIBCXX >= 3.4.31.

## Image

```
ghcr.io/rainerstudios/sbox-native-linux:latest
```

## What's Included

| Component | Version | Purpose |
|-----------|---------|---------|
| Ubuntu Noble | 24.04 | Base OS with glibc 2.39 |
| .NET Runtime | 10.x | s&box server runtime |
| SteamCMD | Latest | Game server updates |
| libvulkan1 | 1.3.x | Source 2 renderer probe |
| libstdc++6 | 6.0.33 | GLIBCXX 3.4.31+ |

## Panel Compatibility

Works with both **Pterodactyl** and **Pelican** panel systems. The entrypoint follows standard yolk conventions:

- `STARTUP` variable with `{{VAR}}` placeholder substitution
- `AUTO_UPDATE` + `SRCDS_APPID` for SteamCMD updates
- UID/GID 999 (`container` user)
- Working directory: `/home/container`

## Egg Configuration

### Startup Command

Use the included launch script as the egg startup command:

```
bash start-sbox-native
```

Or call dotnet directly:

```
dotnet sbox-server.dll +game {{GAME}} +hostname "{{SERVER_NAME}}" +maxplayers {{MAX_PLAYERS}}
```

### Required Egg Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SRCDS_APPID` | `1892930` | Steam App ID for s&box dedicated server |
| `GAME` | `facepunch.walker` | Game package identifier |
| `SERVER_NAME` | `Pterodactyl Sandbox Server` | Server name |
| `MAX_PLAYERS` | `64` | Maximum player count |
| `SBOX_AUTO_UPDATE` | `1` | Auto-update via SteamCMD on boot |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MAP` | *(empty)* | Map/package to load |
| `TOKEN` | *(empty)* | Steam game server token |
| `SBOX_PROJECT` | *(empty)* | Path to .sbproj file |
| `ENABLE_DIRECT_CONNECT` | `0` | Bypass Steam relay (use direct IP) |
| `QUERY_PORT` | *(empty)* | Query port for direct connect |
| `SBOX_BRANCH` | *(empty)* | SteamCMD beta branch |
| `SBOX_EXTRA_ARGS` | *(empty)* | Additional server arguments |

### Startup Detection

Set the egg's `config > startup > done` to:

```
Loading game|Server started
```

## Why Native Linux?

The standard s&box egg uses Wine to run the Windows server binary. This works but adds overhead and can cause stability issues (SDR assertion crashes, memory leaks). s&box now ships native Linux binaries in `bin/linuxsteamrt64/`, making Wine unnecessary.

**Benefits:**
- No Wine overhead or compatibility issues
- Native .NET runtime (not Wine-.NET)
- Smaller image size
- Better stability and crash diagnostics
- Direct gdb/strace debugging if needed

## Building Locally

```bash
docker build --platform linux/amd64 -t ghcr.io/rainerstudios/sbox-native-linux:latest .
```

## License

MIT
