"""Dukascopy 관련 노드 & 관계를 Neo4j에서 조회"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

QUERY = """
MATCH (n)
WHERE n.name CONTAINS 'duka' OR n.name CONTAINS 'Duka'
   OR n.name CONTAINS 'XAUUSD_Duka' OR n.name CONTAINS 'MS_Duka'
OPTIONAL MATCH (n)-[r]-(m)
RETURN labels(n)[0] AS label, n.name AS name, n.description AS description,
       n.created_at AS created_at,
       type(r) AS rel_type,
       CASE WHEN startNode(r) = n THEN '-->' ELSE '<--' END AS direction,
       labels(m)[0] AS related_label, m.name AS related_name
ORDER BY n.name, rel_type
"""

r = run_cypher(QUERY)

if r["status"] != "OK":
    print(f"❌ 쿼리 실패: {r.get('errors','')}")
    sys.exit(1)

rows = r.get("results", [])

print("=" * 70)
print("  📊 Dukascopy 관련 Neo4j DB 조회 결과")
print("=" * 70)

if not rows:
    print("\n  ⚠ 조회 결과가 없습니다.")
else:
    current_node = None
    for row in rows:
        label = row.get("label", "")
        name = row.get("name", "")
        desc = row.get("description", "")
        created = row.get("created_at", "")
        rel_type = row.get("rel_type")
        direction = row.get("direction", "")
        rel_label = row.get("related_label", "")
        rel_name = row.get("related_name", "")
        
        node_key = f"{label}:{name}"
        if node_key != current_node:
            current_node = node_key
            print(f"\n🔷 [{label}] {name}")
            print(f"   설명: {desc}")
            print(f"   생성: {created}")
            print(f"   관계:")
        
        if rel_type:
            print(f"     {direction} [{rel_type}] [{rel_label}] {rel_name}")

    node_names = set(r.get("name","") for r in rows)
    print(f"\n{'=' * 70}")
    print(f"  총 {len(node_names)}개 노드 조회 완료")
    print(f"{'=' * 70}")
