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
- The signaling schema is created by `db/init-signaling.sql` on the first start
  (see the note in that file).
- Image versions default to `latest`; pin `QSP_*_VERSION` in `.env` to released tags
  for reproducible installs.
- The seeded `admin` account's password is not documented here yet.
