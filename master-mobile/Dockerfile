# Stage 1 — build Flutter web bundle
FROM ghcr.io/cirruslabs/flutter:3.24.5 AS build

WORKDIR /app

# Resolve deps first so this layer caches when only source changes.
COPY pubspec.yaml ./
RUN flutter pub get || true

# Bring in the rest of the project.
COPY . .

# Generate platform scaffolding. Use --platforms=web only — without
# --overwrite=false, since that flag suppresses creation of new files when
# a project skeleton is detected, which would skip web/index.html.
# The lib/ directory already exists from our COPY, and `flutter create`
# leaves user files alone by default.
RUN flutter create . \
    --org az.gasimov.master \
    --platforms=web \
    --project-name master_mobile

# Sanity check — the build will fail later with a vague message otherwise.
RUN test -f web/index.html || (echo 'web/index.html missing after flutter create' && exit 1)

RUN flutter pub get

# freezed / json_serializable / riverpod_generator
RUN dart run build_runner build --delete-conflicting-outputs

# i18n — ARB → app_localizations.dart
RUN flutter gen-l10n

# Compile-time API base URL. Override at build with --build-arg API_BASE_URL=...
ARG API_BASE_URL=https://itez.app/api/v1
# Sub-path the bundle is served from. "/" for root, "/mobile/" when mounted
# behind a reverse proxy at itez.app/mobile-dev/.
ARG BASE_HREF=/mobile/
# Inject a visible loading screen + cache-busting into the generated
# web/index.html BEFORE the build, so the user sees something while the
# Dart bundle warms up.
RUN cat > web/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Master.az — home services marketplace">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Master.az">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>Master.az</title>
  <link rel="manifest" href="manifest.json">
  <style>
    html, body { margin:0; padding:0; height:100%; background:#0A0A0A; color:#fff;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    #boot {
      position: fixed; inset: 0; display: flex; flex-direction: column;
      align-items: center; justify-content: center; gap: 18px;
      background: radial-gradient(circle at 50% 30%, #1a1a1d 0%, #0A0A0A 60%);
      transition: opacity .35s ease;
    }
    #boot.hidden { opacity: 0; pointer-events: none; }
    #boot .spin {
      width: 44px; height: 44px; border-radius: 50%;
      border: 3px solid rgba(255,255,0,0.15);
      border-top-color: #FFFF00;
      animation: spin 0.9s linear infinite;
    }
    #boot .label { font-size: 13px; letter-spacing: 2px; color: #FFFF00; }
    #boot .sub { font-size: 11px; color: rgba(255,255,255,0.4); margin-top: 6px; }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div id="boot">
    <div class="spin"></div>
    <div class="label">MASTER.AZ <span id="boot-counter">0s</span></div>
    <div class="sub" id="boot-status">loading mobile preview…</div>
    <pre id="boot-log" style="margin-top:24px;max-width:90%;font-size:10px;color:#94A3B8;white-space:pre-wrap;text-align:left;max-height:40vh;overflow:auto;background:rgba(0,0,0,.4);padding:12px;border-radius:8px;"></pre>
  </div>
  <script>
    // Kill any leftover service workers / caches from previous builds, and
    // ONLY THEN inject the bootstrap script. If we let bootstrap.js fetch
    // through a still-active stale SW, it gets the old bundle (which forced
    // /login). The boot loader script tag is injected dynamically below
    // after this purge completes — there is no static <script src=...> in
    // this file for the bootstrap.
    var __FB_BOOT_SRC = 'flutter_bootstrap.js?v=__BUILD_ID__';
    (function () {
      function injectBootstrap() {
        var s = document.createElement('script');
        s.src = __FB_BOOT_SRC;
        s.async = true;
        document.body.appendChild(s);
      }
      if (!('serviceWorker' in navigator)) {
        injectBootstrap();
        return;
      }
      var ALREADY_RELOADED = '__sw_purged_once';
      Promise.resolve().then(async function () {
        var regs = [];
        try { regs = await navigator.serviceWorker.getRegistrations(); } catch (e) {}
        var hadAny = regs.length > 0;
        await Promise.all(regs.map(function (r) {
          return r.unregister().catch(function () {});
        }));
        if (window.caches) {
          try {
            var keys = await caches.keys();
            await Promise.all(keys.map(function (k) { return caches.delete(k); }));
          } catch (e) {}
        }
        if (hadAny && !sessionStorage.getItem(ALREADY_RELOADED)) {
          // Old SW was alive — its in-memory copy may still serve fetches
          // until the page reloads. Force a clean reload before bootstrap.
          sessionStorage.setItem(ALREADY_RELOADED, '1');
          location.reload();
          return; // don't inject bootstrap on this iteration
        }
        injectBootstrap();
      }).catch(function () { injectBootstrap(); });
    })();
    // Visible "alive" tick so the user can see whether THIS HTML is the one
    // that loaded (not a stale cached version).
    var _bootStart = Date.now();
    setInterval(function() {
      var c = document.getElementById('boot-counter');
      if (c) c.textContent = Math.round((Date.now() - _bootStart) / 1000) + 's · build@2026-04-27-v6';
    }, 250);
    var _bootLog = function(msg) {
      var el = document.getElementById('boot-log');
      if (!el) return;
      el.textContent += '[' + Math.round((Date.now() - _bootStart) / 1000) + 's] ' + msg + '\n';
    };
    _bootLog('boot script started');
    _bootLog('navigator.serviceWorker: ' + ('serviceWorker' in navigator ? 'available' : 'missing'));
    var _bootStatus = function(msg) {
      var el = document.getElementById('boot-status');
      if (el) el.textContent = msg;
    };
    window.addEventListener('flutter-first-frame', function () {
      var b = document.getElementById('boot');
      if (b) { b.classList.add('hidden'); setTimeout(function(){ b.remove(); }, 400); }
    });
    window.addEventListener('error', function(ev) {
      _bootLog('JS ERROR: ' + (ev.error && ev.error.stack || ev.message));
      _bootStatus('error — see log');
    });
    window.addEventListener('unhandledrejection', function(ev) {
      _bootLog('PROMISE REJECTED: ' + (ev.reason && ev.reason.stack || ev.reason));
      _bootStatus('error — see log');
    });
    setTimeout(function () {
      var b = document.getElementById('boot');
      if (b && !b.classList.contains('hidden')) {
        _bootStatus('still loading — check log');
        _bootLog('First frame not fired after 8s.');
        _bootLog('Loader keys: ' + Object.keys(window._flutter?.loader || {}).join(', '));
        _bootLog('engine init: ' + (window._flutter?.loader?.didCreateEngineInitializer ? 'pending' : 'fired'));
      }
    }, 8000);
    setTimeout(function () {
      var b = document.getElementById('boot');
      if (b && !b.classList.contains('hidden')) {
        _bootLog('Still no first frame after 20s.');
      }
    }, 20000);
  </script>
