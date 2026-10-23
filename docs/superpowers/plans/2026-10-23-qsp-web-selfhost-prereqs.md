# qsp-web self-hosting prerequisites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a released `qsp-web` build able to complete OAuth sign-in, and ship it as a runtime-configurable Docker image, so the self-hosting example can run the web client without a rebuild.

**Architecture:** Two changes in the `qsp-web` repository, each its own PR. (1) The OAuth login-redirect page is served from a build-stable path (`/login-redirect.html`) instead of the Vite-only `/src/assets/login-redirect.html`, and the auth server's registered redirect URI is updated to match. (2) A multi-stage Dockerfile builds the Vite bundle and serves `dist/` with nginx; `config.json` is a mounted/overridable runtime file, never baked in. CI publishes `f4fez/qsp-web` following the Java services' conventions.

**Tech Stack:** Vue 3 + Vite 5, yarn 1 (`--frozen-lockfile`), nginx (static serving), GitHub Actions, Docker Hub.

**Spec:** `docs/superpowers/specs/2026-10-16-qsp-website-design.md` (see "Self-hosting example" → "What to build", first two bullets).

## Global Constraints

- Repository: `github.com/Ham-QSP/qsp-web`. Each change is a separate, independently reviewable PR.
- Build command CI runs is `yarn build-only` (vite only); `yarn type-check` currently fails and must not gate the image build.
- yarn 1 with `yarn install --frozen-lockfile --non-interactive`; `@ham-qsp` scope needs a `read:packages` token (`NODE_AUTH_TOKEN`) as in the existing release workflow.
- Image name `f4fez/qsp-web`, tags `:latest` on push to `main` and `:<version>` on release, matching the Java services' CI (build into local daemon → Grype scan with `severity-cutoff: high`, `only-fixed: true` → push).
- `config.json` keys are `signalingServerPrefix`, `authenticationServerPrefix`, `portalUrl`; the web client fetches `/config.json` at startup. The image must let the operator supply it at run time without rebuilding.
- License headers: AGPL-3.0 header block on every new source file, matching existing files in the repo.

## Review Focus

