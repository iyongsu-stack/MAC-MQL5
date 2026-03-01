"""Dukascopy XAUUSD M1 데이터 다운로드 작업 내용을 Neo4j에 삽입 (노드 7건 + 관계 8건)"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

TS = "2026-03-01T17:40:00"

# ============================================================
# 1. 노드 삽입 (7건)
# ============================================================
NODES = [
    # Scripts (3건)
    """
    MERGE (s:Script {name: 'fetch_dukascopy_data.py'})
    SET s.description = 'Dukascopy XAUUSD M1 데이터 다운로더 (curl.exe 기반, 틱→M1 변환)',
        s.path = 'Files/Tools/fetch_dukascopy_data.py',
        s.created_at = datetime("%(ts)s"),
        s.updated_at = datetime("%(ts)s")
    """ % {"ts": TS},
    """
    MERGE (s:Script {name: 'download_duka_all_years.py'})
    SET s.description = '2003~현재 연도별 배치 다운로드 + 이어받기(Resume) 기능',
        s.path = 'Files/Tools/download_duka_all_years.py',
        s.created_at = datetime("%(ts)s"),
        s.updated_at = datetime("%(ts)s")
    """ % {"ts": TS},
    """
    MERGE (s:Script {name: 'verify_duka_all.py'})
    SET s.description = 'Dukascopy Parquet 일괄 무결성 검증 (컬럼/NaN/가격범위 체크)',
        s.path = 'Files/Tools/verify_duka_all.py',
        s.created_at = datetime("%(ts)s"),
        s.updated_at = datetime("%(ts)s")
    """ % {"ts": TS},

    # DataArtifact (1건)
    """
    MERGE (d:DataArtifact {name: 'XAUUSD_M1_Dukascopy'})
    SET d.description = 'Dukascopy 틱 데이터 기반 XAUUSD M1 OHLCV (2003-05-05~현재)',
        d.format = 'parquet+csv',
        d.source = 'Dukascopy Bank SA',
        d.path = 'Files/raw/dukascopy/',
        d.created_at = datetime("%(ts)s"),
        d.updated_at = datetime("%(ts)s")
    """ % {"ts": TS},

    # Workflow (1건)
    """
    MERGE (w:Workflow {name: 'duka-fetch'})
    SET w.description = 'Dukascopy M1 데이터 수집 워크플로우',
        w.path = '.agent/workflows/duka-fetch.md',
        w.created_at = datetime("%(ts)s"),
        w.updated_at = datetime("%(ts)s")
    """ % {"ts": TS},

    # MacroSymbol (1건)
    """
    MERGE (m:MacroSymbol {name: 'XAUUSD_Dukascopy'})
    SET m.description = 'Dukascopy Bank SA 제공 XAUUSD 틱/M1 데이터 (2003~)',
        m.provider = 'Dukascopy',
        m.created_at = datetime("%(ts)s"),
        m.updated_at = datetime("%(ts)s")
    """ % {"ts": TS},

    # Milestone (1건)
    """
    MERGE (ms:Milestone {name: 'MS_Dukascopy_M1_수집완료'})
    SET ms.description = 'Dukascopy M1 전체 기간 다운로드 및 무결성 검증 완료',
        ms.status = '진행중',
        ms.created_at = datetime("%(ts)s"),
        ms.updated_at = datetime("%(ts)s")
    """ % {"ts": TS},
]

# ============================================================
# 2. 관계 삽입 (8건)
# ============================================================
RELS = [
    # download_duka_all_years.py -[TRIGGERS]-> fetch_dukascopy_data.py
    """
    MATCH (a:Script {name: 'download_duka_all_years.py'})
    MATCH (b:Script {name: 'fetch_dukascopy_data.py'})
    MERGE (a)-[:TRIGGERS {created_at: datetime("%(ts)s")}]->(b)
    """ % {"ts": TS},

    # fetch_dukascopy_data.py -[PRODUCES]-> XAUUSD_M1_Dukascopy
    """
    MATCH (a:Script {name: 'fetch_dukascopy_data.py'})
    MATCH (b:DataArtifact {name: 'XAUUSD_M1_Dukascopy'})
    MERGE (a)-[:PRODUCES {created_at: datetime("%(ts)s")}]->(b)
    """ % {"ts": TS},

    # verify_duka_all.py -[CONSUMES]-> XAUUSD_M1_Dukascopy
    """
    MATCH (a:Script {name: 'verify_duka_all.py'})
    MATCH (b:DataArtifact {name: 'XAUUSD_M1_Dukascopy'})
    MERGE (a)-[:CONSUMES {created_at: datetime("%(ts)s")}]->(b)
    """ % {"ts": TS},

    # XAUUSD_M1_Dukascopy -[STORED_IN]-> Tier1_Raw
    """
    MATCH (a:DataArtifact {name: 'XAUUSD_M1_Dukascopy'})
    MATCH (b:DataLayer {name: 'Tier1_Raw'})
    MERGE (a)-[:STORED_IN {created_at: datetime("%(ts)s")}]->(b)
    """ % {"ts": TS},

    # XAUUSD_Dukascopy -[FEEDS]-> XAUUSD_M1_Dukascopy
    """
    MATCH (a:MacroSymbol {name: 'XAUUSD_Dukascopy'})
    MATCH (b:DataArtifact {name: 'XAUUSD_M1_Dukascopy'})
    MERGE (a)-[:FEEDS {created_at: datetime("%(ts)s")}]->(b)
    """ % {"ts": TS},

    # duka-fetch -[TRIGGERS]-> download_duka_all_years.py
    """
    MATCH (a:Workflow {name: 'duka-fetch'})
    MATCH (b:Script {name: 'download_duka_all_years.py'})
    MERGE (a)-[:TRIGGERS {created_at: datetime("%(ts)s")}]->(b)
    """ % {"ts": TS},

    # MS_Dukascopy_M1_수집완료 -[ACHIEVED_BY]-> XAUUSD_M1_Dukascopy
    """
    MATCH (a:Milestone {name: 'MS_Dukascopy_M1_수집완료'})
    MATCH (b:DataArtifact {name: 'XAUUSD_M1_Dukascopy'})
    MERGE (a)-[:ACHIEVED_BY {created_at: datetime("%(ts)s")}]->(b)
    """ % {"ts": TS},

    # Phase1_DataLake -[CONTAINS]-> MS_Dukascopy_M1_수집완료
    """
    MATCH (a:Phase {name: 'Phase1_DataLake'})
    MATCH (b:Milestone {name: 'MS_Dukascopy_M1_수집완료'})
    MERGE (a)-[:CONTAINS {created_at: datetime("%(ts)s")}]->(b)
    """ % {"ts": TS},
]

# ============================================================
# 실행
# ============================================================
print("=" * 60)
print("  Dukascopy 작업 내용 Neo4j DB 삽입")
print("=" * 60)

# 노드 삽입
print(f"\n📦 노드 삽입 ({len(NODES)}건)...")
ok_n = 0
for i, q in enumerate(NODES, 1):
    r = run_cypher(q)
    s = "✅" if r["status"] == "OK" else "❌"
    print(f"  {s} 노드 {i}/{len(NODES)}")
    if r["status"] == "OK":
        ok_n += 1
    else:
        print(f"     {r.get('errors','')}")

# 관계 삽입
print(f"\n🔗 관계 삽입 ({len(RELS)}건)...")
ok_r = 0
for i, q in enumerate(RELS, 1):
    r = run_cypher(q)
    s = "✅" if r["status"] == "OK" else "❌"
    print(f"  {s} 관계 {i}/{len(RELS)}")
    if r["status"] == "OK":
        ok_r += 1
    else:
        print(f"     {r.get('errors','')}")

print(f"\n{'=' * 60}")
print(f"  결과: 노드 {ok_n}/{len(NODES)} 성공 | 관계 {ok_r}/{len(RELS)} 성공")
print(f"{'=' * 60}")
