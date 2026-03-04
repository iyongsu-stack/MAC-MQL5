"""
시드 데이터 일괄 삽입 — seed_data.cypher 기반 SQL Server Graph Tables 이전
===========================================================================
기존 Neo4j seed_data.cypher의 내용을 cypher_cli.py 변환 레이어를 통해
SQL Server Graph Tables에 자동 삽입합니다.
"""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

TS = "2026-03-04T10:54:00"

print("=" * 60)
print("  시드 데이터 일괄 삽입 — SQL Server Graph Tables")
print("=" * 60)

# =====================================================
# 1. StrategyRule (핵심 원칙)
# =====================================================
rules = [
    ("Rule_Shift+1", "상위 TF 데이터 병합 시 반드시 직전 완성봉(Shift+1)만 사용하여 미래참조 방지", "핵심원칙"),
    ("Rule_Friction_Cost_30pt", "모든 수익/실패 판단 시 XAUUSD 거래 마찰비용 30포인트를 반드시 차감", "핵심원칙"),
    ("Rule_No_Absolute_Values", "절대값 사용 금지. 모든 피처는 파생 변환(Δ%, Z-Score, 기울기 등)하여 사용", "핵심원칙"),
    ("TrailingStop_Exit_Only", "청산은 TrailingStopVx가 전담. 고정 TP 사용 안 함. AI는 진입만 학습", "전략구조"),
]

print("\n[1] StrategyRule 삽입...")
ok = 0
for name, desc, typ in rules:
    r = run_cypher(f"MERGE (r:StrategyRule {{name: '{name}'}}) SET r.description = '{desc}', r.type = '{typ}', r.created_date = '2026-02-01'")
    if r["status"] == "OK":
        ok += 1
        print(f"  ✅ {name}")
    else:
        print(f"  ❌ {name}: {r.get('errors', '')}")
print(f"  → {ok}/{len(rules)} 완료")

# =====================================================
# 2. Idea (아이디어)
# =====================================================
ideas = [
    ("Asymmetric_Loss_도입", "롱/숏 비대칭 손실함수를 모델 학습에 적용하여 하락장 숏 정확도 향상", "검토중"),
    ("Feature_Pruning_추가", "SHAP 기반 피처 중요도 하위 10% 자동 제거 파이프라인 추가", "검토중"),
]

print("\n[2] Idea 삽입...")
ok = 0
for name, desc, status in ideas:
    r = run_cypher(f"MERGE (i:Idea {{name: '{name}'}}) SET i.description = '{desc}', i.status = '{status}', i.created_date = '2026-03-01'")
    if r["status"] == "OK":
        ok += 1
        print(f"  ✅ {name}")
    else:
        print(f"  ❌ {name}: {r.get('errors', '')}")
print(f"  → {ok}/{len(ideas)} 완료")

# =====================================================
# 3. Phase (로드맵)
# =====================================================
phases = [
    ("Phase1_DataLake", "Data Lake 구축 및 피처 엔지니어링", "✅완료", 1),
    ("Phase2_AI_Training", "AI 모델 학습 및 SHAP 피처 선택", "🚀진행중", 2),
    ("Phase3_WalkForward", "Walk-Forward 3단계 검증", "⬜미착수", 3),
    ("Phase4_LiveDeploy", "실전 배포 및 모니터링", "⬜미착수", 4),
]

print("\n[3] Phase 삽입...")
ok = 0
for name, desc, status, order in phases:
    r = run_cypher(f"MERGE (p:Phase {{name: '{name}'}}) SET p.description = '{desc}', p.status = '{status}'")
    if r["status"] == "OK":
        ok += 1
        print(f"  ✅ {name}")
    else:
        print(f"  ❌ {name}: {r.get('errors', '')}")
print(f"  → {ok}/{len(phases)} 완료")

# =====================================================
# 4. Phase PRECEDES 관계
# =====================================================
print("\n[4] Phase PRECEDES 관계 삽입...")
precedes = [
    ("Phase1_DataLake", "Phase2_AI_Training"),
    ("Phase2_AI_Training", "Phase3_WalkForward"),
    ("Phase3_WalkForward", "Phase4_LiveDeploy"),
]
ok = 0
for a, b in precedes:
    r = run_cypher(f"MATCH (a:Phase {{name: '{a}'}}) MATCH (b:Phase {{name: '{b}'}}) MERGE (a)-[:PRECEDES]->(b)")
    if r["status"] == "OK":
        ok += 1
        print(f"  ✅ {a} → {b}")
    else:
        print(f"  ❌ {a} → {b}: {r.get('errors', '')}")
print(f"  → {ok}/{len(precedes)} 완료")

