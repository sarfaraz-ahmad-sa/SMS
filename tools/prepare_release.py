#!/usr/bin/env python3
"""Create a local screened source candidate; never upload or deploy.

Allowlisted source only. Unknown art is withheld. Scan reports locations,
never matched values. This is a heuristic safety gate, not a rights certificate.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = set('README.md INSTALLATION.md WHITE_LABEL_GUIDE.md DEMO_ACCOUNTS.md FEATURES.md CHANGELOG.md KNOWN_ISSUES.md COMMERCIAL_LICENSE_DRAFT.md THIRD_PARTY_REVIEW.md AUDIT_BEFORE_CHANGES.md SALE_READINESS_REPORT.md TEST_RESULTS.md FILE_CHANGES.md'.split())
ROOT_FILES = DOCS | set('LICENSE pubspec.yaml pubspec.lock analysis_options.yaml .gitignore .env.example firebase.json firestore.rules firestore.indexes.json storage.rules vercel.json start-demo.cmd repair-android-wrapper.cmd'.split())
CODE_DIRS = {'lib','test','supabase','functions','android','ios','web','scripts','config'}
TEXT_SUFFIXES = {'.dart','.sql','.ts','.js','.json','.yaml','.gradle','.properties','.xml','.kt','.swift','.plist','.xcconfig','.pbxproj','.xcscheme','.xcworkspacedata','.xcsettings','.storyboard','.h','.sh','.md','.txt','.rules','.py','.cmd','.mjs'}
BLOCK_PARTS = {'.git','.vercel','.dart_tool','node_modules','build','Pods','.symlinks','ephemeral','.temp','.branches'}
PATTERNS = {
    'private key': re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    'credential token': re.compile(r'(?:sb_secret_|sb_publishable_|AIza|ghp_|github_pat_|sk_live_)[A-Za-z0-9_.-]{20,}'),
    'JWT literal': re.compile(r'eyJhbGci[A-Za-z0-9_.-]{35,}'),
    'backend endpoint': re.compile(r'https://(?!your-project-ref)[a-z0-9-]+\.supabase\.co'),
    'database credentials': re.compile(r'postgres(?:ql)?://[^\s/]+:[^\s@]+@'),
}

def files():
    if (ROOT / '.git').exists():
        raw = subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z'],cwd=ROOT)
        return sorted(set(x.decode() for x in raw.split(b'\0') if x))
    result=[]
    for base, dirs, names in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in BLOCK_PARTS and d != 'release' and not (Path(base)/d).is_symlink()]
        result.extend(str((Path(base)/n).relative_to(ROOT)) for n in names)
    return sorted(result)

def allowed(name):
    p=Path(name)
    if any(x in BLOCK_PARTS for x in p.parts): return False
    if p.name in {'GoogleService-Info.plist','google-services.json','local.properties','key.properties','.DS_Store'}: return False
    if name.startswith('config/') and not name.endswith('.example.json'): return False
    if name in {'assets/school-mark.svg', 'web/icons/school-mark.svg'}: return True
    if name in ROOT_FILES: return True
    if name in {'tools/apply_brand.py','tools/prepare_release.py','tools/test_prepare_release.py','tools/validate_project.py'}: return True
    return p.parts[0] in CODE_DIRS and (p.suffix in TEXT_SUFFIXES or p.name in {'Podfile','Podfile.lock','gradlew','gradlew.bat'})

def main():
    candidates=[n for n in files() if allowed(n) and (ROOT/n).is_file() and not (ROOT/n).is_symlink()]
    issues=[]
    for name in candidates:
        for line_no,line in enumerate((ROOT/name).read_text(errors='replace').splitlines(),1):
            for kind,pat in PATTERNS.items():
                if pat.search(line): issues.append({'file':name,'line':line_no,'category':kind})
    print(json.dumps({'scanned_files':len(candidates),'findings':issues},indent=2))
    if issues: return 1
    if '--scan-only' in sys.argv: return 0
    out=ROOT/'release';out.mkdir(exist_ok=True)
    archive=out/'school-workspace-screened-candidate.zip'
    if archive.exists():
        print('Candidate already exists; use a new output name or explicitly remove the old candidate after review.')
        return 1
    manifest=[]
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for name in candidates:
            data=(ROOT/name).read_bytes();z.writestr(name,data)
            manifest.append({'file':name,'sha256':hashlib.sha256(data).hexdigest()})
        z.writestr('CANDIDATE_NOTICE.txt','NOT APPROVED FOR SALE. Original artwork/binary assets withheld pending rights review. Supply licensed icons, splash art and any referenced assets before building. Read KNOWN_ISSUES.md. No Git history, customer exports or dependency trees included.\n')
        z.writestr('PACKAGE_MANIFEST.json',json.dumps(manifest,indent=2))
    (out/'PACKAGE_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('Created local screened candidate:',archive.name,'files:',len(manifest))
    return 0

if __name__=='__main__':sys.exit(main())
