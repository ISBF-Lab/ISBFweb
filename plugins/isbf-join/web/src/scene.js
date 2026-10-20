import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { DRACOLoader } from 'three/addons/loaders/DRACOLoader.js';
import { config } from './config.js';
import { createRecruitmentAds } from './ads.js';
import { drawBrandWordmark } from './brand.js';

const keepRoots = new Set([
  'SpeedLines001', 'Railing_R001', 'Railing_L001',
  'Railing001', 'MainSkeleton001', 'Ground001',
  'BillboardInt001', 'BillboardInt002', 'BillboardInt003',
]);

export async function createJourneyScene(container, { onProgress, reducedMotion = false } = {}) {
  const mobile = window.innerWidth < 768;
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(config.scene.background);
  const renderer = new THREE.WebGLRenderer({ antialias: !mobile, powerPreference: 'high-performance' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, mobile ? 1.25 : 1.6));
  renderer.setSize(container.clientWidth, container.clientHeight);
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = config.scene.exposure;
  renderer.setClearColor(config.scene.background);
  container.appendChild(renderer.domElement);
  scene.add(new THREE.HemisphereLight('#ffffff', '#e6edf5', 2.0));
  const keyLight = new THREE.DirectionalLight('#ffffff', 2.4);
  keyLight.position.set(-24, 24, 40);
  keyLight.target.position.set(-13, 5, 20);
  scene.add(keyLight, keyLight.target);

  const draco = new DRACOLoader();
  draco.setDecoderPath(config.model.dracoPath);
  const loader = new GLTFLoader();
  loader.setDRACOLoader(draco);

  let gltf;
  try {
    gltf = await loader.loadAsync(mobile ? config.model.mobile : config.model.desktop, (event) => {
      onProgress?.(event.lengthComputable ? event.loaded / event.total * 0.9 : 0.45);
    });
  } catch (error) {
    draco.dispose();
    renderer.dispose();
    renderer.domElement.remove();
    throw error;
  }

  // Keep the authored walk, rig, rails and dolly camera. Payment displays and
  // campaign billboards belong to the reference, and are outside this page.
  for (const child of [...gltf.scene.children]) {
    if (!keepRoots.has(child.name.replace(/[.\s]/g, ''))) gltf.scene.remove(child);
  }

  await document.fonts.ready;
  const changedMaterials = new Set();
  gltf.scene.traverse((object) => {
    // GLTFLoader represents this multi-material label as a Group. Hide the
    // parent before checking isMesh so its separate lettering is hidden too.
    if (/^Label_R/.test(object.name)) object.visible = false;
    if (!object.isMesh) return;
    object.frustumCulled = false;
    const materials = Array.isArray(object.material) ? object.material : [object.material];
    for (const material of materials) {
      if (!material || changedMaterials.has(material)) continue;
      changedMaterials.add(material);
      material.side = THREE.DoubleSide;
      if (material.name === 'Ground') {
        material.emissiveMap = null;
        material.map = null;
        material.color.set('#ffffff');
        material.emissive?.set('#ffffff');
        material.emissiveIntensity = 1;
        material.toneMapped = false;
      }
      if (['Railing', 'CellShader'].includes(material.name)) {
        material.map = null;
        material.color.set('#ffffff');
        material.toneMapped = false;
      }
      if (material.name === 'Tunnel') {
        // Retain the original white depth lines on the black tunnel atlas.
        material.color.set('#ffffff');
        material.toneMapped = false;
        material.needsUpdate = true;
      }
      if (material.name === 'TunnelBack') {
        material.color.set('#050505');
        material.toneMapped = false;
      }
      if (material.name === 'Ray') {
        material.transparent = true;
        material.opacity = 0.14;
        material.depthWrite = false;
      }
      if (material.name === 'Billboard') {
        material.map = null;
        material.emissiveMap = null;
        material.color.set('#050505');
        material.emissive?.set('#000000');
        material.toneMapped = false;
      }
      if (material.name === 'BlueTag') {
        material.map = null;
        material.emissiveMap = null;
        material.color.set('#000000');
        material.emissive?.set('#161616');
        material.needsUpdate = true;
      }
    }
  });
  // Keep opaque depth like the reference: match blue texels to the scene's
  // background. Actual alpha holes expose white backfaces/floor and wash out
  // the grid, while chroma remapping preserves the authored blue/white UVs.
  const gridMaterials = new Map();
  gltf.scene.getObjectByName('MainSkeleton001')?.traverse((object) => {
    if (!object.isMesh) return;
    const convert = (source) => {
      if (gridMaterials.has(source)) return gridMaterials.get(source);
      const material = new THREE.MeshBasicMaterial({
        color: '#ffffff', map: source.map || source.emissiveMap || null,
        side: THREE.DoubleSide, toneMapped: false,
        transparent: false, depthWrite: true,
      });
      material.name = `ISBFGrid-${source.name}`;
      if (material.map) {
        material.onBeforeCompile = (shader) => {
          shader.uniforms.isbfGridBlue = { value: new THREE.Color(config.scene.background) };
          shader.fragmentShader = 'uniform vec3 isbfGridBlue;\n' + shader.fragmentShader;
          shader.fragmentShader = shader.fragmentShader.replace('#include <map_fragment>', `#include <map_fragment>
            float gridMask = smoothstep(0.012, 0.25, min(diffuseColor.r, diffuseColor.g));
            diffuseColor.rgb = mix(isbfGridBlue, vec3(1.0), gridMask);
          `);
        };
        material.customProgramCacheKey = () => 'isbf-background-grid-v3';
      }
      gridMaterials.set(source, material);
      changedMaterials.add(material);
      return material;
    };
    object.material = Array.isArray(object.material) ? object.material.map(convert) : convert(object.material);
  });
  const portal = gltf.scene.getObjectByName('BillboardInt002');
  if (!portal?.isMesh) throw new Error('The authored billboard entrance is missing.');
  const mouth = getPortalMouth(portal.geometry);
  const billboard = createBillboard(mouth.width / mouth.height);
  // Only the lettering belongs on the entrance plane. An opaque black poster
  // hides the authored tunnel until the camera crosses it, causing a hard pop.
  const posterMaterial = new THREE.MeshBasicMaterial({
    map: billboard, transparent: true, depthWrite: false,
    side: THREE.FrontSide, toneMapped: false,
  });
  const poster = new THREE.Mesh(new THREE.PlaneGeometry(mouth.width, mouth.height), posterMaterial);
  poster.name = 'ISBFRecruitmentBillboard';
  poster.position.copy(mouth.center);
  poster.position.z -= 0.002;
  poster.rotation.y = Math.PI;
  portal.add(poster);
  changedMaterials.add(posterMaterial);
  scene.add(gltf.scene);

  const camera = gltf.cameras.find((item) => /DutchCamera|Camera/i.test(item.name)) || gltf.cameras[0];
  if (!camera) throw new Error('The journey model has no camera.');
  const authoredNear = camera.near;
  camera.far = 1000;
  camera.aspect = container.clientWidth / container.clientHeight;
  camera.updateProjectionMatrix();

  const mixer = new THREE.AnimationMixer(gltf.scene);
  const nodeNames = new Set();
  gltf.scene.traverse((object) => nodeNames.add(object.name));
  let duration = 0;
  for (const clip of gltf.animations) {
    const tracks = clip.tracks.filter((track) => nodeNames.has(THREE.PropertyBinding.parseTrackName(track.name).nodeName));
    if (!tracks.length) continue;
    const action = mixer.clipAction(new THREE.AnimationClip(clip.name, clip.duration, tracks));
    action.setLoop(THREE.LoopOnce, 1);
    action.clampWhenFinished = true;
    action.play();
    duration = Math.max(duration, clip.duration);
  }
  mixer.setTime(duration * 0.42);
  scene.updateMatrixWorld(true);
  const ads = createRecruitmentAds(camera);
  container.dataset.cutoutAds = String(ads.cutoutCount);
  container.dataset.badgeAxis = 'ground-normal-y';
  gltf.scene.add(ads.group);
  ads.group.traverse((object) => {
    if (!object.isMesh) return;
    const materials = Array.isArray(object.material) ? object.material : [object.material];
    materials.forEach((material) => changedMaterials.add(material));
  });
  container.dataset.portalSize = `${mouth.width.toFixed(3)}×${mouth.height.toFixed(3)}`;
  container.dataset.portalMouthDepth = mouth.center.z.toFixed(3);

  let contextLost = false;
  let lastProgress = -1;
  let lastScrollProgress = 0;
  const savedPosition = new THREE.Vector3();
  const savedQuaternion = new THREE.Quaternion();
  const render = (progress, pointer = { x: 0, y: 0 }) => {
    if (contextLost) return;
    lastScrollProgress = progress;
    ads.update(reducedMotion ? 0.5 : progress);
    container.dataset.badgeRotation = (ads.group.children.find((ad) => ad.userData.form === 'badge')?.userData.scrollRotation || 0).toFixed(3);
    container.dataset.adsPhase = reducedMotion || progress >= 0.465 ? 'settled' : progress <= 0.06 ? 'waiting' : 'rising';
    // Reserve the final section of the scroll for the portal flight, instead
    // of compressing the whole tunnel into the last tiny gesture.
    const sample = reducedMotion ? 0.17 : progress <= 0.72
      ? THREE.MathUtils.lerp(config.scene.start, 0.9, progress / 0.72)
      : progress <= 0.86
        ? THREE.MathUtils.lerp(0.9, 0.952, (progress - 0.72) / 0.14)
        : THREE.MathUtils.lerp(0.952, config.scene.end, (progress - 0.86) / 0.14);
    // Preserve the shoe close-up and tunnel clearance while retaining depth
    // precision for the distant lettering.
    const openingNear = THREE.MathUtils.lerp(authoredNear, 0.08, THREE.MathUtils.smoothstep(progress, 0.12, 0.18));
    const tunnelNear = THREE.MathUtils.lerp(0.08, 0.008, THREE.MathUtils.smoothstep(progress, 0.76, 0.86));
    const near = reducedMotion ? 0.08 : Math.min(openingNear, tunnelNear);
    if (camera.near !== near) { camera.near = near; camera.updateProjectionMatrix(); }
    if (lastProgress !== sample) {
      mixer.setTime(Math.min(sample * duration, duration - 0.012));
      lastProgress = sample;
    }
    savedPosition.copy(camera.position);
    savedQuaternion.copy(camera.quaternion);
    if (!mobile && !reducedMotion) {
      camera.position.x += pointer.x * config.scene.parallax;
      camera.position.y += pointer.y * config.scene.parallax * 0.3;
      camera.rotation.y -= pointer.x * 0.008;
    }
    if (mobile) camera.position.x += 0.35;
    scene.updateMatrixWorld(true);
    const cameraInPortal = portal.worldToLocal(camera.getWorldPosition(new THREE.Vector3()));
    const inside = sample >= 0.952;
    container.dataset.phase = inside ? 'tunnel' : 'approach';
    container.dataset.cameraDepth = cameraInPortal.z.toFixed(3);
    scene.background.set(inside ? '#050505' : config.scene.background);
    renderer.render(scene, camera);
    camera.position.copy(savedPosition);
    camera.quaternion.copy(savedQuaternion);
  };

  const resize = () => {
    const width = container.clientWidth;
    const height = container.clientHeight;
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
    renderer.setSize(width, height);
    render(lastScrollProgress);
  };
  const observer = new ResizeObserver(resize);
  observer.observe(container);
  renderer.domElement.addEventListener('webglcontextlost', (event) => { event.preventDefault(); contextLost = true; });
  renderer.domElement.addEventListener('webglcontextrestored', () => { contextLost = false; resize(); });
  render(0);
  await renderer.compileAsync(scene, camera);
  onProgress?.(1);

  return {
    adCount: ads.group.children.length,
    render,
    dispose() {
      observer.disconnect();
      mixer.stopAllAction();
      gltf.scene.traverse((object) => {
        if (object.isMesh) object.geometry.dispose();
      });
      const textures = new Set();
      for (const material of changedMaterials) {
        for (const value of Object.values(material)) if (value?.isTexture) textures.add(value);
        material.dispose();
      }
      textures.forEach((texture) => texture.dispose());
      billboard.dispose();
      draco.dispose();
      renderer.dispose();
    },
  };
}

