# SEO setup — manual steps after deploy

Engineering work that needs an admin/owner to complete in a browser console.
All technical scaffolding (sitemap, robots, hreflang, schema) is live in code
already; this list is just the external-side hookups.

## Search Console enrolment

For each engine, add **all five locale subpaths** as separate properties so we
get per-locale impressions / queries.

### Google Search Console

1. https://search.google.com/search-console
2. Add property → **Domain** (preferred, covers all subdomains): `itez.app`
   - Verify via DNS TXT record (Cloudflare → DNS → Add record).
3. Submit sitemap → `https://itez.app/sitemap.xml`
4. Enable **Enhanced** reports (Core Web Vitals, Mobile Usability,
   Breadcrumbs, FAQ rich result, AggregateRating).
5. International targeting → ensure hreflang is detected (Settings →
   "International targeting" → check the report).

### Bing Webmaster Tools

1. https://www.bing.com/webmasters
2. Add site `https://itez.app` → verify via XML file or meta tag.
3. Submit sitemap.
4. Enable **IndexNow** (Bing pushes new URLs to other engines too). Add an
   IndexNow key file at `/master-site/frontend/public/<key>.txt`.

### Yandex.Webmaster

1. https://webmaster.yandex.com
2. Add site → verify via meta tag (recommended for Cloudflare-fronted sites).
3. Submit sitemap.
4. **Important for RU locale** — Yandex prefers Cyrillic content; our RU
   pages already serve `<html lang="ru">` so it should auto-classify.

### Analytics

- Google Analytics 4 — create a property, install the gtag snippet inside
  `nuxt.config.ts > app.head.script` so it loads on every page.
- Microsoft Clarity (free heatmaps + session recording) — same install
  pattern.

## Robots.txt note

Cloudflare's automatic content-signals robots.txt may override ours at the
edge. If `curl https://itez.app/robots.txt` returns the Cloudflare-generated
preamble instead of our text, disable in:

  CF Dashboard → Security → Bots → AI Audit → "Generate robots.txt" → OFF

Our own `server/routes/robots.txt.ts` then takes over.

## CWV monitoring

Real-User Monitoring beacons land in `master-api:storage/logs/cwv.log` (daily
rotation, 30 days). To build a percentile dashboard:

```bash
docker exec master-api tail -f /var/www/html/storage/logs/cwv.log
```

A future iteration should pipe these into a real time-series DB (InfluxDB /
ClickHouse) for percentile queries.

## Blog seeding

`/blog` lists posts from the `posts` table. Use the admin API:

```bash
curl -X POST https://itez.app/api/v1/admin/posts \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "slug": "skolko-stoit-remont-v-baku-2026",
    "locale": "ru",
    "title": "Сколько стоит ремонт квартиры в Баку в 2026 году",
    "excerpt": "Полный гайд по цене ремонта с разбивкой по работам, материалам и подрядчикам.",
    "body_md": "## Раздел 1\\nТекст...",
    "hero_url": "https://images.unsplash.com/photo-...",
    "published_at": "2026-05-21T10:00:00Z"
  }'
```

Backlink-magnet topics to prioritise:
- "Сколько стоит ремонт квартиры в Баку 2026"
- "10 признаков аварийной проводки"
- "Как выбрать сантехника: чек-лист 2026"
- One post per locale × 5 priority topics × 5 locales = 25 posts to start.

## Content gen reruns

Whenever new categories are added or translations need refresh:

```bash
docker exec master-api php artisan seo:translate-categories            # idempotent
docker exec master-api php artisan seo:generate-category-content        # idempotent
docker exec master-api php artisan seo:generate-city-category-content   # per (city, category)
```

All three commands skip rows already populated and only call Gemini for the
missing ones.
