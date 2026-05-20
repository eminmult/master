export default defineNuxtPlugin(() => {
  if (!import.meta.client) return
  const mark = () => document.documentElement.classList.add('fonts-loaded')
  if ((document as any).fonts?.ready) {
    ;(document as any).fonts.ready.then(mark).catch(mark)
    setTimeout(mark, 4000)
  } else {
    setTimeout(mark, 1500)
  }
})
