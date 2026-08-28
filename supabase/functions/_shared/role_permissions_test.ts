import { validateRoleDelegation } from "./role_permissions.ts";

function expectAllowed(target: string[], actor: string[]) {
  const error = validateRoleDelegation(target, actor);
  if (error !== null) throw new Error(`Expected allowed, got: ${error}`);
}

function expectDenied(target: string[], actor: string[]) {
  const error = validateRoleDelegation(target, actor);
  if (error === null) throw new Error("Expected role delegation to be denied.");
}

Deno.test("Super Admin can assign every role", () => {
  for (const role of [
    "superAdmin", "schoolOwner", "principal", "vicePrincipal", "adminStaff",
    "teacher", "student", "parent",
  ]) expectAllowed([role], ["superAdmin"]);
});

Deno.test("leadership cannot promote at or above its authority", () => {
  expectDenied(["superAdmin"], ["schoolOwner"]);
  expectDenied(["schoolOwner"], ["schoolOwner"]);
  expectDenied(["principal"], ["principal"]);
  expectDenied(["vicePrincipal"], ["vicePrincipal"]);
});

Deno.test("leadership can delegate lower roles", () => {
  expectAllowed(["principal"], ["schoolOwner"]);
  expectAllowed(["vicePrincipal"], ["principal"]);
  expectAllowed(["teacher", "student", "parent"], ["vicePrincipal"]);
});

Deno.test("ordinary administrators cannot assign leadership", () => {
  for (const role of ["superAdmin", "schoolOwner", "principal", "vicePrincipal"]) {
    expectDenied([role], ["adminStaff"]);
  }
  expectDenied(["itAdmin"], ["adminStaff"]);
  expectDenied(["adminStaff"], ["itAdmin"]);
});
