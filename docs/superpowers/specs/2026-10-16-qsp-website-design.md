# QSP website and documentation — design

Date: 2026-10-16
Status: approved (2026-10-23)

## Intent

QSP lets a radio amateur operate their transceiver remotely from a web browser: control (frequency, mode, band, VFO) and live audio. The project needs a public face:

1. a **presentation site** that makes a radio amateur understand, quickly, what QSP is for and what it brings them;
2. a **documentation** (mdbook) that explains how QSP works in simple terms and how to install and configure the agent, plus a shorter advanced part for self-hosters and developers;
3. a **self-hosting example**: a single `docker compose` that runs every infrastructure service, so that someone can try a full QSP instance quickly.

QSP will be offered as a hosted, open service. A standard user only ever installs the **agent** next to their rig; everything else is run for them. The project is free software, so self-hosting and contributing must be possible, but they are the secondary audience.

## Audience

- **Primary:** radio amateurs who want to use the hosted service. They know their rig, CAT and audio interfaces; they are not necessarily developers. Their whole journey is: understand → register their station → install and configure the agent on a Raspberry Pi → operate from a browser.
- **Secondary:** self-hosters and developers. They need the big picture and the fastest path to a running instance. Developers go to each repository's README for details.

## Goals

- A radio amateur landing on the homepage understands in seconds what QSP does and how it works (browser ↔ agent, services only introduce them).
- A radio amateur can go from zero to operating with only the user part of the docs, using a Raspberry Pi as the reference setup.
- A self-hoster can run a complete QSP instance on one machine with one `docker compose up`, by following one docs page.
- Everything is static files, built and published by CI on every push to `main`.

## Non-goals

- No server-side rendering, no backend for the site, no CMS.
- No translation: English only. Can evolve in the future
- No duplication of per-repository details in the docs (see "Docs vs READMEs").
- No production-grade self-hosting guide (TLS, backups, scaling, hardening) — the compose file is a quick-start example.
- No logo or brand identity work; no custom domain for now (can be added later without changing the build).
- No support for non-Linux agents (the agent only runs on Linux today).

## Anti-goals (would be a failure even if it works)

- The homepage or the docs suggest that audio/control goes through the QSP servers. It does not: once connected, the browser and the agent talk **directly** (WebRTC, peer to peer). The servers only handle sign-in and introduce the two.
- The docs become a second, drifting copy of the READMEs.
- The compose example only works on the author's machine (hard-coded IPs such as `192.168.10.40`, as in today's dev configs).
- The site needs a JS framework or a build step to be edited.

## Decisions made with the maintainer

