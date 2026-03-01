"""
Project Scanner & Neo4j Importer (Batch Version)
==================================================
배치 트랜잭션으로 묶어서 한 번에 250개씩 Neo4j에 전송합니다.
"""

import os
import sys
import json
import base64
import urllib.request
from datetime import datetime, timezone, timedelta

ROOT = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5"
KST = timezone(timedelta(hours=9))

NEO4J_HTTP_URI = "http://127.0.0.1:7474/db/neo4j/tx/commit"
NEO4J_USER = "neo4j"
NEO4J_PASSWORD = "KIM10507"

def batch_cypher(queries, batch_size=250):
    """Execute Cypher queries in batches via HTTP Transaction API."""
    auth_str = f"{NEO4J_USER}:{NEO4J_PASSWORD}".encode("utf-8")
    headers = {
        "Authorization": "Basic " + base64.b64encode(auth_str).decode("utf-8"),
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    total_ok = 0
    total_err = 0
    for i in range(0, len(queries), batch_size):
        batch = queries[i:i+batch_size]
        payload = {"statements": [{"statement": q} for q in batch]}
        req = urllib.request.Request(
            NEO4J_HTTP_URI,
            data=json.dumps(payload).encode("utf-8"),
            headers=headers
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                resp = json.loads(response.read().decode("utf-8"))
                if resp.get("errors"):
                    total_err += len(resp["errors"])
                    for e in resp["errors"][:3]:
                        print(f"    ❌ {e.get('message','')[:80]}")
                else:
                    total_ok += len(batch)
        except Exception as e:
            total_err += len(batch)
            print(f"    ❌ Batch {i//batch_size+1} failed: {str(e)[:60]}")
    return total_ok, total_err

def single_cypher(query):
    auth_str = f"{NEO4J_USER}:{NEO4J_PASSWORD}".encode("utf-8")
    headers = {
        "Authorization": "Basic " + base64.b64encode(auth_str).decode("utf-8"),
        "Content-Type": "application/json", "Accept": "application/json"
    }
    payload = {"statements": [{"statement": query}]}
    req = urllib.request.Request(NEO4J_HTTP_URI, data=json.dumps(payload).encode("utf-8"), headers=headers)
    with urllib.request.urlopen(req, timeout=10) as response:
        return json.loads(response.read().decode("utf-8"))

# ==============================================================
SKIP_DIRS = {".git", "__pycache__", "node_modules", ".venv", "Logs", "Tester",
             "Bases", "History", "mcp-metatrader5-server", ".gemini", ".agent",
             "_agents", "Presets"}
SKIP_EXTS = {".log", ".dat", ".bak", ".tmp", ".ini", ".bin", ".raw", ".svg",
             ".png", ".jpg", ".jpeg", ".gif", ".ico", ".woff", ".woff2", ".ttf",
             ".lock", ".toml", ".cfg", ".yml", ".yaml", ".json", ".html", ".css",
             ".js", ".map", ".d.ts", ".ex5", ".ex4", ".pyc"}

def get_mtime_iso(filepath):
    ts = os.path.getmtime(filepath)
    dt = datetime.fromtimestamp(ts, tz=KST)
    return dt.strftime("%Y-%m-%dT%H:%M:%S")

def classify_file(rel_path, filename, ext):
    rel_lower = rel_path.lower().replace("\\", "/")
    if ext == ".mq5" and "expert" in rel_lower:
        return "ExpertAdvisor"
    if ext == ".mqh" and "include" in rel_lower:
        return "FrameworkModule"
    if ext == ".mq5" and "indicator" in rel_lower:
        return "Indicator"
    if ext == ".py" and "ontology" not in rel_lower:
        return "Script"
    if ext in (".parquet",) and "files" in rel_lower:
        return "DataArtifact"
    if ext == ".csv" and "files" in rel_lower:
        return "DataArtifact"
    if ext == ".md" and ("docs" in rel_lower or "ontology" in rel_lower):
        return "Document"
    if ext == ".md" and ("workflow" in rel_lower or ".agent" in rel_lower):
        return "Workflow"
    return None

def infer_tier(rel_path):
    r = rel_path.lower().replace("\\", "/")
    if "/raw/" in r: return "Tier1_Raw"
    if "/processed/" in r: return "Tier2_Processed"
    if "/vectordb/" in r: return "Tier4_VectorDB"
    return None

# ==============================================================
print("=" * 60)
print("  프로젝트 폴더 스캔 & Neo4j 일괄 임포트 (Batch)")
print("=" * 60)

node_queries = []
rel_queries = []

seen_names = {}  # (label, name) -> True (중복 방지)
csv_count = 0

for dirpath, dirs, files in os.walk(ROOT):
    dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
    for f in files:
        ext = os.path.splitext(f)[1].lower()
        if ext in SKIP_EXTS:
            continue
        filepath = os.path.join(dirpath, f)
        rel_path = os.path.relpath(filepath, ROOT)
        
        label = classify_file(rel_path, f, ext)
        if not label:
            continue
        
        # CSV 수 제한 (raw 폴더 대량)
        if ext == ".csv":
            csv_count += 1
            if csv_count > 10:
                continue
        
        name = f.replace("'", "\\'")
        key = (label, name)
        if key in seen_names:
            continue
        seen_names[key] = True
        
        mtime = get_mtime_iso(filepath)
        path_safe = rel_path.replace("\\", "/").replace("'", "\\'")
        
        q = f"MERGE (n:{label} {{name: '{name}'}}) "
        q += f"SET n.path = '{path_safe}', "
        q += f'n.created_at = datetime("{mtime}"), '
        q += f'n.updated_at = datetime("{mtime}")'
        
        tier = infer_tier(rel_path) if label == "DataArtifact" else None
        if tier:
            q += f", n.tier = '{tier}'"
        
        node_queries.append(q)
        
        # DataArtifact → DataLayer
        if tier:
            rel_queries.append(
                f"MATCH (a:DataArtifact {{name: '{name}'}}), (b:DataLayer {{name: '{tier}'}}) "
                f"MERGE (a)-[:STORED_IN]->(b)"
            )

# EA → Module (INCLUDES)
ea_set = {n for (l, n) in seen_names if l == "ExpertAdvisor"}
mod_set = {n for (l, n) in seen_names if l == "FrameworkModule"}
for ea in ea_set:
    for mod in mod_set:
        for ver in ["V9", "V8", "V7", "Vx"]:
            if ver.lower() in ea.lower() and ver.lower() in mod.lower():
                rel_queries.append(
                    f"MATCH (a:ExpertAdvisor {{name: '{ea}'}}), (b:FrameworkModule {{name: '{mod}'}}) "
                    f"MERGE (a)-[:INCLUDES]->(b)"
                )
                break

# Workflow → Script (TRIGGERS)
for wf, scripts in {
    "data-build": ["build_tech_derived.py", "build_labels_barrier.py", "merge_features.py"],
    "data-fetch": ["fetch_macro_data.py", "fetch_fred_data.py"],
}.items():
    for sc in scripts:
        if ("Script", sc) in seen_names:
            rel_queries.append(
                f"MATCH (a:Workflow {{name: '{wf}'}}), (b:Script {{name: '{sc}'}}) "
                f"MERGE (a)-[:TRIGGERS]->(b)"
            )

# Script → DataArtifact (PRODUCES)
for sc, arts in {
    "build_data_lake.py": ["macro_features.parquet"],
    "build_tech_derived.py": ["tech_features_derived.parquet"],
    "build_labels_barrier.py": ["labels_barrier.parquet"],
    "merge_features.py": ["AI_Study_Dataset.parquet"],
}.items():
    for art in arts:
        if ("DataArtifact", art) in seen_names and ("Script", sc) in seen_names:
            rel_queries.append(
                f"MATCH (a:Script {{name: '{sc}'}}), (b:DataArtifact {{name: '{art}'}}) "
                f"MERGE (a)-[:PRODUCES]->(b)"
            )

# DataLayer 보장
for tier in ["Tier1_Raw", "Tier2_Processed", "Tier3_Labeled", "Tier4_VectorDB"]:
    node_queries.insert(0, f"MERGE (n:DataLayer {{name: '{tier}'}})")

# ==============================================================
by_label = {}
for (l, n) in seen_names:
    by_label[l] = by_label.get(l, 0) + 1
print(f"\n📊 발견된 엔티티: {len(seen_names)}개 (중복 제거)")
for l, c in sorted(by_label.items(), key=lambda x: -x[1]):
    print(f"  {l:25s} {c}개")
print(f"🔗 유추된 관계: {len(rel_queries)}개")

print(f"\n[STEP 1] 노드 배치 삽입 ({len(node_queries)}건, 250건/배치)...")
ok1, err1 = batch_cypher(node_queries)
print(f"  ✅ 성공: {ok1} | ❌ 실패: {err1}")

print(f"\n[STEP 2] 관계 배치 삽입 ({len(rel_queries)}건)...")
ok2, err2 = batch_cypher(rel_queries)
print(f"  ✅ 성공: {ok2} | ❌ 실패: {err2}")

# 최종 통계
resp = single_cypher("MATCH (n) RETURN labels(n)[0] AS L, count(n) AS C ORDER BY C DESC")
print(f"\n{'='*60}")
print("  📊 최종 DB 통계")
print(f"{'='*60}")
for row in resp.get("results",[{}])[0].get("data",[]):
    print(f"  {row['row'][0]:25s} {row['row'][1]}개")

resp2 = single_cypher("MATCH ()-[r]->() RETURN type(r) AS R, count(r) AS C ORDER BY C DESC")
print(f"\n🔗 관계:")
for row in resp2.get("results",[{}])[0].get("data",[]):
    print(f"  {row['row'][0]:25s} {row['row'][1]}개")

print(f"\n🎉 완료!")
