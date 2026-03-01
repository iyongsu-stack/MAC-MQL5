"""DB에서 마이크로 데이터 생성용 지표 설정값 조회"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

r = run_cypher("""
MATCH (ind:Indicator)-[:PRODUCES]->(c:DataArtifact {type:'indicator_config'})
RETURN ind.name AS 지표, c.name AS 설정명, c.parameters AS 파라미터
ORDER BY ind.name, c.name
""")

print(f"{'#':>3s}  {'지표':<42s} {'설정명':<28s} {'파라미터'}")
print("-" * 110)
for i, row in enumerate(r.get("results", []), 1):
    print(f"{i:3d}  {row['지표']:<42s} {row['설정명']:<28s} {row['파라미터']}")

print(f"\n총 {len(r.get('results',[]))}건")
