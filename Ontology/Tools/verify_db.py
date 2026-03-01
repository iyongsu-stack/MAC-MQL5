"""DB 검증: 삽입된 데이터 통계 + 관계 확인"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

print("=" * 50)
print("  Neo4j 데이터 검증 리포트")
print("=" * 50)

# 1) 노드 수 통계
r = run_cypher("MATCH (n) RETURN labels(n)[0] AS Label, count(n) AS Count ORDER BY Count DESC")
print("\n📊 노드 통계:")
for row in r.get("results", []):
    print(f"  {row['Label']:25s} {row['Count']}개")

# 2) 관계 수 통계
r2 = run_cypher("MATCH ()-[r]->() RETURN type(r) AS Relation, count(r) AS Count ORDER BY Count DESC")
print("\n🔗 관계 통계:")
for row in r2.get("results", []):
    print(f"  {row['Relation']:25s} {row['Count']}개")

# 3) Phase 순서 확인
r3 = run_cypher("MATCH (a:Phase)-[:PRECEDES]->(b:Phase) RETURN a.name AS From, b.name AS To ORDER BY a.order")
print("\n🗺️ Phase 순서:")
for row in r3.get("results", []):
    print(f"  {row['From']} → {row['To']}")

# 4) Phase1 마일스톤
r4 = run_cypher("MATCH (p:Phase {name:'Phase1_DataLake'})-[:CONTAINS]->(m:Milestone) RETURN m.name AS MS, m.status AS Status")
print("\n📋 Phase1 마일스톤:")
for row in r4.get("results", []):
    print(f"  {row['Status']} {row['MS']}")

# 5) 규칙 목록
r5 = run_cypher("MATCH (r:StrategyRule) RETURN r.name AS Rule, r.type AS Type")
print("\n🚨 등록된 규칙:")
for row in r5.get("results", []):
    print(f"  [{row['Type']}] {row['Rule']}")

# 6) 아이디어 목록
r6 = run_cypher("MATCH (i:Idea) RETURN i.name AS Idea, i.status AS Status")
print("\n💡 등록된 아이디어:")
for row in r6.get("results", []):
    print(f"  [{row['Status']}] {row['Idea']}")

print(f"\n{'=' * 50}")
print("  검증 완료!")
print(f"{'=' * 50}")
