"""빌드 결과를 Neo4j Aura에 동기화하는 스크립트"""
import sys

# pandas 차단
for _k in [k for k in sys.modules if k == 'pandas' or k.startswith('pandas.')]:
    del sys.modules[_k]
class _PB:
    def find_module(self, name, path=None):
        if name == 'pandas' or name.startswith('pandas.'): return self
    def load_module(self, name): raise ImportError(name)
sys.meta_path.insert(0, _PB())

from neo4j import GraphDatabase

URI = "neo4j+s://824847a1.databases.neo4j.io"
USER = "824847a1"
PASS = r"O3PnXe8Fhk3VLxG8h8wC98g4AZrY-4C61jaGyXMcz6w"

driver = GraphDatabase.driver(URI, auth=(USER, PASS))

queries = [
    # 빌드 결과 Action 노드
    """
    MERGE (w:Workflow {name: 'data-build.md'})
    MERGE (r:StrategyRule {name: 'Rule_No_Absolute_Values'})
    MERGE (a:Action {id: 'build_tech_features_derived_20260304'})
    SET a.type = 'Data_Pipeline_Execution',
        a.title = '기술 지표 파생 데이터 재빌드 및 규칙 검증 완료',
        a.description = 'tech_features.parquet 기반 104개 파생 피처 빌드. 14개 절대값 원본 DROP 이중 검증 PASS.',
        a.date = '2026-03-04'
    MERGE (a)-[:EXECUTED]->(w)
    MERGE (a)-[:VALIDATED]->(r)
    RETURN a.title, a.date
    """,
    # 접속 확인
    "MATCH (n) RETURN labels(n)[0] AS label, count(n) AS cnt ORDER BY cnt DESC"
]

print("=== Neo4j Aura 데이터 동기화 시작 ===", flush=True)
with driver.session() as session:
    for i, q in enumerate(queries, 1):
        q = q.strip()
        if q:
            print(f"\n[{i}] 실행 중...", flush=True)
            result = session.run(q)
            records = [dict(r) for r in result]
            for rec in records:
                print(f"    {rec}", flush=True)
            print(f"[{i}] 완료!", flush=True)

driver.close()
print("\n=== 모든 쿼리 성공! ===", flush=True)
