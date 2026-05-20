<template>
  <div v-if="!submitted" class="hm-review-form" :class="{ 'hm-review-card': !inline }">
    <h3><span class="icon">star</span> {{ $t('review.leave_review') }}</h3>
    <p class="hm-review-sub">{{ revieweeName }}</p>

    <!-- Stars -->
    <div class="hm-stars-input">
      <button
        v-for="s in 5"
        :key="s"
        type="button"
        class="hm-star-btn"
        :class="{ active: s <= rating }"
        @click="rating = s"
      >
        <span class="icon">{{ s <= rating ? 'star' : 'star_border' }}</span>
      </button>
    </div>

    <!-- Text -->
    <div class="hm-review-field">
      <textarea
        v-model="text"
        rows="4"
        class="hm-review-textarea"
        :placeholder="$t('review.placeholder')"
      ></textarea>
    </div>

    <!-- Photos -->
    <div class="hm-review-photos">
      <label class="hm-review-photos-label">
        <span class="icon icon-sm">photo_camera</span> {{ $t('review.add_photos') }}
        <span class="hm-review-photos-hint">({{ $t('review.max_photos') }})</span>
      </label>
      <div class="hm-review-photos-grid">
        <div v-for="(photo, i) in photosPreviews" :key="i" class="hm-review-photo-thumb">
          <img :src="photo" />
          <button type="button" class="hm-review-photo-remove" @click="removePhoto(i)">
            <span class="icon" style="font-size:14px">close</span>
          </button>
        </div>
        <label v-if="photosPreviews.length < 5" class="hm-review-photo-add">
          <span class="icon">add_photo_alternate</span>
          <input type="file" accept="image/*" multiple hidden @change="handleFiles" />
        </label>
      </div>
    </div>

    <button
      type="button"
      class="hm-review-submit"
      :disabled="rating === 0 || submitting"
      @click="submit"
    >
      <span v-if="submitting" class="hm-review-spinner"></span>
      {{ submitting ? $t('review.sending') : $t('review.submit') }}
    </button>
  </div>
  <div v-else class="hm-review-done">
    <span class="icon">check_circle</span>
    <p>{{ $t('review.thanks') }}</p>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  orderId: number
  revieweeName: string
  inline?: boolean
}>()

const emit = defineEmits(['reviewed'])
const { t: $t } = useI18n()
const { apiFetch } = useApi()
const toast = useToast()

const rating = ref(0)
const text = ref('')
const submitting = ref(false)
const submitted = ref(false)
const photosBase64 = ref<string[]>([])
const photosPreviews = ref<string[]>([])

function handleFiles(e: Event) {
  const files = (e.target as HTMLInputElement).files
  if (!files) return
  const remaining = 5 - photosPreviews.value.length
  const toProcess = Array.from(files).slice(0, remaining)

  for (const file of toProcess) {
    const reader = new FileReader()
    reader.onload = () => {
      const result = reader.result as string
      photosPreviews.value.push(result)
      photosBase64.value.push(result)
    }
    reader.readAsDataURL(file)
  }
  // Reset input
  (e.target as HTMLInputElement).value = ''
}

function removePhoto(i: number) {
  photosPreviews.value.splice(i, 1)
  photosBase64.value.splice(i, 1)
}

async function submit() {
  if (rating.value === 0) return
  submitting.value = true
  try {
    await apiFetch(`/orders/${props.orderId}/review`, {
      method: 'POST',
      body: {
        rating: rating.value,
        text: text.value || undefined,
        photos: photosBase64.value.length ? photosBase64.value : undefined,
      },
    })
    submitted.value = true
    emit('reviewed')
  } catch (e: any) {
    toast.error(e?.data?.message || $t('auth.error_occurred'))
  }
  submitting.value = false
}
</script>