# =====================================================
# 5. Milestone
# =====================================================
milestones = [
    ("MS_매크로수집완료", "Yahoo Finance 41개 + FRED 19개 매크로 CSV 수집 완료", "✅완료"),
    ("MS_기술지표파생완료", "tech_features_derived.parquet 생성 (Z-score, 기울기, 가속도 등)", "✅완료"),
    ("MS_라벨링완료", "ATR 동적 배리어 라벨링(labels_barrier.parquet) 완료", "✅완료"),
    ("MS_데이터셋병합완료", "AI_Study_Dataset.parquet 최종 병합 및 Shift+1 무결성 검증 통과", "✅완료"),
]

print("\n[5] Milestone 삽입...")
ok = 0
for name, desc, status in milestones:
    r = run_cypher(f"MERGE (m:Milestone {{name: '{name}'}}) SET m.description = '{desc}', m.status = '{status}'")
    if r["status"] == "OK":
        ok += 1
        print(f"  ✅ {name}")
    else:
        print(f"  ❌ {name}: {r.get('errors', '')}")
print(f"  → {ok}/{len(milestones)} 완료")

# Phase1 → Milestone CONTAINS
print("\n[6] Phase1 → Milestone CONTAINS 관계...")
ok = 0
for ms_name, _, _ in milestones:
    r = run_cypher(f"MATCH (p:Phase {{name: 'Phase1_DataLake'}}) MATCH (m:Milestone {{name: '{ms_name}'}}) MERGE (p)-[:CONTAINS]->(m)")
    if r["status"] == "OK":
        ok += 1
        print(f"  ✅ Phase1 → {ms_name}")
    else:
        print(f"  ❌ Phase1 → {ms_name}: {r.get('errors', '')}")
print(f"  → {ok}/{len(milestones)} 완료")

# =====================================================
# 6. DataArtifact + ACHIEVED_BY
# =====================================================
print("\n[7] DataArtifact & ACHIEVED_BY 관계...")
artifacts = [
    ("macro_features.parquet", "Tier2_Processed", "MS_매크로수집완료"),
    ("AI_Study_Dataset.parquet", "Tier2_Processed", "MS_데이터셋병합완료"),
]
ok = 0
for art_name, tier, ms_name in artifacts:
    r = run_cypher(f"MERGE (d:DataArtifact {{name: '{art_name}'}}) SET d.tier = '{tier}'")
    r2 = run_cypher(f"MATCH (m:Milestone {{name: '{ms_name}'}}) MATCH (d:DataArtifact {{name: '{art_name}'}}) MERGE (m)-[:ACHIEVED_BY]->(d)")
    if r["status"] == "OK" and r2["status"] == "OK":
        ok += 1
        print(f"  ✅ {ms_name} → {art_name}")
    else:
        print(f"  ❌ {ms_name} → {art_name}")
print(f"  → {ok}/{len(artifacts)} 완료")

# =====================================================
# 7. Document + DEFINED_IN
# =====================================================
print("\n[8] Document & DEFINED_IN 관계...")
run_cypher("MERGE (doc:Document {name: 'GEMINI.md'}) SET doc.description = '프로젝트 마스터 설정 문서'")
for rule_name in ["Rule_Shift+1", "Rule_Friction_Cost_30pt", "Rule_No_Absolute_Values"]:
    r = run_cypher(f"MATCH (r:StrategyRule {{name: '{rule_name}'}}) MATCH (doc:Document {{name: 'GEMINI.md'}}) MERGE (r)-[:DEFINED_IN]->(doc)")
    if r["status"] == "OK":
        print(f"  ✅ {rule_name} → GEMINI.md")
    else:
        print(f"  ❌ {rule_name} → GEMINI.md")

# =====================================================
# 8. Agent
# =====================================================
print("\n[9] Agent 삽입...")
run_cypher("MERGE (a:Agent {name: '3_Optimizer'}) SET a.description = 'AI 모델 최적화 에이전트'")
r = run_cypher("MATCH (i:Idea {name: 'Asymmetric_Loss_도입'}) MATCH (a:Agent {name: '3_Optimizer'}) MERGE (i)-[:RELATES_TO]->(a)")
if r["status"] == "OK":
    print("  ✅ Asymmetric_Loss_도입 → 3_Optimizer")

# =====================================================
# 최종 통계
# =====================================================
print("\n" + "=" * 60)
r = run_cypher("MATCH (n) RETURN labels(n)[0] AS Label, count(n) AS Count ORDER BY Count DESC")
if r["status"] == "OK":
    print("  📊 노드 통계:")
    for row in r["results"]:
        print(f"     {row['Label']:25s} {row['Count']}개")
print("=" * 60)
print("  🎉 시드 데이터 삽입 완료!")
print("=" * 60)
