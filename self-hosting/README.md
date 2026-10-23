# QSP self-hosting example

A Docker Compose setup that runs a complete QSP instance on one machine:
PostgreSQL, the authentication server, the signaling server and the web client,
all behind one nginx reverse proxy on a single origin.

```shell
cp .env.example .env      # edit QSP_HOST / QSP_PORT if needed
docker compose up -d
```

Then open `http://localhost:8080` (or `http://QSP_HOST:QSP_PORT`).

| Path           | Service                                   |
|----------------|-------------------------------------------|
| `/`            | web client                                |
| `/auth/`       | authentication server (OpenID Connect)    |
| `/signaling/`  | signaling server (agents connect to `ws://HOST:PORT/signaling/server/session`) |

Only `.env` needs editing: `QSP_HOST` / `QSP_PORT` are the public address used by
browsers and agents (the web client's `config.json`, the token issuer and the OAuth
redirect URI are all generated from them). Use a host name or IP that your browser
can reach; there is no hard-coded address.

Stop with `docker compose down` (add `-v` to also delete the database).

## Good to know

- **This is a trial setup with deliberately light security.** One shared database,
  the PostgreSQL superuser, default passwords from `.env.example`, plain HTTP.
  For a real deployment, change the passwords, add TLS in front and use dedicated
  database roles.
- **WebRTC media is peer-to-peer.** The proxy only carries signaling and
  authentication traffic, never audio/video. Peers behind strict NAT may need a
  TURN server, which is not part of this example.
- Image versions are pinned to released tags (`QSP_*_VERSION`); bump them deliberately.
- Both Java services share one database but keep separate Liquibase tracking tables
  (`auth_databasechangelog*`, `signaling_databasechangelog*`).

## Before first use

The auth server seeds an `admin` user. Its password is not set in this example
(there is no setting for it) and must be obtained from the QSP maintainer.
