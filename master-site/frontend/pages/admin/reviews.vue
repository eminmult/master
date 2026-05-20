<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="admin" />
        <div class="hm-dash-main">
      <h1>{{ $t('admin.reviews') }}</h1>
      <p class="text-muted mb-4">{{ $t('admin.reviews_manage') }}</p>
      <div v-if="!loading && reviews.length === 0" class="text-center mt-4 text-muted">{{ $t('admin.no_reviews') }}</div>
      <div v-else-if="reviews.length" class="table-wrap">
        <table class="data-table">
          <thead><tr><th>{{ $t('admin.th_id') }}</th><th>{{ $t('admin.th_order') }}</th><th>{{ $t('admin.th_author') }}</th><th>{{ $t('admin.th_target') }}</th><th>{{ $t('admin.th_score') }}</th><th>{{ $t('admin.th_text') }}</th><th>{{ $t('admin.th_date') }}</th><th></th></tr></thead>
          <tbody>
            <tr v-for="r in reviews" :key="r.id">
              <td>#{{ r.id }}</td>
              <td>#{{ r.order_id }}</td>
              <td>{{ r.reviewer?.first_name }}</td>
              <td>{{ r.reviewee?.first_name }}</td>
              <td>{{ '★'.repeat(r.rating) }}{{ '☆'.repeat(5 - r.rating) }}</td>
              <td class="truncate">{{ r.text || '—' }}</td>
              <td>{{ formatDate(r.created_at) }}</td>
              <td>
                <button type="button" class="btn btn-sm btn-danger" :disabled="deleting[r.id]" @click="removeReview(r.id)">
                  <span class="icon icon-sm">delete</span>
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: ['auth', 'admin'] })
const { t: $t } = useI18n()
const { apiFetch } = useApi()
const { formatDate } = useFormatDate()
const toast = useToast()
const reviews = ref<any[]>([])
const loading = ref(true)
const deleting = reactive<Record<number, boolean>>({})

async function removeReview(id: number) {
  if (!confirm($t('admin.delete_review_confirm'))) return
  deleting[id] = true
  try {
    await apiFetch(`/admin/reviews/${id}`, { method: 'DELETE' })
    reviews.value = reviews.value.filter(r => r.id !== id)
    toast.success($t('admin.review_deleted'))
  } catch (e: any) {
    toast.error(e?.data?.message || $t('auth.error_occurred'))
  } finally {
    deleting[id] = false
  }
}

onMounted(async () => {
  try {
    const res = await apiFetch<{ reviews: any[] }>('/admin/reviews')
    reviews.value = res.reviews
  } catch { reviews.value = [] }
  loading.value = false
})
</script>

<style scoped>
h1 { font-size: 26px; font-weight: 700; margin: 0 0 6px; color: var(--hm-text); letter-spacing: -0.4px; }
.table-wrap {
  overflow-x: auto;
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 16px;
}
.data-table { width: 100%; border-collapse: collapse; font-size: 14px; color: var(--hm-text); }
.data-table th {
  text-align: left; padding: 12px 16px;
  border-bottom: 1px solid var(--hm-border-2);
  font-weight: 700; color: var(--hm-text-3);
  font-size: 11px; text-transform: uppercase; letter-spacing: 0.7px;
  background: var(--hm-bg-2);
}
.data-table td { padding: 14px 16px; border-bottom: 1px solid var(--hm-border-2); color: var(--hm-text-2); }
.data-table tr:last-child td { border-bottom: 0; }
.data-table tr:hover td { background: var(--hm-bg-2); }
.truncate { max-width: 250px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
</style>
