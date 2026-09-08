#!/usr/bin/env python3
# kit-status-parse.py -- parse server.manifest.yml and emit name|type|port lines
# Called by kit-status.sh when python3 is available
import sys, re

manifest_file = sys.argv[1]
with open(manifest_file) as f:
    content = f.read()

blocks = re.split(r'\n  - name:', content)
for block in blocks[1:]:
    lines = ("  - name:" + block).strip().split('\n')
    svc = {}
    for line in lines:
        m = re.match(r'^\s+(\w[\w-]*):\s*(.*)', line)
        if m:
            key = m.group(1).strip()
            val = m.group(2).strip().strip('"')
            if val and val != '~':
                svc[key] = val
    if 'name' in svc:
        stype = svc.get('type', 'docker')
        port  = svc.get('port', '')
        print(f"{svc['name']}|{stype}|{port}")
