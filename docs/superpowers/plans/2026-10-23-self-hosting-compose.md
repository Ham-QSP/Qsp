# Self-hosting compose example Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One `docker compose up` on a single machine gives a working QSP instance — PostgreSQL, auth, signaling, web client, all behind one reverse-proxy origin — configured only through an environment file, so a radio amateur or self-hoster can try the full stack quickly.

**Architecture:** A `self-hosting/` directory in the root `Ham-QSP/Qsp` repo. A reverse proxy (nginx) fronts everything on one origin and routes by path prefix: `/auth` → auth server, `/signaling` → signaling server (including the agent WebSocket at `/signaling/server/session`), everything else → the web client. One PostgreSQL container holds a single database shared by both Java services (they are designed for it); the two services keep their Liquibase tracking tables separate so their identical changeset ids do not collide. Security is deliberately light (maintainer's call): the PostgreSQL superuser is used directly, no dedicated roles, and the env file ships working default passwords. Image versions are pinned to released tags.

**Tech Stack:** Docker Compose, nginx (reverse proxy), PostgreSQL 18, `f4fez/qsp-authentication-server`, `f4fez/qsp-signaling-server`, `f4fez/qsp-web` (from Plan A).

**Spec:** `docs/superpowers/specs/2026-10-16-qsp-website-design.md` — "Self-hosting example" and "Constraints the builder must respect".

## Global Constraints

- Directory: `self-hosting/` at the root of `Ham-QSP/Qsp`.
- **No hard-coded IP.** The only per-machine configuration is the public host name and port, plus passwords, all in `self-hosting/.env` (with a committed `self-hosting/.env.example`).
- **Single shared database**, PostgreSQL superuser `postgres`, no dedicated roles (spec, maintainer's call 2026-10-23).
- **Separate Liquibase tracking tables per service** via `SPRING_LIQUIBASE_DATABASE_CHANGE_LOG_TABLE` / `SPRING_LIQUIBASE_DATABASE_CHANGE_LOG_LOCK_TABLE` — both changelogs use changeset id `1`, author "Florian MAZEN", file `db/changelog/00000_initial.yaml`, so a shared `databasechangelog` would fail checksum validation on the second service to start. Business tables do not overlap (`qsp_auth_*` vs `station`/`agent`).
- **Pinned image versions**, not `:latest` (spec "Order and versions"). The exact tags are filled in once the maintainer runs the releases from Plan A's merges.
- **Security is light but not silent:** default passwords live in `.env.example`; the docs page states plainly they are for a local trial and lists what a real deployment must change.
- **WebRTC media is peer-to-peer** and does not pass through the proxy; the compose relays only signaling and control, never media.

## Review Focus

- **JWT issuer consistency (the main trap):** a token's `iss` claim is the public auth URL the browser used (`http://HOST:PORT/auth`); the signaling server validates that claim *and* must fetch JWKS from inside the compose network. The design sets signaling's `issuer-uri` to the public URL (claim validation) and its `jwk-set-uri` to the internal URL (`http://auth:9000/oauth2/jwks`), and sets the auth server's own issuer to the public URL so the `iss` claim matches. Covered by Task 3's verification.
- **OAuth redirect URI mismatch:** the auth server's registered `portal` redirect URI must equal `http://HOST:PORT/login-redirect.html` exactly, or sign-in fails with `invalid_redirect_uri`. Covered by Task 2 + Task 5.
- **Agent WebSocket path through the proxy:** the agent connects to `ws://HOST:PORT/signaling/server/session`; the proxy must forward `/signaling/server/session` to the signaling server's `/server/session` with `Upgrade`/`Connection` headers, or the agent never connects. Covered by Task 1 + Task 5.
- **CORS:** single origin means the browser's calls to `/auth` and `/signaling` are same-origin, avoiding the signaling server's hard-coded `http://localhost:3000` allow-list. The design must keep everything on one origin; if it ever splits, CORS breaks. Covered by Task 5's end-to-end check.
- **Startup ordering / first-run migrations:** both services run Liquibase against the same database on first boot; `depends_on` with a Postgres healthcheck must gate them, and the separate lock tables must let them migrate concurrently without deadlock. Covered by Task 3.

---

### Task 1: Reverse proxy and compose skeleton (Postgres + proxy)

**Files:**
- Create: `self-hosting/docker-compose.yml`
- Create: `self-hosting/.env.example`
- Create: `self-hosting/proxy/nginx.conf`
- Create: `self-hosting/README.md` (short pointer to the docs page; full walkthrough lives in the mdbook — Plan C)

**Interfaces:**
- Produces: a compose network where services are reachable by name (`db`, `auth`, `signaling`, `web`, `proxy`); the proxy listens on `${QSP_PORT}` and routes `/auth/*`, `/signaling/*` (incl. WebSocket), and `/` (web). `.env` defines `QSP_HOST`, `QSP_PORT`, `POSTGRES_PASSWORD`, `QSP_ADMIN_PASSWORD`.

- [ ] **Step 1: Write `.env.example`** with `QSP_HOST=localhost`, `QSP_PORT=8080`, `POSTGRES_PASSWORD=<default>`, `QSP_ADMIN_PASSWORD=<default>`, and a header comment that these defaults are for a local trial only.

- [ ] **Step 2: Write the Postgres + proxy services in `docker-compose.yml`** — `db` using `postgres:18` with `POSTGRES_PASSWORD` and `POSTGRES_DB=qsp`, a healthcheck (`pg_isready -U postgres`), and a named volume; `proxy` using a pinned `nginx` image, mounting `proxy/nginx.conf`, publishing `${QSP_PORT}:80`, `depends_on` web/auth/signaling.

- [ ] **Step 3: Write `proxy/nginx.conf`** — one `server` on port 80. `location /auth/ { proxy_pass http://auth:9000/; }` (strip prefix), `location /signaling/ { proxy_pass http://signaling:7080/; }` with `proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade"; proxy_http_version 1.1;` so `/signaling/server/session` upgrades, and `location / { proxy_pass http://web:80/; }`. Forward `Host` and `X-Forwarded-*` headers.

- [ ] **Step 4: Verify proxy + db come up**

Run: `cd self-hosting && cp .env.example .env && docker compose up -d db proxy && docker compose ps`
Expected: `db` healthy, `proxy` running. `docker compose down` after.

- [ ] **Step 5: Commit**

```bash
git add self-hosting/docker-compose.yml self-hosting/.env.example self-hosting/proxy/nginx.conf self-hosting/README.md
git commit -m "feat(self-hosting): reverse proxy and compose skeleton"
```

---

### Task 2: Auth server service (single DB, separate Liquibase tables, public issuer, redirect URI)

**Files:**
- Modify: `self-hosting/docker-compose.yml` (add `auth`)

**Interfaces:**
- Consumes: `db`, `.env` (`QSP_HOST`, `QSP_PORT`, `POSTGRES_PASSWORD`, `QSP_ADMIN_PASSWORD`).
- Produces: auth server reachable in-network at `http://auth:9000`, publicly at `http://${QSP_HOST}:${QSP_PORT}/auth`; JWKS in-network at `http://auth:9000/oauth2/jwks`; issuer claim = `http://${QSP_HOST}:${QSP_PORT}/auth`.

- [ ] **Step 1: Add the `auth` service** pinned to `f4fez/qsp-authentication-server:<version>` with env:
  - `SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/qsp`, `SPRING_DATASOURCE_USERNAME=postgres`, `SPRING_DATASOURCE_PASSWORD=${POSTGRES_PASSWORD}`
  - `SPRING_LIQUIBASE_DATABASE_CHANGE_LOG_TABLE=auth_databasechangelog`, `SPRING_LIQUIBASE_DATABASE_CHANGE_LOG_LOCK_TABLE=auth_databasechangeloglock`
  - `SPRING_SECURITY_OAUTH2_AUTHORIZATIONSERVER_ISSUER=http://${QSP_HOST}:${QSP_PORT}/auth` (makes the `iss` claim match the public URL)
  - `QSP_AUTHORIZATION_CLIENTS_PORTAL_REDIRECT-URI[0]=http://${QSP_HOST}:${QSP_PORT}/login-redirect.html` (exact match with Plan A's client path; Spring relaxed binding accepts this form — verify the exact env key against the property `qsp.authorization.clients.portal.redirect-uri`)
  - `depends_on: db (service_healthy)`

- [ ] **Step 2: Verify the issuer and discovery document**

Run: `cd self-hosting && docker compose up -d db auth && sleep for health then: curl -fsS http://localhost:8080/auth/.well-known/openid-configuration | grep -o '"issuer":"[^"]*"'`
Expected: `"issuer":"http://localhost:8080/auth"` — the issuer is the public URL, not an internal name. (Use the proxy from Task 1, or curl the container directly with the forwarded host header.)

- [ ] **Step 3: Verify the seeded admin tables migrated into the shared DB under the auth tracking table**

Run: `docker compose exec db psql -U postgres -d qsp -c "select count(*) from auth_databasechangelog;"` and `... -c "select username from qsp_auth_users;"`
Expected: a non-zero changelog count and the `admin` row present.

- [ ] **Step 4: Commit**

```bash
git add self-hosting/docker-compose.yml
git commit -m "feat(self-hosting): auth server on shared DB with public issuer"
```

---

### Task 3: Signaling server service (shared DB, separate Liquibase tables, split issuer/JWKS)

**Files:**
- Modify: `self-hosting/docker-compose.yml` (add `signaling`)

**Interfaces:**
- Consumes: `db`, `auth`, `.env`.
- Produces: signaling reachable in-network at `http://signaling:7080`, publicly at `/signaling`; validates Bearer JWTs whose `iss` is the public auth URL, fetching keys from `http://auth:9000/oauth2/jwks`.

- [ ] **Step 1: Add the `signaling` service** pinned to `f4fez/qsp-signaling-server:<version>` with env:
  - `SPRING_LIQUIBASE_URL=jdbc:postgresql://db:5432/qsp`, `SPRING_LIQUIBASE_USER=postgres`, `SPRING_LIQUIBASE_PASSWORD=${POSTGRES_PASSWORD}`
  - `SPRING_R2DBC_URL=r2dbc:postgresql://db:5432/qsp`, `SPRING_R2DBC_USERNAME=postgres`, `SPRING_R2DBC_PASSWORD=${POSTGRES_PASSWORD}`
  - `SPRING_LIQUIBASE_DATABASE_CHANGE_LOG_TABLE=signaling_databasechangelog`, `SPRING_LIQUIBASE_DATABASE_CHANGE_LOG_LOCK_TABLE=signaling_databasechangeloglock`
  - `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER-URI=http://${QSP_HOST}:${QSP_PORT}/auth` (validates the `iss` claim)
  - `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK-SET-URI=http://auth:9000/oauth2/jwks` (fetches keys in-network — resolves the issuer trap without DNS hairpinning)
  - `depends_on: db (service_healthy)`, `auth (service_started)`

- [ ] **Step 2: Verify both services coexist in the shared DB (the collision check)**

Run: `docker compose up -d db auth signaling` then `docker compose exec db psql -U postgres -d qsp -c "\dt"` and check logs: `docker compose logs signaling | grep -i 'liquibase\|started'`
Expected: tables `qsp_auth_*`, `station`, `agent`, `auth_databasechangelog`, `signaling_databasechangelog` all present; signaling starts without a Liquibase "checksum" / "Validation Failed" error. This is the single-DB decision proven.

- [ ] **Step 3: Verify JWT acceptance end-to-end** — obtain a token from auth (admin, `QSP_ADMIN_PASSWORD`, PKCE is only for the portal public client; for this check use the resource-owner path only if available, otherwise defer the token check to Task 5's browser flow) and call a protected signaling endpoint; confirm `401` without a token and `2xx`/`403`-by-role with a valid one, never a `500` from key-fetch failure.
Expected: no JWKS fetch error in `signaling` logs; issuer validation passes.

- [ ] **Step 4: Commit**

```bash
git add self-hosting/docker-compose.yml
git commit -m "feat(self-hosting): signaling server with split issuer/JWKS on shared DB"
```

---

### Task 4: Web client service and single-origin config.json

**Files:**
- Modify: `self-hosting/docker-compose.yml` (add `web`)
- Create: `self-hosting/web/config.json` (templated at run time) and, if templating is needed, `self-hosting/web/config.json.template` + an entrypoint note

**Interfaces:**
- Consumes: the `f4fez/qsp-web:<version>` image (Plan A), `.env`.
- Produces: the web client served at `/`, reading a `config.json` whose three prefixes all point at the single public origin.

- [ ] **Step 1: Add the `web` service** pinned to `f4fez/qsp-web:<version>`. Provide `config.json` with `signalingServerPrefix=http://${QSP_HOST}:${QSP_PORT}/signaling`, `authenticationServerPrefix=http://${QSP_HOST}:${QSP_PORT}/auth`, `portalUrl=http://${QSP_HOST}:${QSP_PORT}`. Because `config.json` needs env substitution and the image serves a static file, render it at startup: mount a template and an entrypoint that `envsubst`s it to `/usr/share/nginx/html/config.json`, or generate `self-hosting/web/config.json` from `.env` via a tiny init step. Choose whichever keeps "only `.env` is edited" true.

- [ ] **Step 2: Verify the served config reflects `.env`**

Run: set `QSP_HOST`/`QSP_PORT` in `.env`, `docker compose up -d web proxy`, `curl -fsS http://localhost:8080/config.json`
Expected: all three prefixes carry the configured host and port; `portalUrl` has no trailing path.

- [ ] **Step 3: Commit**

```bash
git add self-hosting/docker-compose.yml self-hosting/web/
git commit -m "feat(self-hosting): web client with single-origin runtime config"
```

---

### Task 5: Full-stack bring-up and sign-in smoke test

**Files:** none (verification + any fixes fold back into Tasks 1–4).

- [ ] **Step 1: Clean bring-up from scratch**

Run: `cd self-hosting && cp .env.example .env && docker compose down -v && docker compose up -d && docker compose ps`
Expected: every service healthy/running; no restart loops.

- [ ] **Step 2: Verify the OAuth authorize + redirect path resolves**

Run: `curl -fsS -o /dev/null -w '%{http_code}\n' "http://localhost:8080/auth/oauth2/authorize?response_type=code&client_id=portal&redirect_uri=http://localhost:8080/login-redirect.html&scope=openid&code_challenge=x&code_challenge_method=S256&state=x"`
Expected: a redirect to the login page (302) — **not** `invalid_redirect_uri`. A `invalid_redirect_uri` means Task 2's redirect-URI env did not bind; fix the env key.

- [ ] **Step 3: Verify the agent WebSocket endpoint upgrades through the proxy**

Run: a WebSocket probe to `ws://localhost:8080/signaling/server/session` (e.g. `websocat` or a tiny script) and confirm the server sends `SERVER_HELLO`.
Expected: handshake upgrades (101) and the first `SERVER_HELLO` JSON arrives — proves the proxy forwards the agent socket.

- [ ] **Step 4: Manual browser sign-in** (documented, run by a human): open `http://localhost:8080`, sign in as `admin` / `QSP_ADMIN_PASSWORD`, confirm the popup closes and the client is authenticated. This is the end-to-end proof the issuer/redirect/CORS constraints all hold at once.

- [ ] **Step 5: Record the verified version pins** in `.env.example`/compose comments so "one `docker compose up` works" stays reproducible, and note that bumping them is a deliberate change.

- [ ] **Step 6: Commit**

```bash
git add -A self-hosting/
git commit -m "chore(self-hosting): pin verified image versions and bring-up notes"
```

---

## Self-Review

- **Spec coverage:** compose running Postgres + auth + signaling + web + single-origin proxy → Tasks 1–4; one `docker compose up`, env-only config, no hard-coded IP → Tasks 1 & 5; issuer trap → Task 3; redirect URI → Tasks 2 & 5; CORS via single origin → Task 5; WebRTC not relayed → stated, nothing in the proxy routes media; pinned versions → Global Constraints + Task 5. The "Self-hosting quick start" docs page is Plan C. Admin password handling: the seeded admin's plaintext is supplied by the maintainer and used as `QSP_ADMIN_PASSWORD` default in `.env.example` (maintainer's choice 2026-10-23) — **fill the real value in before the example is usable**.
- **Type/name consistency:** redirect path `/login-redirect.html`, issuer `http://${QSP_HOST}:${QSP_PORT}/auth`, and internal JWKS `http://auth:9000/oauth2/jwks` are used identically across auth and signaling tasks. Liquibase table names are distinct per service.
- **Review Focus:** issuer (Task 3), redirect (Tasks 2/5), WS path (Tasks 1/5), CORS (Task 5), first-run migrations (Task 3) — each has a verification step.
- **Proportion:** infra plan, no application code; verification-heavy by design, which is correct for a compose example whose failure modes are integration-level.
- **Open item for the maintainer:** confirm the exact Spring relaxed-binding env key for the indexed redirect URI property (`QSP_AUTHORIZATION_CLIENTS_PORTAL_REDIRECT-URI[0]` vs `..._REDIRECTURI_0_`); Task 2 Step 1 verifies it empirically, so the plan is not blocked, but it is the one env key most likely to need a tweak.

## Execution Handoff

Plan complete. **Prerequisite:** Plan A merged and released so the pinned tags (`f4fez/qsp-web`, and the auth image carrying Plan A's redirect-URI default) exist. Recommended execution: **Native** — the tasks build one compose file incrementally and every constraint is proven by a command here; a fresh reviewer at the end checks the whole `self-hosting/` tree. Review the plan and confirm.
