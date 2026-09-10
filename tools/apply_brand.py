#!/usr/bin/env python3
"""Synchronize public platform labels from the same JSON used by Flutter."""
import html
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def apply(config):
    name = str(config.get('APP_NAME', 'School Workspace')).strip()
    company = str(config.get('COMPANY_NAME', 'Example Academy')).strip()
    if not name or not company or len(name) > 80 or len(company) > 120:
        raise ValueError('Application/company name is empty or too long')
    p = ROOT / 'web/index.html'
    s = p.read_text()
    old_name = json.loads((ROOT / 'web/manifest.json').read_text()).get('name', 'School Workspace')
    match = re.search(r'<meta name="brand-company" content="([^"]*)">', s)
    old_company = html.unescape(match[1]) if match else 'Example Academy'
    s = s.replace(html.escape(old_name), html.escape(name)).replace(html.escape(old_company), html.escape(company))
    marker = '<meta name="brand-company" content="'+html.escape(company, quote=True)+'">'
    if match:
        s = re.sub(r'<meta name="brand-company" content="[^"]*">', lambda _: marker, s)
    else:
        s = s.replace('<head>', '<head>\n  '+marker, 1)
    s = re.sub(r'<title>.*?</title>', lambda _: '<title>'+html.escape(name)+'</title>', s)
    s = re.sub(r'(<meta name="apple-mobile-web-app-title" content=")[^"]*', lambda m: m[1]+html.escape(name, quote=True), s)
    p.write_text(s)
    p = ROOT / 'web/manifest.json'
    data = json.loads(p.read_text()); data.update(name=name, short_name=name)
    p.write_text(json.dumps(data, indent=2)+'\n')
    p = ROOT / 'android/app/src/main/AndroidManifest.xml'
    s = re.sub(r'android:label="[^"]*"', lambda _: 'android:label="'+html.escape(name, quote=True)+'"', p.read_text())
    p.write_text(s)
    p = ROOT / 'ios/Runner/Info.plist'
    s = p.read_text()
    if '<key>CFBundleDisplayName</key>' in s:
        s = re.sub(r'(<key>CFBundleDisplayName</key>\s*<string>).*?</string>',lambda m:m[1]+html.escape(name)+'</string>',s)
    else:
        s = s.replace('<dict>', '<dict>\n\t<key>CFBundleDisplayName</key>\n\t<string>'+html.escape(name)+'</string>',1)
    p.write_text(s)
    print('Updated web, Android and iOS public labels (no backend values printed).')

if __name__ == '__main__':
    apply(json.loads(Path(sys.argv[1]).read_text()))
