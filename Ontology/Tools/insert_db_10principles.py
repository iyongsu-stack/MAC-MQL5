"""DB 작성 핵심 10원칙을 Neo4j에 삽입/업데이트"""
import sys, os
from datetime import datetime, timezone, timedelta

sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

KST = timezone(timedelta(hours=9))
TS = datetime.now(KST).strftime("%Y-%m-%dT%H:%M:%S")

RULES = [
    {
        "name": "Rule_Shift+1",
        "desc": "미래 참조 편향 방지. 상위 TF/매크로 병합 시 직전 완성봉(Shift+1)만 사용. Z-score: x.shift(1).rolling(W), Macro 병합 전 shift(1) 적용"
    },
    {
        "name": "Rule_No_Absolute_Values",
        "desc": "절대값 사용 엄격 금지 + 6가지 파생 유형 강제(Δ%, 가속도, Z-Score, 이격도, 롤링상관, 비율). Tick Volume은 MA 대비 비율, BOPWMA/BSPWMA는 Slope+Accel+Slope_Zscore만 허용"
    },
    {
        "name": "Rule_Friction_Cost_30pt",
        "desc": "모든 수익/실패 판단 시 XAUUSD 거래 마찰비용 30포인트($0.30)를 반드시 차감"
    },
    {
        "name": "TrailingStop_Exit_Only",
        "desc": "청산은 TrailingStopVx가 전담. 고정 TP 사용 안 함. AI는 진입만 학습"
    },
    {
        "name": "Rule_Warmup_Dropna",
        "desc": "2계층 macro_features의 첫 ~1440행은 rolling 웜업 NaN 포함. M1 병합 최종 스크립트에서 반드시 dropna() 호출. 2계층 저장 단계에서는 dropna 금지"
    },
    {
        "name": "Rule_Ffill_Only_No_Bfill",
        "desc": "매크로 피처 NaN은 ffill(직전 거래일 유지)로만 처리. bfill은 미래참조이므로 절대 사용 금지"
    },
    {
        "name": "Rule_Winsorization",
        "desc": "극단적 이상치(Z-score ±10 이상)는 삭제 대신 상하위 1~5% 클리핑(Winsorization)으로 보존. 딥러닝 필수 적용, 트리 모델(LightGBM) 선택 적용"
    },
]

def main():
    print("🚀 DB 작성 핵심 10원칙을 Neo4j에 삽입합니다...")
    ok, fail = 0, 0

    for rule in RULES:
        r = run_cypher(f"""
        MERGE (sr:StrategyRule {{name: "{rule['name']}"}})
        SET sr.description = "{rule['desc']}",
            sr.source = 'Memo.md 10원칙',
            sr.created_at = coalesce(sr.created_at, datetime("{TS}")),
            sr.updated_at = datetime("{TS}")
        """)
        if r.get("status") == "OK":
            print(f"  ✅ {rule['name']}")
            ok += 1
        else:
            print(f"  ❌ {rule['name']}: {r.get('errors')}")
            fail += 1

        # Memo.md Document에 DEFINED_IN 관계 연결
        run_cypher(f"""
        MATCH (sr:StrategyRule {{name: "{rule['name']}"}})
        MATCH (d:Document {{name: 'Memo.md'}})
        MERGE (sr)-[r:DEFINED_IN]->(d)
        SET r.created_at = coalesce(r.created_at, datetime("{TS}"))
        """)

    print(f"\n🎉 완료: ✅ {ok}개 성공, ❌ {fail}개 실패")

if __name__ == "__main__":
    main()
