# Install the agent

The agent is shipped as a `.deb` package for Debian-based Linux, including Raspberry Pi OS. Packages for 64-bit ARM (`arm64`) and Intel/AMD (`amd64`) are published on the [qsp-agent releases page](https://github.com/Ham-QSP/qsp-agent/releases).

1. Check your architecture. On a Raspberry Pi with 64-bit Raspberry Pi OS this prints `arm64`:

   ```shell
   dpkg --print-architecture
   ```

2. Download the `.deb` for that architecture from the [releases page](https://github.com/Ham-QSP/qsp-agent/releases) (use the latest release).

3. Install it. Replace the file name with the one you downloaded:

   ```shell
   sudo apt install ./qsp-agent_VERSION_arm64.deb
   ```

The package installs:

| What | Where |
|------|-------|
| The program | `/usr/bin/qsp-agent` |
| The configuration file | `/etc/qsp-agent/config.toml` |
| The systemd service | `qsp-agent.service` |

It also creates a dedicated system user and group named `qsp-agent`, which the service runs as.

Next: [Configure the agent](configure-agent.md).
