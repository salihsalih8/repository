#!/usr/bin/env python3
"""brain-graph.py — Kuzu embedded knowledge graph for Akatsuki Brain. Usage: build|query|stats|rebuild"""

import kuzu, sys, os, re, shutil
from datetime import datetime

BRAIN_DIR = os.path.dirname(os.path.abspath(__file__))
GRAPH_DIR = os.path.join(BRAIN_DIR, "graph", "kuzu.db")
EVENTS_LOG = os.path.join(BRAIN_DIR, "events.log")

ENTITIES = {"Healspot":"competitor","Ramen Bae":"competitor","immi":"competitor","Power Noods":"competitor","Amazon":"platform","OpenClaw":"platform","Claude Code":"tool","DeepSeek":"model","GitHub":"platform","Kakuzu":"agent","Telegram":"channel","QMD":"tool","Backblaze B2":"service","Kuzu":"tool"}
CONCEPTS = {"hero claim":"brand","avocado oil":"ingredient","seed oils":"ingredient","brain architecture":"system","private-by-default":"system","importance scoring":"system","opus quota":"operation","cache-TTL pruning":"system","memory-wiki":"system","protein ramen":"niche","P0-P3 gating":"system"}
ROLES = {"nagato":"leader","pain":"execution","kakuzu":"finance","deidara":"brand","system":"infrastructure","claude":"reasoning","claude-opus":"reasoning"}

def get_conn():
    db = kuzu.Database(GRAPH_DIR)
    return kuzu.Connection(db)

def build():
    shutil.rmtree(GRAPH_DIR, ignore_errors=True)
    conn = get_conn()
    conn.execute("CREATE NODE TABLE Agent (name STRING, role STRING, PRIMARY KEY (name))")
    conn.execute("CREATE NODE TABLE Event (id SERIAL, date TIMESTAMP, agent STRING, importance INT64, confidence STRING, message STRING, PRIMARY KEY (id))")
    conn.execute("CREATE NODE TABLE Entity (name STRING, etype STRING, PRIMARY KEY (name))")
    conn.execute("CREATE NODE TABLE Concept (name STRING, domain STRING, PRIMARY KEY (name))")
    conn.execute("CREATE REL TABLE CreatedBy (FROM Event TO Agent)")
    conn.execute("CREATE REL TABLE MentionsEntity (FROM Event TO Entity)")
    conn.execute("CREATE REL TABLE MentionsConcept (FROM Event TO Concept)")
    
    if not os.path.exists(EVENTS_LOG):
        print("⚠️  No events.log"); return
    
    with open(EVENTS_LOG) as f:
        raw = f.read()
    
    blocks = [b.strip() for b in raw.split('\n---\n') if b.strip()]
    
    agents = set()
    ev_count = 0
    for block in blocks:
        fm = {}; msg = ""
        mode = "fm"
        for line in block.split('\n'):
            s = line.strip()
            if not s: continue
            if mode == "fm" and ':' in s:
                k, v = s.split(':', 1); k = k.strip()
                if k in ('date','agent','importance','confidence'):
                    fm[k] = v.strip()
                else:
                    mode = "msg"; msg = s
            else:
                mode = "msg"
                if msg: msg += " "
                msg += s
        
        if not msg: msg = f"{fm.get('agent','?')}: {block[:80]}"
        
        agent = fm.get('agent', 'unknown')
        imp = int(fm.get('importance', 2))
        conf = fm.get('confidence', 'medium')
        
        if agent not in agents:
            conn.execute("CREATE (:Agent {name: $n, role: $r})",
                        {"n": agent, "r": ROLES.get(agent, "unknown")})
            agents.add(agent)
        
        conn.execute("CREATE (:Event {date: $d, agent: $a, importance: $i, confidence: $c, message: $m})",
                    {"d": datetime.now(), "a": agent, "i": imp, "c": conf, "m": msg[:500]})
        conn.execute("MATCH (e:Event), (a:Agent {name: $a}) WHERE e.message = $m CREATE (e)-[:CreatedBy]->(a)",
                    {"a": agent, "m": msg[:500]})
        ev_count += 1
        
        msg_l = msg.lower()
        for name, etype in ENTITIES.items():
            if name.lower() in msg_l:
                conn.execute("MERGE (:Entity {name: $n}) SET etype = $t", {"n": name, "t": etype})
        for name, domain in CONCEPTS.items():
            if name.lower() in msg_l:
                conn.execute("MERGE (:Concept {name: $n}) SET domain = $d", {"n": name, "d": domain})
    
    print(f"✅ Graph built: {ev_count} events, {len(agents)} agents")
    stats()

def stats():
    conn = get_conn()
    for t in ["Agent","Event","Entity","Concept"]:
        r = conn.execute(f"MATCH (n:{t}) RETURN COUNT(*)")
        if r.has_next(): print(f"  {t}: {r.get_next()[0]}")
    for rn in ["CreatedBy","MentionsEntity","MentionsConcept"]:
        try:
            r = conn.execute(f"MATCH ()-[n:{rn}]->() RETURN COUNT(*)")
            if r.has_next(): print(f"  {rn}: {r.get_next()[0]}")
        except: pass
    try:
        dbsize = sum(os.path.getsize(os.path.join(GRAPH_DIR, f)) for f in os.listdir(GRAPH_DIR) if os.path.isfile(os.path.join(GRAPH_DIR, f)))
        print(f"  DB size: {dbsize/1024:.0f} KB")
    except: pass

def do_query(q=None):
    conn = get_conn()
    if q:
        r = conn.execute(q)
        while r.has_next(): print(r.get_next())
    else:
        print("=== Agent Activity ===")
        r = conn.execute("MATCH (e:Event) RETURN e.agent, COUNT(*) as c ORDER BY c DESC")
        while r.has_next():
            row = r.get_next(); print(f"  {row[0]}: {row[1]} events")

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "stats"
    if cmd == "build": build()
    elif cmd == "query": do_query(sys.argv[2] if len(sys.argv) > 2 else None)
    elif cmd == "stats": stats()
    elif cmd == "rebuild": build()
    else: print(f"Usage: brain-graph.py [build|query|stats|rebuild]")
