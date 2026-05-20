// Tiny realtime SSE relay for itez.app.
//
// Why this exists: Cloudflare Flexible SSL silently downgrades WSS → HTTP on
// the proxied apex, so a WebSocket client never connects. Plain HTTP streaming
// (SSE) sails through any CF tier on Free/Flexible.
//
// Flow:
//   1. Backend publishes events to Redis channel `realtime:user:{id}`.
//   2. Each authenticated SSE connection subscribes to the channel for the
//      authenticated user only and pipes incoming payloads down as
//      `data: <json>\n\n` SSE frames.
//   3. Server emits a heartbeat every 20s so intermediaries don't reap idle
//      connections.
//
// Auth: client passes `?token=<bearer-sanctum-token>` (EventSource can't set
// headers). We verify the token against Laravel by querying the api /auth/me
// once per connection (cached for the duration of the connection lifetime).

const http = require('http');
const url = require('url');
const Redis = require('ioredis');

const PORT = parseInt(process.env.SSE_PORT || '8086', 10);
const REDIS_URL = process.env.REDIS_URL || 'redis://default:redispass@master-redis:6379';
const API_INTERNAL = process.env.API_INTERNAL_URL || 'http://master-api:8000/api';

const server = http.createServer(async (req, res) => {
  const u = url.parse(req.url, true);

  if (u.pathname === '/sse/health') {
    res.writeHead(200, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ status: 'ok', port: PORT }));
  }

  if (u.pathname !== '/sse/stream') {
    res.writeHead(404, { 'content-type': 'text/plain' });
    return res.end('not found');
  }

  const token = (u.query && u.query.token) ? String(u.query.token) : '';
  if (!token) {
    res.writeHead(401, { 'content-type': 'text/plain' });
    return res.end('missing token');
  }

  // Validate token against the API and grab the user id.
  let userId;
  try {
    const apiRes = await fetch(`${API_INTERNAL}/auth/me`, {
      headers: { 'Authorization': 'Bearer ' + token, 'Accept': 'application/json' },
    });
    if (!apiRes.ok) {
      res.writeHead(401, { 'content-type': 'text/plain' });
      return res.end('invalid token');
    }
    const data = await apiRes.json();
    userId = data && data.user && data.user.id;
  } catch (e) {
    res.writeHead(502, { 'content-type': 'text/plain' });
    return res.end('auth backend unreachable');
  }
  if (!userId) {
    res.writeHead(401, { 'content-type': 'text/plain' });
    return res.end('no user');
  }

  // Begin SSE stream.
  res.writeHead(200, {
    'content-type':                'text/event-stream',
    'cache-control':               'no-cache, no-store, must-revalidate',
    'connection':                  'keep-alive',
    'x-accel-buffering':           'no',                            // nginx
    'access-control-allow-origin': req.headers.origin || '*',
    'access-control-allow-credentials': 'true',
  });
  res.write(`retry: 3000\n\n`);
  res.write(`event: ready\ndata: ${JSON.stringify({ user_id: userId })}\n\n`);

  const sub = new Redis(REDIS_URL);
  const channel = `realtime:user:${userId}`;
  sub.subscribe(channel, (err, count) => {
    if (err) {
      res.write(`event: error\ndata: ${JSON.stringify({ message: err.message })}\n\n`);
    }
  });
  sub.on('message', (_, payload) => {
    res.write(`data: ${payload}\n\n`);
  });

  // Heartbeat — keeps proxies happy, helps clients detect dead links.
  const hb = setInterval(() => {
    res.write(`: ping ${Date.now()}\n\n`);
  }, 20000);

  const cleanup = () => {
    clearInterval(hb);
    try { sub.unsubscribe(channel); } catch (_) {}
    try { sub.quit(); } catch (_) {}
  };
  req.on('close', cleanup);
  req.on('error', cleanup);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[sse] listening on :${PORT} → redis ${REDIS_URL}`);
});