function getPortalMouth(geometry) {
  const positions = geometry.getAttribute('position');
  let minZ = Infinity;
  for (let i = 0; i < positions.count; i += 1) minZ = Math.min(minZ, positions.getZ(i));
  const bounds = new THREE.Box3();
  for (let i = 0; i < positions.count; i += 1) {
    if (Math.abs(positions.getZ(i) - minZ) < 0.01) bounds.expandByPoint(new THREE.Vector3().fromBufferAttribute(positions, i));
  }
  const size = bounds.getSize(new THREE.Vector3());
  if (!size.x || !size.y) throw new Error('Cannot measure the authored billboard opening.');
  return { center: bounds.getCenter(new THREE.Vector3()), width: size.x, height: size.y };
}

function createBillboard(aspect) {
  const canvas = document.createElement('canvas');
  canvas.width = 4096;
  canvas.height = Math.round(canvas.width / aspect);
  const ctx = canvas.getContext('2d');
  const w = canvas.width; const h = canvas.height;
  // The same real tunnel is visible behind the wordmark from the approach
  // through the entrance; do not replace it with a flat background or stripes.
  ctx.clearRect(0, 0, w, h);
  drawBrandWordmark(ctx, { x: w * 0.5, y: h * 0.51, width: w * 0.82, maxHeight: h * 0.29 });
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  // This texture is placed on a new Three.js plane, rather than glTF UVs.
  texture.flipY = true;
  texture.anisotropy = 4;
  return texture;
}
