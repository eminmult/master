# Browser preview

Quick way to open the Flutter app in a browser without installing the SDK
locally. Runs in Docker, served by nginx on port **8095**.

## First run (build is slow — ~5-10 min, mostly downloading Flutter SDK image)

```bash
cd /root/master-mobile
docker compose up -d --build
```

Then open: **http://YOUR_SERVER_IP:8095**

(If you're on the server itself: http://localhost:8095)

## After source changes

```bash
cd /root/master-mobile
docker compose up -d --build      # rebuild bundle
# or just:
docker compose restart master-mobile-web   # if only nginx config changed
```

Subsequent builds are fast (~30 sec) — only the changed source layer rebuilds.

## Pointing at a different API

By default the bundle calls `https://master.gasimov.az/api/v1`. Override:

```bash
API_BASE_URL=http://localhost:8093/api/v1 docker compose up -d --build
```

The compile-time env is baked into the JS bundle — no runtime config swap.

## Troubleshooting

**CORS error in browser console** — the backend allows `http://localhost:8094`
and the regex `^https?://[^/]+:8094$`. If your server is on a custom domain
or non-localhost IP and CORS still blocks, add your URL to
`/root/master-site/backend/config/cors.php` → `allowed_origins`.

**Blank page / stuck on splash** — open DevTools network tab. If the bundle
loads but `/auth/me` returns 401 in a loop, you don't have a token yet —
just navigate to `/login`. Splash redirects to login automatically.

**Build fails on `flutter create`** — check Docker has enough disk (need
~5 GB free for the Flutter SDK image and intermediate layers).

## Logs

```bash
docker compose logs -f master-mobile-web      # nginx access/error
docker compose ps                              # status + healthcheck
```

## What it gives you in the browser

- Full app, all 21 screens
- Real API calls to the master-site backend
- Hot-reloading is **NOT** available — this is a built bundle. For hot
  reload during development, use Flutter SDK locally.

## Difference from running on a phone

- No push notifications (FCM web has limited support; not wired here)
- No background geolocation (browser sandbox)
- Same UI / API behavior as iOS/Android otherwise
