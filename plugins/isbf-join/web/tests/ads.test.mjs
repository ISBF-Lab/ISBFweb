import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from 'three';
import { adDesigns, createAdShape, badgeRotationAt, badgeOrientationAt, createOneLetters } from '../src/ads.js';

function board(form) {
  const shape = createAdShape(1, 1, form);
  const group = new THREE.Group();
  const material = new THREE.MeshBasicMaterial({ side: THREE.DoubleSide });
  const back = new THREE.Mesh(new THREE.ExtrudeGeometry(shape, { depth: 0.025, bevelEnabled: false, curveSegments: 48 }), material);
  const print = new THREE.Mesh(new THREE.ShapeGeometry(shape, 48), material);
  print.position.z = 0.029;
  group.add(back, print);
  group.updateMatrixWorld(true);
  const ray = new THREE.Raycaster();
  return {
    shape,
    hits(x, y) { ray.set(new THREE.Vector3(x, y, 1), new THREE.Vector3(0, 0, -1)); return ray.intersectObject(group, true).length; },
    dispose() { back.geometry.dispose(); print.geometry.dispose(); material.dispose(); },
  };
}

test('only the graphic and round side boards have cut-through apertures', () => {
  assert.equal(adDesigns.length, 6);
  const holes = adDesigns.map(({ form }) => createAdShape(1, 1, form).holes.length);
  assert.deepEqual(holes, [0, 0, 1, 2, 0, 0]);
});

test('the star is a real hole through both the face and extruded back', () => {
  const model = board('graphic');
  try {
    assert.equal(model.hits(0, 0.1), 0);
    assert.equal(model.hits(0.15, 0.1), 0);
    assert.ok(model.hits(0, -0.32) > 0, 'The title area must remain solid.');
  } finally { model.dispose(); }
});

test('round slots pass through while preserving the round frame and text area', () => {
  const model = board('badge');
  try {
    assert.equal(model.hits(0.417, 0), 0);
    assert.equal(model.hits(-0.417, 0), 0);
    assert.ok(model.hits(0, 0) > 0);
    assert.ok(model.hits(0.475, 0) > 0);
  } finally { model.dispose(); }
});

test('round board rotation is deterministic, scroll-driven and reversible', () => {
  assert.equal(badgeRotationAt(0), 0);
  assert.equal(badgeRotationAt(0.085), 0);
  const forward = badgeRotationAt(0.5);
  assert.ok(forward > badgeRotationAt(0.3));
  assert.equal(badgeRotationAt(0.5), forward, 'Idle time must not change the angle.');
  assert.equal(badgeRotationAt(0.86), Math.PI * 2);
  assert.equal(badgeRotationAt(1), Math.PI * 2);
  assert.equal(badgeRotationAt(0), 0, 'Returning to the start must reset the angle.');
});

test('the round board turns about the ground-normal Y axis, not its face normal', () => {
  const original = new THREE.Quaternion().setFromEuler(new THREE.Euler(0.3, 0.2, -0.1));
  const turned = badgeOrientationAt(0.5, original);
  const delta = turned.clone().multiply(original.clone().invert());
  assert.ok(Math.abs(delta.x) < 1e-12);
  assert.ok(Math.abs(delta.z) < 1e-12);
  assert.ok(Math.abs(delta.y) > 0.1);
  const point = new THREE.Vector3(0.4, 0.7, 0.2);
  assert.ok(Math.abs(point.clone().applyQuaternion(original).y - point.clone().applyQuaternion(turned).y) < 1e-12);
  assert.ok(badgeOrientationAt(0, original).angleTo(original) < 1e-7);
});

test('the extruded ONE including its bevel stays clear of its backing face', () => {
  for (const width of [0.8, 3, 10]) {
    const faceDepth = 0.04;
    const letters = createOneLetters(width, width / 1.25, faceDepth);
    const box = new THREE.Box3().setFromObject(letters);
    assert.ok(box.min.z > faceDepth + width * 0.015);
    letters.traverse((object) => { if (object.isMesh) object.geometry.dispose(); });
    letters.children[0].material.forEach((material) => material.dispose());
  }
});
