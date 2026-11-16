<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/effectcraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.effectcraft.png" width="128" height="128" alt="EffectCraft application icon">
</p>

<h1 align="center">EffectCraft Web — Docker Image</h1>
<p align="center">
  A community-maintained Docker image for
  <a href="https://github.com/storytold/effectcraft">EffectCraft</a>,
  bringing its Rust/WebAssembly-based motion graphics and visual effects studio to a self-hosted web interface.
  <br>
  Automated builds and image publication to GitHub Container Registry (GHCR).
</p>

<p align="center">
  <a href="https://github.com/MikaPST/effectcraft-web/actions/workflows/publish-image.yml">
    <img src="https://github.com/MikaPST/effectcraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build and publish EffectCraft Web">
  </a>
  <a href="https://github.com/MikaPST/effectcraft-web/releases/latest">
    <img src="https://img.shields.io/github/v/release/MikaPST/effectcraft-web?label=Release&logo=github&color=blue" alt="Latest Release">
  </a>
  <a href="https://github.com/MikaPST/effectcraft-web/pkgs/container/effectcraft-web">
    <img src="https://ghcr-badge.egpl.dev/mikapst/effectcraft-web/latest_tag?trim=major&label=GHCR" alt="GHCR image tag">
  </a>
  <a href="docker-compose.yml">
    <img src="https://img.shields.io/badge/Docker%20Compose-ready-2496ED?logo=docker&logoColor=white" alt="Docker Compose configuration">
  </a>
</p>

---

## Why this repository?

The official EffectCraft project provides a WebAssembly-based motion graphics, compositing and visual effects editor that runs in a browser. This repository builds the **official upstream release** and packages its compiled static site in a lightweight NGINX image for straightforward self-hosting.

The goals are to:

- Compile EffectCraft Web from an **official release tag**, without modifying upstream application source code.
- Publish ready-to-use multi-platform images to GHCR for `linux/amd64` and `linux/arm64`.
- Check daily for new official releases and allow manual or forced rebuilds.
- Create or update a matching GitHub Release **only after** a successful Docker image push.
- Keep the `Dockerfile`, `nginx.conf`, `.dockerignore` and GitHub Actions workflow **separate, readable and version-controlled**.
- Preserve EffectCraft's offline-capable PWA, Web Workers, audio worklet and browser-local project storage.
- Provide documented Docker Compose and Unraid Community Applications deployments.
- Include upstream licenses and attribution notices within the runtime image.

This is independent community packaging, **not an official EffectCraft release** and not an upstream fork.

## How it works

EffectCraft runs its engine and egui interface directly in the user's browser using WebAssembly. The container serves static files through NGINX: it does **not** run a remote desktop, a remote render farm or a shared media storage service.

- **Motion graphics studio:** compose layers, keyframe properties, apply effects and render jobs from the Render Queue.
- **Browser-local documents:** projects, imported media, settings and auto-saves live in browser-managed storage, not in Docker volumes.
- **Background Web Workers:** dedicated workers execute rendering and analysis tasks and process viewer frames without necessarily blocking the main interface.
- **WebGPU / WebGL2:** the application prefers WebGPU where supported and falls back to WebGL2.
- **Offline-capable PWA:** a service worker can cache the application after a first successful visit over a secure origin.
- **Exports:** finished renders and saved projects are downloaded by the browser; the container does not store them.

### Browser data and backups

EffectCraft uses the browser's Origin Private File System (OPFS) when available, otherwise IndexedDB, and otherwise an in-memory fallback. Storage is tied to a **specific browser profile and origin** (scheme, hostname and port). It is not shared across browsers or devices.

> [!IMPORTANT]
> Browser storage is **not a server-side backup**. Clearing site data, changing the public URL, switching browsers or using memory-only mode can make project data unavailable. Keep independent copies of projects, imported media and rendered files.

EffectCraft is **alpha software**. Test upgrades and verify exports before using it for important production work.

## Docker image

The published image is:

```text
ghcr.io/mikapst/effectcraft-web:latest
```

Each successfully packaged official upstream release also has a versioned tag:

```text
ghcr.io/mikapst/effectcraft-web:<upstream-version>
```

Use an existing versioned tag for a stable upstream version. `latest` is mutable; a forced rebuild can also overwrite the image behind an existing version tag. For exact deployment reproducibility, pin the **GHCR image digest**.

### Option 1 — Docker Compose (recommended)

The repository includes `docker-compose.yml`:

