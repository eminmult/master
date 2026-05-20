<template><span style="display:none" /></template>

<script setup lang="ts">
// Site-wide JSON-LD: Organization + WebSite (with SearchAction). Mounted in
// the hm layout so every public page emits these on first paint. Specific
// page types add their own Person/Service/FAQ/Review schemas on top.

const SITE_ORIGIN = 'https://itez.app'

const orgSchema = {
  '@context': 'https://schema.org',
  '@type': 'Organization',
  name: 'itez.app',
  url: SITE_ORIGIN,
  logo: `${SITE_ORIGIN}/favicon.svg`,
  sameAs: [
    'https://www.instagram.com/itez.app',
    'https://www.tiktok.com/@itez.app',
    'https://www.facebook.com/itez.app',
  ],
  contactPoint: [
    {
      '@type': 'ContactPoint',
      contactType: 'customer support',
      email: 'support@itez.app',
      areaServed: 'AZ',
      availableLanguage: ['az', 'ru', 'en', 'tr', 'ar'],
    },
  ],
}

const websiteSchema = {
  '@context': 'https://schema.org',
  '@type': 'WebSite',
  name: 'itez.app',
  url: SITE_ORIGIN,
  potentialAction: {
    '@type': 'SearchAction',
    target: {
      '@type': 'EntryPoint',
      urlTemplate: `${SITE_ORIGIN}/masters?search={search_term_string}`,
    },
    'query-input': 'required name=search_term_string',
  },
  inLanguage: ['az', 'ru', 'en', 'tr', 'ar'],
}

useHead({
  script: [
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify(orgSchema),
      key: 'jsonld-org',
    },
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify(websiteSchema),
      key: 'jsonld-website',
    },
  ],
})
</script>
