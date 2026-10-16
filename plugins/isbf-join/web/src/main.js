import './styles.css';
import { config } from './config.js';
import { createGallery } from './gallery.js';
import { createApplicationDialog } from './application.js';

const $ = (selector) => document.querySelector(selector);
const journey = $('#journey');
const join = $('#join');
const brand = $('.brand-mark');
const stage = journey.querySelector('.stage');
const themeColor = $('meta[name="theme-color"]');
const timeline = $('#timeline-progress');
const cue = $('#scroll-cue');
const scrollLabel = $('#scroll-label');
const replay = $('#replay-button');
const loader = $('#loader');
const progressText = $('#loader-progress');
const progressBar = $('#loader-bar');
const vignette = $('.scene-vignette');
const tunnelFade = $('#tunnel-fade');
createApplicationDialog();
const motionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
let reducedMotion = motionQuery.matches;
const gallery = createGallery({ reducedMotion });
let scene;
let currentProgress = 0;
let targetProgress = 0;
let raf = 0;
let previousTime = 0;
let loaded = false;
let inView = true;
let autoScrollFrame = 0;
let loaderProgress = 0;
const pointer = { x: 0, y: 0, targetX: 0, targetY: 0 };
const clamp = (value) => Math.max(0, Math.min(1, value));
const smoothstep = (start, end, value) => { const t = clamp((value - start) / (end - start)); return t * t * (3 - 2 * t); };
let viewportTheme = '';

document.querySelectorAll('a[href="https://isbf-one.com"]').forEach((link) => { link.href = config.homeUrl; });

document.body.classList.add('is-loading');
if ('scrollRestoration' in history) history.scrollRestoration = 'manual';
if (!location.hash) window.scrollTo(0, 0);

function setLoadProgress(value) {
  loaderProgress = Math.max(loaderProgress, clamp(value));
  progressBar.style.width = `${loaderProgress * 100}%`;
  progressText.textContent = `${String(Math.round(loaderProgress * 100)).padStart(2, '0')}%`;
}

function journeyRange() {
  // Match the actual sticky stage, including Safari's changing toolbar height.
  return Math.max(1, journey.offsetHeight - stage.clientHeight);
}

function updateViewportTheme(progress) {
  const galleryReached = reducedMotion
    ? join.getBoundingClientRect().top <= 0
    : targetProgress >= 1;
  const phase = galleryReached || (!reducedMotion && progress >= 0.995)
    ? 'gallery' : !reducedMotion && progress >= 0.86 ? 'tunnel' : 'opening';
  if (viewportTheme === phase) return;
  viewportTheme = phase;
  const color = { opening: config.scene.background, tunnel: '#050505', gallery: '#171717' }[phase];
  themeColor.content = color;
  document.documentElement.style.setProperty('--viewport-bg', color);
  document.documentElement.dataset.viewportTheme = phase;
  document.body.classList.toggle('is-blue-scene', phase === 'opening');
}

function measureScroll() {
  const range = journeyRange();
  targetProgress = clamp((window.scrollY - journey.offsetTop) / range);
  // Keep the transparent mark with the gallery introduction, not over its copy.
  brand.style.transform = `translateY(${Math.min(0, join.getBoundingClientRect().top)}px)`;
  // Also update when the hero has left the viewport or the page opens at #join.
  updateViewportTheme(loaded && inView ? currentProgress : targetProgress);
  if (!raf && loaded && inView && !document.hidden) raf = requestAnimationFrame(frame);
}

function updateOverlay(progress) {
  timeline.style.transform = `scaleX(${progress})`;
  vignette.style.opacity = String(1 - smoothstep(0.65, 0.78, progress));
  tunnelFade.style.opacity = reducedMotion ? '0' : String(smoothstep(0.965, 1, progress));
  updateViewportTheme(progress);
  cue.style.opacity = String(1 - smoothstep(0.8, 0.87, progress));
  cue.style.pointerEvents = progress > 0.87 ? 'none' : '';
  scrollLabel.textContent = progress < 0.08 ? '向下滚动，开启下一步' : '继续向前，探索更多可能';
}

function frame(time) {
  raf = 0;
  const delta = previousTime ? Math.min((time - previousTime) / 1000, 0.05) : 1 / 60;
  previousTime = time;
  const factor = reducedMotion ? 1 : 1 - Math.exp(-config.scene.smoothing * delta);
  currentProgress += (targetProgress - currentProgress) * factor;
  if (Math.abs(currentProgress - targetProgress) < 0.00005) currentProgress = targetProgress;
  pointer.x += (pointer.targetX - pointer.x) * factor;
  pointer.y += (pointer.targetY - pointer.y) * factor;
  scene?.render(currentProgress, pointer);
  updateOverlay(currentProgress);
  if (!document.hidden && inView && (Math.abs(currentProgress - targetProgress) > 0.00005 || Math.abs(pointer.x - pointer.targetX) > 0.001 || Math.abs(pointer.y - pointer.targetY) > 0.001)) {
    raf = requestAnimationFrame(frame);
  }
}

