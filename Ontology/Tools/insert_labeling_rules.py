"""Triple Barrier 라벨링 규칙을 Neo4j에 삽입"""
import sys, os
from datetime import datetime, timezone, timedelta

sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

KST = timezone(timedelta(hours=9))
TS = datetime.now(KST).strftime("%Y-%m-%dT%H:%M:%S")

RULES = [
    {
        "name": "Label_Triple_Barrier",
        "desc": "Triple Barrier 라벨링: TP=ATR(14)×1.0, SL=ATR(14)×1.2(비대칭), 시간배리어=45봉. 방향별 분리(label_long/label_short). ATR은 Wilder Smoothing(alpha=1/14) OHLC 기반"
    },
    {
        "name": "Label_Setup_Filter",
        "desc": "Setup 필터: LRAVGST_Avg(180)_BSPScale > 1.0(롱), < -1.0(숏) 황금구간에서만 라벨 생성. 필터 미통과 봉은 라벨링 대상 제외"
    },
    {
        "name": "Label_Direction_Separation",
        "desc": "롱/숏 방향별 분리 라벨링: label_long(상승 성공=1), label_short(하락 성공=1)을 독립 컬럼으로 저장. AI 학습 시 롱 모델과 숏 모델 분리 학습 지원"
    },
    {
        "name": "Label_Friction_Cost_Applied",
        "desc": "라벨링 수익률 계산 시 Friction Cost $0.30(30pt) 항상 차감. TP/SL/시간초과 모든 경우에 적용: (Exit - Entry - 0.30) / Entry × 100"
    },
    {
        "name": "Label_Lookahead_Prevention",
        "desc": "진입 시점의 ATR만 사용(직전 완성봉 기준). Future High/Low는 i+1 ~ i+45 구간만 참조. 현재봉 데이터 미사용으로 Look-ahead Bias 완전 차단"
    },
    {
        "name": "Label_Training_Periods",
        "desc": "학습 구간: 2012-01-01~2015-12-31(하락장) + 2019-01-01~2021-12-31(상승장). 다양한 레짐 포함으로 모델 일반화 목표"
    },
    {
        "name": "Label_Judgment_Logic",
        "desc": "판정 로직: TP 먼저 도달=label 1(성공), SL 먼저 도달=label 0(실패), 45봉 시간초과=label 0(실패). Exit가격은 타임아웃 시 종가 사용"
    },
]

def main():
    print("🚀 라벨링(Triple Barrier) 규칙을 Neo4j에 삽입합니다...")
    ok, fail = 0, 0

    for rule in RULES:
        r = run_cypher(f"""
        MERGE (sr:StrategyRule {{name: "{rule['name']}"}})
        SET sr.description = "{rule['desc']}",
            sr.category = 'labeling',
            sr.source = 'build_labels_barrier.py',
            sr.created_at = coalesce(sr.created_at, datetime("{TS}")),
            sr.updated_at = datetime("{TS}")
        """)
        if r.get("status") == "OK":
            print(f"  ✅ {rule['name']}")
            ok += 1
        else:
            print(f"  ❌ {rule['name']}: {r.get('errors')}")
            fail += 1

        # build_labels_barrier.py Script 노드에 DEFINED_IN 관계 연결
        run_cypher(f"""
        MATCH (sr:StrategyRule {{name: "{rule['name']}"}})
        MERGE (s:Script {{name: 'build_labels_barrier.py'}})
        ON CREATE SET s.path = 'Files/Tools/build_labels_barrier.py', s.language = 'Python'
        MERGE (sr)-[r:DEFINED_IN]->(s)
        SET r.created_at = coalesce(r.created_at, datetime("{TS}"))
        """)

    # 기존 규칙과 라벨링 규칙 간 관계 연결
    relations = [
        ("Label_Friction_Cost_Applied", "IMPLEMENTS", "Rule_Friction_Cost_30pt"),
        ("Label_Lookahead_Prevention", "IMPLEMENTS", "Rule_Shift+1"),
        ("Label_Direction_Separation", "RELATES_TO", "TrailingStop_Exit_Only"),
    ]
    for src, rel, tgt in relations:
        r = run_cypher(f"""
        MATCH (a:StrategyRule {{name: "{src}"}})
        MATCH (b:StrategyRule {{name: "{tgt}"}})
        MERGE (a)-[r:{rel}]->(b)
        SET r.created_at = coalesce(r.created_at, datetime("{TS}"))
        """)
        icon = "✅" if r.get("status") == "OK" else "❌"
        print(f"  {icon} 관계: {src} -[{rel}]-> {tgt}")

    print(f"\n🎉 완료: ✅ {ok}개 성공, ❌ {fail}개 실패")

if __name__ == "__main__":
    main()
