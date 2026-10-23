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
- Image versions default to `latest`; pin `QSP_*_VERSION` in `.env` to released tags
  for reproducible installs.

## Before first use

The auth server seeds an `admin` user. Its password is not set in this example
(there is no setting for it) and must be obtained from the QSP maintainer.

## Temporary workaround: signaling database schema

The released signaling image does not run its Liquibase migrations (upstream bug
in qsp-signaling-server: it ships only `liquibase-core`, no Spring Boot Liquibase
module). Until that is fixed, `db/init-signaling.sql` creates the signaling tables
by hand:

- The schema is duplicated from the changelog and may drift from it.
- The script only runs on a fresh database volume; after a schema change use
  `docker compose down -v` (deletes data).
- Once the upstream image runs Liquibase again, remove the script (otherwise
  Liquibase fails with "table already exists") and set the signaling tracking-table
  variables `SPRING_LIQUIBASE_DATABASE_CHANGE_LOG_TABLE` /
  `..._LOCK_TABLE` (see the comments in the SQL file).
