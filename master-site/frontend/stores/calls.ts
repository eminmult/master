import { defineStore } from 'pinia'

/*
 * In-app voice calls store.
 *
 * Wires WebRTC (browser native) to a Reverb (Pusher-protocol) signaling channel.
 * Phones are never shown to either party — this is the only direct voice channel
 * between the client and the master, and is only available while the order is in
 * an active work state (confirmed/accepted/on_the_way/arrived/in_progress/awaiting_completion).
 *
 * Lifecycle (caller view):
 *   startOutgoing() → POST /calls (server creates Call row, broadcasts call.ringing
 *   to callee) → wait for `call.accepted` → SDP answer → media flows → end()
 *
 * Lifecycle (callee view, listening on private user.{id}):
 *   `call.ringing` arrives → modal shows accept/reject → accept() POSTs /calls/{id}/accept
 *   with SDP answer → media flows → end()
 *
 * Signaling messages relayed via POST /calls/{id}/signal (type: offer|answer|ice).
 */

interface CallPayload {
  id: number
  order_id: number
  caller_id: number
  callee_id: number
  status: 'ringing' | 'accepted' | 'rejected' | 'missed' | 'ended' | 'cancelled'
  started_at: string | null
  accepted_at: string | null
  ended_at: string | null
  duration_sec: number | null
  caller?: { id: number; first_name: string; last_name: string | null; avatar_url: string | null } | null
  callee?: { id: number; first_name: string; last_name: string | null; avatar_url: string | null } | null
}

type Phase = 'idle' | 'dialing' | 'incoming' | 'in_call' | 'ended'

let echoInstance: any = null
let peerConn: RTCPeerConnection | null = null
let localStream: MediaStream | null = null
let remoteAudioEl: HTMLAudioElement | null = null
let pendingIce: RTCIceCandidateInit[] = []
let pendingRemoteSdp: RTCSessionDescriptionInit | null = null
let durationTimer: number | null = null

const RTC_CONFIG: RTCConfiguration = {
  iceServers: [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
  ],
}

