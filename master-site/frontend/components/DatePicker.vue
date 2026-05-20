<template>
  <div class="datepicker">
    <div class="dp-header">
      <button type="button" @click="prevMonth"><span class="icon">chevron_left</span></button>
      <strong>{{ monthNames[viewMonth] }} {{ viewYear }}</strong>
      <button type="button" @click="nextMonth"><span class="icon">chevron_right</span></button>
    </div>
    <div class="dp-weekdays">
      <span v-for="d in dayNames" :key="d">{{ d }}</span>
    </div>
    <div class="dp-days">
      <button
        v-for="(day, i) in calendarDays"
        :key="i"
        type="button"
        class="dp-day"
        :class="{
          empty: !day,
          today: day && isToday(day),
          selected: day && isSelected(day),
          disabled: day && isPast(day),
          other: day && day.getMonth() !== viewMonth,
        }"
        :disabled="!day || isPast(day)"
        @click="day && selectDay(day)"
      >
        {{ day ? day.getDate() : '' }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue: string // YYYY-MM-DD
}>()
const emit = defineEmits(['update:modelValue'])
const { t: $t } = useI18n()

const now = new Date()
const viewMonth = ref(now.getMonth())
const viewYear = ref(now.getFullYear())

const monthNames = computed(() => [
  $t('months.0'), $t('months.1'), $t('months.2'), $t('months.3'),
  $t('months.4'), $t('months.5'), $t('months.6'), $t('months.7'),
  $t('months.8'), $t('months.9'), $t('months.10'), $t('months.11'),
])

const dayNames = computed(() => [
  $t('days_short.1'), $t('days_short.2'), $t('days_short.3'), $t('days_short.4'),
  $t('days_short.5'), $t('days_short.6'), $t('days_short.0'),
])

const calendarDays = computed(() => {
  const first = new Date(viewYear.value, viewMonth.value, 1)
  const lastDay = new Date(viewYear.value, viewMonth.value + 1, 0).getDate()
  let startDay = first.getDay() - 1 // Monday = 0
  if (startDay < 0) startDay = 6

  const days: (Date | null)[] = []
  for (let i = 0; i < startDay; i++) days.push(null)
  for (let d = 1; d <= lastDay; d++) days.push(new Date(viewYear.value, viewMonth.value, d))
  return days
})

function isToday(d: Date) {
  return d.toDateString() === now.toDateString()
}

function isSelected(d: Date) {
  if (!props.modelValue) return false
  return d.toISOString().split('T')[0] === props.modelValue
}

function isPast(d: Date) {
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  return d < today
}

function selectDay(d: Date) {
  emit('update:modelValue', d.toISOString().split('T')[0])
}

function prevMonth() {
  if (viewMonth.value === 0) { viewMonth.value = 11; viewYear.value-- }
  else viewMonth.value--
}

function nextMonth() {
  if (viewMonth.value === 11) { viewMonth.value = 0; viewYear.value++ }
  else viewMonth.value++
}
</script>

<style scoped>
.datepicker { background: #fff; border: 1px solid var(--gray-200); border-radius: var(--radius-sm); padding: 0.75rem; }
.dp-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.75rem; }
.dp-header strong { font-size: 0.938rem; }
.dp-header button { padding: 0.25rem; color: var(--gray-500); }
.dp-header button:hover { color: var(--primary); }
.dp-weekdays { display: grid; grid-template-columns: repeat(7, 1fr); text-align: center; margin-bottom: 0.375rem; }
.dp-weekdays span { font-size: 0.688rem; font-weight: 600; color: var(--gray-400); text-transform: uppercase; }
.dp-days { display: grid; grid-template-columns: repeat(7, 1fr); gap: 2px; }
.dp-day {
  display: flex; align-items: center; justify-content: center;
  width: 36px; height: 36px; margin: 0 auto;
  border-radius: 50%; font-size: 0.875rem; font-weight: 500;
  cursor: pointer; transition: all 0.15s; border: none; background: none;
}
.dp-day:hover:not(.disabled):not(.empty) { background: var(--gray-100); }
.dp-day.today { font-weight: 700; color: var(--primary); }
.dp-day.selected { background: var(--primary); color: #fff; }
.dp-day.disabled { color: var(--gray-300); cursor: not-allowed; }
.dp-day.empty { cursor: default; }
.dp-day.other { color: var(--gray-300); }
</style>