<style scoped>
.hm-review-form { display: flex; flex-direction: column; gap: 16px; }
.hm-review-card {
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 20px;
  padding: 22px;
}
:global(html.theme-light) .hm-review-card { background: #fff; }
.hm-review-form h3 {
  display: flex; align-items: center; gap: 8px;
  font-size: 17px; font-weight: 700;
  color: var(--hm-text);
  font-family: "Public Sans", sans-serif;
  margin: 0;
}
.hm-review-form h3 .icon { color: var(--hm-accent); font-size: 22px; }
:global(html.theme-light) .hm-review-form h3 .icon { color: #b07f00; }
.hm-review-sub {
  font-size: 13px; color: var(--hm-text-3);
  margin: -8px 0 4px;
}

/* Stars */
.hm-stars-input { display: flex; gap: 4px; }
.hm-star-btn {
  padding: 4px;
  color: var(--hm-text-3);
  background: transparent; border: 0; cursor: pointer;
  transition: all 0.15s;
}
.hm-star-btn .icon { font-size: 34px; }
.hm-star-btn.active { color: var(--hm-accent); }
:global(html.theme-light) .hm-star-btn.active { color: #facc15; }
.hm-star-btn:hover { transform: scale(1.12); }

/* Textarea */
.hm-review-textarea {
  width: 100%;
  padding: 14px 16px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border-2);
  border-radius: 14px;
  color: var(--hm-text);
  font-family: inherit; font-size: 14px;
  line-height: 1.5;
  resize: vertical;
  transition: border-color 0.15s;
}
.hm-review-textarea:focus { border-color: var(--hm-accent); outline: 0; }
.hm-review-textarea::placeholder { color: var(--hm-text-3); }

/* Photos */
.hm-review-photos { display: flex; flex-direction: column; gap: 8px; }
.hm-review-photos-label {
  display: flex; align-items: center; gap: 6px;
  font-size: 13px; font-weight: 600;
  color: var(--hm-text-2);
}
.hm-review-photos-label .icon { color: var(--hm-accent); }
:global(html.theme-light) .hm-review-photos-label .icon { color: #b07f00; }
.hm-review-photos-hint { color: var(--hm-text-3); font-weight: 400; font-size: 11px; }
.hm-review-photos-grid { display: flex; gap: 8px; flex-wrap: wrap; }
.hm-review-photo-thumb {
  position: relative;
  width: 76px; height: 76px;
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid var(--hm-border-2);
}
.hm-review-photo-thumb img { width: 100%; height: 100%; object-fit: cover; }
.hm-review-photo-remove {
  position: absolute; top: 4px; right: 4px;
  width: 22px; height: 22px;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.7); color: #fff;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; border: none;
  transition: background 0.15s;
}
.hm-review-photo-remove:hover { background: #ef4444; }
.hm-review-photo-add {
  width: 76px; height: 76px;
  background: var(--hm-bg-2);
  border: 1.5px dashed var(--hm-border);
  border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer;
  color: var(--hm-text-3);
  transition: all 0.15s;
}
.hm-review-photo-add:hover { border-color: var(--hm-accent); color: var(--hm-accent); }
:global(html.theme-light) .hm-review-photo-add:hover { border-color: #b07f00; color: #b07f00; }
.hm-review-photo-add .icon { font-size: 28px; }

/* Submit */
.hm-review-submit {
  background: var(--hm-accent);
  color: #000;
  font-weight: 700;
  border: 0;
  padding: 14px 22px;
  border-radius: 14px;
  cursor: pointer;
  transition: transform 0.15s;
  font-family: inherit;
  font-size: 15px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: 100%;
}
:global(html.theme-light) .hm-review-submit { background: #facc15; color: #111; }
.hm-review-submit:hover:not(:disabled) { transform: translateY(-1px); }
.hm-review-submit:disabled { opacity: 0.5; cursor: wait; }
.hm-review-spinner {
  width: 16px; height: 16px;
  border: 2px solid rgba(0, 0, 0, 0.25);
  border-top-color: #000;
  border-radius: 50%;
  animation: hm-rv-spin 0.8s linear infinite;
}
@keyframes hm-rv-spin { to { transform: rotate(360deg); } }

/* Done state */
.hm-review-done {
  display: flex; flex-direction: column; align-items: center; gap: 10px;
  text-align: center; padding: 32px 22px;
  background: var(--hm-bg-2);
  border: 1px solid rgba(34, 197, 94, 0.3);
  border-radius: 16px;
}
.hm-review-done .icon { font-size: 36px; color: #22c55e; }
.hm-review-done p { font-weight: 600; color: var(--hm-text); margin: 0; font-size: 15px; }
</style>
