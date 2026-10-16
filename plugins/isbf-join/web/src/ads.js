import * as THREE from 'three';

// Original six recruitment designs, now printed white on black.
export const adDesigns = [
  { id: 'portrait', side: 'left', form: 'portrait', x: -0.78, y: 0.13, distance: 12, width: 0.42, ratio: 0.72, roll: -0.08, revealAt: 0.06 },
  { id: 'banner', side: 'left', form: 'banner', x: -0.75, y: -0.46, distance: 19, width: 0.5, ratio: 1.75, roll: 0.09, revealAt: 0.14 },
  { id: 'graphic', side: 'left', form: 'graphic', x: -0.7, y: 0.73, distance: 29, width: 0.36, ratio: 1, roll: 0.15, revealAt: 0.22 },
  { id: 'badge', side: 'right', form: 'badge', x: 0.77, y: 0.26, distance: 13.5, width: 0.39, ratio: 1, roll: -0.1, revealAt: 0.085 },
  { id: 'ticket', side: 'right', form: 'ticket', x: 0.76, y: -0.45, distance: 21, width: 0.49, ratio: 1.9, roll: 0.07, revealAt: 0.165 },
  { id: 'one', side: 'right', form: 'letters', x: 0.67, y: 0.76, distance: 30, width: 0.4, ratio: 1.25, roll: -0.1, revealAt: 0.245 },
];

export function badgeRotationAt(progress, start = 0.085) {
  const spin = THREE.MathUtils.clamp((progress - start) / (0.86 - start), 0, 1);
  return spin * spin * (3 - 2 * spin) * Math.PI * 2;
}

const groundNormal = new THREE.Vector3(0, 1, 0);
export function badgeOrientationAt(progress, baseOrientation, start = 0.085, target = new THREE.Quaternion()) {
  // Ground.001 lies in XZ. Yaw in its parent's Y axis, not the sign's local Z.
  return target.setFromAxisAngle(groundNormal, badgeRotationAt(progress, start)).multiply(baseOrientation);
}

const black = '#050505';
const white = '#ffffff';

