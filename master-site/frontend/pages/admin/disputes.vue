<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="admin" />
        <div class="hm-dash-main">
      <h1>{{ $t('admin.disputes') }}</h1>
      <p class="text-muted mb-4">{{ $t('admin.disputes_manage') }}</p>
      <div v-if="!loading && disputes.length === 0" class="text-center mt-4 text-muted">{{ $t('admin.no_disputes') }}</div>
      <div v-else-if="disputes.length" class="table-wrap">
        <table class="data-table">
          <thead><tr><th>{{ $t('admin.th_id') }}</th><th>{{ $t('admin.th_order') }}</th><th>{{ $t('admin.th_reporter') }}</th><th>{{ $t('admin.th_reason') }}</th><th>{{ $t('admin.th_status') }}</th><th>{{ $t('admin.th_date') }}</th><th></th></tr></thead>
          <tbody>
            <tr v-for="d in disputes" :key="d.id">
              <td>#{{ d.id }}</td>
              <td>#{{ d.order_id }}</td>
              <td>{{ d.reporter?.first_name }}</td>
              <td>{{ d.reason }}</td>
              <td><span class="badge" :class="d.status === 'open' ? 'badge-danger' : d.status === 'resolved' ? 'badge-success' : 'badge-warning'">{{ d.status }}</span></td>
              <td>{{ formatDate(d.created_at) }}</td>
              <td>
                <button v-if="d.status !== 'resolved'" type="button" class="btn btn-sm btn-primary" @click="openResolve(d)">{{ $t('admin.resolve') }}</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Resolve popup -->
      <Teleport to="body">
        <div v-if="resolving" class="popup-overlay" @click.self="resolving = null">
          <div class="popup-card">
            <div class="popup-header">
              <h3>{{ $t('admin.resolve_dispute_title') }} #{{ resolving.id }}</h3>
              <button type="button" @click="resolving = null"><span class="icon">close</span></button>
            </div>
            <div class="popup-body">
              <div class="form-group">
                <label>{{ $t('admin.resolution') }}</label>
                <select v-model="resolution.resolution">
                  <option value="client_win">{{ $t('admin.resolution_client_win') }}</option>
                  <option value="master_win">{{ $t('admin.resolution_master_win') }}</option>
                  <option value="warning">{{ $t('admin.resolution_warning') }}</option>
                  <option value="no_action">{{ $t('admin.resolution_no_action') }}</option>
                </select>
              </div>
              <div class="form-group">
                <label>{{ $t('admin.admin_note') }}</label>
                <textarea v-model="resolution.admin_note" rows="4"></textarea>
              </div>
              <div class="form-group"><label><input v-model="resolution.ban_master" type="checkbox"> {{ $t('admin.ban_master') }}</label></div>
              <div class="form-group"><label><input v-model="resolution.ban_client" type="checkbox"> {{ $t('admin.ban_client') }}</label></div>
            </div>
            <div class="popup-footer">
              <button type="button" class="btn btn-primary btn-block" :disabled="submitting" @click="submitResolve">
                {{ submitting ? $t('common.loading') : $t('admin.resolve') }}
              </button>
            </div>
          </div>
        </div>
      </Teleport>
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
const disputes = ref<any[]>([])
const loading = ref(true)
const resolving = ref<any | null>(null)
const submitting = ref(false)
const resolution = reactive({
  resolution: 'client_win',
  admin_note: '',
  ban_master: false,
  ban_client: false,
})

function openResolve(d: any) {
  resolving.value = d
  Object.assign(resolution, { resolution: 'client_win', admin_note: '', ban_master: false, ban_client: false })
}

async function submitResolve() {
  if (!resolving.value) return
  submitting.value = true
  try {
    const res = await apiFetch<{ dispute: any }>(`/admin/disputes/${resolving.value.id}/resolve`, {
      method: 'POST',
      body: resolution,
    })
    const idx = disputes.value.findIndex(x => x.id === res.dispute.id)
    if (idx !== -1) disputes.value[idx] = res.dispute
    resolving.value = null
    toast.success($t('admin.resolve_sent'))
  } catch (e: any) {
    toast.error(e?.data?.message || $t('auth.error_occurred'))
  }
  submitting.value = false
}

onMounted(async () => {
  try {
    const res = await apiFetch<{ disputes: any[] }>('/admin/disputes')
    disputes.value = res.disputes
  } catch { disputes.value = [] }
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
</style>
