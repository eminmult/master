# Master.az Mobile API — Integration Guide

Base URL: `https://master.gasimov.az/api/v1`

All endpoints return JSON. Auth uses **bearer tokens** issued by Sanctum. Use the versioned path — the unversioned `/api/*` aliases exist only for the legacy web frontend and may break without notice.

---

## 1. Conventions

### Headers (every authenticated request)

```
Authorization: Bearer <token>
Accept: application/json
Accept-Language: az | ru | en | tr | ar
Content-Type: application/json
```

`Accept-Language` controls which translation of user-generated content (orders, reviews, master profiles) the server returns. Defaults to `az`.

### Standard error shape

```json
// 401 unauthenticated
{ "message": "Unauthenticated." }

// 422 validation
{ "message": "...", "errors": { "field": ["..."] } }

// 402 subscription gate (master with inactive subscription)
{ "message": "Subscription expired", "code": "subscription_required", "subscription_expires_at": "..." }
```

### Pagination shape

```json
{ "items": [...], "total": 123, "page": 1, "per_page": 20, "has_more": true }
```

Chat messages use cursor pagination via `?before=<msg_id>`.

---

## 2. Bootstrap flow (cold start)

### 2.1 GET `/app/config` (no auth)

```json
{
  "min_supported_version": { "ios": "1.0.0", "android": "1.0.0" },
  "latest_version":         { "ios": "1.0.0", "android": "1.0.0" },
  "force_update": false,
  "maintenance": false,
  "maintenance_message": null,
  "store_urls": { "ios": "...", "android": "..." },
  "features": {
    "subscription_required": false,
    "free_launch_until": "2026-12-31",
    "reverb_enabled": true
  },
  "support": { "email": "...", "phone": null, "whatsapp": null },
  "urls": { "web": "...", "terms": "...", "privacy": "..." },
  "server_time": "2026-04-27T08:11:45+00:00"
}
```

If `bundleVersion < min_supported_version` → hard wall with store link. If `maintenance: true` → splash with `maintenance_message`.

### 2.2 GET `/health` (no auth)

`200` when DB/Redis/queue are reachable, `503` otherwise.

---

## 3. Authentication

### 3.1 Register client

`POST /auth/register/client`
```json
{ "first_name": "...", "last_name": "...", "phone": "+994501234567",
  "email": "...", "password": "...", "password_confirmation": "..." }
```

### 3.2 Register master

`POST /auth/register/master`
```json
{ "first_name": "...", "last_name": "...", "phone": "+994...", "email": "...",
  "password": "...", "password_confirmation": "...",
  "city": "Bakı", "district": "Yasamal", "description": "...",
  "experience_years": 5, "category_ids": [1, 5] }
```

Both return `{ user, token }`. After register, phone OTP is auto-sent and email verification (if email provided) is queued.

### 3.3 Login

`POST /auth/login`  →  `{ "login": "<phone OR email>", "password": "..." }`  →  `{ user, token }`

### 3.4 Verification endpoints

```
POST /auth/phone/request-otp                       # throttle 3/min
POST /auth/phone/verify-otp     { "code": "123456" }
POST /auth/resend-verification                     # email — throttle 5/min
POST /auth/verify-email         { "token": "...", "user_id": 42 }
```

### 3.5 Token refresh — call every 7 days

`POST /auth/refresh`  →  `{ "token": "...", "expires_at": "..." }`

Tokens expire after **30 days**. Refresh proactively before expiry. If refresh returns 401 → token already dead, force re-login.

### 3.6 Current user

`GET /auth/me`

For masters, includes the subscription block:
```json
{
  "user": {
    "id": 1, "role": "master",
    "subscription": {
      "active": true, "expires_at": "...", "required": false,
      "free_launch_until": "2026-12-31", "can_operate": true
    }
  }
}
```

When `subscription.required && !subscription.can_operate` → show paywall, block apply/chat actions.

### 3.7 Logout

`POST /auth/logout` — revokes current token. Always call `/devices/unregister` first.

### 3.8 Password reset

```
POST /auth/forgot-password   { "login": "<phone or email>" }
POST /auth/reset-password    { "login": "...", "token": "...", "password": "...", "password_confirmation": "..." }
```