function animateScroll(destination, duration = 1300) {
  cancelAnimationFrame(autoScrollFrame);
  if (reducedMotion) { window.scrollTo(0, destination); return; }
  const start = window.scrollY;
  const started = performance.now();
  const tick = (now) => {
    const t = clamp((now - started) / duration);
    const eased = t < 0.5 ? 4 * t ** 3 : 1 - (-2 * t + 2) ** 3 / 2;
    window.scrollTo(0, start + (destination - start) * eased);
    if (t < 1) autoScrollFrame = requestAnimationFrame(tick);
  };
  autoScrollFrame = requestAnimationFrame(tick);
}

function restart() { animateScroll(0, 1600); }
window.addEventListener('scroll', measureScroll, { passive: true });
window.addEventListener('resize', measureScroll, { passive: true });
const stageObserver = new ResizeObserver(measureScroll);
stageObserver.observe(stage);
window.visualViewport?.addEventListener('resize', measureScroll, { passive: true });
window.addEventListener('pageshow', measureScroll);
for (const event of ['wheel', 'touchstart', 'pointerdown', 'keydown']) {
  window.addEventListener(event, () => cancelAnimationFrame(autoScrollFrame), { passive: true });
}
window.addEventListener('pointermove', (event) => {
  if (event.pointerType !== 'mouse' || reducedMotion || window.innerWidth < 768) return;
  pointer.targetX = (event.clientX / window.innerWidth) * 2 - 1;
  pointer.targetY = -((event.clientY / window.innerHeight) * 2 - 1);
  if (!raf && loaded && inView && !document.hidden) raf = requestAnimationFrame(frame);
}, { passive: true });
document.documentElement.addEventListener('pointerleave', () => {
  pointer.targetX = pointer.targetY = 0;
  if (!raf && loaded && inView) raf = requestAnimationFrame(frame);
});
document.addEventListener('visibilitychange', () => {
  if (document.hidden) { cancelAnimationFrame(raf); raf = 0; }
  else { previousTime = 0; measureScroll(); }
});
new IntersectionObserver(([entry]) => {
  inView = entry.isIntersecting;
  if (inView) measureScroll();
}, { rootMargin: '100px' }).observe(journey);

cue.addEventListener('click', () => {
  animateScroll(Math.min(journeyRange(), window.scrollY + stage.clientHeight * 0.85), 1100);
});
replay.addEventListener('click', restart);
$('#back-to-start').addEventListener('click', restart);
for (const link of document.querySelectorAll('a[href="#join"]')) {
  link.addEventListener('click', (event) => {
    event.preventDefault();
    animateScroll($('#join').offsetTop, 1550);
    $('#join').focus({ preventScroll: true });
  });
}
motionQuery.addEventListener('change', () => window.location.reload());

async function init() {
  const started = performance.now();
  setLoadProgress(0.06);
  try {
    const { createJourneyScene } = await import('./scene.js');
    setLoadProgress(0.12);
    scene = await createJourneyScene($('#scene'), {
      onProgress: (value) => setLoadProgress(0.12 + value * 0.88),
      reducedMotion,
    });
    document.body.dataset.scene = 'ready';
    document.body.dataset.floatingAds = String(scene.adCount);
  } catch (error) {
    console.error('ISBF-One journey could not load:', error);
    document.body.dataset.scene = 'fallback';
    const fallback = document.createElement('div');
    fallback.className = 'scene-fallback';
    fallback.innerHTML = '<span aria-hidden="true">ONE.</span>';
    $('#scene').replaceChildren(fallback);
    journey.style.height = CSS.supports('height', '100dvh') ? '100dvh' : '100svh';
    reducedMotion = true;
    scrollLabel.textContent = '探索下一步';
  }
  setLoadProgress(1);
  const remaining = Math.max(0, 900 - (performance.now() - started));
  await new Promise((resolve) => setTimeout(resolve, remaining));
  document.body.classList.remove('is-loading');
  document.body.classList.add('is-ready');
  loader.classList.add('is-exiting');
  loaded = true;
  measureScroll();
  updateOverlay(0);
  window.setTimeout(() => loader.remove(), 900);
}

window.addEventListener('pagehide', () => {
  cancelAnimationFrame(raf);
  cancelAnimationFrame(autoScrollFrame);
  stageObserver.disconnect();
  window.visualViewport?.removeEventListener('resize', measureScroll);
  scene?.dispose();
  gallery.dispose();
});

measureScroll();
init();
