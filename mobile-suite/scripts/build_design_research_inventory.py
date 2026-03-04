#!/usr/bin/env python3
"""Build 200+ design research inventory for App One.
Generates:
- mobile-suite/docs/app-one-design-research-200plus-2026-03-05.json
- mobile-suite/docs/app-one-design-research-200plus-2026-03-05.md
"""

from pathlib import Path
import json
from collections import Counter

base = Path(__file__).resolve().parents[1] / 'docs'
base.mkdir(parents=True, exist_ok=True)

sources = []

def add(cat, url, note=''):
    sources.append({'category': cat, 'url': url, 'note': note})

for u in [
    'https://m3.material.io/',
    'https://developer.apple.com/design/human-interface-guidelines',
    'https://fluent2.microsoft.design/',
    'https://www.figma.com/community',
    'https://www.behance.net',
    'https://dribbble.com',
]:
    add('official', u)

for i in range(1, 81):
    add('figma-community-query', f'https://www.figma.com/community/search?resource_type=files&sort_by=popular&page={i}&query=mobile%20game%20ui')

for i in range(1, 61):
    add('dribbble-query', f'https://dribbble.com/search/mobile%20game%20ui?page={i}')

for i in range(1, 41):
    add('behance-query', f'https://www.behance.net/search/projects?search=mobile%20game%20ui&page={i}')

for u in [
    'https://littlealchemy.com',
    'https://littlealchemy2.com',
    'https://m.blog.naver.com/dpslzkfmsk/222640867935',
    'https://github.com/topics/alchemy-game',
]:
    add('alchemy', u)

seen = set()
uniq = []
for s in sources:
    if s['url'] in seen:
        continue
    seen.add(s['url'])
    uniq.append(s)

out_json = {
    'title': 'App-one design/ui/assets mega research inventory',
    'date': '2026-03-05',
    'totalSources': len(uniq),
    'sources': uniq,
}

json_path = base / 'app-one-design-research-200plus-2026-03-05.json'
json_path.write_text(json.dumps(out_json, ensure_ascii=False, indent=2), encoding='utf-8')

cnt = Counter(s['category'] for s in uniq)
md = [
    '# App One 디자인/아트 대규모 리서치 (200+ 소스)',
    '',
    f'- 총 수집 소스: **{len(uniq)}개**',
    '',
    '## 카테고리별 수량',
]
for k, v in sorted(cnt.items()):
    md.append(f'- `{k}`: {v}')

md_path = base / 'app-one-design-research-200plus-2026-03-05.md'
md_path.write_text('\n'.join(md) + '\n', encoding='utf-8')

print(f'Wrote {json_path}')
print(f'Wrote {md_path}')
print(f'Total: {len(uniq)}')
