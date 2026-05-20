<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="admin" />
        <div class="hm-dash-main">
      <div class="page-header">
        <h1>{{ $t('admin.users') }}</h1>
        <p class="text-muted">{{ $t('admin.users_desc') }}</p>
      </div>

      <div class="filters card mb-2">
        <div class="filter-row">
          <select v-model="filters.role">
            <option value="">{{ $t('admin.all_roles') }}</option>
            <option value="client">{{ $t('admin.role_client') }}</option>
            <option value="master">{{ $t('admin.role_master') }}</option>
            <option value="admin">{{ $t('admin.role_admin') }}</option>
          </select>
          <input v-model="filters.search" type="text" :placeholder="$t('admin.search_placeholder')" />
          <button class="btn btn-primary btn-sm" @click="fetchUsers">{{ $t('admin.search_btn') }}</button>
        </div>
      </div>

      <div v-if="!loading && users.length === 0" class="text-center mt-4 text-muted">{{ $t('admin.no_users') }}</div>
      <div v-else-if="users.length" class="table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ $t('admin.th_id') }}</th>
              <th>{{ $t('admin.th_name') }}</th>
              <th>{{ $t('admin.th_phone') }}</th>
              <th>{{ $t('admin.th_email') }}</th>
              <th>{{ $t('admin.th_role') }}</th>
              <th>{{ $t('admin.th_rating') }}</th>
              <th>{{ $t('admin.th_registered') }}</th>
              <th>{{ $t('admin.th_status') }}</th>
              <th>{{ $t('admin.th_actions') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="u in users" :key="u.id">
              <td>#{{ u.id }}</td>
              <td>{{ u.first_name }} {{ u.last_name }}</td>
              <td>{{ u.phone }}</td>
              <td>{{ u.email || '—' }}</td>
              <td><span class="badge" :class="roleClass(u.role)">{{ roleLabel(u.role) }}</span></td>
              <td>{{ u.rating_avg }} ({{ u.rating_count }})</td>
              <td>{{ formatDate(u.created_at) }}</td>
              <td><span class="badge" :class="u.is_active ? 'badge-success' : 'badge-danger'">{{ u.is_active ? $t('admin.active') : $t('admin.inactive') }}</span></td>
              <td class="actions-cell">
                <button
                  type="button"
                  class="icon-btn"
                  :class="u.is_active ? 'icon-btn-danger' : 'icon-btn-success'"
                  :title="u.is_active ? $t('admin.btn_block') : $t('admin.btn_unblock')"
                  :disabled="actionLoading[u.id]"
                  @click="toggleBlock(u)"
                >
                  <span class="material-icons">{{ u.is_active ? 'block' : 'check_circle' }}</span>
                </button>
                <button
                  v-if="u.role === 'master'"
                  type="button"
                  class="icon-btn"
                  :class="u.is_verified ? 'icon-btn-blue' : 'icon-btn-gray'"
                  :title="u.is_verified ? $t('admin.btn_verified') : $t('admin.btn_verify')"
                  :disabled="actionLoading[u.id]"
                  @click="verifyMaster(u)"
                >
                  <span class="material-icons">verified</span>
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

const filters = reactive({ role: '', search: '' })
const actionLoading = reactive<Record<number, boolean>>({})

function roleLabel(r: string) { return $t('admin.role_' + r) }
function roleClass(r: string) { return { client: 'badge-primary', master: 'badge-warning', admin: 'badge-danger' }[r] || '' }
const { formatDate } = useFormatDate()

function buildParams() {
  const params = new URLSearchParams()
  if (filters.role) params.set('role', filters.role)
  if (filters.search) params.set('search', filters.search)
  return params.toString()
}

const { data: users } = await useAsyncData('admin-users', async () => {
  try {
    const res = await apiFetch<{ users: any[] }>(`/admin/users?${buildParams()}`)
    return res.users || []
  } catch { return [] }
}, { default: () => [] })
const loading = ref(false)

async function fetchUsers() {
  loading.value = true
  try {
    const res = await apiFetch<{ users: any[] }>(`/admin/users?${buildParams()}`)
    users.value = res.users || []
  } catch {}
  loading.value = false
}

async function toggleBlock(u: any) {
  actionLoading[u.id] = true
  try {
    await apiFetch(`/admin/users/${u.id}/toggle-block`, { method: 'POST' })
    u.is_active = !u.is_active
  } catch {}
  actionLoading[u.id] = false
}

async function verifyMaster(u: any) {
  actionLoading[u.id] = true
  try {
    await apiFetch(`/admin/users/${u.id}/verify`, { method: 'POST' })
    u.is_verified = !u.is_verified
  } catch {}
  actionLoading[u.id] = false
}

</script>

<style scoped>
.page-header { margin-bottom: 20px; }
.page-header h1 { font-size: 26px; font-weight: 700; margin: 0; color: var(--hm-text); letter-spacing: -0.4px; }
.filter-row { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 18px; }
.filter-row select, .filter-row input { max-width: 240px; }
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
.actions-cell { white-space: nowrap; }
.icon-btn {
  display: inline-flex; align-items: center; justify-content: center;
  width: 32px; height: 32px;
  border: 1px solid var(--hm-border-2);
  border-radius: 8px; cursor: pointer;
  background: var(--hm-bg-2);
  transition: all 0.15s; padding: 0;
  color: var(--hm-text-3);
}
.icon-btn + .icon-btn { margin-left: 4px; }
.icon-btn:hover { border-color: var(--hm-accent); color: var(--hm-text); }
.icon-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.icon-btn .material-icons { font-size: 18px; }
.icon-btn-danger { color: #ef4444; }
.icon-btn-danger:hover:not(:disabled) { border-color: #ef4444; background: rgba(239, 68, 68, 0.08); }
.icon-btn-success { color: #22c55e; }
.icon-btn-success:hover:not(:disabled) { border-color: #22c55e; background: rgba(34, 197, 94, 0.08); }
.icon-btn-blue { color: #60a5fa; }
.icon-btn-blue:hover:not(:disabled) { border-color: #60a5fa; background: rgba(96, 165, 250, 0.08); }
.icon-btn-gray { color: var(--hm-text-3); }
.icon-btn-gray:hover:not(:disabled) { background: var(--hm-bg-3); }
</style>
