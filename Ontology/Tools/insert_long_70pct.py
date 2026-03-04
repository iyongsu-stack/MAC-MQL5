"""
Neo4j DB 등록: 70% 승률 롱 라벨링 메가 Grid Search 결과
- Document: 보고서
- StrategyRule: 라벨링 규칙
- Script: 시뮬레이션 스크립트
- Insight: 핵심 발견
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "Ontology", "Tools"))
from cypher_cli import run_cypher, run_multi_cypher

TS = "2026-03-03T14:27:00"

queries = []

# ── 1. 보고서 Document 노드 ──
queries.append(f"""
MERGE (doc:Document {{name: 'long_labeling_70pct_report.md'}})
SET doc.description = '70% 승률 롱 라벨링 메가 Grid Search 보고서 (2019-2020, TP=3ATR, SL=CE_Upl2, 30봉, 2742조합 탐색)',
    doc.path = 'Docs/TrendTrading Development Strategy/long_labeling_70pct_report.md',
    doc.created_at = datetime("{TS}"),
    doc.updated_at = datetime("{TS}")
""")

# ── 2. 시뮬레이션 스크립트 노드 ──
for name, desc, path in [
    ("sim_long_mega.py", "메가 Grid Search (13타점×260필터, 2742조합 전수탐색)", "Files/Tools/sim_long_mega.py"),
    ("sim_long_70pct.py", "1차 단순 필터 시뮬레이션 (26조합)", "Files/Tools/sim_long_70pct.py"),
    ("analyze_chandelier_distance.py", "CE_Upl2-Close 거리를 ATR 배수로 분석", "Files/Tools/analyze_chandelier_distance.py"),
]:
    queries.append(f"""
    MERGE (s:Script {{name: '{name}'}})
    SET s.description = '{desc}',
        s.path = '{path}',
        s.created_at = datetime("{TS}"),
        s.updated_at = datetime("{TS}")
    """)

# ── 3. StrategyRule: 70% 이상 라벨링 규칙(후보) ──
queries.append(f"""
MERGE (sr:StrategyRule {{name: 'Label_Long_70pct_Candidate1'}})
SET sr.description = '[롱 후보1] QQE(12-32)GC + BSP(180)>2.5 + TV>2×MA60 → 승률80%(10건/2019-2020). TP=3ATR, SL=CE_Upl2, 30봉',
    sr.win_rate = 80.0,
    sr.sample_count = 10,
    sr.tp_mult = 3.0,
    sr.sl_type = 'Chandelier_Upl2',
    sr.time_bars = 30,
    sr.status = 'candidate',
    sr.created_at = datetime("{TS}"),
    sr.updated_at = datetime("{TS}")
""")

queries.append(f"""
MERGE (sr:StrategyRule {{name: 'Label_Long_70pct_Candidate2'}})
SET sr.description = '[롱 후보2] QQE(5-14)GC + BSP(180)>2.0 + TV>2×MA60 → 승률70.6%(17건/2019-2020). TP=3ATR, SL=CE_Upl2, 30봉',
    sr.win_rate = 70.6,
    sr.sample_count = 17,
    sr.tp_mult = 3.0,
    sr.sl_type = 'Chandelier_Upl2',
    sr.time_bars = 30,
    sr.status = 'candidate',
    sr.created_at = datetime("{TS}"),
    sr.updated_at = datetime("{TS}")
""")

# ── 4. Insight: 핵심 발견 ──
queries.append(f"""
MERGE (ins:Insight {{name: 'Insight_TickVolume_Key_To_70pct'}})
SET ins.description = 'TP=3ATR+CE_Upl2 SL 조건에서 70% 승률 달성의 핵심은 TickVolume > 2×MA(60) 필터. 세력 참여 봉에서만 진입 시 가짜 반등 제거 효과.',
    ins.created_at = datetime("{TS}"),
    ins.updated_at = datetime("{TS}")
""")

queries.append(f"""
MERGE (ins:Insight {{name: 'Insight_CE_Upl2_Distance_2_87ATR'}})
SET ins.description = 'Chandelier_Upl2(MaxHigh22-4.5×ATR22)와 Close 사이 중앙 거리는 2.87×ATR. TP=3ATR일 때 R:R 중앙값≈1.05로 거의 1:1. 순수 확률 게임에 가까워 타점 정밀도가 결정적.',
    ins.created_at = datetime("{TS}"),
    ins.updated_at = datetime("{TS}")
""")

# ── 5. 관계 연결 ──
# Script → Document (REPORTED_IN)
queries.append(f"""
MATCH (s:Script {{name: 'sim_long_mega.py'}})
MATCH (doc:Document {{name: 'long_labeling_70pct_report.md'}})
MERGE (s)-[:REPORTED_IN {{created_at: datetime("{TS}")}}]->(doc)
""")

# StrategyRule → Document (DEFINED_IN)
for rule in ['Label_Long_70pct_Candidate1', 'Label_Long_70pct_Candidate2']:
    queries.append(f"""
    MATCH (sr:StrategyRule {{name: '{rule}'}})
    MATCH (doc:Document {{name: 'long_labeling_70pct_report.md'}})
    MERGE (sr)-[:DEFINED_IN {{created_at: datetime("{TS}")}}]->(doc)
    """)

# Insight → StrategyRule (RELATES_TO)
queries.append(f"""
MATCH (ins:Insight {{name: 'Insight_TickVolume_Key_To_70pct'}})
MATCH (sr:StrategyRule {{name: 'Label_Long_70pct_Candidate1'}})
MERGE (ins)-[:RELATES_TO {{created_at: datetime("{TS}")}}]->(sr)
""")
queries.append(f"""
MATCH (ins:Insight {{name: 'Insight_TickVolume_Key_To_70pct'}})
MATCH (sr:StrategyRule {{name: 'Label_Long_70pct_Candidate2'}})
MERGE (ins)-[:RELATES_TO {{created_at: datetime("{TS}")}}]->(sr)
""")

# Insight → Document
queries.append(f"""
MATCH (ins:Insight {{name: 'Insight_CE_Upl2_Distance_2_87ATR'}})
MATCH (doc:Document {{name: 'long_labeling_70pct_report.md'}})
MERGE (ins)-[:DEFINED_IN {{created_at: datetime("{TS}")}}]->(doc)
""")

# StrategyRule 간 관계 (기존 라벨링 규칙 연결)
queries.append(f"""
MATCH (new:StrategyRule {{name: 'Label_Long_70pct_Candidate1'}})
MATCH (old:StrategyRule {{name: 'Label_QQE_GoldenCross_3Barrier'}})
MERGE (new)-[:EVOLVES_FROM {{created_at: datetime("{TS}"), reason: 'QQE 기반 + TickVolume+BSP 필터 강화로 승률 80% 달성'}}]->(old)
""")

# ── 실행 ──
print(f"총 {len(queries)}개 쿼리 실행...")
ok = 0; fail = 0
for i, q in enumerate(queries):
    r = run_cypher(q)
    if r.get("status") == "OK":
        ok += 1
    else:
        fail += 1
        print(f"  ❌ [{i}] {r}")

print(f"\n✅ 완료: {ok} 성공 / {fail} 실패")