</body>
</html>
HTML

RUN flutter build web --release \
    --web-renderer canvaskit \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --base-href=${BASE_HREF} \
    --no-tree-shake-icons \
    --pwa-strategy=none

# Replace the empty flutter_service_worker.js with a self-purging worker.
# Users who registered the legacy Flutter SW from earlier builds still have
# it active in their browser — it intercepts every fetch under /mobile/ and
# returns stale cached responses (including the old "force /login" bundle).
# When their browser does its periodic SW update check (auto, on next
# navigation), it fetches THIS file, sees the bytes differ, installs it,
# activates immediately (skipWaiting), nukes every cache, claims all
# clients, then reloads each open tab so users see the fresh app without
# any manual cache clearing.
RUN cat > build/web/flutter_service_worker.js <<'SW'
self.addEventListener('install', (e) => {
  self.skipWaiting();
});
self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    try {
      const keys = await caches.keys();
      await Promise.all(keys.map((k) => caches.delete(k)));
    } catch (err) {}
    try { await self.clients.claim(); } catch (err) {}
    try {
      const cs = await self.clients.matchAll({ type: 'window' });
      for (const c of cs) {
        try { c.navigate(c.url); } catch (err) {}
      }
    } catch (err) {}
    try { await self.registration.unregister(); } catch (err) {}
  })());
});
// No fetch handler → all requests pass through to network. The legacy
// Flutter SW had a fetch handler that served stale cache; this one does
// not, so once activated, the browser fetches everything fresh.
SW

# Force local CanvasKit. The CLI flag --no-web-resources-cdn does NOT
# always set useLocalCanvasKit:true in buildConfig (Flutter 3.24 quirk),
# so we patch the generated bootstrap script directly. We also have local
# canvaskit/* files because the SDK ships them with --use-local-canvaskit
# behaviour by default in 3.24.
RUN sed -i 's/"engineRevision":"\([^"]*\)","builds":/"engineRevision":"\1","useLocalCanvasKit":true,"builds":/g' build/web/flutter_bootstrap.js \
 && grep -o '"useLocalCanvasKit":[^,]*' build/web/flutter_bootstrap.js | head -1

# Cache-busting. Cloudflare caches main.dart.js / flutter_bootstrap.js /
# canvaskit.js as immutable on first hit (Flutter's default headers say so),
# and once cached, even if origin changes headers to no-store, CF keeps the
# stale bundle until 30-day expiry. We append ?v=BUILD_ID to every asset URL
# so CF treats each new build as a fresh resource (BYPASS instead of HIT).
ARG BUILD_ID=dev
RUN BUILD_ID="${BUILD_ID:-$(date +%s)}" && echo "Build ID = $BUILD_ID" \
 && sed -i "s|__BUILD_ID__|${BUILD_ID}|g" build/web/index.html \
 && sed -i "s|\"main\.dart\.js\"|\"main.dart.js?v=${BUILD_ID}\"|g" build/web/flutter_bootstrap.js \
 && sed -i "s|\"canvaskit\\.js\"|\"canvaskit.js?v=${BUILD_ID}\"|g" build/web/flutter_bootstrap.js \
 && sed -i "s|\"canvaskit\\.wasm\"|\"canvaskit.wasm?v=${BUILD_ID}\"|g" build/web/flutter_bootstrap.js \
 && echo "$BUILD_ID" > build/web/build-id.txt

# Strip the service-worker registration call that Flutter still emits in
# flutter_bootstrap.js even with --pwa-strategy=none. We don't want any
# service worker — they cause "old version stuck in browser" bugs and
# offer zero benefit for the preview deployment. Multi-line perl regex,
# since the load() call spans several lines.
RUN perl -0777 -pi -e 's/_flutter\.loader\.load\(\s*\{[^}]*?serviceWorkerSettings[^}]*?\}\s*\}\s*\)/_flutter.loader.load({})/gs' build/web/flutter_bootstrap.js \
 && tail -c 200 build/web/flutter_bootstrap.js \
 && grep -q '_flutter\.loader\.load({})' build/web/flutter_bootstrap.js \
   || (echo 'service worker registration not stripped (perl regex did not match)' && exit 1)

# Stage 2 — serve the static bundle behind nginx
FROM nginx:alpine

# Drop default site and our SPA-friendly conf.
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# The build artefact.
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD wget -qO- http://localhost/ > /dev/null || exit 1
