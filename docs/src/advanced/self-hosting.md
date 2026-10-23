# Self-hosting quick start

You can run a complete QSP instance on one machine with Docker Compose: PostgreSQL, the authentication server, the signaling server and the web client, behind one nginx reverse proxy.

> **This is a trial setup, not a production one.** It uses a single shared database with the PostgreSQL superuser, default passwords, a default admin account and plain HTTP. See [Before you expose it](#before-you-expose-it).

The example lives in the [`self-hosting/` folder](https://github.com/Ham-QSP/Qsp/tree/main/self-hosting) of the repository, with its own README. This page is the short tour; the README has the details and the exact commands.

You need Docker with the Compose plugin.

## 1. Start the stack

From the `self-hosting/` folder:

```shell
cp .env.example .env      # edit QSP_HOST / QSP_PORT if needed
docker compose up -d
```

`QSP_HOST` and `QSP_PORT` are the public address that browsers and agents use to reach the instance. Use a name or address that they can actually reach. Then open `http://QSP_HOST:QSP_PORT` (by default `http://localhost:8080`).

## 2. Sign in as the admin

The authentication server seeds an `admin` user with a default development password. The default password and how to change it are in the README section [Before first use: the admin account](https://github.com/Ham-QSP/Qsp/tree/main/self-hosting#before-first-use-the-admin-account). **Change it before anyone else can reach the instance.**

## 3. Create a station and an agent

Until the web client has a screen for it, a station and its agent are created through the signaling server's REST API. In short:

1. Get an access token for `admin`.
2. Create a station with your callsign.
3. Register an agent on that station.
4. Generate the agent's secret.

The README has a complete copy-and-paste walkthrough with `curl`: [Create a station and an agent](https://github.com/Ham-QSP/Qsp/tree/main/self-hosting#create-a-station-and-an-agent). At the end you have an **agent ID** and an **agent secret**.

## 4. Point an agent at your instance

[Install the agent](../getting-started/install-agent.md) as for the hosted service, then in `/etc/qsp-agent/config.toml` use your instance's address. The self-hosted example is plain HTTP, so the agent URL uses `ws://`:

```toml
[signaling_server]
url = "ws://HOST:PORT/signaling/server/session"
agentId = "THE_AGENT_ID"
agentSecret = "THE_AGENT_SECRET"
```

`HOST:PORT` is the `QSP_HOST:QSP_PORT` from your `.env`. Then [run the agent as a service](../getting-started/run-as-service.md).

## 5. Operate

Open `http://HOST:PORT` in your browser and sign in. Your station appears once its agent is connected. As always, the audio goes directly between your browser and the agent (see [How QSP works](../how-qsp-works.md)): the proxy only carries sign-in and signaling traffic.

Stop the stack with `docker compose down` (add `-v` to also delete the database).

## Before you expose it

Before anyone outside a trusted network can reach the instance:

- Set **strong passwords** in `.env` instead of the defaults.
- **Change the admin password.**
- Use **dedicated database roles** per service instead of the PostgreSQL superuser.
- Put **TLS** in front of the proxy for browsers (`https://`). Note that the agent does **not support `wss://` yet**: agents must still reach the signaling server over plain `ws://`, so keep a plain-HTTP path or port for `/signaling/server/session` reachable to your agents (for example on a trusted network) until TLS support lands in the agent.
- Remember that the signaling server only checks that a token is valid, not roles, so any signed-in user can manage stations.
- Without a TURN server, peers behind strict NAT may not be able to connect (see [Troubleshooting](../troubleshooting.md)).