Email reset link points to `https://master.gasimov.az/reset-password?token=X&login=Y` — handle as universal link / app link to open the native screen.

---

## 4. Push notifications (FCM)

### 4.1 Register on login / on FCM token refresh

`POST /devices/register`
```json
{ "platform": "ios" | "android",
  "token":    "<FCM token>",
  "app_version": "1.0.0",
  "device_model": "iPhone 15 Pro",
  "locale": "ru" }
```

FCM rotates tokens — on `onNewToken` (Android) / `didReceiveRegistrationToken` (iOS), POST again. Server upserts on `token` (unique).

### 4.2 Unregister on logout

`POST /devices/unregister`  →  `{ "token": "<FCM token>" }`

### 4.3 Payload shape

Server sends FCM with both `notification` (system-rendered) and `data` (deep-link routing):

```json
{
  "notification": { "title": "...", "body": "..." },
  "data": {
    "type": "order_accepted | new_message | proposal_received | ...",
    "order_id": "5",
    "application_id": "12",
    "sender_id": "8"
  }
}
```

All `data` values are strings (FCM contract). Cast `parseInt(order_id)` on the client.

### 4.4 Notification types

| `data.type` | Trigger | Deep link |
|---|---|---|
| `order_created` | client created an order | `/orders/{order_id}` |
| `order_accepted` | master accepted client's direct request | `/orders/{order_id}` |
| `order_assigned` | master got a new assigned order | `/orders/{order_id}` |
| `proposal_received` | master sent date+price | `/order-applications/{application_id}` |
| `proposal_accepted` | client accepted master's proposal | `/orders/{order_id}` |
| `application_accepted` | (mirror of above for the master) | `/orders/{order_id}` |
| `master_on_the_way` | status update | `/orders/{order_id}` |
| `master_arrived` | status update | `/orders/{order_id}` |
| `order_completed` | both notified — prompt review | `/orders/{order_id}` review |
| `order_canceled` | counterparty canceled | `/orders/{order_id}` |
| `new_message` | chat — silence in-foreground if chat is open | `/order-applications/{application_id}/chat` |
| `new_review` | someone reviewed you | `/profile` |
| `dispute_opened` | counterparty filed dispute | `/orders/{order_id}` |
| `order_expired` | system auto-canceled | new order screen |

---

## 5. Order flow (canonical)

### 5.1 Categories — cache locally

```
GET /categories
GET /categories/{id}
```

### 5.2 Browse masters

```
GET /masters?category_id=1&city=Bakı&page=1
GET /masters/{id}
GET /masters/{id}/reviews
```

### 5.3 Public announcements feed (for masters)

```
GET /orders/public
GET /orders/public/{id}
```

### 5.4 AI smart-search → category classification

`POST /smart-search`  →  `{ "text": "Krani sızır", "photo": "<base64>" }` (photo optional)

### 5.5 Client creates order

`POST /orders`
```json
{ "category_id": 1, "subcategory_id": null,
  "description": "...", "estimated_budget": 100,
  "address": "Bakı, ...", "latitude": 40.4, "longitude": 49.86,
  "preferred_master_id": null,
  "photos": ["<base64>", ...] }
```

`estimated_budget` max `999999`. `photos` up to 5.

### 5.6 Master applies to public order

`POST /orders/{order}/apply`  →  `{ "message": "...", "proposed_price": 80 }`

Throttled `10/min`, daily cap `50`. Returns 402 if subscription gate is on and master is inactive.

### 5.7 Per-application chat

```
GET  /order-applications/{application}/messages?before=<msg_id>
POST /order-applications/{application}/messages   { "text": "..." }
```

Server **masks phone numbers, emails, Telegram/WhatsApp handles** before saving — UI should explain this in the placeholder text.

### 5.8 Master sends concrete proposal

`POST /order-applications/{application}/propose`  →  `{ "proposed_date": "ISO8601", "proposed_price": 80 }`

`proposed_date` must be in the future. `proposed_price` max `999999`.

### 5.9 Client accepts proposal — closes the announcement

`POST /order-applications/{application}/accept-proposal`