```yaml
services:
  effectcraft-web:
    image: ghcr.io/mikapst/effectcraft-web:latest
    container_name: effectcraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

Start the application from the repository root:

```bash
docker compose up -d
```

Open it in the browser:

```text
http://YOUR_SERVER_IP:8080
```

Replace `YOUR_SERVER_IP` with the server's address. On the same computer, use `http://localhost:8080`. For full PWA and WebGPU functionality from other devices, use an **HTTPS** reverse proxy.

#### Useful Compose commands

```bash
# View container logs
docker compose logs -f

# Pull the latest image and recreate the container
docker compose pull
docker compose up -d

# Stop and remove the container
docker compose down
```

No `.env` file or persistent application volume is required for the default configuration. To change the public host port, edit the left-hand side of `8080:8080`; for example, `8081:8080`.

### Option 2 — Run directly with Docker

```bash
docker pull ghcr.io/mikapst/effectcraft-web:latest

docker run -d \
  --name effectcraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/effectcraft-web:latest
```

Open `http://YOUR_SERVER_IP:8080` or `http://localhost:8080` from the Docker host.

Optional resource limits can be added to `docker run`, but most interactive rendering and project processing takes place in the **client browser**, not the NGINX container.

### Network access and reverse proxies

NGINX listens on **port 8080**. For external access, put it behind a reverse proxy such as Traefik that provides HTTPS and forwards requests to the container over HTTP.

The independent, version-controlled `nginx.conf`:

- Serves `.wasm` as `application/wasm` and `.js` with the standard JavaScript MIME type.
- Uses gzip compression for WebAssembly, JavaScript, CSS and other compressible content.
- Returns `Cache-Control: no-cache` for **all application assets**, especially `index.html`, `sw.js`, `.wasm`, `.js` and the web manifest.
- Includes `X-Content-Type-Options: nosniff` for static assets.
- Exposes a lightweight `GET /healthz` endpoint for container health checks.
- Runs NGINX on an unprivileged port as the **non-root `nginx` user**.

**Why `no-cache` rather than `immutable`?** EffectCraft's built assets have stable names such as `effectcraft_web_bg.wasm` across releases. Browsers must revalidate these files after upgrades or they may keep using an outdated version. `no-cache` allows the browser to store files but requires checking freshness before reuse; unchanged resources can still receive HTTP `304` responses.

WebGPU, clipboard APIs and the service worker require a secure browser context (`https://` or localhost). On plain HTTP from other machines, some features are unavailable or use fallback paths.

Upstream does not require COOP/COEP isolation headers for ordinary static hosting. If your proxy forces COEP `require-corp`, apply compatible Cross-Origin-Resource-Policy headers to the served assets.

The upstream site's URLs are relative, allowing hosting at a domain root or below a prefix. If a reverse proxy publishes the container below `/effectcraft/`, configure it to **strip that prefix** before forwarding requests to the container, and use the same public origin consistently so browser storage and service-worker scope stay stable.

Do not expose an unprotected HTTP port directly to the public Internet.

### Renderer and startup options

EffectCraft offers the following browser query parameters:

| URL option | Behaviour |
|---|---|
| *(none)* | Restore the previous session; use the demo on a first visit. WebGPU is preferred when available. |
| `?empty` | Start a blank project without restoring or recording the prior session. |
| `?demo` | Show the demo project without overwriting the saved session. |
| `?home` | Show the start screen. |
| `?webgl` | Force the WebGL2 renderer. |
| `?cpu` | Force the slower CPU canvas path. |
| `?storage=indexeddb` | Request IndexedDB storage. |
| `?storage=memory` | Use memory-only storage; projects will not persist between sessions. |
| `?noworkers` | Disable background frame workers. |
| `?frameworkers=N` | Set the number of frame workers (upstream default: 2). |
| `?nogpuworkers` | Disable GPU rendering inside job and frame workers. |
| `?nosw` | Avoid registering the service worker. |

For example:

```text
https://YOUR_DOMAIN/?webgl
https://YOUR_DOMAIN/?empty
```

To select the initial project behavior for visitors, a **custom** `effectcraft-config.json` can be added beside `index.html`:

```json
{"startup":"empty"}
```

Upstream supports the values `empty`, `demo` and `last` (default). In this configuration file, `empty` **restores the last session when available and otherwise starts blank**; this is different from the `?empty` URL flag, which bypasses session restoration. The file should be served with `Cache-Control: no-cache`, as supplied by the included NGINX configuration.

The standard workflow does **not** inject a custom `effectcraft-config.json`; adding it requires a deliberate packaging change.

### Embedding EffectCraft in another website

The web application supports iframe hosting. For example:

