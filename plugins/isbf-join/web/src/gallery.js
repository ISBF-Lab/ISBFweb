import { config } from './config.js';

// Native horizontal scrolling stays available for touch, trackpads and keys.
// The second, accessibility-hidden group makes the idle movement seamless.
export function createGallery({ reducedMotion = false } = {}) {
  const viewport = document.querySelector('#gallery-window');
  const track = document.querySelector('#gallery-track');
  const items = config.gallery.items.length ? config.gallery.items : [{ image: '', title: '你的图片', alt: '' }];
  const group = document.createElement('div');
  group.className = 'gallery-group';
  group.setAttribute('role', 'presentation');

  items.forEach((item, index) => {
    const card = document.createElement('figure');
    card.className = 'gallery-card is-placeholder';
    card.setAttribute('role', 'listitem');
    card.dataset.imageState = item.image ? 'loading' : 'empty';
    const placeholder = document.createElement('div');
    placeholder.className = 'gallery-placeholder';
    const number = document.createElement('span');
    number.className = 'gallery-image-number';
    number.textContent = String(index + 1).padStart(2, '0');
    const hint = document.createElement('span');
    hint.className = 'gallery-image-hint';
    hint.textContent = '待添加图片';
    placeholder.append(number, hint);
    placeholder.setAttribute('aria-hidden', 'true');
    card.append(placeholder);
    if (item.image) {
      const image = document.createElement('img');
      image.alt = item.alt || item.title || `团队影像 ${index + 1}`;
      image.loading = 'lazy';
      image.decoding = 'async';
      image.addEventListener('load', () => { card.classList.remove('is-placeholder'); card.dataset.imageState = 'loaded'; });
      image.addEventListener('error', () => { image.hidden = true; card.dataset.imageState = 'error'; hint.textContent = '图片暂时无法加载'; });
      image.src = /^(https?:)?\/\//.test(item.image) || item.image.startsWith('data:image/')
        ? item.image : `${import.meta.env.BASE_URL}${item.image.replace(/^\/+/, '')}`;
      card.append(image);
    }
    card.setAttribute('aria-label', item.alt || item.title || `团队影像 ${index + 1}`);
    group.append(card);
  });
  track.append(group);
  if (!reducedMotion) {
    const duplicate = group.cloneNode(true);
    duplicate.setAttribute('aria-hidden', 'true');
    duplicate.inert = true;
    // Clones do not inherit listeners; each image reveals after its own load.
    duplicate.querySelectorAll('img').forEach((copy) => {
      const reveal = () => { copy.closest('.gallery-card').classList.remove('is-placeholder'); };
      copy.addEventListener('load', reveal);
      copy.addEventListener('error', () => { copy.hidden = true; copy.closest('.gallery-card').classList.add('is-placeholder'); });
      if (copy.complete && copy.naturalWidth) reveal();
    });
    track.append(duplicate);
  }
  viewport.dataset.itemCount = String(items.length);
  let raf = 0;
  let previousTime = 0;
  let visible = false;
  let hovered = false;
  let focused = false;
  let dragging = false;
  let resumeAt = 0;
  let lastPageY = window.scrollY;
  let period = group.getBoundingClientRect().width;
  let fractionalMove = 0;
  const speed = Number.isFinite(config.gallery.speed) ? Math.max(0, config.gallery.speed) : 28;
  const active = () => !reducedMotion && speed > 0 && visible && !document.hidden && !document.body.classList.contains('has-dialog') && !hovered && !focused && !dragging;
  const updateOffset = () => { viewport.dataset.offset = viewport.scrollLeft.toFixed(1); };
  const move = (delta) => {
    if (period <= viewport.clientWidth || !delta) return;
    fractionalMove += delta;
    const wholePixels = Math.trunc(fractionalMove);
    fractionalMove -= wholePixels;
    if (!wholePixels) return;
    viewport.scrollLeft = ((viewport.scrollLeft + wholePixels) % period + period) % period;
    updateOffset();
  };
  const frame = (time) => {
    raf = 0;
    const delta = previousTime ? Math.min((time - previousTime) / 1000, 0.05) : 0;
    previousTime = time;
    if (active() && time >= resumeAt) move(speed * delta);
    if (active()) raf = requestAnimationFrame(frame);
  };
  const start = () => { if (!raf && active()) { previousTime = 0; raf = requestAnimationFrame(frame); } };
  const onPageScroll = () => {
    const delta = window.scrollY - lastPageY;
    lastPageY = window.scrollY;
    if (active()) move(delta * 0.32);
    start();
  };
  const onVisibility = () => { if (document.hidden) { cancelAnimationFrame(raf); raf = 0; } else start(); };
  const observer = new IntersectionObserver(([entry]) => { visible = entry.isIntersecting; start(); }, { threshold: 0.01 });
  observer.observe(viewport);
  const resizeObserver = new ResizeObserver(() => { period = group.getBoundingClientRect().width; });
  resizeObserver.observe(group);
  viewport.addEventListener('pointerenter', (event) => { if (event.pointerType === 'mouse') hovered = true; });
  viewport.addEventListener('pointerleave', () => { hovered = false; start(); });
  viewport.addEventListener('focusin', () => { focused = true; });
  viewport.addEventListener('focusout', (event) => { focused = viewport.contains(event.relatedTarget); start(); });
  viewport.addEventListener('pointerdown', () => { dragging = true; });
  const onPointerUp = () => { dragging = false; resumeAt = performance.now() + 1200; start(); };
  window.addEventListener('pointerup', onPointerUp);
  window.addEventListener('pointercancel', onPointerUp);
  viewport.addEventListener('wheel', () => { resumeAt = performance.now() + 1200; }, { passive: true });
  viewport.addEventListener('scroll', () => {
    if (!reducedMotion && period > viewport.clientWidth && viewport.scrollLeft >= period) viewport.scrollLeft -= period;
    updateOffset();
  }, { passive: true });
  const dialog = document.querySelector('#contact-dialog');
  dialog?.addEventListener('close', start);
  window.addEventListener('scroll', onPageScroll, { passive: true });
  document.addEventListener('visibilitychange', onVisibility);
  updateOffset();
  return {
    dispose() {
      cancelAnimationFrame(raf);
      observer.disconnect();
      resizeObserver.disconnect();
      window.removeEventListener('scroll', onPageScroll);
      window.removeEventListener('pointerup', onPointerUp);
      window.removeEventListener('pointercancel', onPointerUp);
      document.removeEventListener('visibilitychange', onVisibility);
      dialog?.removeEventListener('close', start);
    },
  };
}
