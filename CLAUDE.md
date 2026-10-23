# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This directory is the `github.com/Ham-QSP/Qsp` repository, which only tracks the workspace-level files (this `CLAUDE.md`, `.gitignore`). It holds several independent repositories of the QSP project (remote operation of ham radio transceivers over the Internet), each with its own remote under `github.com/Ham-QSP`, its own CI and its own branches. Run git, build and `gh` commands from inside the relevant sub-repository. Some sub-repositories have their own `CLAUDE.md` / `AGENTS.md` with more detail (`qsp-agent`, `qsp-authentication`).

## Repositories

| Directory | Stack | Build / test |
|---|---|---|
| `qsp-agent/` | Rust workspace (tokio, webrtc-rs, Hamlib via bindgen, cpal, Opus) | `cargo build --workspace --locked`, `cargo test --workspace --locked`, `cargo fmt --all --check` |
| `qsp-signaling-server/` | Kotlin, Spring Boot 4 WebFlux, R2DBC + Liquibase, PostgreSQL | `./mvnw verify`, `./mvnw spring-boot:run` (port 7080) |
| `qsp-authentication/` | Kotlin, Spring Authorization Server, PostgreSQL + Liquibase | `./mvnw verify`, `./mvnw spring-boot:run` (port 9000); tests use Testcontainers and need Docker |
| `qsp-web/` | Vue 3 + Vuetify + Pinia, Vite, TypeScript | yarn 1 (`yarn.lock`, no `npm install`): `yarn install --frozen-lockfile`, `yarn dev` (port 3000), `yarn build-only` (vite only, what CI runs), `yarn type-check` (`vue-tsc`, currently failing), `yarn build` (both), `yarn lint` (runs `eslint --fix`) |
| `qsp-proto-files/` | Protobuf schemas (buf) packaged as a Rust crate (prost) and a TS package (`@bufbuild/protobuf`) | `npm run lint` (buf lint), `npm run generate`, `npm run build`, `cargo test --workspace` |
| `qsp-infra/` | Ansible + docker compose (PostgreSQL, databases and roles) | `ansible-playbook ansible/main.yml --vault-password-file vault.pass -i ansible/hosts.ini` (vars are vault-encrypted) |

The Java services require JDK 25. For a single Maven test, use `./mvnw test -Dtest=ClassName#method`. For a single Rust test, use `cargo test -p <crate> <name>`.

## System architecture

```
qsp-web (browser) ──OAuth2 PKCE──► qsp-authentication (/oauth2/token, JWT issuer)
     │ REST + Bearer JWT
     ▼
qsp-signaling-server ◄──WebSocket /server/session── qsp-agent (next to the radio)
     │                                                   │
     └──── relays one SDP offer/answer ────────────────┘
qsp-web ◄════ WebRTC: Opus audio track + "qsp-control" data channel (protobuf) ════► qsp-agent
```

- **Signaling server**: a JWT resource server whose issuer is the authentication server (`spring.security.oauth2.resourceserver.jwt.issuer-uri`). `/server/session` is the only unauthenticated endpoint, and it is where agents connect.
  - Agents connect over a WebSocket with JSON messages tagged by `command` (`SERVER_HELLO` → `AGENT_HELLO` carrying `agentId`/`agentSecret`, `CLIENT_INIT` → `INIT_RESPONSE`, `MESSAGE_ERROR`).
  - Clients call `POST /client/signal` with `{agentSessionId, clientSdp}`. The server forwards it as `CLIENT_INIT` on the agent's socket and returns the agent's SDP answer.
  - `GET /client/agents` lists the connected agent sessions. `/station/**` manages stations and agents and generates the agent HMAC secrets. `GET /server/description` returns the server name and description.
  - Agent sessions live in memory; stations and agents are stored in PostgreSQL.
- **Single signaling round trip**: there is no trickle ICE. The agent waits for ICE gathering to complete before answering, so all candidates travel in that single SDP answer. Any change to the handshake affects the agent, the signaling server and the web client together.
- **Control protocol**: after the WebRTC connection opens, the web client sends an agent `Hello` on the `qsp-control` data channel. The agent replies with the transceiver capabilities and then streams frequency/mode updates. Commands (frequency, mode, band, VFO ops) are only accepted after the hello.
- **Shared schemas**: messages are `AgentControlMessage` from `qsp-proto-files/proto/qsp/trxcontrol/v1/trx_control.proto`. The Rust crate re-exports that package as `qsp_proto_files::qsp::message::v1`.
  - Consumers pin a released version: `qsp-agent` uses a git tag in `qsp-agent/Cargo.toml`, and `qsp-web` uses `@ham-qsp/proto-files` from GitHub Packages, which needs a `read:packages` token in `~/.npmrc` (see `qsp-web/README.md`).
  - To change the protocol, edit the proto, bump the version in both `Cargo.toml` and `package.json`, tag `v*`, then update both consumers.
- **Web client runtime config**: the web client loads `/config.json` at startup (`qsp-web/public/config.json`), which holds `signalingServerPrefix`, `authenticationServerPrefix` and `portalUrl`. The signaling server's `ClientController` only allows CORS from `http://localhost:3000`.

## CI / release conventions

- Java services: CI runs `./mvnw verify` on PRs. A push to `main` publishes the Docker image `f4fez/qsp-<name>:latest`. Releases run manually through GitHub Actions "Run workflow" (Maven Release Plugin, tag `v<version>`).
- `qsp-agent`: CI builds `.deb` packages (amd64/arm64/armhf) and publishes them on `v*` tags.
- `qsp-proto-files`: a `v*` tag publishes the TS package.
- Dependabot opens monthly PRs. On `qsp-authentication`, the `main` ruleset restricts updates, so merges go through the repository-admin bypass.
