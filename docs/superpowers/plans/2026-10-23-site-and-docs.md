# Presentation site and documentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A static presentation site and an mdbook documentation, built and published to GitHub Pages by CI on every push to `main`, so a radio amateur understands QSP in seconds and can go from zero to operating, and a self-hoster can reach a running instance from one docs page.

**Architecture:** `site/` holds a single `index.html` (in-page anchors), one stylesheet, an inline-SVG "How it works" diagram, and a placeholder screenshot. `docs/` holds an mdbook (`docs/book.toml`, `docs/src/…`) with a User part and an Advanced part. A GitHub Actions workflow builds the book, lays the site at the Pages root and the book under `/docs/`, and deploys; PR builds validate the book without deploying. Everything is static — no framework, no build step to edit the site.

**Tech Stack:** Static HTML/CSS (+ minimal JS only if needed), mdbook (pinned version), GitHub Actions, GitHub Pages.

**Spec:** `docs/superpowers/specs/2026-10-16-qsp-website-design.md` — "Homepage structure", "Docs table of contents", "Site layout and publishing", "Hosted service: what the user guide may assume", "Docs vs READMEs".

## Global Constraints

- Everything is static files, editable without a build step; the site needs no JS framework.
- English only. Sober styling. Light and dark themes follow the system setting (`prefers-color-scheme`).
- **Anti-goal — never imply media/control goes through QSP servers.** The diagram and copy must show the browser↔agent connection as a thick, two-way **direct** (peer-to-peer, WebRTC) link; the QSP services appear above in dashed lines, labelled sign-in and "introduce browser and agent" only.
- **No hard-coded IP** anywhere; the service address in the docs is a single, clearly-marked placeholder defined in one place (an mdbook variable or one include) so it is replaced once when known.
- The user guide targets the hosted service **as it will be**, with provisional procedures clearly marked where the product is not there yet (manual "register your station" via the operator; no self sign-up; no public address yet). Nothing claims the service is open today.
- Reference hardware for the user guide: a Raspberry Pi running 64-bit Raspberry Pi OS; state clearly that only Linux is supported.
- Docs are a **map**, not a second copy of the READMEs: the advanced part links to each repo's README for depth; the user part is self-sufficient and may restate agent details in friendlier terms.
- Pin the mdbook version in the workflow. Publish from the `Ham-QSP/Qsp` repo via GitHub Actions as the Pages source.

## Review Focus

- **The "direct connection" message:** a reader must not come away thinking audio/control is relayed by QSP servers — the single most important correctness property of the whole site. Covered by Task 1 (diagram) and reviewed in Task 1 Step 4.
- **Dark mode legibility:** the inline-SVG diagram and the page must be readable in both themes (stroke/fill via `currentColor` or theme tokens, explicit `body` background). Covered by Task 1.
- **Phone width:** no horizontal scroll, 16px side gutter, diagram scales down. Covered by Task 1.
- **Placeholder service address appears in exactly one place:** a reader (or the maintainer) can replace it once; it must not be copy-pasted across pages. Covered by Task 3.
- **Book builds in CI before deploy:** a broken `SUMMARY.md` link must fail the PR build, not ship a 404. Covered by Task 4.

---

### Task 1: Presentation site (`site/`)

**Files:**
- Create: `site/index.html`, `site/styles.css`, `site/assets/screenshot-placeholder.*` (clearly marked placeholder)
- Create (optional): `site/app.js` only if a feature genuinely needs it (e.g. copy-to-clipboard); otherwise omit.

**Interfaces:**
- Produces: the Pages root page. Links: *Get started* → `/docs/` agent install guide; *Read the docs* → `/docs/`; GitHub → repo. In-page anchors `#features`, `#how-it-works`.

- [ ] **Step 1: Build the page structure** per the validated wireframe — top nav (QSP · Features · How it works · Docs · GitHub); hero (one-line promise, sub-line, *Get started* + *Read the docs* buttons); web-client screenshot (placeholder); three benefit tiles (browser-only, live audio, Hamlib-supported rigs — final wording is yours); How it works (diagram + three short paragraphs: the agent / the QSP services / your browser); Get started in three steps (install the agent, sign in, operate); open-source band (free software; self-host with docker compose → advanced docs).