- **Sign-in in a from-scratch production build** (not dev server): the redirect page must exist in `dist/` and the popup's `BroadcastChannel` round-trip must complete. Covered by Task 1.
- **`config.json` missing or unreadable at container start:** the client already throws "… prefix is not configured"; the image must always serve a `config.json` (the operator's, or a documented default), so a 404 on `/config.json` never happens silently. Covered by Task 2.
- **Image rebuild not required per deployment:** two different `config.json` files mounted into the same image must yield two differently-configured instances. Covered by Task 2.
- **SPA deep-link / refresh:** nginx must fall back to `index.html` for client-side routes, else a refresh on any route 404s. Covered by Task 2.
- **Grype high-severity gate:** the chosen nginx base image must pass the same scan the Java images pass, or the push step fails. Covered by Task 2.

---

### Task 1: Production-stable OAuth redirect page

**Files:**
- Modify: `qsp-web/src/stores/authent.ts:158-163` (the `loginRedirectUrl()` method)
- Move/Create: the redirect page so it lands in the build output as `dist/login-redirect.html` — put the source at `qsp-web/public/login-redirect.html` (Vite copies `public/` verbatim to `dist/`), migrating the content of `qsp-web/src/assets/login-redirect.html`
- Delete: `qsp-web/src/assets/login-redirect.html` once moved
- Cross-repo: `qsp-authentication/src/main/resources/application.yaml` — `qsp.authorization.clients.portal.redirect-uri` (its own PR; see note)

**Interfaces:**
- Produces: the client's OAuth `redirect_uri` is now `portalUrl + "/login-redirect.html"`. The compose example (Plan B) and the auth server's registered redirect URI must use this exact path.

- [ ] **Step 1: Confirm the failure** — build the current client and show the page is absent from the output.

Run: `cd qsp-web && yarn install --frozen-lockfile && yarn build-only && ls dist/src/assets/login-redirect.html dist/login-redirect.html`
Expected: both `ls` fail (no such file) — the redirect page is not in `dist/` today. This is the bug.

- [ ] **Step 2: Move the redirect page into `public/`**

`git mv src/assets/login-redirect.html public/login-redirect.html`. Keep its content and AGPL header unchanged — it reads `code`/`state` from the query string and posts on the `authent_popup` `BroadcastChannel`, which is path-independent.

- [ ] **Step 3: Point the client at the build-stable path**

In `src/stores/authent.ts`, change the returned value in `loginRedirectUrl()` from `this.config.portalUrl + "/src/assets/login-redirect.html"` to `this.config.portalUrl + "/login-redirect.html"`. Leave the `portalUrl`-not-configured guard as is.

- [ ] **Step 4: Verify the page is now in the build output**

Run: `cd qsp-web && yarn build-only && test -f dist/login-redirect.html && echo OK`
Expected: prints `OK`.

- [ ] **Step 5: Commit (qsp-web)**

```bash
cd qsp-web
git add public/login-redirect.html src/stores/authent.ts
git commit -m "fix: serve OAuth login-redirect page from build-stable path"
```

- [ ] **Step 6: Update the auth server's registered redirect URI (separate PR, qsp-authentication)**

In `qsp-authentication/src/main/resources/application.yaml`, the default `qsp.authorization.clients.portal.redirect-uri` is `http://localhost:3000/src/assets/login-redirect.html`. The production path is now `/login-redirect.html`. The registered URI must match the client's `redirect_uri` exactly (Spring Authorization Server requires an exact match). Because the host/port differ per deployment, the compose example overrides this through the environment variable `QSP_AUTHORIZATION_CLIENTS_PORTAL_REDIRECT_URI[0]` (Plan B) — but the committed default should still be self-consistent for local `yarn dev`: change it to `http://localhost:3000/login-redirect.html`. Commit in `qsp-authentication`:

```bash
cd qsp-authentication
git add src/main/resources/application.yaml
git commit -m "fix: align portal redirect URI with build-stable redirect path"
```

Note: `yarn dev` serves `public/` at the root too, so `/login-redirect.html` works on the dev server as well; the old `/src/assets/...` path stops being used by either environment.

---

### Task 2: Runtime-configurable Docker image for qsp-web

**Files:**
- Create: `qsp-web/.package/Dockerfile`
- Create: `qsp-web/.package/nginx.conf` (or `default.conf.template`)
- Create: `qsp-web/.package/config.json` (a documented default baked in as a fallback)
- Modify: `qsp-web/.github/workflows/release.yml` (add image build/push on release) and add `:latest` publishing on push to `main` (new job, mirroring the Java `docker` job)

**Interfaces:**
- Consumes: the `dist/` produced by `yarn build-only`, now including `login-redirect.html` from Task 1.
- Produces: image `f4fez/qsp-web` that serves the static client on port 80, serves `/config.json` from `/usr/share/nginx/html/config.json` (overridable by mounting a file or baking a layer), and falls back to `index.html` for unknown routes. The compose example (Plan B) mounts its own `config.json` here.

- [ ] **Step 1: Write the Dockerfile**

Multi-stage. Builder stage: a pinned Node 22 image, `corepack enable`, `yarn install --frozen-lockfile --non-interactive` (passing `NODE_AUTH_TOKEN` as a build secret or arg for the `@ham-qsp` scope), `yarn build-only`. Runtime stage: a pinned nginx image (choose one that passes the Grype high-severity gate), copy `dist/` to `/usr/share/nginx/html`, copy `.package/config.json` as the default, copy `.package/nginx.conf`. Do **not** run `yarn type-check`.

- [ ] **Step 2: Write the nginx config**

Serve `/usr/share/nginx/html`; `location / { try_files $uri $uri/ /index.html; }` for SPA routing; ensure `/config.json` is served with `Cache-Control: no-store` so a remounted config is picked up on reload. Listen on 80.

- [ ] **Step 3: Build the image and verify sign-in assets and SPA fallback are served**

```bash
cd qsp-web
docker build -f .package/Dockerfile -t qsp-web:test --secret id=node_auth,env=NODE_AUTH_TOKEN .
cid=$(docker run -d -p 8099:80 qsp-web:test)
curl -fsS localhost:8099/login-redirect.html >/dev/null && echo REDIRECT_OK
curl -fsS localhost:8099/config.json >/dev/null && echo CONFIG_OK
curl -fsS localhost:8099/some/deep/route | grep -q '<div id="app">' && echo SPA_OK
docker rm -f "$cid"
```
Expected: `REDIRECT_OK`, `CONFIG_OK`, `SPA_OK`.

- [ ] **Step 4: Verify runtime config override needs no rebuild**

```bash
echo '{"signalingServerPrefix":"http://x/signaling","authenticationServerPrefix":"http://x/auth","portalUrl":"http://x"}' > /tmp/cfg.json
cid=$(docker run -d -p 8099:80 -v /tmp/cfg.json:/usr/share/nginx/html/config.json:ro qsp-web:test)
curl -fsS localhost:8099/config.json | grep -q '"portalUrl":"http://x"' && echo OVERRIDE_OK
docker rm -f "$cid"
```
Expected: `OVERRIDE_OK` — the same image serves the mounted config.

- [ ] **Step 5: Add CI publishing**

Mirror the Java `docker` job: on push to `main`, build into the local daemon, scan with `anchore/scan-action` (`severity-cutoff: high`, `only-fixed: true`, `fail-build: true`), upload the SARIF, then push `f4fez/qsp-web:latest`; on release, also push `f4fez/qsp-web:<version>`. Use `secrets.DOCKER_HUB_USERNAME` / `secrets.DOCKER_HUB_TOKEN` and `secrets.GITHUB_TOKEN` for the `@ham-qsp` package read. Pin all actions by SHA as the existing workflows do.

- [ ] **Step 6: Verify the scan gate locally**

Run: `anchore/grype qsp-web:test --fail-on high --only-fixed` (or the CLI equivalent) and confirm it exits 0. If it fails, bump the nginx base image to a digest that passes, as the auth Dockerfile comment describes doing for its base.
Expected: exit 0.

- [ ] **Step 7: Commit (qsp-web)**

```bash
cd qsp-web
git add .package/ .github/workflows/release.yml
git commit -m "feat: publish runtime-configurable qsp-web Docker image"
```

---

## Self-Review

- **Spec coverage:** "Docker image for qsp-web" → Task 2; "Fix sign-in in the built web client" → Task 1. Both spec bullets covered.
- **Cross-repo ordering:** Task 1's auth-server redirect-URI change and both qsp-web changes must be merged and **released** (so Plan B can pin versions) before Plan B's compose can pin `f4fez/qsp-web:<version>` and the matching auth image. This matches the spec's "Order and versions".
- **Type consistency:** the redirect path string `"/login-redirect.html"` is identical in the client (`loginRedirectUrl`), the auth server default, and Plan B's `QSP_AUTHORIZATION_CLIENTS_PORTAL_REDIRECT_URI[0]` override.
- **Proportion:** config/infra work; no algorithmic code, so no code bodies — correct for this plan.

## Execution Handoff

Plan complete. It has a cross-repo dependency (auth server redirect URI) and an external release step the maintainer runs. Recommended execution: **Native**, because the tasks are few, mostly infra, and each is verifiable locally with Docker before the maintainer releases. Review the plan and confirm the approach.
