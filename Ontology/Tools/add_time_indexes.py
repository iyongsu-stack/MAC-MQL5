"""19종 엔티티에 대한 created_at / updated_at 시간 인덱스 일괄 추가"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

LABELS = [
    "ExpertAdvisor", "FrameworkModule", "Indicator", "Script",
    "DataLayer", "DataArtifact", "Feature", "MacroSymbol", "PerformanceMetric",
    "Agent", "Role", "StrategyRule", "Workflow", "Document",
    "Environment", "MonitoringAlert",
    "Idea", "Insight",
    "Phase", "Milestone",
]

print("=" * 55)
print("  시간 인덱스 추가 — created_at / updated_at")
print("=" * 55)

ok = 0
for label in LABELS:
    for prop in ["created_at", "updated_at"]:
        idx = f"idx_{label.lower()}_{prop}"
        q = f'CREATE INDEX {idx} IF NOT EXISTS FOR (n:{label}) ON (n.{prop})'
        r = run_cypher(q)
        s = "✅" if r["status"] == "OK" else "❌"
        print(f"  {s} {label}.{prop}")
        if r["status"] == "OK":
            ok += 1

# 기존 노드에 created_at 일괄 세팅 (아직 없는 노드만)
print("\n기존 노드에 created_at 백필...")
r = run_cypher("""
MATCH (n) WHERE n.created_at IS NULL
SET n.created_at = datetime("2026-03-01T11:52:00"),
    n.updated_at = datetime("2026-03-01T11:52:00")
RETURN count(n) AS updated
""")
cnt = r.get("results", [{}])[0].get("updated", 0)
print(f"  ✅ {cnt}개 노드에 시간 속성 추가 완료")

print(f"\n{'='*55}")
print(f"  🎉 인덱스 {ok}개 생성 완료!")
print(f"{'='*55}")
