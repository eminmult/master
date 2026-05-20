<template>
  <div class="hm-page">
    <div class="hm-page-inner">
      <div class="hm-dash">
        <HmDashSidebar role="admin" />
        <div class="hm-dash-main">
      <div class="page-header">
        <div>
          <h1>{{ $t('admin.categories') }}</h1>
          <p class="text-muted">{{ $t('admin.categories_manage') }}</p>
        </div>
        <button class="btn btn-primary" @click="openAdd">
          <span class="icon">add</span> {{ $t('admin.cat_add') }}
        </button>
      </div>

      <div v-if="!loading" class="categories-list">
        <div v-for="cat in categories" :key="cat.id" class="cat-card card">
          <div class="cat-row">
            <div class="cat-header">
              <span class="cat-icon"><CatIcon :icon="cat.icon_url" /></span>
              <div>
                <h3>{{ cat.name }}</h3>
                <p class="text-muted">{{ cat.description }}</p>
                <span class="cat-slug">{{ cat.slug }}</span>
              </div>
            </div>
            <div class="cat-actions">
              <button class="btn btn-sm btn-outline" @click="openEdit(cat)">
                <span class="icon">edit</span> {{ $t('admin.cat_edit') }}
              </button>
              <button class="btn btn-sm btn-outline btn-success" @click="openAddSub(cat)">
                <span class="icon">add</span> {{ $t('admin.cat_add_sub') }}
              </button>
              <button class="btn btn-sm btn-outline btn-danger" @click="confirmDelete(cat)">
                <span class="icon">delete</span> {{ $t('admin.cat_delete') }}
              </button>
            </div>
          </div>
          <div v-if="cat.subcategories?.length" class="subcats">
            <span v-for="sub in cat.subcategories" :key="sub.id" class="badge badge-primary">{{ sub.name }}</span>
          </div>
        </div>
      </div>

      <!-- Modal: Add/Edit Category -->
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal-box card">
          <h2>{{ editTarget ? $t('admin.cat_edit') : (isSubcat ? $t('admin.cat_add_sub') : $t('admin.cat_add')) }}</h2>
          <form @submit.prevent="saveCategory">
            <div class="form-group">
              <label>{{ $t('admin.cat_name') }}</label>
              <input v-model="form.name" type="text" class="form-control" required />
            </div>
            <div class="form-group">
              <label>{{ $t('admin.cat_slug') }}</label>
              <input v-model="form.slug" type="text" class="form-control" required />
            </div>
            <div class="form-group">
              <label>{{ $t('admin.cat_icon') }}</label>
              <input v-model="form.icon_url" type="text" class="form-control" placeholder="ph:wrench" />
            </div>
            <div class="form-group">
              <label>{{ $t('admin.cat_description') }}</label>
              <textarea v-model="form.description" class="form-control" rows="2"></textarea>
            </div>
            <div v-if="formError" class="alert alert-danger mt-2">{{ formError }}</div>
            <div class="modal-footer">
              <button type="button" class="btn btn-outline" @click="closeModal">{{ $t('admin.cat_cancel') }}</button>
              <button type="submit" class="btn btn-primary" :disabled="saving">
                {{ saving ? $t('common.loading') : $t('admin.cat_save') }}
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- Confirm Delete -->
      <div v-if="deleteTarget" class="modal-overlay" @click.self="deleteTarget = null">
        <div class="modal-box card">
          <h2>{{ $t('admin.cat_delete_confirm') }}</h2>
          <p class="text-muted">{{ deleteTarget.name }}</p>
          <div class="modal-footer">
            <button class="btn btn-outline" @click="deleteTarget = null">{{ $t('admin.cat_cancel') }}</button>
            <button class="btn btn-danger" :disabled="saving" @click="doDelete">
              {{ saving ? $t('common.loading') : $t('admin.cat_delete') }}
            </button>
          </div>
        </div>
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

const categories = ref<any[]>([])
const loading = ref(true)
const showModal = ref(false)
const editTarget = ref<any>(null)
const isSubcat = ref(false)
const parentCat = ref<any>(null)
const deleteTarget = ref<any>(null)
const saving = ref(false)
const formError = ref('')

const form = ref({ name: '', slug: '', icon_url: '', description: '' })

async function loadCategories() {
  try {
    const res = await apiFetch<{ categories: any[] }>('/admin/categories')
    categories.value = res.categories
  } catch {
    try {
      const res = await apiFetch<{ categories: any[] }>('/categories')
      categories.value = res.categories
    } catch {}
  }
  loading.value = false
}

function openAdd() {
  editTarget.value = null
  isSubcat.value = false
  parentCat.value = null
  form.value = { name: '', slug: '', icon_url: '', description: '' }
  formError.value = ''
  showModal.value = true
}

function openEdit(cat: any) {
  editTarget.value = cat
  isSubcat.value = false
  parentCat.value = null
  form.value = { name: cat.name, slug: cat.slug, icon_url: cat.icon_url || '', description: cat.description || '' }
  formError.value = ''
  showModal.value = true
}

function openAddSub(cat: any) {
  editTarget.value = null
  isSubcat.value = true
  parentCat.value = cat
  form.value = { name: '', slug: '', icon_url: '', description: '' }
  formError.value = ''
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  editTarget.value = null
  isSubcat.value = false
  parentCat.value = null
}

