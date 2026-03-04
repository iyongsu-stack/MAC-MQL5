"""기존 라벨링을 대체할 '눌림목 후 재상승(Pullback & Momentum)' 라벨링 기법을 Neo4j에 저장"""
import sys, os
from datetime import datetime, timezone, timedelta

sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

KST = timezone(timedelta(hours=9))
TS = datetime.now(KST).strftime("%Y-%m-%dT%H:%M:%S")

IDEA = {
    "name": "Idea_Pullback_Setup_Labeling",
    "desc": "무차별 라벨링 대신 '황금구간 내 눌림목 후 재상승' 타점만 정밀 라벨링하는 기법. TDI 골든/데드크로스를 활용하여 8.6만개 봉에서 7천여개의 핵심 스나이퍼 타점만 추출. 향후 AI 학습 성능 개선에 적용 예정.",
    "methodology": "1. 메인추세: LRAVGST_Avg(180)_BSPScale > 1.0 (롱)\n2. 눌림목: TDI_(13-34-2-7)_TrSi < TDI_(13-34-2-7)_Signal (본선이 신호선 하향 이탈)\n3. 타점: 현재 봉에서 본선이 신호선을 상향 돌파(골든크로스)하는 첫 순간 AND 황금구간 유지"
}

def main():
    print("🚀 스나이퍼 라벨링(Pullback Setup) 기법을 아이디어로 DB에 저장합니다...")
    
    # Idea 노드 생성
    r1 = run_cypher(f"""
    MERGE (i:Idea {{name: "{IDEA['name']}"}})
    SET i.description = "{IDEA['desc']}",
        i.methodology = "{IDEA['methodology']}",
        i.status = 'proposed',
        i.created_at = coalesce(i.created_at, datetime("{TS}")),
        i.updated_at = datetime("{TS}")
    """)
    
    if r1.get("status") == "OK":
        print(f"  ✅ 아이디어 노드 생성: {IDEA['name']}")
    else:
        print(f"  ❌ 실패: {r1.get('errors')}")

    # 기존 Label_Setup_Filter 규칙과 제안/대체 관계로 연결
    r2 = run_cypher(f"""
    MATCH (i:Idea {{name: "{IDEA['name']}"}})
    MATCH (sr:StrategyRule {{name: "Label_Setup_Filter"}})
    MERGE (i)-[r:PROPOSES_ALTERNATIVE_TO]->(sr)
    SET r.created_at = coalesce(r.created_at, datetime("{TS}"))
    """)

    if r2.get("status") == "OK":
        print(f"  ✅ 관계 생성: {IDEA['name']} -[PROPOSES_ALTERNATIVE_TO]-> Label_Setup_Filter")
    else:
        print(f"  ❌ 관계 생성 실패: {r2.get('errors')}")

    print("\n🎉 완료!")

if __name__ == "__main__":
    main()
