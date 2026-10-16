import assert from "node:assert/strict";
import test from "node:test";
import { validateApplication } from "../shared/application.js";

const validFields = {
  name: "申请人",
  studentId: "2026101401",
  phone: "+86 138-0013-8000",
};

test("normalizes browser whitespace without changing contact field names", () => {
  const result = validateApplication({
    name: "\uFEFF 申请人\u00a0",
    studentId: " 2026101401 ",
    phone: " +86 138-0013-8000 ",
  });
  assert.equal(result.valid, true);
  assert.deepEqual(result.fields, validFields);
  assert.deepEqual(result.errors, {});
});

test("text limits count UTF-16 code units, including supplementary characters", () => {
  assert.equal(
    validateApplication({
      ...validFields,
      name: "😀".repeat(30),
      studentId: "😀".repeat(20),
    }).valid,
    true
  );
  assert.deepEqual(
    Object.keys(
      validateApplication({
        ...validFields,
        name: "😀".repeat(31),
        studentId: "😀".repeat(21),
      }).errors
    ),
    ["name", "studentId"]
  );
});

test("rejects non-string values and internal control characters", () => {
  for (const value of [
    null,
    123,
    true,
    [],
    {},
    "12\u000034",
    "12\n34",
    "12\u007f34",
  ]) {
    const result = validateApplication({
      name: value,
      studentId: value,
      phone: value,
    });
    assert.equal(result.valid, false);
    assert.deepEqual(Object.keys(result.errors), [
      "name",
      "studentId",
      "phone",
    ]);
  }
  assert.deepEqual(Object.keys(validateApplication(null).errors), [
    "name",
    "studentId",
    "phone",
  ]);
});

test("accepts international phone formatting and enforces digit and total length limits", () => {
  for (const phone of ["1234567", "+86 (138) 0013-8000", "+123456789012345"]) {
    assert.equal(
      validateApplication({ ...validFields, phone }).valid,
      true,
      phone
    );
  }
  for (const phone of [
    "123456",
    "1234567890123456",
    "1234567#",
    `1${" ".repeat(24)}234567`,
  ]) {
    assert.deepEqual(
      Object.keys(validateApplication({ ...validFields, phone }).errors),
      ["phone"]
    );
  }
});
