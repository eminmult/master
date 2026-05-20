let audioContext: AudioContext | null = null

export function useSound() {
  function playNotification() {
    try {
      if (!audioContext) audioContext = new AudioContext()
      const osc = audioContext.createOscillator()
      const gain = audioContext.createGain()
      osc.connect(gain)
      gain.connect(audioContext.destination)
      osc.frequency.setValueAtTime(800, audioContext.currentTime)
      osc.frequency.setValueAtTime(600, audioContext.currentTime + 0.1)
      gain.gain.setValueAtTime(0.3, audioContext.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3)
      osc.start(audioContext.currentTime)
      osc.stop(audioContext.currentTime + 0.3)
    } catch {}
  }

  function playMessage() {
    try {
      if (!audioContext) audioContext = new AudioContext()
      const osc = audioContext.createOscillator()
      const gain = audioContext.createGain()
      osc.connect(gain)
      gain.connect(audioContext.destination)
      osc.frequency.setValueAtTime(523, audioContext.currentTime)
      osc.frequency.setValueAtTime(659, audioContext.currentTime + 0.08)
      gain.gain.setValueAtTime(0.2, audioContext.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.2)
      osc.start(audioContext.currentTime)
      osc.stop(audioContext.currentTime + 0.2)
    } catch {}
  }

  return { playNotification, playMessage }
}
