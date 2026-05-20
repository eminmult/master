<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="admin" />
        <div class="hm-dash-main">
          <div class="hm-dash-head">
            <div>
              <h1>{{ $t('admin.cat_suggestions') }}</h1>
              <p class="hm-page-sub">{{ $t('admin.cat_suggestions_desc') }}</p>
            </div>
            <div class="hm-sugg-counters">
              <span class="hm-sugg-counter" :class="{ active: filter === 'pending' }" @click="setFilter('pending')">
                <strong>{{ pendingCount }}</strong> {{ $t('cat_sugg.status_pending') }}
              </span>
              <span class="hm-sugg-counter" :class="{ active: filter === 'approved' }" @click="setFilter('approved')">
                <strong>{{ approvedCount }}</strong> {{ $t('cat_sugg.status_approved') }}
              </span>
              <span class="hm-sugg-counter" :class="{ active: filter === 'rejected' }" @click="setFilter('rejected')">
                <strong>{{ rejectedCount }}</strong> {{ $t('cat_sugg.status_rejected') }}
              </span>
              <span class="hm-sugg-counter" :class="{ active: !filter }" @click="setFilter('')">
                {{ $t('cat_sugg.all') }}
              </span>
            </div>
          </div>

          <div v-if="pending && !suggestions.length" class="hm-loading">{{ $t('common.loading') }}</div>

          <div v-else-if="!filteredList.length" class="hm-empty-state">
            <span class="icon">inbox</span>
            <h3>{{ $t('cat_sugg.empty_title') }}</h3>
            <p>{{ $t('cat_sugg.empty_desc') }}</p>
          </div>

          <div v-else class="hm-sugg-list">
            <article v-for="s in filteredList" :key="s.id" class="hm-sugg-card" :class="'hm-sugg-' + s.status">
              <header class="hm-sugg-head">
                <div class="hm-sugg-icon">
                  <CatIcon :icon="s.suggested_icon || 'ph:lightbulb'" />
                </div>
                <div class="hm-sugg-meta">
                  <h3>{{ s.name }}</h3>
                  <div class="hm-sugg-by">
                    <span class="icon icon-sm">person</span>
                    {{ s.user?.first_name }} {{ s.user?.last_name || '' }}
                    <span class="hm-sugg-role">{{ s.user?.role === 'master' ? $t('admin.role_master') : $t('admin.role_client') }}</span>
                    · {{ formatDateTime(s.created_at) }}
                  </div>
                </div>
                <span class="hm-sugg-status" :class="'hm-sugg-status-' + s.status">
                  {{ $t('cat_sugg.status_' + s.status) }}
                </span>
              </header>

              <p v-if="s.description" class="hm-sugg-desc">{{ s.description }}</p>

              <div v-if="s.admin_note" class="hm-sugg-note">
                <span class="icon icon-sm">sticky_note_2</span>
                <span>{{ s.admin_note }}</span>
              </div>

              <footer v-if="s.status === 'pending'" class="hm-sugg-actions">
                <button type="button" class="hm-btn hm-btn-primary hm-btn-sm" @click="openApprove(s)">
                  <span class="icon icon-sm">check</span> {{ $t('cat_sugg.approve') }}
                </button>
                <button type="button" class="hm-btn hm-btn-ghost hm-btn-sm" @click="openReject(s)">
                  <span class="icon icon-sm">close</span> {{ $t('cat_sugg.reject') }}
                </button>
              </footer>
              <footer v-else class="hm-sugg-reviewed">
                <span class="icon icon-sm">{{ s.status === 'approved' ? 'verified' : 'block' }}</span>
                {{ $t('cat_sugg.reviewed_by', { name: s.reviewer?.first_name || '—', when: formatDateTime(s.reviewed_at) }) }}
              </footer>
            </article>
          </div>
        </div>
      </div>
    </div>

    <!-- Approve modal -->
    <Transition name="hm-pop">
      <div v-if="approving" class="hm-modal-overlay" @click.self="approving = null">
        <div class="hm-modal hm-popover">
          <div class="hm-popover-glow"></div>
          <h2>{{ $t('cat_sugg.approve_title') }}</h2>
          <p class="hm-modal-sub">{{ $t('cat_sugg.approve_desc') }}</p>
          <div class="hm-form-group">
            <label class="hm-auth-label">{{ $t('cat_sugg.final_name') }}</label>
            <input v-model="approveForm.name" type="text" class="hm-form-input" />
          </div>
          <div class="hm-form-group">
            <label class="hm-auth-label">{{ $t('cat_sugg.icon_name') }}</label>
            <input v-model="approveForm.icon_url" type="text" class="hm-form-input" placeholder="e.g. ph:wrench" />
            <span class="hm-form-hint">Phosphor icon name via Iconify — <a href="https://icon-sets.iconify.design/ph/" target="_blank">browse ph: icons</a></span>
          </div>
          <div class="hm-form-group">
            <label class="hm-auth-label">{{ $t('cat_sugg.admin_note_optional') }}</label>
            <textarea v-model="approveForm.admin_note" class="hm-form-textarea" rows="2"></textarea>
          </div>
          <div class="hm-modal-actions">
            <button type="button" class="hm-btn hm-btn-ghost hm-btn-sm" @click="approving = null">{{ $t('common.cancel') }}</button>
            <button type="button" class="hm-btn hm-btn-primary hm-btn-sm" @click="submitApprove" :disabled="submitting">
              <span class="icon icon-sm">check</span> {{ submitting ? $t('common.loading') : $t('cat_sugg.approve') }}
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Reject modal -->
    <Transition name="hm-pop">
      <div v-if="rejecting" class="hm-modal-overlay" @click.self="rejecting = null">
        <div class="hm-modal hm-popover">
          <div class="hm-popover-glow"></div>
          <h2>{{ $t('cat_sugg.reject_title') }}</h2>
          <p class="hm-modal-sub">{{ $t('cat_sugg.reject_desc') }}</p>
          <div class="hm-form-group">
            <label class="hm-auth-label">{{ $t('cat_sugg.reason_optional') }}</label>
            <textarea v-model="rejectNote" class="hm-form-textarea" rows="3" :placeholder="$t('cat_sugg.reason_placeholder')"></textarea>
          </div>
          <div class="hm-modal-actions">
            <button type="button" class="hm-btn hm-btn-ghost hm-btn-sm" @click="rejecting = null">{{ $t('common.cancel') }}</button>
            <button type="button" class="hm-btn hm-btn-primary hm-btn-sm" @click="submitReject" :disabled="submitting">
              <span class="icon icon-sm">close</span> {{ submitting ? $t('common.loading') : $t('cat_sugg.reject') }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'auth' })

