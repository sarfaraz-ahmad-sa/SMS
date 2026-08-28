#!/usr/bin/env python3
"""Static validation that does not require the Flutter SDK."""

from __future__ import annotations

import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def dart_files() -> list[Path]:
    return sorted((ROOT / "lib").rglob("*.dart")) + sorted((ROOT / "test").rglob("*.dart"))


def validate_delimiters(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[tuple[str, int]] = []
    line = 1
    i = 0
    quote: str | None = None
    triple = False
    block_comment = False
    errors: list[str] = []

    while i < len(text):
        char = text[i]
        pair = text[i : i + 2]
        if char == "\n":
            line += 1
        if block_comment:
            if pair == "*/":
                block_comment = False
                i += 2
            else:
                i += 1
            continue
        if quote:
            if triple:
                if text[i : i + 3] == quote * 3:
                    quote = None
                    triple = False
                    i += 3
                else:
                    i += 1
                continue
            if char == "\\":
                i += 2
                continue
            if char == quote:
                quote = None
            i += 1
            continue
        if pair == "//":
            end = text.find("\n", i)
            i = len(text) if end < 0 else end
            continue
        if pair == "/*":
            block_comment = True
            i += 2
            continue
        if char in ("'", '"'):
            if text[i : i + 3] == char * 3:
                quote = char
                triple = True
                i += 3
            else:
                quote = char
                i += 1
            continue
        if char in "([{":
            stack.append((char, line))
        elif char in ")]}":
            if not stack or stack[-1][0] != pairs[char]:
                errors.append(f"{path.relative_to(ROOT)}:{line}: mismatched {char}")
                break
            stack.pop()
        i += 1

    if stack:
        opening, opening_line = stack[-1]
        errors.append(f"{path.relative_to(ROOT)}:{opening_line}: unclosed {opening}")
    return errors


def relative_import_issues(files: list[Path]) -> list[str]:
    issues: list[str] = []
    import_pattern = re.compile(r"^import\s+['\"]([^'\"]+)['\"]", re.MULTILINE)
    for path in files:
        text = path.read_text(encoding="utf-8", errors="ignore")
        for import_path in import_pattern.findall(text):
            if import_path.startswith(("dart:", "package:")):
                continue
            if not (path.parent / import_path).resolve().exists():
                issues.append(f"{path.relative_to(ROOT)} -> {import_path}")
    return issues


def main() -> int:
    files = dart_files()
    delimiter_errors = [error for path in files for error in validate_delimiters(path)]
    import_errors = relative_import_issues(files)

    catalog = (ROOT / "lib/core/erp/erp_catalog.dart").read_text(encoding="utf-8")
    rules = (ROOT / "firestore.rules").read_text(encoding="utf-8")
    permissions_source = (ROOT / "lib/services/models/app_permission.dart").read_text(encoding="utf-8")

    modules = re.findall(r"\bErpModule\s*\(", catalog)
    module_ids = re.findall(
        r"static const ErpModule \w+ = ErpModule\(\s*id:\s*'([^']+)'",
        catalog,
    )
    collections = re.findall(r"\bcollection:\s*'([^']+)'", catalog)
    entitlement_source = (
        ROOT / "lib/services/plan_entitlement_service.dart"
    ).read_text(encoding="utf-8")
    entitlement_ids = set(
        re.findall(
            r"^\s*'([^']+)': SaasFeature\.",
            entitlement_source,
            re.MULTILINE,
        )
    )
    missing_entitlement_ids = sorted(set(module_ids) - entitlement_ids)
    unknown_entitlement_ids = sorted(entitlement_ids - set(module_ids))
    permission_definitions = set(
        re.findall(r"static const String \w+ = '([^']+)'", permissions_source)
    )
    permission_references = set(
        re.findall(r"AppPermission\.\w+", "\n".join(path.read_text(encoding="utf-8", errors="ignore") for path in files))
    )
    missing_rule_collections = sorted({collection for collection in collections if f"'{collection}'" not in rules})

    json_files = [
        ROOT / "firebase.json",
        ROOT / "firestore.indexes.json",
        ROOT / "vercel.json",
        ROOT / "web/manifest.json",
        ROOT / "functions/package.json",
        ROOT / "tools/firebase_admin/package.json",
    ]
    json_errors: list[str] = []
    for path in json_files:
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except Exception as error:  # noqa: BLE001
            json_errors.append(f"{path.relative_to(ROOT)}: {error}")

    node_files = [
        ROOT / "functions/index.js",
        ROOT / "tools/firebase_admin/migrate-flat-collections.mjs",
        ROOT / "tools/firebase_admin/migrate-saas-foundation.mjs",
        ROOT / "tools/firebase_admin/backfill-portal-links.mjs",
        ROOT / "tools/firebase_admin/seed-enterprise-data.mjs",
        ROOT / "tools/firebase_admin/seed-tenant.mjs",
    ]
    node_errors: list[str] = []
    for path in node_files:
        result = subprocess.run(
            ["node", "--check", str(path)],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode:
            node_errors.append(f"{path.relative_to(ROOT)}: {result.stderr.strip()}")

    account_sources = {
        "functions/index.js": (ROOT / "functions/index.js").read_text(encoding="utf-8"),
        "supabase/functions/school-accounts/index.ts": (
            ROOT / "supabase/functions/school-accounts/index.ts"
        ).read_text(encoding="utf-8"),
        "AccountManagement.dart": (ROOT / "lib/Screens/AccountManagement.dart").read_text(encoding="utf-8"),
        "FirstLoginPasswordScreen.dart": (ROOT / "lib/Screens/FirstLoginPasswordScreen.dart").read_text(encoding="utf-8"),
        "firestore.rules": rules,
    }
    account_requirements = {
        "functions/index.js": [
            "exports.provisionSchoolUser",
            "exports.manageSchoolUser",
            "exports.completeInitialPasswordChange",
            "validateTemporaryPassword",
            'recordType === "guardian"',
        ],
        "supabase/functions/school-accounts/index.ts": [
            'new Set(["completePasswordChange", "recordLogin"])',
            'action === "completePasswordChange"',
            "must_change_password: false",
        ],
        "AccountManagement.dart": [
            "AccountSetupMethod.temporaryPassword",
            "_LinkedRecordDropdown",
            "UserRole.parent => 'guardian'",
            "resetTemporaryPassword",
        ],
        "FirstLoginPasswordScreen.dart": [
            "completeInitialPasswordChange",
            "Change password & continue",
            "AuthException",
            "SchoolAccountException",
            "must be different from the temporary password",
        ],
        "firestore.rules": [
            "requiresPersonalScope",
            "validStudentRelation",
            "isRelatedToSignedInUser(tenantId",
        ],
    }
    account_errors = [
        f"{source}: missing {requirement}"
        for source, requirements in account_requirements.items()
        for requirement in requirements
        if requirement not in account_sources[source]
    ]

    dashboard_source = (ROOT / "lib/Screens/home.dart").read_text(
        encoding="utf-8"
    )
    dashboard_errors = []
    if "child: _LiteDashboard(" not in dashboard_source:
        dashboard_errors.append(
            "home.dart: lightweight dashboard is not the active render path"
        )
    if "countWhere('admission_applications'" in dashboard_source:
        dashboard_errors.append(
            "home.dart: admission dashboard fallback performs status-query fan-out"
        )

    vercel_config = json.loads((ROOT / "vercel.json").read_text(encoding="utf-8"))
    vercel_build_command = str(vercel_config.get("buildCommand", ""))
    vercel_build_script = ROOT / "scripts/vercel_build.sh"
    vercel_errors = []
    if len(vercel_build_command) > 256:
        vercel_errors.append(
            "vercel.json: buildCommand exceeds Vercel's 256-character limit"
        )
    if vercel_build_command != "bash scripts/vercel_build.sh":
        vercel_errors.append(
            "vercel.json: buildCommand is not wired to scripts/vercel_build.sh"
        )
    if not vercel_build_script.is_file():
        vercel_errors.append("scripts/vercel_build.sh: missing")
    else:
        vercel_script_source = vercel_build_script.read_text(encoding="utf-8")
        for required in (
            "build web --release",
            "ENABLE_SUPABASE_PRIMARY=true",
            "SUPABASE_URL=",
            "SUPABASE_PUBLISHABLE_KEY=",
            "SUPABASE_AUTH_REDIRECT_URL=",
            'if [[ -n "${SUPABASE_URL:-}" ]]',
            'if [[ -n "${SUPABASE_PUBLISHABLE_KEY:-}" ]]',
        ):
            if required not in vercel_script_source:
                vercel_errors.append(
                    f"scripts/vercel_build.sh: missing {required}"
                )
        for unsafe_override in (
            '--dart-define="SUPABASE_URL=${SUPABASE_URL:-}"',
            '--dart-define="SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY:-}"',
        ):
            if unsafe_override in vercel_script_source:
                vercel_errors.append(
                    "scripts/vercel_build.sh: empty Supabase environment values "
                    "can override bundled public configuration"
                )

    brand_sources = {
        "school_brand.dart": (ROOT / "lib/Widgets/school_brand.dart").read_text(
            encoding="utf-8"
        ),
        "LoginPage.dart": (ROOT / "lib/Screens/LoginPage.dart").read_text(
            encoding="utf-8"
        ),
        "SplashScreen.dart": (ROOT / "lib/Screens/SplashScreen.dart").read_text(
            encoding="utf-8"
        ),
        "MainDrawer.dart": (ROOT / "lib/Widgets/MainDrawer.dart").read_text(
            encoding="utf-8"
        ),
        "web/index.html": (ROOT / "web/index.html").read_text(encoding="utf-8"),
        "web/manifest.json": (ROOT / "web/manifest.json").read_text(
            encoding="utf-8"
        ),
    }
    brand_requirements = {
        "school_brand.dart": [
            "class SchoolBrandMark",
            "class SchoolBrandLockup",
            "logoUrl",
            "class _SeefMarkPainter",
        ],
        "LoginPage.dart": ["SchoolBrandMark", "SchoolBrandLockup"],
        "SplashScreen.dart": ["SchoolBrandMark"],
        "MainDrawer.dart": ["SchoolBrandMark", "state.tenant?.logoUrl"],
        "web/index.html": ["icons/seef-school-logo.svg", "#172554"],
        "web/manifest.json": ["icons/Icon-192.png", "icons/Icon-512.png"],
    }
    brand_errors = [
        f"{source}: missing {requirement}"
        for source, requirements in brand_requirements.items()
        for requirement in requirements
        if requirement not in brand_sources[source]
    ]
    for asset in (
        ROOT / "assets/seef_school_logo.svg",
        ROOT / "assets/seef_school_logo.png",
        ROOT / "web/icons/seef-school-logo.svg",
        ROOT / "web/icons/Icon-192.png",
        ROOT / "web/icons/Icon-512.png",
        ROOT / "web/favicon.png",
    ):
        if not asset.is_file() or asset.stat().st_size == 0:
            brand_errors.append(f"{asset.relative_to(ROOT)}: missing or empty")

    onboarding_sources = {
        "migration": (
            ROOT
            / "supabase/migrations/202608250018_platform_school_onboarding.sql"
        ).read_text(encoding="utf-8"),
        "function": (
            ROOT / "supabase/functions/platform-onboarding/index.ts"
        ).read_text(encoding="utf-8"),
        "service": (
            ROOT / "lib/services/platform_onboarding_service.dart"
        ).read_text(encoding="utf-8"),
        "screen": (
            ROOT / "lib/Screens/Saas/platform_school_onboarding_screen.dart"
        ).read_text(encoding="utf-8"),
        "main": (ROOT / "lib/main.dart").read_text(encoding="utf-8"),
        "drawer": (ROOT / "lib/Widgets/MainDrawer.dart").read_text(
            encoding="utf-8"
        ),
        "login": (ROOT / "lib/Screens/LoginPage.dart").read_text(
            encoding="utf-8"
        ),
        "requests": (ROOT / "lib/Screens/AccessRequests.dart").read_text(
            encoding="utf-8"
        ),
    }
    onboarding_requirements = {
        "migration": [
            "provision_school_tenant",
            "security definer",
            "array['schoolOwner']::text[]",
            "to service_role",
            "from public, anon, authenticated",
            "platform.school.created",
        ],
        "function": [
            '.contains("roles", ["superAdmin"])',
            "Only a platform Super Admin can create schools.",
            "inviteUserByEmail",
            "createUser",
            'admin.rpc(\n      "provision_school_tenant"',
            "deleteUser(createdAuthUserId)",
            "This school code is already in use.",
        ],
        "service": [
            "class PlatformOnboardingService",
            "'platform-onboarding'",
            "OwnerSetupMethod.temporaryPassword",
        ],
        "screen": [
            "UserRole.superAdmin",
            "Create school and owner account",
            "Generate strong password",
            "PlatformOnboardingService",
        ],
        "main": ["'/platform-onboarding'"],
        "drawer": [
            "state.user?.roles.contains(UserRole.superAdmin)",
            "'New School'",
            "'/platform-onboarding'",
        ],
        "login": ["Request a school login ID", "const RequestLogin()"],
        "requests": [
            "Approve and create account",
            "initialDisplayName: request.name",
            "initialEmail: request.email",
        ],
    }
    onboarding_errors = [
        f"{source}: missing {requirement}"
        for source, requirements in onboarding_requirements.items()
        for requirement in requirements
        if requirement not in onboarding_sources[source]
    ]
    hidden_request_pattern = re.compile(
        r"if\s*\(!BackendConfig\.isSupabasePrimary\)\s*\.\.\.<Widget>\["
        r"[\s\S]{0,700}Request a school login ID"
    )
    if hidden_request_pattern.search(onboarding_sources["login"]):
        onboarding_errors.append(
            "LoginPage.dart: access request is hidden in Supabase-primary mode"
        )

    lines = [
        "SEEF School ERP static validation",
        f"UTC: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        f"Dart source/test files: {len(files)}",
        f"Dart lexical/delimiter validation: {'PASS' if not delimiter_errors else 'FAIL'}",
        f"Missing relative imports: {len(import_errors)}",
        f"ERP modules: {len(modules)}",
        f"ERP module IDs: {len(module_ids)} (unique {len(set(module_ids))})",
        f"Entitlement module IDs missing: {missing_entitlement_ids}",
        f"Unknown entitlement module IDs: {unknown_entitlement_ids}",
        f"ERP workflows/collections: {len(collections)} (unique {len(set(collections))})",
        f"Collections missing from rules: {missing_rule_collections}",
        f"Permission definitions: {len(permission_definitions)}",
        f"Permission references found: {len(permission_references)}",
        f"JSON validation: {'PASS' if not json_errors else 'FAIL'}",
        f"Node syntax validation: {'PASS' if not node_errors else 'FAIL'}",
        f"Secure account lifecycle validation: {'PASS' if not account_errors else 'FAIL'}",
        f"Lightweight dashboard validation: {'PASS' if not dashboard_errors else 'FAIL'}",
        f"Vercel deployment validation: {'PASS' if not vercel_errors else 'FAIL'}",
        f"Premium branding validation: {'PASS' if not brand_errors else 'FAIL'}",
        f"Controlled school onboarding validation: {'PASS' if not onboarding_errors else 'FAIL'}",
        "",
        "Flutter SDK validation is separate:",
        "flutter analyze",
        "flutter test",
        "flutter build web --release --no-wasm-dry-run",
    ]

    entitlement_errors = []
    if missing_entitlement_ids or unknown_entitlement_ids:
        entitlement_errors.append(
            "Plan entitlement module IDs do not match the ERP catalog."
        )
    details = (
        delimiter_errors
        + import_errors
        + json_errors
        + node_errors
        + account_errors
        + dashboard_errors
        + vercel_errors
        + brand_errors
        + onboarding_errors
        + entitlement_errors
    )
    if details:
        lines.extend(["", "Failures:", *details])

    output = "\n".join(lines) + "\n"
    (ROOT / "STATIC_VALIDATION.txt").write_text(output, encoding="utf-8")
    print(output, end="")
    return 1 if details or missing_rule_collections else 0


if __name__ == "__main__":
    raise SystemExit(main())