- [ ] **Step 2: Draw the inline-SVG "How it works" diagram** — *Your browser* and *QSP agent* (rig attached via CAT + audio) joined by a thick two-way **direct connection** labelled audio + control, peer to peer; *QSP services* above in dashed outline with dashed links only, labelled sign-in and "introduce browser and agent". No animation. Use theme-aware colors.

- [ ] **Step 3: Style for both themes and phone width** — define color tokens on `:root`, redefine under `@media (prefers-color-scheme: dark)`, explicit `body` background; ensure 16px gutter, no horizontal scroll, diagram scales on narrow screens.

- [ ] **Step 4: Verify locally and review the direct-connection message**

Run: serve `site/` statically (`python3 -m http.server -d site 8081`) and open it; check in light and dark, at desktop and ~375px widths.
Expected: no horizontal scroll; diagram legible in both themes; a first-time reader can see that browser↔agent is direct and that services only introduce them. Fix copy/diagram if the relay misreading is possible.

- [ ] **Step 5: Commit**

```bash
git add site/
git commit -m "feat: QSP presentation site"
```

---

### Task 2: mdbook scaffold and shared "How it works" + service-address placeholder

**Files:**
- Create: `docs/book.toml`, `docs/src/SUMMARY.md`, `docs/src/introduction.md`, `docs/src/how-qsp-works.md`
- Create: the single source of the service-address placeholder (an mdbook variable via `[preprocessor]` or one `{{#include}}` file, e.g. `docs/src/_service-address.md`)

**Interfaces:**
- Produces: a buildable book with the full ToC wired in `SUMMARY.md` (pages added in Task 3); `how-qsp-works.md` carries the same direct-connection message as the site; the service address resolves from one place.

- [ ] **Step 1: Write `book.toml`** — title, English, default theme following system, a link back to the homepage (`/`) in the nav. Configure the chosen include/variable mechanism for the service address.

- [ ] **Step 2: Write `SUMMARY.md`** with the validated ToC: User part (Introduction · How QSP works · Getting started [Requirements · Register your station · Install the agent · Configure the agent · Run as a service · Operate from your browser] · Troubleshooting); Advanced part (Architecture · Self-hosting quick start · Developer guide). Create stub files so the book builds.