const { t: $t } = useI18n()
const { apiFetch } = useApi()
const toast = useToast()
const { formatDateTime } = useFormatDate()

const filter = ref<'pending' | 'approved' | 'rejected' | ''>('pending')

const { data: response, pending, refresh } = await useAsyncData(
  () => `admin-cat-suggestions:${filter.value}`,
  async () => {
    const url = filter.value ? `/admin/category-suggestions?status=${filter.value}` : '/admin/category-suggestions'
    try { return await apiFetch<any>(url) }
    catch { return { suggestions: [], pending_count: 0 } }
  },
  { default: () => ({ suggestions: [], pending_count: 0 }), watch: [filter] },
)

const suggestions = computed(() => response.value?.suggestions || [])
const pendingCount = computed(() => response.value?.pending_count ?? 0)
const approvedCount = computed(() => suggestions.value.filter((s: any) => s.status === 'approved').length)
const rejectedCount = computed(() => suggestions.value.filter((s: any) => s.status === 'rejected').length)
const filteredList = computed(() => suggestions.value)

function setFilter(f: string) { filter.value = f as any }

// Approve
const approving = ref<any | null>(null)
const approveForm = reactive({ name: '', icon_url: '', admin_note: '' })
const submitting = ref(false)

function openApprove(s: any) {
  approving.value = s
  approveForm.name = s.name
  approveForm.icon_url = s.suggested_icon || 'ph:wrench'
  approveForm.admin_note = ''
}
async function submitApprove() {
  if (!approving.value) return
  submitting.value = true
  try {
    await apiFetch(`/admin/category-suggestions/${approving.value.id}/approve`, {
      method: 'POST',
      body: { name: approveForm.name, icon_url: approveForm.icon_url, admin_note: approveForm.admin_note || undefined },
    })
    toast.success($t('cat_sugg.approved_toast'))
    approving.value = null
    await refresh()
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  finally { submitting.value = false }
}

// Reject
const rejecting = ref<any | null>(null)
const rejectNote = ref('')

function openReject(s: any) { rejecting.value = s; rejectNote.value = '' }
async function submitReject() {
  if (!rejecting.value) return
  submitting.value = true
  try {
    await apiFetch(`/admin/category-suggestions/${rejecting.value.id}/reject`, {
      method: 'POST',
      body: { admin_note: rejectNote.value || undefined },
    })
    toast.success($t('cat_sugg.rejected_toast'))
    rejecting.value = null
    await refresh()
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  finally { submitting.value = false }
}
</script>

<style scoped>
h1 { font-size: 26px; font-weight: 700; margin: 0 0 4px; color: var(--hm-text); letter-spacing: -0.4px; }

.hm-dash-head { display: flex; justify-content: space-between; align-items: flex-end; gap: 14px; margin-bottom: 18px; flex-wrap: wrap; }
.hm-sugg-counters { display: flex; gap: 8px; flex-wrap: wrap; }
.hm-sugg-counter {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 8px 14px; border-radius: 999px;
  background: var(--hm-bg-2); border: 1px solid var(--hm-border);
  font-size: 12px; font-weight: 600; color: var(--hm-text-2);
  cursor: pointer; transition: all .15s;
}
.hm-sugg-counter:hover { border-color: var(--hm-text-3); }
.hm-sugg-counter.active { background: rgba(var(--hm-accent-rgb, 250, 204, 21), 0.12); border-color: var(--hm-accent); color: var(--hm-accent); }
.hm-sugg-counter strong { font-size: 14px; }

.hm-sugg-list { display: flex; flex-direction: column; gap: 12px; }

.hm-sugg-card {
  background: var(--hm-bg-card);
  border: 1px solid var(--hm-border);
  border-left: 3px solid var(--hm-text-3);
  border-radius: 14px;
  padding: 18px 20px;
}
.hm-sugg-pending { border-left-color: #facc15; }
.hm-sugg-approved { border-left-color: #22c55e; }
.hm-sugg-rejected { border-left-color: #ef4444; opacity: 0.75; }

.hm-sugg-head {
  display: flex; gap: 14px; align-items: flex-start;
}
.hm-sugg-icon {
  width: 48px; height: 48px; border-radius: 12px;
  background: rgba(var(--hm-accent-rgb, 250, 204, 21), 0.14);
  color: var(--hm-accent);
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.hm-sugg-icon .icon { font-size: 26px; }
.hm-sugg-meta { flex: 1; min-width: 0; }
.hm-sugg-meta h3 { font-size: 16px; font-weight: 700; color: var(--hm-text); margin: 0 0 4px; letter-spacing: -0.2px; }
.hm-sugg-by {
  display: inline-flex; align-items: center; gap: 4px; flex-wrap: wrap;
  font-size: 12px; color: var(--hm-text-3);
}
.hm-sugg-by .icon { font-size: 14px; }
.hm-sugg-role {
  background: var(--hm-bg-2);
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 10.5px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin-left: 4px;
}

.hm-sugg-status {
  font-size: 10.5px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.06em;
  padding: 4px 10px; border-radius: 999px;
  flex-shrink: 0;
}
.hm-sugg-status-pending { background: rgba(250,204,21,0.15); color: #facc15; }
.hm-sugg-status-approved { background: rgba(34,197,94,0.15); color: #22c55e; }
.hm-sugg-status-rejected { background: rgba(239,68,68,0.15); color: #ef4444; }

.hm-sugg-desc { font-size: 13.5px; color: var(--hm-text-2); margin: 12px 0 0; line-height: 1.5; }
.hm-sugg-note {
  display: flex; gap: 8px; align-items: flex-start;
  background: var(--hm-bg-2); padding: 10px 12px;
  border-radius: 10px; font-size: 12.5px; color: var(--hm-text-2);
  margin-top: 10px;
}
.hm-sugg-note .icon { color: var(--hm-text-3); flex-shrink: 0; }

.hm-sugg-actions { display: flex; gap: 8px; margin-top: 14px; padding-top: 14px; border-top: 1px dashed var(--hm-border); }
.hm-sugg-reviewed {
  margin-top: 14px; padding-top: 12px;
  border-top: 1px dashed var(--hm-border);
  display: inline-flex; align-items: center; gap: 6px;
  font-size: 12px; color: var(--hm-text-3);
}
.hm-sugg-reviewed .icon { font-size: 16px; }

/* Modal */
.hm-modal-overlay {
  position: fixed; inset: 0; background: rgba(0, 0, 0, 0.65);
  display: flex; align-items: center; justify-content: center;
  padding: 20px; z-index: 1000;
  -webkit-backdrop-filter: blur(4px); backdrop-filter: blur(4px);
}
.hm-modal {
  position: relative;
  width: min(480px, 100%);
  padding: 24px;
  margin: 0;
}
.hm-modal h2 { font-size: 18px; font-weight: 700; color: var(--hm-text); margin: 0 0 4px; }
.hm-modal-sub { font-size: 13px; color: var(--hm-text-3); margin: 0 0 18px; }
.hm-modal-actions { display: flex; gap: 8px; justify-content: flex-end; margin-top: 12px; }
</style>
