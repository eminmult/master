<template>
  <Teleport to="body">
    <div v-if="visible" class="call-overlay" :class="{ 'is-incoming': calls.phase === 'incoming' }">
      <div class="call-card">
        <div class="call-avatar" :style="avatarStyle">
          <span v-if="!calls.peerAvatar">{{ initial }}</span>
        </div>
        <div class="call-name">{{ displayName }}</div>
        <div class="call-state">{{ stateLabel }}</div>

        <div v-if="calls.error" class="call-error">{{ calls.error }}</div>

        <div class="call-actions">
          <template v-if="calls.phase === 'incoming'">
            <button class="ca-btn ca-reject" @click="calls.reject">
              <span class="icon">call_end</span>
            </button>
            <button class="ca-btn ca-accept" @click="calls.accept">
              <span class="icon">call</span>
            </button>
          </template>
          <template v-else-if="calls.phase === 'dialing' || calls.phase === 'in_call'">
            <button class="ca-btn ca-mute" :class="{ active: calls.micMuted }" @click="calls.toggleMic">
              <span class="icon">{{ calls.micMuted ? 'mic_off' : 'mic' }}</span>
            </button>
            <button class="ca-btn ca-reject" @click="calls.end">
              <span class="icon">call_end</span>
            </button>
          </template>
          <template v-else-if="calls.phase === 'ended'">
            <button class="ca-btn ca-dismiss" @click="calls.dismiss">
              <span class="icon">close</span>
            </button>
          </template>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
const calls = useCallsStore()
const { t } = useI18n()

const visible = computed(() => calls.phase !== 'idle')

const displayName = computed(() => calls.peerName || t('calls.unknown_caller'))
const initial = computed(() => (calls.peerName || '?').slice(0, 1).toUpperCase())
const avatarStyle = computed(() => calls.peerAvatar
  ? { backgroundImage: `url(${calls.peerAvatar})`, backgroundSize: 'cover', backgroundPosition: 'center', color: 'transparent' }
  : {})

const fmt = (s: number) => {
  const m = Math.floor(s / 60).toString().padStart(2, '0')
  const ss = (s % 60).toString().padStart(2, '0')
  return `${m}:${ss}`
}

const stateLabel = computed(() => {
  switch (calls.phase) {
    case 'dialing':  return t('calls.dialing')
    case 'incoming': return t('calls.incoming')
    case 'in_call':  return fmt(calls.durationSec)
    case 'ended':    return calls.durationSec > 0
        ? `${t('calls.ended')} · ${fmt(calls.durationSec)}`
        : t('calls.ended')
    default: return ''
  }
})
</script>

<style scoped>
.call-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.85);
  z-index: 9000;
  display: flex; align-items: center; justify-content: center;
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
}
.call-card {
  width: 320px; max-width: calc(100vw - 32px);
  background: #111; color: #fff;
  border: 1px solid #222;
  border-radius: 22px;
  padding: 32px 24px;
  display: flex; flex-direction: column; align-items: center;
  box-shadow: 0 30px 80px rgba(0,0,0,0.5);
}
.call-avatar {
  width: 96px; height: 96px; border-radius: 50%;
  background: #ff0; color: #000;
  display: flex; align-items: center; justify-content: center;
  font-size: 36px; font-weight: 800;
  margin-bottom: 18px;
  border: 3px solid rgba(255,255,255,0.08);
}
.call-name { font-size: 20px; font-weight: 700; }
.call-state { font-size: 14px; color: #aaa; margin-top: 6px; min-height: 18px; }
.call-error { color: #f87171; font-size: 13px; margin-top: 10px; text-align: center; }
.call-actions { display: flex; gap: 22px; margin-top: 28px; align-items: center; }
.ca-btn {
  width: 60px; height: 60px; border-radius: 50%;
  border: 0; cursor: pointer; color: #fff;
  display: flex; align-items: center; justify-content: center;
  transition: transform .12s, background .12s;
}
.ca-btn:active { transform: scale(0.94); }
.ca-btn .icon {
  font-family: 'Material Symbols Rounded', 'Material Icons';
  font-size: 28px; font-weight: 400;
}
.ca-accept { background: #22c55e; }
.ca-accept:hover { background: #16a34a; }
.ca-reject { background: #ef4444; }
.ca-reject:hover { background: #dc2626; }
.ca-mute { background: #2a2a2a; }
.ca-mute.active { background: #f59e0b; }
.ca-dismiss { background: #2a2a2a; }

@keyframes ring-pulse {
  0%   { box-shadow: 0 0 0 0 rgba(34,197,94,0.6); }
  70%  { box-shadow: 0 0 0 24px rgba(34,197,94,0); }
  100% { box-shadow: 0 0 0 0 rgba(34,197,94,0); }
}
.call-overlay.is-incoming .call-avatar {
  animation: ring-pulse 1.4s infinite;
}
</style>