Server transitions order to `confirmed`, auto-rejects all other applications.

### 5.10 Master order status

`POST /orders/{order}/status`  →  `{ "status": "on_the_way | arrived | in_progress | awaiting_completion" }`

### 5.11 Client confirms completion

`POST /orders/{order}/status`  →  `{ "status": "completed" }`

### 5.12 Reviews

```
POST /orders/{order}/review   { "rating": 5, "text": "...", "tags": [] }
GET  /reviews/pending          # orders awaiting your review
```

### 5.13 Cancel / withdraw / dispute

```
POST /orders/{order}/cancel                              { "reason": "..." }    # client only
POST /order-applications/{application}/withdraw                                  # master pulls back
POST /orders/{order}/dispute   { "reason": "...", "description": "..." }
```

Dispute requires order in confirmed / on_the_way / arrived / in_progress / awaiting_completion / completed.

---

## 6. Master endpoints

```
PUT  /master/profile
PUT  /master/status                       { "is_active": true | false }
POST /master/location                     { "latitude": ..., "longitude": ..., "heading": ... }
GET  /master/work-hours
POST /master/work-hours                   { "hours": [{ "day": 1, "start": "09:00", "end": "18:00" }] }
GET  /master/earnings
GET  /master/applications                 # paginated, 20 per page
GET  /master/applied-order-ids            # quick lookup for "have I applied?"
```

`/master/location` should be batched — send every 30s while order is `on_the_way` or `arrived`, not every GPS tick.

---

## 7. Client endpoints

```
PUT    /client/profile
GET    /addresses
POST   /addresses
PUT    /addresses/{id}
DELETE /addresses/{id}
```

---

## 8. Avatars / photos

### Avatar
`POST /avatar`  →  `{ "avatar": "data:image/jpeg;base64,..." }` — server makes 3 WebP sizes, returns `{ "avatar_url": "..." }`.

### Order photos
Pass `photos: ["<base64>", ...]` (up to 5) in `POST /orders` body.

Avoid multipart — Cloudflare may strip large multipart bodies. JSON+base64 is safe.

---

## 9. Notifications inbox

```
GET  /notifications
GET  /notifications/unread-count
POST /notifications/{id}/read
POST /notifications/read-all
```

`title` / `body` are JSON-encoded localized maps `{ "az": "...", "ru": "...", "en": "..." }` — pick the user's locale client-side.

---

## 10. Real-time (planned)

WebSocket via Laravel Reverb is **scaffolded but not wired**. Until then mobile should poll:

- Active chat: 5s while open, 30s in background
- Orders list: 60s
- Notifications: pull-to-refresh + on push

When Reverb ships, subscribe to:
- `private-application.{id}` — new chat messages
- `private-orders.{userId}` — order status changes
- `private-notifications.{userId}` — server-side push echoes

---

## 11. GDPR

```
GET  /me/export                  # JSON dump of all PII the server holds
POST /me/delete   { "confirm": "DELETE" }     # anonymizes — blocked if you have active orders
```

---

## 12. Versioning policy

- `/api/v1/...` is canonical — what mobile must target.
- Additive changes ship in-place; clients **must ignore unknown JSON keys**.
- Breaking changes ship at `/api/v2/...`. `v1` keeps working until sunset (typically 6+ months after `v2` is GA).
- Server enforces `min_supported_version` via `/app/config`. Bump it to force-update broken builds.

---

## 13. Recommended client architecture

- HTTP client: single interceptor adds bearer + Accept + Accept-Language.
- 401 handler: try `/auth/refresh` once → if that also 401s → log out.
- 402 handler with `code: subscription_required` → show paywall.
- Push handler: in-foreground → in-app banner; on tap → deep-link by `data.type` + `data.order_id`.
- Offline cache: categories, last `auth/me`, last viewed master list — for instant cold-start.
- Crash reporting: send URL + status only (not bodies — may contain PII).

---

## 14. Endpoint quick-list (for Postman / Insomnia import)