- [ ] **Step 3: Write Introduction and How QSP works** — the latter restates the direct-connection model (reuse the site's wording/diagram concept) and is the single explanation the user and advanced parts both point to.

- [ ] **Step 4: Define the service-address placeholder once** — a clearly-marked placeholder (e.g. `https://qsp.example.org` labelled "replace with the service address once known") in `_service-address.md` / a variable, referenced everywhere else.

- [ ] **Step 5: Verify the book builds**

Run: `cd docs && mdbook build && test -f book/index.html && echo OK`
Expected: `OK`, no broken-link warnings.

- [ ] **Step 6: Commit**

```bash
git add docs/book.toml docs/src/
git commit -m "feat(docs): mdbook scaffold, ToC, and How QSP works"
```

---

### Task 3: User guide and advanced pages (content)

**Files:**
- Modify/Create: the stub pages from Task 2 under `docs/src/` (Getting started sub-pages, Troubleshooting, Architecture, Self-hosting quick start, Developer guide).

**Interfaces:**
- Consumes: the service-address placeholder (Task 2); the `self-hosting/` compose example (Plan B) for the quick-start page; the agent config format (`qsp-agent/package/config.toml`, `ws://.../signaling/server/session`).

- [ ] **Step 1: Write the User "Getting started" flow** for the hosted service as it will be, Raspberry Pi (64-bit Raspberry Pi OS) as reference, Linux-only stated clearly:
  - Requirements; Register your station (**provisional:** ask the operator for an account; the operator creates the station + agent and hands over the agent ID and secret; note this will become self-service);
  - Install the agent (`.deb`, amd64/arm64); Configure the agent (`/etc/qsp-agent/config.toml`: `[signaling_server]` url/agentId/agentSecret; audio uses the system default input device — state only that); Run as a service (systemd, foreground, `--config /etc/qsp-agent/config.toml`); Operate from your browser.
  - Mark clearly that the service is not open yet and nothing here claims otherwise.

- [ ] **Step 2: Write Troubleshooting** — common agent/connection failures, including that WebRTC is direct so both ends must be reachable and what typically breaks it (no TURN in QSP today).

- [ ] **Step 3: Write Architecture** (advanced) as a map linking each repo's README, and **Self-hosting quick start** walking through the `self-hosting/` compose (Plan B): start the stack, sign in as the seeded admin, create a station and an agent via the signaling REST API (until a UI exists), point an agent at the instance, operate. Warn it is not a production setup and list what to change (dedicated DB roles, strong passwords, the admin password, TLS). **Developer guide** points to per-repo CONTRIBUTING/README.

- [ ] **Step 4: Verify build and links**

Run: `cd docs && mdbook build`
Expected: builds clean; the service address appears only via the single placeholder (grep: `grep -rn 'qsp.example.org' docs/src | wc -l` matches only the definition file plus intended references, never a stray IP).

- [ ] **Step 5: Commit**

```bash
git add docs/src/
git commit -m "feat(docs): user guide and advanced documentation"
```

---

### Task 4: GitHub Pages publishing workflow

**Files:**
- Create: `.github/workflows/pages.yml` (in the root `Ham-QSP/Qsp` repo)

**Interfaces:**
- Consumes: `site/` and `docs/`.
- Produces: on push to `main`, a Pages deployment with `site/` at the root and the built book under `/docs/`; on PRs, a build-only validation (no deploy).

- [ ] **Step 1: Write the workflow** — a `build` job: checkout, install a **pinned** mdbook version, `mdbook build docs`, assemble a publish directory (`site/` → root, `docs/book/` → `docs/`), upload the Pages artifact. A `deploy` job gated on `github.ref == 'refs/heads/main'` using the official Pages deploy action with `pages: write`/`id-token: write`. On `pull_request`, run `build` only (no deploy). Pin actions by SHA, matching the other workflows' hygiene.

- [ ] **Step 2: Verify the assembled output locally**

Run: a local dry run of the assembly (`mdbook build docs && mkdir -p _site && cp -r site/. _site/ && mkdir -p _site/docs && cp -r docs/book/. _site/docs/ && test -f _site/index.html && test -f _site/docs/index.html && echo OK`)
Expected: `OK` — root page and book both present at the right paths; the site's `/docs/` links resolve.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/pages.yml
git commit -m "ci: build and publish site + docs to GitHub Pages"
```

- [ ] **Step 4 (maintainer, cannot be done from code):** enable GitHub Pages on `Ham-QSP/Qsp` with "GitHub Actions" as the source (spec "Maintainer prerequisites").

---

## Self-Review

- **Spec coverage:** homepage structure → Task 1; diagram/direct-connection → Tasks 1 & 2; ToC → Task 2; user guide with provisional procedures + Raspberry Pi + Linux-only → Task 3; advanced/self-hosting quick start linking Plan B → Task 3; `site/` + `docs/` layout and Pages workflow with pinned mdbook, PR build vs deploy → Task 4; placeholder service address in one place → Tasks 2 & 3. Screenshot placeholder until a real capture exists → Task 1.
- **Consistency:** the How-it-works diagram/message is authored once (site, Task 1) and the book's `how-qsp-works.md` mirrors it (Task 2); the service address is one placeholder. The self-hosting page references `self-hosting/` exactly as Plan B names it.
- **Review Focus:** direct-connection (Tasks 1/2), dark mode + phone width (Task 1), single placeholder (Tasks 2/3), CI-build-before-deploy (Task 4) each covered.
- **Proportion:** content/infra plan; no code bodies, which is correct. The wording is explicitly left to the builder per the spec.
- **Dependency:** the Self-hosting quick-start page (Task 3 Step 3) is most accurate once Plan B's compose is final; it can be drafted in parallel and reconciled against the verified compose.

## Execution Handoff

Plan complete. Independent of Plans A/B except the self-hosting quick-start page, which cites Plan B. Recommended execution: **Native** — the site and docs are authoring tasks best iterated in one session with a browser preview, with one fresh reviewer at the end (especially for the direct-connection message and dark-mode/phone rendering). Review the plan and confirm the approach.