export function createRecruitmentAds(camera) {
  camera.updateWorldMatrix(true, false);
  const root = new THREE.Group();
  root.name = 'ISBFFloatingAds';
  const eye = camera.getWorldPosition(new THREE.Vector3());
  const middle = new THREE.Vector3(0, 0, 0.5).unproject(camera);
  const screenUp = new THREE.Vector3(0, 1, 0.5).unproject(camera).sub(middle).normalize();
  const screenRight = new THREE.Vector3(1, 0, 0.5).unproject(camera).sub(middle).normalize();
  const tangent = Math.tan(THREE.MathUtils.degToRad(camera.fov) / 2);
  const entrances = [];

  for (const design of adDesigns) {
    const direction = new THREE.Vector3(design.x, design.y, 0.5).unproject(camera).sub(eye).normalize();
    const width = design.width * design.distance * tangent * camera.aspect;
    const height = width / design.ratio;
    const group = new THREE.Group();
    group.name = `ISBFAd-${design.side}-${design.form}`;
    group.userData = { ...design };
    group.position.copy(eye).addScaledVector(direction, design.distance);
    group.up.copy(screenUp);
    group.lookAt(eye);
    const faceRight = new THREE.Vector3(1, 0, 0).applyQuaternion(group.quaternion);
    if (faceRight.dot(screenRight) < 0) group.scale.x = -1;
    group.rotateZ(design.roll);
    const shape = createAdShape(width, height, design.form);
    group.userData.apertureCount = shape.holes.length;
    const depth = Math.min(width, height) * 0.025;
    group.add(new THREE.Mesh(
      new THREE.ExtrudeGeometry(shape, { depth, bevelEnabled: false, curveSegments: 48 }),
      [new THREE.MeshBasicMaterial({ color: black, side: THREE.DoubleSide, toneMapped: false }), new THREE.MeshBasicMaterial({ color: '#252525', side: THREE.DoubleSide, toneMapped: false })],
    ));
    const face = new THREE.Mesh(new THREE.ShapeGeometry(shape, 48), new THREE.MeshBasicMaterial({
      map: makeAdTexture(design), side: THREE.DoubleSide, toneMapped: false,
      polygonOffset: true, polygonOffsetFactor: -1, polygonOffsetUnits: -1,
    }));
    const uv = face.geometry.getAttribute('uv');
    const positions = face.geometry.getAttribute('position');
    for (let i = 0; i < uv.count; i += 1) uv.setXY(i, positions.getX(i) / width + 0.5, positions.getY(i) / height + 0.5);
    face.position.z = depth + Math.min(width, height) * 0.004;
    group.add(face);
    if (design.form === 'badge') {
      // A turning disk has a readable reverse face, not a mirrored front print.
      const reverse = new THREE.Mesh(face.geometry.clone(), face.material);
      reverse.position.z = -Math.min(width, height) * 0.004;
      reverse.rotation.y = Math.PI;
      group.add(reverse);
    }
    if (design.form === 'letters') group.add(createOneLetters(width, height, face.position.z));
    entrances.push({
      group, home: group.position.clone(),
      orientation: group.quaternion.clone(),
      below: screenUp.clone().multiplyScalar(-design.distance * tangent * 2.6),
      start: design.revealAt,
    });
    group.visible = false;
    root.add(group);
  }

  return {
    group: root,
    cutoutCount: entrances.filter(({ group }) => group.userData.apertureCount > 0).length,
    update(progress) {
      for (const entrance of entrances) {
        const t = THREE.MathUtils.clamp((progress - entrance.start) / 0.22, 0, 1);
        const eased = t * t * (3 - 2 * t);
        entrance.group.visible = t > 0;
        entrance.group.position.copy(entrance.home).addScaledVector(entrance.below, 1 - eased);
        entrance.group.quaternion.copy(entrance.orientation);
        if (entrance.group.userData.form === 'badge') {
          // Scroll owns the angle: no idle animation, drift, or reverse jumps.
          const angle = badgeRotationAt(progress, entrance.start);
          badgeOrientationAt(progress, entrance.orientation, entrance.start, entrance.group.quaternion);
          entrance.group.userData.scrollRotation = angle;
        }
      }
    },
  };
}

function starShape(radius) {
  const points = [];
  for (let i = 0; i < 32; i += 1) {
    const angle = i / 32 * Math.PI * 2;
    const r = i % 4 === 0 || i % 4 === 3 ? radius : radius * 0.21;
    points.push(new THREE.Vector2(Math.cos(angle) * r, Math.sin(angle) * r));
  }
  return new THREE.Shape(points);
}

export function createAdShape(width, height, form) {
  const shape = new THREE.Shape();
  const x = width / 2; const y = height / 2;
  if (form === 'badge') {
    shape.absarc(0, 0, x, 0, Math.PI * 2, false);
    for (const middle of [0, Math.PI]) {
      const start = middle - Math.PI * 0.22;
      const end = middle + Math.PI * 0.22;
      const outer = width * 0.439; const inner = width * 0.395;
      const radius = (outer + inner) / 2; const cap = (outer - inner) / 2;
      const slot = new THREE.Path();
      slot.absarc(0, 0, outer, start, end, false);
      slot.absarc(radius * Math.cos(end), radius * Math.sin(end), cap, end, end + Math.PI, false);
      slot.absarc(0, 0, inner, end, start, true);
      slot.absarc(radius * Math.cos(start), radius * Math.sin(start), cap, start + Math.PI, start + Math.PI * 2, false);
      slot.closePath();
      shape.holes.push(slot);
    }
    return shape;
  }
  const r = Math.min(width, height) * 0.035;
  shape.moveTo(-x + r, -y);
  shape.lineTo(x - r, -y); shape.quadraticCurveTo(x, -y, x, -y + r);
  if (form === 'ticket') {
    const notch = height * 0.12;
    shape.lineTo(x, -notch); shape.quadraticCurveTo(x - notch * 1.5, 0, x, notch);
  }
  shape.lineTo(x, y - r); shape.quadraticCurveTo(x, y, x - r, y);
  shape.lineTo(-x + r, y); shape.quadraticCurveTo(-x, y, -x, y - r);
  if (form === 'ticket') {
    const notch = height * 0.12;
    shape.lineTo(-x, notch); shape.quadraticCurveTo(-x + notch * 1.5, 0, -x, -notch);
  }
  shape.lineTo(-x, -y + r); shape.quadraticCurveTo(-x, -y, -x + r, -y);
  if (form === 'graphic') {
    const points = starShape(width * 0.24).getPoints().reverse();
    points.forEach((point) => { point.y += height * 0.1; });
    const star = new THREE.Path(points);
    star.closePath();
    shape.holes.push(star);
  }
  return shape;
}

