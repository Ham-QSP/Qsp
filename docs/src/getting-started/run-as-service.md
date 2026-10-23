# Run as a service

The package installs a systemd service, `qsp-agent.service`. It runs the agent in the foreground as the `qsp-agent` user, with `--config /etc/qsp-agent/config.toml`, and restarts it if it fails.

Start it now and at every boot:

```shell
sudo systemctl enable --now qsp-agent.service
```

Check that it is running:

```shell
systemctl status qsp-agent.service
```

Read the logs:

```shell
journalctl -u qsp-agent.service
```

Add `-f` to follow the logs live. After you change `/etc/qsp-agent/config.toml`, restart the service:

```shell
sudo systemctl restart qsp-agent.service
```

Do not add the `--daemon` option to the service: systemd runs the agent in the foreground.

Next: [Operate from your browser](operate.md).
