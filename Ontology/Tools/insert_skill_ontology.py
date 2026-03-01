"""Neo4j 온톨로지 스킬 관련 작업 내용을 Neo4j에 삽입"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

TS = "2026-03-01T17:57:00"

# ============================================================
# 노드 (4건)
# ============================================================
NODES = [
    # SKILL.md 문서
    f"""
    MERGE (d:Document {{name: 'SKILL_neo4j-ontology.md'}})
    SET d.description = 'Neo4j 그래프 DB 온톨로지 관리 스킬 — 노드 19종/관계 26종 스키마, cypher_cli 사용법, 삽입/조회 패턴 포함',
        d.path = '.gemini/antigravity/skills/neo4j-ontology/SKILL.md',
        d.type = 'skill',
        d.created_at = datetime("{TS}"),
        d.updated_at = datetime("{TS}")
    """,

    # cypher_cli.py (이미 존재할 수 있으므로 MERGE)
    f"""
    MERGE (s:Script {{name: 'cypher_cli.py'}})
    SET s.description = 'Neo4j HTTP API 기반 Cypher 쿼리 실행 엔진 (run_cypher, run_multi_cypher)',
        s.path = 'Ontology/Tools/cypher_cli.py',
        s.updated_at = datetime("{TS}")
    """,

    # 온톨로지 마스터 문서
    f"""
    MERGE (d:Document {{name: 'ontology_graph_db.md'}})
    SET d.description = '프로젝트 온톨로지 기반 그래프 DB 설계 마스터 문서 — 노드 19종, 관계 26종, Mermaid 다이어그램, Cypher 예제',
        d.path = 'Ontology/Docs/ontology_graph_db.md',
        d.updated_at = datetime("{TS}")
    """,

    # 마일스톤
    f"""
    MERGE (ms:Milestone {{name: 'MS_온톨로지_스킬_생성완료'}})
    SET ms.description = 'Neo4j 온톨로지 관리 스킬(SKILL.md) 생성 및 스키마 문서화 완료',
        ms.status = '완료',
        ms.created_at = datetime("{TS}"),
        ms.updated_at = datetime("{TS}")
    """,
]

# ============================================================
# 관계 (5건)
# ============================================================
RELS = [
    # SKILL.md가 cypher_cli.py 사용을 정의
    f"""
    MATCH (a:Document {{name: 'SKILL_neo4j-ontology.md'}})
    MATCH (b:Script {{name: 'cypher_cli.py'}})
    MERGE (a)-[:RESTRICTS {{created_at: datetime("{TS}"), note: '스킬이 도구 사용 규칙을 정의'}}]->(b)
    """,

    # SKILL.md가 ontology_graph_db.md 스키마를 참조
    f"""
    MATCH (a:Document {{name: 'SKILL_neo4j-ontology.md'}})
    MATCH (b:Document {{name: 'ontology_graph_db.md'}})
    MERGE (a)-[:RELATES_TO {{created_at: datetime("{TS}"), note: '스킬이 온톨로지 스키마를 참조'}}]->(b)
    """,

    # 마일스톤 → 스킬 문서
    f"""
    MATCH (a:Milestone {{name: 'MS_온톨로지_스킬_생성완료'}})
    MATCH (b:Document {{name: 'SKILL_neo4j-ontology.md'}})
    MERGE (a)-[:ACHIEVED_BY {{created_at: datetime("{TS}")}}]->(b)
    """,

    # Phase1_DataLake → 마일스톤
    f"""
    MATCH (a:Phase {{name: 'Phase1_DataLake'}})
    MATCH (b:Milestone {{name: 'MS_온톨로지_스킬_생성완료'}})
    MERGE (a)-[:CONTAINS {{created_at: datetime("{TS}")}}]->(b)
    """,

    # GEMINI.md가 스킬을 참조
    f"""
    MATCH (a:Document {{name: 'GEMINI.md'}})
    MATCH (b:Document {{name: 'SKILL_neo4j-ontology.md'}})
    MERGE (a)-[:RELATES_TO {{created_at: datetime("{TS}"), note: 'GEMINI.md의 Neo4j 자동 기록 규칙을 스킬이 구체화'}}]->(b)
    """,
]

# ============================================================
# 실행
# ============================================================
print("=" * 60)
print("  Neo4j 온톨로지 스킬 메타데이터 DB 삽입")
print("=" * 60)

print(f"\n📦 노드 삽입 ({len(NODES)}건)...")
ok_n = 0
for i, q in enumerate(NODES, 1):
    r = run_cypher(q)
    s = "✅" if r["status"] == "OK" else "❌"
    print(f"  {s} 노드 {i}/{len(NODES)}")
    if r["status"] != "OK":
        print(f"     {r.get('errors','')}")
    else:
        ok_n += 1

print(f"\n🔗 관계 삽입 ({len(RELS)}건)...")
ok_r = 0
for i, q in enumerate(RELS, 1):
    r = run_cypher(q)
    s = "✅" if r["status"] == "OK" else "❌"
    print(f"  {s} 관계 {i}/{len(RELS)}")
    if r["status"] != "OK":
        print(f"     {r.get('errors','')}")
    else:
        ok_r += 1

print(f"\n{'=' * 60}")
print(f"  결과: 노드 {ok_n}/{len(NODES)} 성공 | 관계 {ok_r}/{len(RELS)} 성공")
print(f"{'=' * 60}")