async function saveCategory() {
  saving.value = true
  formError.value = ''
  try {
    const payload: any = { ...form.value }
    if (isSubcat.value && parentCat.value) {
      payload.parent_id = parentCat.value.id
    }
    if (editTarget.value) {
      await apiFetch(`/admin/categories/${editTarget.value.id}`, { method: 'PUT', body: payload })
    } else {
      await apiFetch('/admin/categories', { method: 'POST', body: payload })
    }
    closeModal()
    loading.value = true
    await loadCategories()
  } catch (e: any) {
    formError.value = e?.data?.message || $t('auth.error_occurred')
  }
  saving.value = false
}

function confirmDelete(cat: any) {
  deleteTarget.value = cat
}

async function doDelete() {
  if (!deleteTarget.value) return
  saving.value = true
  try {
    await apiFetch(`/admin/categories/${deleteTarget.value.id}`, { method: 'DELETE' })
    deleteTarget.value = null
    loading.value = true
    await loadCategories()
  } catch (e: any) {
    formError.value = e?.data?.message || $t('auth.error_occurred')
    deleteTarget.value = null
  }
  saving.value = false
}

onMounted(loadCategories)
</script>

<style scoped>
.page-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 14px; margin-bottom: 20px; flex-wrap: wrap; }
.page-header h1 { font-size: 26px; font-weight: 700; margin: 0 0 4px; color: var(--hm-text); letter-spacing: -0.4px; }
.categories-list { display: flex; flex-direction: column; gap: 14px; }
.cat-card {
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 16px;
  padding: 18px;
}
.cat-row { display: flex; align-items: center; justify-content: space-between; gap: 14px; flex-wrap: wrap; }
.cat-header { display: flex; align-items: center; gap: 16px; }
.cat-icon {
  font-size: 28px;
  line-height: 1;
  width: 52px; height: 52px;
  border-radius: 14px;
  background: rgba(255, 255, 0, 0.10);
  display: grid;
  place-items: center;
  flex-shrink: 0;
}
:global(html.theme-light) .cat-icon { background: rgba(177, 127, 0, 0.12); }
.cat-header h3 { font-size: 16px; font-weight: 700; margin: 0 0 2px; color: var(--hm-text); }
.cat-header p { font-size: 13px; margin: 0; color: var(--hm-text-3); }
.cat-slug { font-size: 11px; color: var(--hm-text-3); font-family: monospace; }
.cat-actions { display: flex; gap: 8px; flex-wrap: wrap; }
.cat-actions .btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border-2);
  border-radius: 10px;
  color: var(--hm-text);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}
.cat-actions .btn:hover { border-color: var(--hm-accent); }
.cat-actions .btn-success { color: #22c55e; border-color: rgba(34, 197, 94, 0.3); }
.cat-actions .btn-success:hover { background: rgba(34, 197, 94, 0.08); }
.cat-actions .btn-danger { color: #ef4444; border-color: rgba(239, 68, 68, 0.3); }
.cat-actions .btn-danger:hover { background: rgba(239, 68, 68, 0.08); }
.subcats { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 14px; padding-top: 14px; border-top: 1px solid var(--hm-border-2); }
.btn .icon { font-size: 14px; vertical-align: middle; }

.modal-overlay {
  position: fixed; inset: 0;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
  z-index: 1000;
  display: flex; align-items: center; justify-content: center;
  padding: 16px;
}
.modal-box {
  width: 100%;
  max-width: 480px;
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 20px;
  padding: 24px;
  box-shadow: 0 25px 50px rgba(0, 0, 0, 0.4);
}
:global(html.theme-light) .modal-box { background: #fff; }
.modal-box h2 { font-size: 18px; font-weight: 700; margin: 0 0 16px; color: var(--hm-text); }
.form-group { margin-bottom: 14px; }
.form-group label { display: block; font-size: 12px; font-weight: 600; margin-bottom: 6px; color: var(--hm-text-3); text-transform: uppercase; letter-spacing: 0.5px; }
.form-control {
  width: 100%;
  padding: 11px 14px;
  border: 1px solid var(--hm-border-2);
  border-radius: 12px;
  font-size: 14px;
  background: var(--hm-bg-2);
  color: var(--hm-text);
  font-family: inherit;
}
.form-control:focus { outline: 0; border-color: var(--hm-accent); }
textarea.form-control { resize: vertical; }
.modal-footer { display: flex; justify-content: flex-end; gap: 10px; margin-top: 18px; }
.modal-footer .btn {
  padding: 10px 18px;
  border-radius: 12px;
  font-weight: 600;
  font-size: 13px;
  cursor: pointer;
  border: 1px solid var(--hm-border-2);
  background: var(--hm-bg-2);
  color: var(--hm-text);
}
.modal-footer .btn-primary {
  background: var(--hm-accent);
  border-color: transparent;
  color: #000;
}
:global(html.theme-light) .modal-footer .btn-primary { background: #facc15; color: #111; }
.modal-footer .btn-outline { background: transparent; }
.modal-footer .btn-danger { background: #ef4444; color: #fff; border-color: transparent; }
.alert { padding: 10px 14px; border-radius: 10px; font-size: 13px; margin-bottom: 10px; }
.alert-danger { background: rgba(239, 68, 68, 0.10); border: 1px solid rgba(239, 68, 68, 0.3); color: var(--hm-text); }
</style>
