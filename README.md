<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/effectcraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.effectcraft.png" width="128" height="128" alt="EffectCraft application icon">
</p>

<h1 align="center">EffectCraft Web — Docker Image</h1>
<p align="center">
  A community-maintained Docker image for
  <a href="https://github.com/storytold/effectcraft">EffectCraft</a>,
  bringing its WebAssembly-based motion graphics and compositing studio to a self-hosted web interface.
  <br>
  Build automation and image publication to GitHub Container Registry (GHCR).
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

The upstream EffectCraft project provides a WebAssembly build that can be served as a static website. This repository automates building that web application from upstream source and packages the generated files into a lightweight NGINX-based Docker image.

The goals are to:

- Publish a matching GitHub Release only after the Docker build and push succeed.
- Build the WebAssembly application from official release tags in [storytold/effectcraft](https://github.com/storytold/effectcraft).
- Check weekly for new official releases and publish a versioned image to GHCR.
- Provide Docker deployment for Unraid Community Applications.
- Keep this packaging project separate from the upstream EffectCraft source code.

This is an independent community packaging project. It is **not an official EffectCraft release** and is not affiliated with or endorsed by the EffectCraft or ArtCraft maintainers.

## How it works

EffectCraft is a motion graphics and visual effects application written in Rust. Its web application runs the same engine and egui interface in the browser using WebAssembly, with WebGPU and a WebGL2 fallback. The container serves the compiled static web files through NGINX; it does not run a remote desktop or server-side rendering service.

- **Browser-based studio:** create compositions from layers, animate properties with keyframes, apply effects and render through the Render Queue.
- **Local-first projects:** projects, imported media, settings and auto-saves stay in browser-managed storage and on the user's device. They are not uploaded to this container.
- **Background processing:** Web Workers handle long-running render and analysis jobs without blocking the interface.
- **Offline-capable PWA:** the service worker precaches the application after the first visit, allowing it to load offline.
- **Export downloads:** rendered files are downloaded by the browser; the container does not store render outputs.

**Important:** browser storage belongs to the browser profile and origin on a particular device. It is not shared between users or browsers, and it is not a server-side backup. Use the application's save and backup workflows and keep independent copies of important projects and source media.

EffectCraft is in **alpha** and is under active development. The upstream project explicitly cautions that it is not yet recommended for production client work. Test updates and verify your workflows before relying on it for important projects.

## Docker image

The published image is:

```text
ghcr.io/mikapst/effectcraft-web:latest
```

Each official upstream release is also published under its exact version tag, for example:

```text
ghcr.io/mikapst/effectcraft-web:vX.Y.Z
```

Use a versioned tag if you want to keep a deployment on a specific release. The `latest` tag updates when an image is published.

### Quick start with Docker Compose

A `docker-compose.yml` file is provided at the repository root:

```yaml
services:
  effectcraft-web:
    image: ghcr.io/mikapst/effectcraft-web:latest
    container_name: effectcraft-web
    restart: unless-stopped
    ports:
      - "8080:8080"
```

Start EffectCraft Web from the repository directory:

```bash
docker compose up -d
```

Then open:

```text
http://YOUR_SERVER_IP:8080
```

Replace `YOUR_SERVER_IP` with the IP address or hostname of your server. On the same computer, use `http://localhost:8080`.

### Run directly with Docker

```bash
docker run -d \
  --name effectcraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/effectcraft-web:latest
```

### Useful commands

```bash
# View logs
docker compose logs -f

# Pull the latest image and recreate the container
docker compose pull
docker compose up -d

# Stop and remove the container
docker compose down
```

No `.env` file or persistent Docker volume is required for the default configuration. The host port is `8080`; to use a different host port, change the left-hand side of the port mapping, for example `8081:8080`.

### Reverse proxy and browser requirements

The NGINX configuration follows the upstream hosting guidance:

- serves `.wasm` files with the `application/wasm` MIME type;
- serves `.js` files with the `text/javascript` MIME type;
- enables gzip compression for WebAssembly, JavaScript and HTML;
- applies `Cache-Control: no-cache` to `index.html`, `sw.js`, `.wasm` and `.js` because their filenames stay the same between releases;
- serves the site using relative URLs, so it can be hosted at a domain root or under a URL prefix when the reverse proxy preserves the path.

**HTTPS is recommended and required for full browser capabilities.** WebGPU and clipboard access need a secure context (`https://` or `http://localhost`). Service workers also require a secure context. On other plain-HTTP origins, EffectCraft falls back to WebGL2.

The upstream hosting guide does not require COOP or COEP isolation headers. If another layer in your infrastructure adds `Cross-Origin-Embedder-Policy: require-corp`, it must also provide an appropriate `Cross-Origin-Resource-Policy` header for the application's files.

### Renderer and startup options

EffectCraft selects WebGPU when available and otherwise falls back to WebGL2. URL query parameters can override the startup behaviour:

| URL option | Behaviour |
|---|---|
| No option | Restore the previous session; on first visit, open the demo project |
| `?empty` | Start with a blank project without restoring or recording the session |
| `?demo` | Open the demo project without replacing the saved session |
| `?home` | Show the start screen |
| `?webgl` | Force the WebGL2 backend |
| `?cpu` | Force the CPU canvas path; slowest but most compatible |
| `?storage=indexeddb` | Force IndexedDB storage |
| `?storage=memory` | Force memory-only storage |
| `?noworkers` | Disable frame workers |
| `?nosw` | Do not register the service worker |

For example:

```text
https://YOUR_DOMAIN/?webgl
```

To choose the initial project mode for every visitor, an optional `effectcraft-config.json` can be placed next to `index.html`:

```json
{"startup":"empty"}
```

Supported values are `empty`, `demo` and `last` (default). If you add this file to a custom build, serve it with `Cache-Control: no-cache`.

## Automated builds

GitHub Actions checks the official [EffectCraft releases](https://github.com/storytold/effectcraft/releases), builds the WebAssembly application from the selected upstream tag and publishes the image to GHCR.

| Trigger | Behaviour |
|---|---|
| Weekly schedule | Checks the latest official EffectCraft release and builds it if it has not already been published here |
| Manual workflow dispatch | Builds the latest official release, or a specified `upstream_tag` |
| Force rebuild | Rebuilds an already published version with `force_rebuild: true` |
| Changes to packaging files on `main` | Rebuilds the current official upstream release with the updated workflow |

### Published tags

- `latest` — the latest successfully published image (mutable tag).
- `<upstream-version>` — the exact official upstream tag, for example `vX.Y.Z`.
- `upstream-<commit>` — the upstream source commit used for the image (first 12 hexadecimal characters).

The image targets both `linux/amd64` and `linux/arm64`. The workflow checks out **the official upstream release tag**, rather than compiling `main` as the versioned source.

### GitHub Releases

After a successful Docker build and GHCR push, the workflow creates or updates a [GitHub Release](https://github.com/MikaPST/effectcraft-web/releases) matching the upstream tag. It includes the upstream release notes, source link and commit, Docker tags, supported architectures and (when available) the published image digest.

The Release badge at the top of this README updates automatically. Scheduled runs skip versions already released here. You can force a rebuild from **Actions → Build and publish EffectCraft Web → Run workflow**.

> [!IMPORTANT]
> A GitHub Release is created only after the Docker image has been successfully published. The `latest` tag may change after a rebuild; pin a versioned image tag for a stable deployment. Auxiliary source repositories (for example `craft-fonts`) may be checked out separately and are not necessarily pinned to the upstream release commit.

### Build pipeline

The workflow:

1. Checks out this repository.
2. Checks out the upstream EffectCraft repository.
3. Installs the Rust WebAssembly target and the exact `wasm-bindgen-cli` version required by the upstream project (`0.2.129`).
4. Runs `cargo xtask web` from the upstream repository.
5. Checks the generated static site in `upstream/target/web/dist`, including the WebAssembly module, JavaScript glue, render worker, audio worklet and service worker.
6. Generates the Dockerfile and NGINX configuration in a temporary build context.
7. Packages the static site into an NGINX image and publishes it to GHCR.

EffectCraft bundles its web fonts in the upstream application; this build does not need a separate `craft-fonts` checkout.

The WebAssembly module is large. The upstream documentation reports approximately 58 MB before optimization, with gzip reducing it to about 17 MB for the documented version. The build uses NGINX gzip compression to reduce transfer size. The browser's service worker caches the application after the first successful visit.

The workflow generates the Dockerfile and NGINX configuration during the GitHub Actions run. Separate `Dockerfile`, `nginx.conf` and `.dockerignore` files are therefore not required in this packaging repository.

The repository is primarily intended as an automated image-build and publication pipeline; the normal way to consume it is to pull the published image.

## Unraid Community Applications

This image can be deployed on Unraid.

The Unraid Community Applications template is maintained in [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps), separately from this image-build repository.

In the meantime, EffectCraft Web can be deployed on Unraid using the Docker Compose configuration above or by configuring the container manually with:

- **Repository:** `ghcr.io/mikapst/effectcraft-web:latest`
- **Container port:** `8080`
- **Host port:** `8080` by default

Remember that projects and imported media are stored in each user's browser storage, not in the Unraid appdata directory. Clearing browser data, changing browser profiles or using a different origin can make that data unavailable. Keep independent backups.
- **Template:** [effectcraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/effectcraft-web.xml)

## Upstream project

- **EffectCraft source code:** [storytold/effectcraft](https://github.com/storytold/effectcraft)
- **EffectCraft web build and browser architecture:** [docs/web.md](https://github.com/storytold/effectcraft/blob/main/docs/web.md)
- **EffectCraft web hosting instructions:** [packaging/web/README.md](https://github.com/storytold/effectcraft/blob/main/packaging/web/README.md)
- **Official releases:** [EffectCraft releases](https://github.com/storytold/effectcraft/releases)

The MikaPST GitHub Release tracks the upstream version but represents independent Docker packaging, not an official EffectCraft distribution.

## License and attribution

EffectCraft is dual-licensed under the MIT License or Apache License 2.0, at the user's option, as specified by the upstream project. Required notices and third-party asset attributions are maintained in the upstream repository; consult its `NOTICE` and `ATTRIBUTION.md` files.

The ArtCraft name, wordmark and logos in the upstream `docs/brand/` directory are trademarks and are not covered by the software license. Their use is subject to the upstream `docs/brand/LICENSE-brand.txt`. The license of the upstream application and its assets does not automatically determine the license of the packaging files maintained in this repository. If you want to grant reuse rights for your own workflow, Compose file and documentation, select and include a separate `LICENSE` for this repository.

## Disclaimer

This repository is maintained independently and is not affiliated with, sponsored by or endorsed by the EffectCraft project or its maintainers.

EffectCraft is alpha software. Keep independent backups of important projects and source media, and test updates before relying on the application for important work.