```
# Public
GET  /api/v1/health
GET  /api/v1/app/config
GET  /api/v1/categories
GET  /api/v1/categories/{id}
GET  /api/v1/masters
GET  /api/v1/masters/{id}
GET  /api/v1/masters/{id}/reviews
GET  /api/v1/users/{id}/profile
GET  /api/v1/orders/public
GET  /api/v1/orders/public/{id}
GET  /api/v1/stats/public
POST /api/v1/smart-search

# Auth (public)
POST /api/v1/auth/register/client
POST /api/v1/auth/register/master
POST /api/v1/auth/login
POST /api/v1/auth/forgot-password
POST /api/v1/auth/reset-password
POST /api/v1/auth/verify-email

# Auth (authenticated)
GET  /api/v1/auth/me
POST /api/v1/auth/logout
POST /api/v1/auth/refresh
POST /api/v1/auth/resend-verification
POST /api/v1/auth/phone/request-otp
POST /api/v1/auth/phone/verify-otp

# Devices (authenticated)
POST /api/v1/devices/register
POST /api/v1/devices/unregister

# Privacy
GET  /api/v1/me/export
POST /api/v1/me/delete

# Orders
POST /api/v1/orders
GET  /api/v1/orders/my
GET  /api/v1/orders/available
GET  /api/v1/orders/{order}
POST /api/v1/orders/{order}/accept
POST /api/v1/orders/{order}/decline
POST /api/v1/orders/{order}/confirm
POST /api/v1/orders/{order}/reject-proposal
POST /api/v1/orders/{order}/status
POST /api/v1/orders/{order}/cancel
POST /api/v1/orders/{order}/dispute

# Applications
POST /api/v1/orders/{order}/apply
GET  /api/v1/orders/{order}/applications
POST /api/v1/order-applications/{app}/start-discussion
POST /api/v1/order-applications/{app}/reject
POST /api/v1/order-applications/{app}/withdraw
POST /api/v1/order-applications/{app}/propose
POST /api/v1/order-applications/{app}/accept-proposal
POST /api/v1/order-applications/{app}/reject-proposal
GET  /api/v1/order-applications/{app}/messages
POST /api/v1/order-applications/{app}/messages
GET  /api/v1/master/applications
GET  /api/v1/master/applied-order-ids

# Chat (legacy order-scoped — for confirmed orders)
GET  /api/v1/orders/{order}/messages
POST /api/v1/orders/{order}/messages
GET  /api/v1/chat/unread

# Reviews
POST /api/v1/orders/{order}/review
GET  /api/v1/reviews/pending

# Notifications
GET  /api/v1/notifications
GET  /api/v1/notifications/unread-count
POST /api/v1/notifications/{id}/read
POST /api/v1/notifications/read-all

# Master
PUT  /api/v1/master/profile
PUT  /api/v1/master/status
POST /api/v1/master/location
GET  /api/v1/master/work-hours
POST /api/v1/master/work-hours
GET  /api/v1/master/earnings

# Client
PUT    /api/v1/client/profile
GET    /api/v1/addresses
POST   /api/v1/addresses
PUT    /api/v1/addresses/{id}
DELETE /api/v1/addresses/{id}

# Avatar
POST /api/v1/avatar

# Category suggestions
POST /api/v1/category-suggestions
GET  /api/v1/category-suggestions/mine

# Admin (role:admin)
GET  /api/v1/admin/users
GET  /api/v1/admin/orders
GET  /api/v1/admin/categories
POST /api/v1/admin/categories
PUT  /api/v1/admin/categories/{id}
DELETE /api/v1/admin/categories/{id}
GET  /api/v1/admin/category-suggestions
POST /api/v1/admin/category-suggestions/{id}/approve
POST /api/v1/admin/category-suggestions/{id}/reject
GET  /api/v1/admin/reviews
DELETE /api/v1/admin/reviews/{id}
GET  /api/v1/admin/disputes
POST /api/v1/admin/disputes/{id}/resolve
GET  /api/v1/admin/analytics
GET  /api/v1/admin/analytics/daily
POST /api/v1/admin/users/{id}/toggle-block
POST /api/v1/admin/users/{id}/verify
POST /api/v1/admin/users/{id}/extend-subscription
POST /api/v1/admin/users/{id}/deactivate-subscription
POST /api/v1/admin/orders/{id}/set-status
```
