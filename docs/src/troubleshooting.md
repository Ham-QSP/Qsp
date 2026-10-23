# Troubleshooting

Start by reading the agent logs:

```shell
journalctl -u qsp-agent.service
```

## The agent does not start

- The service expects `/etc/qsp-agent/config.toml` to exist and to be valid TOML. Check the logs for the first error message.
- Only one agent can run with a given configuration at a time (it keeps a lock file). Make sure you are not also running it by hand.

## The agent cannot connect to the service

- Check `url`, `agentId` and `agentSecret` in `[signaling_server]`. The URL must look like `wss://<service-host>/signaling/server/session` (use `ws://` only for a plain-HTTP self-hosted instance).
- Check that the computer has internet access and can reach the service.
- The agent keeps retrying with growing delays, so it will reconnect by itself when the service is back.

## The radio does not respond

- Check the Hamlib `model`, `rig_pathname` and `serial_speed`, and that your radio's CAT settings match.
- Permission denied on the serial port: add the `qsp-agent` user to the `dialout` group (see [Configure the agent](getting-started/configure-agent.md)) and restart the service.

## No audio

- The agent uses the system's default audio input device. Check that this is the one your radio is connected to, and that the `qsp-agent` user is in the `audio` group.

## The station is connected but there is no audio or control in the browser

Your browser and your agent talk to each other **directly** (see [How QSP works](how-qsp-works.md)). That means both ends must be able to reach each other, and QSP has **no TURN relay server today** to carry the traffic when they cannot.

The direct connection typically fails when:

- one side is behind a **symmetric NAT**;
- a **restrictive firewall** blocks UDP traffic, as in some company, school or public networks;
- one side is behind **CGNAT** (carrier-grade NAT), as on many mobile and some home internet connections, where you share one public address with other customers.

What you can try:

- Connect your browser from another network (for example a different Wi-Fi, or mobile data instead of Wi-Fi), to find out which side is the problem.
- Check the router and firewall at the station: it must allow outgoing UDP traffic.
- Ask your internet provider whether you are behind CGNAT, and whether they can give you a public address.