function makeAdTexture(design) {
  const canvas = document.createElement('canvas');
  canvas.width = 1536;
  canvas.height = Math.round(canvas.width / design.ratio);
  const ctx = canvas.getContext('2d');
  const w = canvas.width; const h = canvas.height;
  ctx.fillStyle = black; ctx.fillRect(0, 0, w, h);
  ctx.fillStyle = white; ctx.strokeStyle = white;
  const line = (x1, y1, x2, y2) => { ctx.beginPath(); ctx.moveTo(x1 * w, y1 * h); ctx.lineTo(x2 * w, y2 * h); ctx.stroke(); };
  const text = (value, x, y, size, weight = 500, align = 'left') => {
    ctx.fillStyle = white; ctx.font = `${weight} ${size * w}px Inter, "PingFang SC", "Microsoft YaHei", sans-serif`; ctx.textAlign = align; ctx.textBaseline = 'middle'; ctx.fillText(value, x * w, y * h);
  };
  const title = (lines, x, y, size, gap = 1.02) => lines.split('\n').forEach((value, i) => text(value, x, y + i * size * design.ratio * gap, size, 800));
  const star = (x, y, radius) => {
    ctx.save(); ctx.translate(w * x, h * y); ctx.fillStyle = white;
    for (let i = 0; i < 4; i += 1) { ctx.save(); ctx.rotate(i * Math.PI / 4); ctx.fillRect(-radius * 0.075, -radius, radius * 0.15, radius * 2); ctx.restore(); }
    ctx.restore();
  };
  ctx.lineWidth = 2;
  if (design.form === 'portrait') {
    text('ISBF-One', 0.08, 0.055, 0.037, 700); text('01 / EXPLORE', 0.92, 0.055, 0.026, 500, 'right');
    line(0.08, 0.09, 0.92, 0.09);
    title('STAY\nCURIOUS.', 0.07, 0.2, 0.17);
    star(0.5, 0.57, w * 0.3);
    text('保持好奇', 0.08, 0.84, 0.07); text('THE NEXT QUESTION IS YOURS.', 0.08, 0.94, 0.026);
    line(0.08, 0.9, 0.92, 0.9);
  } else if (design.form === 'banner') {
    text('02', 0.065, 0.49, 0.27, 400);
    line(0.34, 0.12, 0.34, 0.88);
    title('MAKE IT\nHAPPEN.', 0.39, 0.32, 0.105, 1.04);
    text('把想法变成现实', 0.4, 0.85, 0.038); text('ISBF-One', 0.94, 0.12, 0.025, 500, 'right');
  } else if (design.form === 'graphic') {
    text('03 / CREATE', 0.08, 0.08, 0.03); text('ISBF-One', 0.92, 0.08, 0.03, 500, 'right');
    const points = starShape(w * 0.24).getPoints();
    ctx.beginPath();
    points.forEach((point, i) => {
      const x = w * 0.5 + point.x; const y = h * 0.4 - point.y;
      if (i) ctx.lineTo(x, y); else ctx.moveTo(x, y);
    });
    ctx.closePath(); ctx.lineWidth = 6; ctx.stroke(); ctx.lineWidth = 2;
    title('CREATE\nTOGETHER.', 0.08, 0.76, 0.1, 1.03); text('一起创造', 0.08, 0.95, 0.035);
  } else if (design.form === 'badge') {
    ctx.lineWidth = 5; ctx.beginPath(); ctx.arc(w / 2, h / 2, w * 0.46, 0, Math.PI * 2); ctx.stroke();
    ctx.lineWidth = w * 0.044 + 6; ctx.lineCap = 'round';
    for (const middle of [0, Math.PI]) {
      ctx.beginPath(); ctx.arc(w / 2, h / 2, w * 0.417, middle - Math.PI * 0.22, middle + Math.PI * 0.22); ctx.stroke();
    }
    ctx.lineWidth = 2; ctx.lineCap = 'butt';
    text('ISBF-One / 04', 0.5, 0.2, 0.036, 600, 'center');
    text('FIND YOUR', 0.5, 0.4, 0.125, 800, 'center'); text('PEOPLE.', 0.5, 0.54, 0.15, 800, 'center');
    text('与同路人同行', 0.5, 0.72, 0.051, 500, 'center');
    star(0.5, 0.84, w * 0.03);
  } else if (design.form === 'ticket') {
    text('ISBF-One / JOIN THE JOURNEY', 0.08, 0.14, 0.025, 700);
    title('ADMIT\nONE', 0.07, 0.39, 0.13, 0.88);
    ctx.setLineDash([11, 10]); line(0.72, 0.1, 0.72, 0.9); ctx.setLineDash([]);
    text('05', 0.85, 0.42, 0.12, 400, 'center');
    text('ONE WAY', 0.85, 0.7, 0.025, 600, 'center'); text('下一站，一起向前', 0.08, 0.88, 0.033);
  } else {
    text('06 / TAKE THE NEXT STEP', 0.075, 0.1, 0.029, 600); line(0.075, 0.17, 0.925, 0.17);
    text('每一步，从 ONE 开始', 0.5, 0.85, 0.046, 500, 'center'); text('ISBF-One', 0.5, 0.95, 0.025, 700, 'center');
  }
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.anisotropy = 4;
  return texture;
}

