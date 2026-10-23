# Configure the agent

{{#include ../../includes/service-host.md}}

The agent reads `/etc/qsp-agent/config.toml`. Edit it as root:

```shell
sudoedit /etc/qsp-agent/config.toml
```

## Name and description

```toml
name = "My Station"
description = "Remote HF station"
```

## Connection to the QSP service

Put the service address, and the agent ID and secret from [Register your station](register-station.md), in the `[signaling_server]` section:

```toml
[signaling_server]
url = "wss://<service-host>/signaling/server/session"
agentId = "YOUR_AGENT_ID"
agentSecret = "YOUR_AGENT_SECRET"
```

The URL has the form `wss://<service-host>/signaling/server/session`: replace `<service-host>` with the address of the service (see the placeholder note above).

If the agent loses its connection, it retries by itself with growing delays, so you do not need to restart it.

## Your transceiver

```toml
[transceiver]
model = 1

[transceiver.port]
rig_pathname = "/dev/ttyUSB0"
serial_speed = "115200"
```

- `model` is the Hamlib model number of your radio (`rigctl --list` shows them, after `sudo apt install libhamlib-utils`; or see the [list of supported radios](https://github.com/Hamlib/Hamlib/wiki/Supported-Radios)). The value `1` is Hamlib's dummy radio, which is handy to test the connection without a real rig.
- `rig_pathname` is the serial device of your CAT cable and `serial_speed` its speed. These entries are passed straight to Hamlib, so use the parameters Hamlib documents for your radio and connection type.

## Audio

The agent uses the system's **default audio input device**.

## Permissions for the serial port

The service runs as the `qsp-agent` user. If your radio shows up as `/dev/ttyUSB0` or under `/dev/serial/`, that user may need to be in the `dialout` group to open it, and in the `audio` group to capture sound:

```shell
sudo usermod -aG dialout,audio qsp-agent
```

Then continue with [Run as a service](run-as-service.md).