export const useCallsStore = defineStore('calls', {
  state: () => ({
    phase: 'idle' as Phase,
    call: null as CallPayload | null,
    micMuted: false,
    durationSec: 0,
    error: '' as string,
    /** display name + avatar of the *other* party — populated on outgoing & incoming */
    peerName: '' as string,
    peerAvatar: '' as string | null,
    /**
     * Last realtime chat event delivered over the user-channel. UI components
     * watch this and re-fetch their thread when scope+scope_id matches.
     * Shape: { scope: 'order'|'application', scope_id: number, message: {...}, _ts: number }
     */
    chatBus: null as any,
  }),

  actions: {
    /**
     * Subscribe to the private user channel. Called once after login (from default.vue).
     * Safe to call multiple times — re-uses the existing Echo instance.
     */
    async connect() {
      if (!import.meta.client) return
      const auth = useAuthStore()
      if (!auth.user?.id) return
      if (echoInstance) return

      const { default: Echo } = await import('laravel-echo')
      const { default: Pusher } = await import('pusher-js')
      ;(window as any).Pusher = Pusher

      const config = useRuntimeConfig()
      const { authToken } = useApi()

      echoInstance = new Echo({
        broadcaster: 'reverb',
        key: (config.public as any).reverbKey || process.env.NUXT_PUBLIC_REVERB_KEY,
        wsHost: (config.public as any).reverbHost || process.env.NUXT_PUBLIC_REVERB_HOST,
        wsPort: Number((config.public as any).reverbPort || process.env.NUXT_PUBLIC_REVERB_PORT || 443),
        wssPort: Number((config.public as any).reverbPort || process.env.NUXT_PUBLIC_REVERB_PORT || 443),
        forceTLS: ((config.public as any).reverbScheme || process.env.NUXT_PUBLIC_REVERB_SCHEME) === 'https',
        enabledTransports: ['ws', 'wss'],
        authEndpoint: (config.public as any).apiBase.replace(/\/api\/v\d+\/?$/, '/api').replace(/\/$/, '') + '/broadcasting/auth',
        auth: {
          headers: { Authorization: `Bearer ${authToken.value || ''}` },
        },
      })

      const channel = echoInstance.private(`user.${auth.user.id}`)
      channel.listen('.call.ringing',   (e: any) => this._onIncoming(e))
      channel.listen('.call.accepted',  (e: any) => this._onAccepted(e))
      channel.listen('.call.rejected',  (e: any) => this._onTerminated(e, 'rejected'))
      channel.listen('.call.cancelled', (e: any) => this._onTerminated(e, 'cancelled'))
      channel.listen('.call.ended',     (e: any) => this._onTerminated(e, 'ended'))
      channel.listen('.call.offer',     (e: any) => this._onRemoteSdp(e, 'offer'))
      channel.listen('.call.answer',    (e: any) => this._onRemoteSdp(e, 'answer'))
      channel.listen('.call.ice',       (e: any) => this._onRemoteIce(e))
      // Chat messages — piggy-back on the same channel; UI components watch
      // `chatBus` to trigger an instant refresh of the open conversation.
      channel.listen('.chat.message',   (e: any) => { this.chatBus = { ...e, _ts: Date.now() } })
    },

    disconnect() {
      try { echoInstance?.disconnect() } catch {}
      echoInstance = null
    },

    /**
     * Outgoing call — caller side.
     */
    async startOutgoing({ orderId, calleeId, calleeName, calleeAvatar }: { orderId: number; calleeId: number; calleeName?: string; calleeAvatar?: string | null }) {
      if (this.phase !== 'idle' && this.phase !== 'ended') return
      this.error = ''
      this.peerName = calleeName || ''
      this.peerAvatar = calleeAvatar ?? null
      this.phase = 'dialing'

      try {
        await this._ensureLocalMedia()
        await this._buildPeer(true)
        const offer = await peerConn!.createOffer({ offerToReceiveAudio: true })
        await peerConn!.setLocalDescription(offer)

        const { apiFetch } = useApi()
        const res = await apiFetch<{ call: CallPayload }>('/calls', {
          method: 'POST',
          body: { order_id: orderId, callee_id: calleeId, sdp: offer },
        })
        this.call = res.call
      } catch (e: any) {
        this.error = e?.data?.message || e?.message || 'Call failed'
        this.phase = 'ended'
        this._teardown()
      }
    },

    /**
     * Incoming call — callee side. Triggered automatically by Reverb event.
     */
    async accept() {
      if (this.phase !== 'incoming' || !this.call || !pendingRemoteSdp) return
      try {
        await this._ensureLocalMedia()
        await this._buildPeer(false)
        await peerConn!.setRemoteDescription(pendingRemoteSdp)
        await this._flushPendingIce()
        const answer = await peerConn!.createAnswer()
        await peerConn!.setLocalDescription(answer)

        const { apiFetch } = useApi()
        await apiFetch(`/calls/${this.call.id}/accept`, {
          method: 'POST',
          body: { sdp: answer },
        })
        this.phase = 'in_call'
        this._startTimer()
      } catch (e: any) {
        this.error = e?.data?.message || e?.message || 'Failed to accept'
        await this.end()
      }
    },

    async reject() {
      if (this.phase !== 'incoming' || !this.call) return
      const { apiFetch } = useApi()
      try {
        await apiFetch(`/calls/${this.call.id}/reject`, { method: 'POST' })
      } catch {}
      this.phase = 'ended'
      this._teardown()
    },

    async end() {
      if (!this.call) {
        this.phase = 'ended'
        this._teardown()
        return
      }
      const { apiFetch } = useApi()
      try {
        await apiFetch(`/calls/${this.call.id}/end`, { method: 'POST' })
      } catch {}
      this.phase = 'ended'
      this._teardown()
    },

    toggleMic() {
      if (!localStream) return
      this.micMuted = !this.micMuted
      localStream.getAudioTracks().forEach(t => { t.enabled = !this.micMuted })
    },

    dismiss() {
      this.phase = 'idle'
      this.call = null
      this.error = ''
      this.peerName = ''
      this.peerAvatar = null
      this.durationSec = 0
    },

    // -------- private --------

    async _ensureLocalMedia() {
      if (localStream) return
      localStream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false })
    },

    async _buildPeer(isCaller: boolean) {
      peerConn = new RTCPeerConnection(RTC_CONFIG)
      localStream?.getTracks().forEach(t => peerConn!.addTrack(t, localStream!))

      peerConn.onicecandidate = async (ev) => {
        if (!ev.candidate || !this.call) return
        const { apiFetch } = useApi()
        try {
          await apiFetch(`/calls/${this.call.id}/signal`, {
            method: 'POST',
            body: { type: 'ice', payload: ev.candidate.toJSON() },
          })
        } catch {}
      }

      peerConn.ontrack = (ev) => {
        if (!remoteAudioEl) {
          remoteAudioEl = document.createElement('audio')
          remoteAudioEl.autoplay = true
          document.body.appendChild(remoteAudioEl)
        }
        remoteAudioEl.srcObject = ev.streams[0]
      }

      peerConn.onconnectionstatechange = () => {
        if (!peerConn) return
        if (peerConn.connectionState === 'failed' || peerConn.connectionState === 'disconnected') {
          this.end()
        }
      }
    },

    _onIncoming(e: any) {
      if (this.phase === 'in_call' || this.phase === 'dialing') return // ignore overlap
      const callId = e.call_id
      const p = e.payload || {}
      this.call = {
        id: callId,
        order_id: p.order_id,
        caller_id: p.caller_id,
        callee_id: useAuthStore().user!.id,
        status: 'ringing',
        started_at: new Date().toISOString(),
        accepted_at: null, ended_at: null, duration_sec: null,
        caller: p.caller || null, callee: null,
      }
      if (p.caller) {
        const c = p.caller
        this.peerName = `${c.first_name || ''} ${c.last_name || ''}`.trim()
        this.peerAvatar = c.avatar_url || null
      }
      pendingRemoteSdp = p.sdp || null
      pendingIce = []
      this.phase = 'incoming'
      this._playRingtone()
    },

    async _onAccepted(e: any) {
      if (this.phase !== 'dialing' || !peerConn) return
      const sdp = e.payload?.sdp
      if (!sdp) return
      await peerConn.setRemoteDescription(sdp)
      await this._flushPendingIce()
      this.phase = 'in_call'
      this._startTimer()
    },

    _onTerminated(_e: any, _reason: string) {
      this.phase = 'ended'
      this._teardown()
    },

    async _onRemoteSdp(e: any, kind: 'offer' | 'answer') {
      if (!peerConn) return
      const sdp = e.payload
      if (!sdp) return
      await peerConn.setRemoteDescription(sdp)
      if (kind === 'offer') {
        const ans = await peerConn.createAnswer()
        await peerConn.setLocalDescription(ans)
      }
      await this._flushPendingIce()
    },

    async _onRemoteIce(e: any) {
      const c = e.payload
      if (!c) return
      if (!peerConn || !peerConn.remoteDescription) {
        pendingIce.push(c)
        return
      }
      try { await peerConn.addIceCandidate(c) } catch {}
    },

    async _flushPendingIce() {
      if (!peerConn || !pendingIce.length) return
      for (const c of pendingIce) {
        try { await peerConn.addIceCandidate(c) } catch {}
      }
      pendingIce = []
    },

    _startTimer() {
      this._stopTimer()
      const t0 = Date.now()
      durationTimer = window.setInterval(() => {
        this.durationSec = Math.floor((Date.now() - t0) / 1000)
      }, 1000) as unknown as number
    },

    _stopTimer() {
      if (durationTimer) { clearInterval(durationTimer); durationTimer = null }
    },

    _playRingtone() {
      // Lightweight beep using WebAudio — no asset dependency.
      try {
        const ctx = new (window.AudioContext || (window as any).webkitAudioContext)()
        const osc = ctx.createOscillator()
        const gain = ctx.createGain()
        osc.frequency.value = 440
        osc.connect(gain); gain.connect(ctx.destination)
        gain.gain.setValueAtTime(0.0001, ctx.currentTime)
        gain.gain.exponentialRampToValueAtTime(0.2, ctx.currentTime + 0.05)
        gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.4)
        osc.start()
        osc.stop(ctx.currentTime + 0.5)
      } catch {}
    },

    _teardown() {
      this._stopTimer()
      try { peerConn?.getSenders().forEach(s => s.track?.stop()) } catch {}
      try { peerConn?.close() } catch {}
      peerConn = null
      try { localStream?.getTracks().forEach(t => t.stop()) } catch {}
      localStream = null
      pendingIce = []
      pendingRemoteSdp = null
      if (remoteAudioEl) { try { remoteAudioEl.srcObject = null; remoteAudioEl.remove() } catch {}; remoteAudioEl = null }
    },
  },
})
