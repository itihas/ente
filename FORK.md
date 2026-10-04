# itihas/ente fork notes

This fork tracks [ente-io/ente](https://github.com/ente-io/ente) and adds what
the self-hosted deployment on `remotihas` (see `../remotihas/ente.nix`) needs.
Everything here is fork-only; upstream merges should not touch this file.

## What the fork adds

- **Nix flake** (`flake.nix`): packages `ente-server` (museum), `ente-cli`,
  `ente-wasm` (the `rust/bindings/wasm/{prelogin,photos,auth,cast}` crates,
  built with cargo + `wasm-bindgen-cli_0_2_125` instead of `wasm-pack`, which
  downloads tools at build time) and `ente-web` (npm workspace; builds the
  photos, albums, accounts, auth, cast, share, embed and memories apps).
- **NixOS module** `services.ente`: museum as a systemd service, nginx vhosts
  for the apps, and an `env.js` that injects `NEXT_PUBLIC_ENTE_ENDPOINT` at
  runtime (the web build doesn't inline it, so Next's `process` polyfill picks
  up `window.process.env`).
- **Upload proxy** (`services.ente.uploadProxy`, museum's `s3.upload-proxy`),
  described below.

## Slow uploads to Hetzner Object Storage (fixed by the upload proxy)

### Symptom

Uploads from the web and desktop apps ran at ~2.6 Mbit/s on a link that
measures 91 Mbit/s up. A 560 MB test set took 28 minutes.

### Cause

**Hetzner Object Storage keeps a small HTTP/2 flow-control window for uploads.**
An HTTP/2 upload stream can only have ~64 KB unacknowledged, so its
throughput is ~64 KB per round trip, whatever the bandwidth. From India to
`hel1` (~170 ms RTT) that is ~0.31 MB/s. Browsers (and Electron) always
negotiate HTTP/2 with the endpoint, and JavaScript cannot force HTTP/1.1 for a
`fetch`.

Evidence (2026-10-04, same presigned 25 MB PUT from the same machine):

| Request | Throughput |
|---|---|
| curl `--http2` to `hel1.your-objectstorage.com` | 0.31 MB/s |
| curl `--http1.1` to the same URL | 6.2 MB/s |
| Browser `fetch` PUT (Chromium) | 0.31 MB/s |
| Same HTTP/2 PUT relayed through an ssh tunnel via remotihas | 0.33 MB/s (the window is end-to-end) |
| Presigned PUT from remotihas itself (~1 ms RTT) | 25–35 MB/s |
| Raw ssh stream to remotihas (same city as `hel1`) | 33–36 Mbit/s |

Things that turned out **not** to be the bottleneck: the route to Helsinki,
IPv6 vs IPv4, path-style vs virtual-hosted URLs (both are capped over HTTP/2),
Hetzner throttling presigned URLs, and the client's main-thread MD5 (13 MB/s,
~40× the capped rate).

### Fix

Upload over HTTP/1.1 to a proxy close to the bucket:

1. **museum** (`server/pkg/utils/s3config/s3config.go`): new optional config

   ```yaml
   s3:
     use_path_style_urls: true   # required: the rewrite only swaps the origin
     upload-proxy:
       from: https://hel1.your-objectstorage.com
       to: https://s3.ente.example.org
   ```

   `S3Config.UploadURL` rewrites presigned upload URLs from `from` to `to`.
   The path and query (including the signature) are unchanged; the proxy must
   send the original `Host` so the signature still verifies. A URL that doesn't
   match is passed through with a warning (`Upload URL origin … does not match
   s3.upload-proxy.from`). If only one of `from`/`to` is set, museum refuses to
   start.
2. **Call sites** (`server/pkg/controller/file.go`): the four presigned upload
   URLs handed to clients are wrapped in `c.S3Config.UploadURL(...)`:
   `getObjectURL` (single PUTs, incl. thumbnails), `getPartURL` (multipart
   parts), and both multipart `CompleteURL`s. Public-album uploads go through
   the same functions.
3. **NixOS module**: `services.ente.uploadProxy = { enable; subdomain ? "s3";
   upstream; }` sets the museum config above and adds an nginx vhost
   `<subdomain>.<domain>` with `http2 = false`, `proxy_pass https://<upstream>`,
   `proxy_set_header Host <upstream>`, `proxy_ssl_name <upstream>`, request
   buffering off and `client_max_body_size 64m` (parts are 20 MB). Downloads
   are not proxied.

Because the rewrite happens in museum, every client benefits (web, desktop,
mobile) without client changes.

### Result

Same 560 MB test set (one 456 MB video, one 76 MB video, seven small files),
uploaded from the web app; timed from museum's request log:

| Run | Upload path | Time | Throughput |
|---|---|---|---|
| Before | direct to Hetzner over HTTP/2 | 28 min 13 s | 2.6 Mbit/s |
| After | through `s3.ente.itihas.xyz` over HTTP/1.1 | 1 min 56 s | 38.7 Mbit/s |

### When merging upstream

- If upstream changes how `file.go` presigns upload URLs (new endpoints, renamed
  helpers), re-wrap every URL handed to clients in `S3Config.UploadURL`.
  `grep -n "UploadURL(url)" server/pkg/controller/file.go` should list four
  sites. Other presigned uploads (`pkg/controller/filedata` video previews,
  contact attachments) are not wrapped yet; desktop video-preview uploads go
  through Node's `fetch` (HTTP/1.1), so they aren't affected by the cap.
- After deploying, check that uploads actually go through the proxy:
  `grep -c "does not match s3.upload-proxy" /var/log/ente/ente.log` should not
  grow, and nginx's access log should show `PUT /<bucket>/…` requests.
- If ente's HTTP/2 behaviour or Hetzner's window ever changes, compare
  `curl --http2` and `curl --http1.1` PUTs of a presigned URL; if they match,
  the proxy is no longer needed.

## Other notes from the 2026-10 upstream sync

- Upstream's museum returns `410 Gone` on the legacy `GET /files/upload-urls`
  and `GET /files/multipart-upload-urls` routes for users created after
  2026-04-01 or with an even user ID. ente-desktop 1.7.27 uses the newer
  `POST` routes and is unaffected; old mobile builds may not be.
- Upstream's streaming multipart uploads (no whole-file buffering) are only
  enabled for users with the `internalUser` remote-store flag.
- A worker-based MD5 for upload checksums (13 MB/s on the main thread → ~180
  MB/s per worker) is drafted but not applied; see `git stash list` /
  the `md5-draft` stash on the machine that drafted it.
