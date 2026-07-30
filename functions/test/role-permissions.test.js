"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  allRoles,
  effectivePermissionsForRoles,
} = require("../role-permissions");

test("all supported school roles are available", () => {
  assert.ok(allRoles.includes("student"));
  assert.ok(allRoles.includes("teacher"));
  assert.ok(allRoles.includes("adminStaff"));
  assert.ok(allRoles.includes("schoolOwner"));
});

test("student receives portal permissions but no management permission", () => {
  const permissions = effectivePermissionsForRoles(["student"]);
  assert.ok(permissions.includes("exams.view"));
  assert.ok(permissions.includes("leave.apply"));
  assert.ok(!permissions.includes("students.manage"));
});

test("teacher and admin defaults include their operational permissions", () => {
  assert.ok(
    effectivePermissionsForRoles(["teacher"]).includes("attendance.mark"),
  );
  assert.ok(
    effectivePermissionsForRoles(["adminStaff"]).includes("users.manage"),
  );
});

test("leadership receives wildcard access", () => {
  assert.deepEqual(effectivePermissionsForRoles(["schoolOwner"]), ["*"]);
});