- **Repository:** everything lives in the root repository `github.com/Ham-QSP/Qsp` (this directory). Sub-projects remain separate repositories, ignored by the root `.gitignore`.
- **Language:** English only.
- **Tech:** static HTML/CSS (and JS only where really useful) for the presentation site; mdbook for the documentation. No SSR.
- **Homepage structure** (validated on a wireframe):
  1. top navigation: QSP · Features · How it works · Docs · GitHub;
  2. hero: one-line promise ("Operate your radio from anywhere."-style), short sub-line, buttons *Get started* (→ agent install guide) and *Read the docs*;
  3. screenshot of the web client;
  4. three benefit tiles (initial proposal: browser only, live audio, Hamlib-supported rigs — final wording is the builder's);
  5. **How it works** with a diagram: *Your browser* and *QSP agent* (with the rig attached via CAT + audio) linked by a thick, two-way **direct connection** (audio + control, peer to peer); *QSP services* drawn above in dashed lines, with dashed links only, labelled as sign-in and "introduce browser and agent"; then three short paragraphs (the agent / the QSP services / your browser);
  6. *Get started* in three steps: install the agent, sign in, operate;
  7. an open-source band: free software, self-host with docker compose → advanced docs.
- **Docs table of contents** (validated):
  - User part: Introduction · How QSP works (same diagram) · Getting started (Requirements · Register your station · Install the agent · Configure the agent · Run as a service · Operate from your browser) · Troubleshooting.
  - Advanced part: Architecture · Self-hosting quick start (docker compose) · Developer guide.
- **Reference hardware:** a Raspberry Pi running the 64-bit Raspberry Pi OS (the agent's `.deb` releases are built for amd64 and arm64). The docs state clearly that only Linux is supported.
- **Docker work is in scope:** the self-hosting example, including the missing pieces it needs (see below).
- **The self-hosting example favours simplicity over security** (maintainer's call): a single database shared by both services (they are designed for it), no dedicated database roles, the services use the PostgreSQL superuser directly, and default passwords are acceptable in the example. It is a trial setup, not a template for production.
- **User guide targets the hosted service as it will be** (option chosen by the maintainer), even though it is not open yet. See "Hosted service: what the user guide may assume".
- **Audio device:** the agent always uses the system's default audio input device. A setting to choose the device will be added to the agent later, outside this project. The docs only state that the agent uses the default device; they do not explain how to change it.

## Hosted service: what the user guide may assume

The hosted service is not open yet, and several pieces of the self-service journey do not exist (verified in the code on 2026-10-16):

- there is no public address;
- accounts are created by an administrator only (`/users` requires the admin role); there is no self sign-up;
- stations and agents have no owner: any signed-in user can list and manage all of them, including agent secrets; there is no self-service "register your station" UI;
- the agent's WebSocket client (`tokio-tungstenite`) is built without TLS, so it cannot connect to a `wss://` URL.

The user guide is written for the hosted service as it will be, with **provisional procedures** where the product is not there yet:

- the service address is a single, clearly marked placeholder (defined once, e.g. an mdbook variable or one include, so it is replaced in one place when known);
- "Register your station" describes the current manual process: the user asks the service operator for an account, and the operator creates the station and agent and gives the user the agent ID and secret. The page says this will become self-service;
- the homepage "Get started" points to the docs as planned; nothing claims the service is open today.

Not part of this project (the maintainer chose option A without the extra development): self sign-up, station ownership, and TLS (`wss://`) support in the agent. *My note:* the hosted service will need agent TLS before it opens; the user guide's agent configuration example should use the URL form the hosted service will use, and that gap must be tracked separately.

## Docs vs READMEs

Each repository's README is the source of truth for its own details (build commands, every configuration option, internals). The advanced docs are a **map**: they explain what no single README can — how the services fit together, the order of the connection setup, the shortest path to a running instance — and link to the relevant README at each step for depth. When writing the docs reveals that a README lacks something needed, the README gets fixed (in its own repository, via a PR), not the docs.

The user part is different: it is the complete, self-sufficient guide for a radio amateur, written for them, and may restate what they need from the agent README in friendlier terms.

## Site layout and publishing (my calls)

- `site/` — the presentation site: a single `index.html` (in-page anchors for Features and How it works), one stylesheet, optional small script, images. The diagram is inline SVG, no animation. Light and dark themes follow the system setting. Sober styling.
- `docs/` — the mdbook (`docs/book.toml`, `docs/src/…`). Design notes like this one live under `docs/superpowers/`, outside `docs/src`, so they are not published.
- Published with **GitHub Pages** from the `Qsp` repository (public, so Pages is free) by a GitHub Actions workflow on push to `main`: build the mdbook, place the presentation site at the root and the book under `/docs/`, deploy. Pin the mdbook version in the workflow. A PR build (without deploy) validates that the book builds.
- The homepage screenshot is a real capture of `qsp-web`; until one exists, a clearly marked placeholder is acceptable.
- "Get started" links to the docs' agent install guide. There is no link to the hosted service yet: its public address does not exist.

## Self-hosting example

### What exists today

- Docker images are published for the authentication server (`f4fez/qsp-authentication-server`) and the signaling server (`f4fez/qsp-signaling-server`), built from each repo's `.package/Dockerfile`: `:latest` on push to `main`, a version tag on release.
- `qsp-web` is released as a static archive (`qsp-web-<version>.tar.xz`); there is **no Docker image**.
- `qsp-infra` runs PostgreSQL 18 with docker compose, but creates databases and roles with Ansible and vault-encrypted variables — not reusable as is.
- The web client reads `/config.json` at startup (`signalingServerPrefix`, `authenticationServerPrefix`, `portalUrl`). The current dev/prod setup puts both services behind one origin with path prefixes (`…:81/auth`, `…:81/signaling`).
- The authentication server seeds an `admin` user (Liquibase `00000_initial.yaml`). Users are created through its `/users` REST API; stations and agents (and the agent HMAC secret) through the signaling server's `/station/**` REST API. There is no web UI for these yet.

### What to build

- A **Docker image for `qsp-web`**, in the `qsp-web` repository, following the same conventions as the Java services (`.package/Dockerfile`, published as `f4fez/qsp-web` by CI: `:latest` on push to `main`, a version tag on release). It serves the built static files and lets the operator provide `config.json` at run time (no rebuild per deployment).
- **Fix sign-in in the built web client** (`qsp-web`): the OAuth redirect points to `portalUrl + "/src/assets/login-redirect.html"`, a path that only exists on the Vite dev server and is absent from the production build. The released archive therefore cannot complete sign-in. The redirect page must be part of the build output, and the auth server's registered redirect URI updated to match.
- In the root repository, a **self-hosting example** directory (name is the builder's call, e.g. `self-hosting/`) containing the compose file, an example environment file, and whatever small config files the services need. It runs:
  - PostgreSQL with a single database shared by both services (they are designed to run this way), so no init step is needed beyond what the official image does; both services connect with the PostgreSQL superuser (`postgres`), no dedicated roles;
  - both services keep their tables in the `public` schema (their table names do not overlap), but each one gets its own Liquibase tracking tables through `SPRING_LIQUIBASE_DATABASE_CHANGE_LOG_TABLE` / `SPRING_LIQUIBASE_DATABASE_CHANGE_LOG_LOCK_TABLE`: both changelogs use the same changeset id, author and file path (`db/changelog/00000_initial.yaml`, id `1`), so a shared `databasechangelog` table would make the second service fail checksum validation (maintainer's choice, 2026-10-23);
  - `qsp-authentication` and `qsp-signaling-server`;
  - the web client;
  - a single entry point (reverse proxy) exposing everything on **one origin** with path prefixes, like the current deployment, so the browser, the agent's WebSocket (`/server/session`) and OAuth redirects all use the same host.
- One `docker compose up` must give a working instance on a single machine, configured only through the environment file (public host name / port; passwords have working defaults). No hard-coded IP.
- The docs page "Self-hosting quick start" walks through: start the stack, sign in, create a station and an agent (using the seeded admin and the REST APIs, until a UI exists), point an agent at the instance, operate. It warns that this is not a production setup and says what to change for one.

### Constraints the builder must respect

- **JWT issuer consistency.** Tokens carry the issuer URL that the browser sees; the signaling server validates it (`issuer-uri`) and must also be able to fetch the auth server's metadata/keys from inside the compose network. The setup must make both true at once — this is the main trap of the compose example.
- **OAuth redirect URIs** registered in the auth server (`qsp.authorization.clients.portal.redirect-uri`) must match the web client's public URL.
- **CORS:** the signaling server only allows `http://localhost:3000` today; a single-origin setup avoids the problem, otherwise it must be made configurable.
- **WebRTC is direct between browser and agent.** The compose example does not relay media. There is no TURN server in QSP today; the docs must say that both ends need to be able to reach each other (and what typically breaks it).
- **Security is deliberately light:** the example environment file may ship working default passwords (database superuser, seeded admin). The docs page says plainly that these defaults are for a local trial only, and lists what a real deployment must change (dedicated database roles, strong passwords, admin password change, TLS).
- Changes needed in sub-projects (e.g. making a setting configurable through an environment variable) go to those repositories as separate PRs, keeping their own conventions.
- The reverse-proxy configuration behind today's `…:81/auth` / `…:81/signaling` deployment is not in any repository: the proxy is designed from scratch.

### Order and versions (my calls)

- Sub-project PRs (web image, sign-in fix, any configurability such as CORS or the issuer behind a path prefix) come first. The maintainer merges them and runs the releases (manual Release workflows for the Java services and `qsp-web`).
- The compose example then **pins released image versions**, not `:latest`, so that "one `docker compose up` works" stays true when `main` moves. Bumping them is a deliberate change.

### Maintainer prerequisites (cannot be done from code)

- Enable GitHub Pages on `Ham-QSP/Qsp` with "GitHub Actions" as the source.
- Make sure the `qsp-web` repository has the Docker Hub credentials its CI needs to publish `f4fez/qsp-web` (the Java repos use `DOCKER_HUB_USERNAME` / `DOCKER_HUB_TOKEN`).
- Run the sub-project releases.

## Left to the builder

- Final wording of the homepage and the docs, visual style details, the benefit tiles' content.
- The reverse proxy choice and its configuration; the exact compose layout and file names.
- How the web image injects `config.json`.
- How to solve the issuer constraint (network alias, proxy headers, separate JWK set URI…), as long as one `docker compose up` works with only the environment file.
- mdbook theme tweaks, as long as navigation back to the homepage exists.
- Order of work, as long as each piece can be reviewed on its own (site, docs, web image, compose example).
