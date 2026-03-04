"""
Neo4j DB 등록: 60% 이상 주요 조합 상위 10건
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "Ontology", "Tools"))
from cypher_cli import run_cypher

TS = "2026-03-03T14:37:00"

# 60% 이상 상위 10건 (70% 이상 2건은 이미 등록됨)
combos = [
    ("Label_Long_60pct_03", "QQE(12-32)GC", "BSP>2.0 + TV>2×", 68.4, 19),
    ("Label_Long_60pct_04", "DeepValue(5봉)", "BSP>2.0 + TV>2×", 66.7, 15),
    ("Label_Long_60pct_05", "QQE(5-14)GC", "BSP>2.5 + TV>2×", 66.7, 12),
    ("Label_Long_60pct_06", "QQE(5-14)GC", "BSP>2.5 + TV>1.5×", 65.0, 40),
    ("Label_Long_60pct_07", "DeepValue(5봉)", "BSP>2.5 + TV>1.5×", 63.9, 36),
    ("Label_Long_60pct_08", "DeepValue(5봉)", "BSP>2.5 + TV>2×", 63.6, 11),
    ("Label_Long_60pct_09", "DeepValue(10봉)", "BSP>2.5 + TV>1.5×", 62.5, 32),
    ("Label_Long_60pct_10", "QQE_GC+3봉확인", "CE≤1.5 + TV>2×", 62.5, 8),
    ("Label_Long_60pct_11", "BSP_Slope전환", "BSP>1.5 + TV>2×", 60.0, 15),
    ("Label_Long_60pct_12", "DeepValue(10봉)", "BSP>2.0 + TV>2×", 60.0, 10),
]

ok = 0; fail = 0
for name, entry, filt, wr, samples in combos:
    desc = f'[롱 60%+] 타점={entry}, 필터={filt} → 승률{wr}%({samples}건/2019-2020). TP=3ATR, SL=CE_Upl2, 30봉'
    q = f"""
    MERGE (sr:StrategyRule {{name: '{name}'}})
    SET sr.description = '{desc}',
        sr.entry_type = '{entry}',
        sr.filter_set = '{filt}',
        sr.win_rate = {wr},
        sr.sample_count = {samples},
        sr.tp_mult = 3.0,
        sr.sl_type = 'Chandelier_Upl2',
        sr.time_bars = 30,
        sr.status = 'candidate',
        sr.created_at = datetime("{TS}"),
        sr.updated_at = datetime("{TS}")
    """
    r = run_cypher(q)
    if r.get("status") == "OK":
        ok += 1
    else:
        fail += 1
        print(f"  ❌ {name}: {r}")

# 보고서 문서와 연결
for name, *_ in combos:
    q2 = f"""
    MATCH (sr:StrategyRule {{name: '{name}'}})
    MATCH (doc:Document {{name: 'long_labeling_70pct_report.md'}})
    MERGE (sr)-[:DEFINED_IN {{created_at: datetime("{TS}")}}]->(doc)
    """
    r2 = run_cypher(q2)
    if r2.get("status") == "OK":
        ok += 1
    else:
        fail += 1

print(f"✅ 완료: {ok} 성공 / {fail} 실패 (노드 10 + 관계 10 = 20건)")