```html
<iframe
  src="https://YOUR_DOMAIN/"
  title="EffectCraft motion graphics editor"
  style="width: 100%; height: 720px; border: 0;"
  allow="fullscreen; clipboard-read; clipboard-write"
  allowfullscreen>
</iframe>
```

When used across origins, browser privacy controls can restrict or partition storage. A sandboxed iframe generally requires `allow-scripts allow-same-origin allow-downloads allow-popups`; host-side CSP or `X-Frame-Options` must allow the desired embedding origin.

See the official [web hosting instructions](https://github.com/storytold/effectcraft/blob/main/packaging/web/README.md) for full guidance.

## Repository structure

This repository keeps Docker packaging independent from the official EffectCraft source:

```text
effectcraft-web/
├── .github/
│   └── workflows/
│       └── publish-image.yml
├── .dockerignore
├── Dockerfile
├── nginx.conf
├── docker-compose.yml
└── README.md
```

| File | Purpose |
|---|---|
| `.github/workflows/publish-image.yml` | Detect official releases, compile WebAssembly, publish a multi-platform Docker image, and create matching GitHub Releases. |
| `Dockerfile` | Provide a lightweight, non-root NGINX runtime image and container health check. |
| `nginx.conf` | Configure MIME types, compression, revalidation caching, security headers and `/healthz`. |
| `.dockerignore` | Limit Docker packaging to compiled static assets, required notices and version-controlled runtime files. |
| `docker-compose.yml` | Provide a ready-to-use self-hosted deployment. |
| `README.md` | Document deployment, architecture, automated builds, licenses and maintenance. |

### Docker build architecture

Unlike PhotoCraft's multi-stage Dockerfile, EffectCraft builds the WebAssembly application **once in GitHub Actions**, then packages the resulting site using a version-controlled Dockerfile.

```text
GitHub Actions workspace/
├── packaging/              # MikaPST/effectcraft-web
│   ├── Dockerfile
│   ├── nginx.conf
│   └── .dockerignore
├── upstream/               # storytold/effectcraft (official release tag)
└── docker-context/         # temporary Docker build context
    ├── Dockerfile          # copied from packaging/
    ├── nginx.conf          # copied from packaging/
    ├── .dockerignore       # copied from packaging/
    ├── site/               # upstream/target/web/dist/
    └── legal/              # upstream licenses and attribution notices
```

The workflow performs these operations:

1. Check out and validate the version-controlled packaging repository.
2. Resolve the latest official EffectCraft release, or a requested `upstream_tag`.
3. Skip already-published versions unless `force_rebuild` is enabled or packaging files have changed.
4. Check out `storytold/effectcraft` at the exact upstream release tag.
5. Install Rust, the `wasm32-unknown-unknown` target, and the `wasm-bindgen-cli` version required by upstream `xtask`.
6. Cache Rust dependencies and run **`cargo xtask web`** from the upstream repository.
7. Validate the generated `index.html`, `effectcraft_web_bg.wasm`, `effectcraft_web.js`, render worker, audio worklet, service worker and web manifest.
8. Assemble a temporary Docker context with the compiled site and the official license and attribution files.
9. Copy the versioned `Dockerfile`, `nginx.conf` and `.dockerignore` from this repository into that context.
10. Build and push `linux/amd64` and `linux/arm64` images using Docker Buildx.
11. Create or update the matching GitHub Release **after** GHCR publication succeeds.

The temporary `upstream/`, `docker-context/`, `site/` and `legal/` directories are generated during GitHub Actions; they are **not committed to this repository**. The runtime image does not need Rust or a build toolchain.

**No separate `craft-fonts` checkout is needed:** the EffectCraft upstream web build already bundles the fonts used by its browser edition. This differs from DesignCraft and TextureCraft.

> [!NOTE]
> Upstream EffectCraft has a comparatively large WebAssembly module (the official v0.3.1 documentation cites roughly 58 MB before optimization, about 17 MB with gzip). Build times, memory requirements and file sizes may change as EffectCraft evolves.

## Automated builds

GitHub Actions checks the official [EffectCraft releases](https://github.com/storytold/effectcraft/releases), compiles the selected official tag, and publishes the image to GHCR.

| Trigger | Behaviour |
|---|---|
| Daily schedule (`03:17 UTC`) | Check for a new official EffectCraft release and skip it when already packaged. |
| Manual workflow dispatch | Build the latest official release or the supplied `upstream_tag`. |
| Force rebuild | Rebuild an existing version with `force_rebuild: true`. |
| Packaging changes on `main` | Rebuild the latest official upstream release when `Dockerfile`, `nginx.conf`, `.dockerignore`, `docker-compose.yml`, `README.md` or the workflow changes. |

### Published tags

Each successful GHCR publication updates these tags:

- `latest` — the most recently successfully published image.
- `<upstream-version>` — the exact official upstream release tag.
- `upstream-<commit>` — the first 12 characters of the official upstream Git commit.

Images are published for `linux/amd64` and `linux/arm64`. The same compiled WebAssembly assets are used on both platforms; only the lightweight NGINX runtime is packaged for each architecture.

The upstream source is checked out at the **official release tag**, not the development branch. GitHub Actions uses the upstream `xtask` build command, including its WebAssembly and service-worker preparation steps.

### GitHub Releases

After a successful Docker build and GHCR push, the workflow creates or updates a [GitHub Release](https://github.com/MikaPST/effectcraft-web/releases) matching the official upstream release tag.

Each release includes:

- The official EffectCraft release name and URL.
- The upstream source commit and publication date.
- GHCR tags (`latest`, the version tag and `upstream-<commit>`).
- Supported architectures (`linux/amd64` and `linux/arm64`).
- The published Docker manifest digest, when available.
- The official upstream release notes and an independent-packaging disclaimer.

The Release badge at the top of the README reflects the latest published GitHub Release. Scheduled and ordinary manual runs skip releases already published in this repository. You can rebuild one from **Actions → Build and publish EffectCraft Web → Run workflow** using `force_rebuild`.

> [!IMPORTANT]
> GitHub Releases are created or updated **only after** the multi-platform image has been pushed successfully to GHCR.
>
> `latest` and versioned tags can be updated by forced rebuilds; pin the image digest when binary stability is essential.

## Unraid Community Applications

EffectCraft Web can be deployed with the existing Unraid template maintained in [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps):

- **Unraid template:** [effectcraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/effectcraft-web.xml)
- **Container image:** `ghcr.io/mikapst/effectcraft-web:latest`
- **Container port:** `8080`
- **Default host port:** `8080`

The Unraid XML template is maintained **separately** from this Docker packaging repository. Projects, imported media and auto-saves live in each user's browser storage, **not** in the Unraid `appdata` directory. Keep independent copies of important projects and files.

## Upstream project

EffectCraft is a Rust-based motion graphics and compositing studio developed by the ArtCraft team and contributors.

- **Official source:** [storytold/effectcraft](https://github.com/storytold/effectcraft)
- **Official web architecture:** [docs/web.md](https://github.com/storytold/effectcraft/blob/main/docs/web.md)
- **Official web hosting instructions:** [packaging/web/README.md](https://github.com/storytold/effectcraft/blob/main/packaging/web/README.md)
- **Official releases:** [EffectCraft releases](https://github.com/storytold/effectcraft/releases)

The MikaPST image tracks official upstream versions but represents independently maintained Docker packaging, **not** an official EffectCraft distribution.

## License and attribution

EffectCraft source code is dual-licensed under the **MIT License or Apache License 2.0**, at the user's option. The upstream project maintains license and asset-attribution details; these must be preserved when redistributing the application.

The publishing workflow copies the upstream `LICENSE-MIT`, `LICENSE-APACHE`, `NOTICE` and `ATTRIBUTION.md` into the image's `/licenses/` directory. Available third-party notices from `licenses/` and the upstream ArtCraft brand-license document are also included.

- [Upstream MIT License](https://github.com/storytold/effectcraft/blob/main/LICENSE-MIT)
- [Upstream Apache License 2.0](https://github.com/storytold/effectcraft/blob/main/LICENSE-APACHE)
- [Upstream NOTICE](https://github.com/storytold/effectcraft/blob/main/NOTICE)
- [Upstream asset attribution](https://github.com/storytold/effectcraft/blob/main/ATTRIBUTION.md)
- [Brand usage and restrictions](https://github.com/storytold/effectcraft/blob/main/docs/brand/LICENSE-brand.txt)

EffectCraft and ArtCraft marks and artwork are governed by upstream branding terms, which are **separate from the code's open-source licenses**. This independent packaging does not claim to be official or endorsed.

The source licenses do not automatically license the original Docker packaging files of this repository. Consult any separately provided packaging `LICENSE` for those terms.

## Disclaimer

This community-maintained repository is not affiliated with, sponsored by or endorsed by EffectCraft, ArtCraft or their maintainers.

EffectCraft is alpha software. Browser capabilities and storage behavior can differ by environment. Test updates, verify important exports and keep independent backups of projects and source media.