export function createOneLetters(width, height, backingDepth) {
  const group = new THREE.Group();
  const material = [new THREE.MeshBasicMaterial({ color: white, side: THREE.DoubleSide, toneMapped: false }), new THREE.MeshBasicMaterial({ color: '#b6b6b6', side: THREE.DoubleSide, toneMapped: false })];
  const o = new THREE.Shape(); o.absellipse(0.39, 0.55, 0.39, 0.55, 0, Math.PI * 2, false, 0);
  const hole = new THREE.Path(); hole.absellipse(0.39, 0.55, 0.2, 0.35, 0, Math.PI * 2, true, 0); o.holes.push(hole);
  const polygon = (points) => new THREE.Shape(points.map(([x, y]) => new THREE.Vector2(x, y)));
  const n = polygon([[0, 0], [0.18, 0], [0.18, 0.72], [0.68, 0], [0.87, 0], [0.87, 1.1], [0.69, 1.1], [0.69, 0.39], [0.2, 1.1], [0, 1.1]]);
  const e = polygon([[0, 0], [0.72, 0], [0.72, 0.19], [0.2, 0.19], [0.2, 0.48], [0.64, 0.48], [0.64, 0.67], [0.2, 0.67], [0.2, 0.91], [0.72, 0.91], [0.72, 1.1], [0, 1.1]]);
  for (const [shape, x] of [[o, 0], [n, 0.94], [e, 1.97]]) {
    const mesh = new THREE.Mesh(new THREE.ExtrudeGeometry(shape, { depth: 0.12, bevelEnabled: true, bevelSize: 0.012, bevelThickness: 0.012, bevelSegments: 2, curveSegments: 24 }), material);
    mesh.position.x = x; group.add(mesh);
  }
  const scale = width * 0.82 / 2.69;
  group.scale.setScalar(scale);
  // A proportional physical gap survives mobile GPU depth quantization.
  // The bevel also extends backwards, so a tiny constant gap is not enough.
  group.position.set(-width * 0.41, -height * 0.18, backingDepth + width * 0.02);
  return group;
}
