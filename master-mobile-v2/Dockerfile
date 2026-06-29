# Stage 1 — build Flutter web bundle (BLoC + auto_route стек)
FROM ghcr.io/cirruslabs/flutter:3.24.5 AS build

WORKDIR /app

# Кэш слоёв: pubspec первый, чтобы переустановка зависимостей не запускалась
# на каждое изменение исходников.
COPY pubspec.yaml ./
RUN flutter pub get || true

COPY . .

# Скаффолдинг web-папки. lib/ уже наш, --platforms=web просто создаст web/.
RUN flutter create . \
    --org az.gasimov.itez \
    --platforms=web \
    --project-name itez_mobile

RUN test -f web/index.html || (echo 'web/index.html missing' && exit 1)

RUN flutter pub get

# auto_route_generator → *.gr.dart (мы коммитим bootstrap-версию,
# но codegen всё равно пройдёт, чтобы свежие фичи попали в роутер).
RUN dart run build_runner build --delete-conflicting-outputs || true

# ARB → AppLocalizations
RUN flutter gen-l10n || true

# Compile-time configs — переопределяются через --build-arg.
ARG API_BASE_URL=https://itez.app/api/v1
ARG SITE_URL=https://itez.app
ARG REVERB_HOST=ws.itez.app
ARG REVERB_KEY=
ARG REVERB_PORT=443
ARG BASE_HREF=/mobile-v2/

# Boot loader + SW-purger в index.html — копия паттерна из v1, доказавшего
# работу против застрявших стейлных service worker'ов на проде.
RUN cat > web/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="itez — home services marketplace">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-title" content="itez">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>itez</title>
  <link rel="manifest" href="manifest.json">
  <style>
    html, body { margin:0; padding:0; height:100%; background:#FF7A1A; color:#fff;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    #boot {
      position: fixed; inset: 0; display: flex; flex-direction: column;
      align-items: center; justify-content: center; gap: 18px;
      background: radial-gradient(circle at 50% 30%, #FF7A1A 0%, #E65F00 70%);
      transition: opacity .35s ease;
    }
    #boot.hidden { opacity: 0; pointer-events: none; }
    #boot .spin {
      width: 44px; height: 44px; border-radius: 50%;
      border: 3px solid rgba(255,255,255,0.25);
      border-top-color: #ffffff;
      animation: spin 0.9s linear infinite;
    }
    #boot .label { font-size: 13px; letter-spacing: 2px; color: #fff; }
    #boot .sub { font-size: 11px; color: rgba(255,255,255,0.7); margin-top: 6px; }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div id="boot">
    <div class="spin"></div>
    <div class="label">itez <span id="boot-counter">0s</span></div>
    <div class="sub" id="boot-status">loading…</div>
  </div>
  <script>
    var __FB_BOOT_SRC = 'flutter_bootstrap.js?v=__BUILD_ID__';
    (function () {
      function injectBootstrap() {
        var s = document.createElement('script');
        s.src = __FB_BOOT_SRC;
        s.async = true;
        document.body.appendChild(s);
      }
      if (!('serviceWorker' in navigator)) { injectBootstrap(); return; }
      var ALREADY_RELOADED = '__sw_purged_once';
      Promise.resolve().then(async function () {
        var regs = [];
        try { regs = await navigator.serviceWorker.getRegistrations(); } catch (e) {}
        var hadAny = regs.length > 0;
        await Promise.all(regs.map(function (r) { return r.unregister().catch(function () {}); }));
        if (window.caches) {
          try {
            var keys = await caches.keys();
            await Promise.all(keys.map(function (k) { return caches.delete(k); }));
          } catch (e) {}
        }
        if (hadAny && !sessionStorage.getItem(ALREADY_RELOADED)) {
          sessionStorage.setItem(ALREADY_RELOADED, '1');
          location.reload();
          return;
        }
        injectBootstrap();
      }).catch(function () { injectBootstrap(); });
    })();
    var _bootStart = Date.now();
    setInterval(function() {
      var c = document.getElementById('boot-counter');
      if (c) c.textContent = Math.round((Date.now() - _bootStart) / 1000) + 's';
    }, 250);
    window.addEventListener('flutter-first-frame', function () {
      var b = document.getElementById('boot');
      if (b) { b.classList.add('hidden'); setTimeout(function(){ b.remove(); }, 400); }
    });
  </script>
</body>
</html>
HTML

RUN flutter build web --release \
    --web-renderer canvaskit \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=SITE_URL=${SITE_URL} \
    --dart-define=REVERB_HOST=${REVERB_HOST} \
    --dart-define=REVERB_KEY=${REVERB_KEY} \
    --dart-define=REVERB_PORT=${REVERB_PORT} \
    --base-href=${BASE_HREF} \
    --no-tree-shake-icons \
    --pwa-strategy=none

# Self-purging SW: убивает стейлные регистрации, чтобы пользователи
# не зависали на старом бандле (см. v1).
RUN cat > build/web/flutter_service_worker.js <<'SW'
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    try { const keys = await caches.keys();
      await Promise.all(keys.map((k) => caches.delete(k))); } catch (err) {}
    try { await self.clients.claim(); } catch (err) {}
    try {
      const cs = await self.clients.matchAll({ type: 'window' });
      for (const c of cs) { try { c.navigate(c.url); } catch (err) {} }
    } catch (err) {}
    try { await self.registration.unregister(); } catch (err) {}
  })());
});
SW

# Force-local CanvasKit (Flutter 3.24 quirk: --no-web-resources-cdn не всегда
# проставляет useLocalCanvasKit).
RUN sed -i 's/"engineRevision":"\([^"]*\)","builds":/"engineRevision":"\1","useLocalCanvasKit":true,"builds":/g' build/web/flutter_bootstrap.js || true

# Cache busting: ?v=BUILD_ID на main.dart.js / canvaskit, чтобы Cloudflare
# не отдавал стейлный бандл из своего edge-кэша.
ARG BUILD_ID=dev
RUN BUILD_ID="${BUILD_ID:-$(date +%s)}" && echo "Build ID = $BUILD_ID" \
 && sed -i "s|__BUILD_ID__|${BUILD_ID}|g" build/web/index.html \
 && sed -i "s|\"main\.dart\.js\"|\"main.dart.js?v=${BUILD_ID}\"|g" build/web/flutter_bootstrap.js \
 && sed -i "s|\"canvaskit\\.js\"|\"canvaskit.js?v=${BUILD_ID}\"|g" build/web/flutter_bootstrap.js \
 && sed -i "s|\"canvaskit\\.wasm\"|\"canvaskit.wasm?v=${BUILD_ID}\"|g" build/web/flutter_bootstrap.js \
 && echo "$BUILD_ID" > build/web/build-id.txt

# Удаляем регистрацию SW из bootstrap (Flutter 3.24 эмиттит её даже при
# --pwa-strategy=none — она цепляет стейлные кэши).
RUN perl -0777 -pi -e 's/_flutter\.loader\.load\(\s*\{[^}]*?serviceWorkerSettings[^}]*?\}\s*\}\s*\)/_flutter.loader.load({})/gs' build/web/flutter_bootstrap.js || true

# Stage 2 — статика за nginx
FROM nginx:alpine
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD wget -qO- http://localhost/ > /dev/null || exit 1
