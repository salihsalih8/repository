#!/usr/bin/env python3
"""brain-recall.py — Per-entry quarantine-aware passive recall filter.
Used by brain-load.sh to surface importance=5 events respecting quarantine."""

import sys, re
from datetime import datetime


def parse_events(text):
    """Parse events.log into list of {frontmatter dict, message}."""
    entries = []
    raw_entries = re.split(r'\n\n+', text.strip())
    
    for entry in raw_entries:
        entry = entry.strip()
        if not entry:
            continue
        if entry.startswith('---'):
            entry = entry[3:].strip()
        if entry.endswith('---'):
            entry = entry[:-3].strip()
        
        parts = re.split(r'\n---\s*\n', entry, maxsplit=1)
        fm_block = parts[0]
        message = parts[1].strip() if len(parts) > 1 else ''
        
        fm = {}
        for line in fm_block.split('\n'):
            line = line.strip()
            if not line or ':' not in line:
                continue
            k, v = line.split(':', 1)
            k = k.strip()
            if k in ('date', 'agent', 'importance', 'confidence', 'quarantine_until'):
                fm[k] = v.strip()
        
        fm['_message'] = message if message else f"({fm.get('agent', '?')} event)"
        entries.append(fm)
    
    return entries


def main():
    events_log = sys.argv[1] if len(sys.argv) > 1 else "events.log"
    try:
        with open(events_log, 'r') as f:
            text = f.read()
    except FileNotFoundError:
        return

    entries = parse_events(text)
    now = datetime.now().timestamp()

    for fm in entries:
        try:
            importance = int(fm.get('importance', 0))
        except ValueError:
            continue
        if importance != 5:
            continue

        confidence = fm.get('confidence', 'medium')
        quarantine_until = fm.get('quarantine_until')

        if confidence != 'high' and quarantine_until:
            try:
                qt = datetime.strptime(quarantine_until, '%Y-%m-%d %H:%M EDT')
                qt_epoch = qt.timestamp()  # naive datetime timestamp = local timezone
                if qt_epoch > now:
                    continue  # still in quarantine
            except ValueError:
                pass  # unparseable — surface it

        print(fm['_message'])


if __name__ == '__main__':
    main()
