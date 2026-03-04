import sys, os
from datetime import datetime, timezone, timedelta

# Ontology/Tools/cypher_cli.py 경로 추가
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

# KST 생성
KST = timezone(timedelta(hours=9))
TS = datetime.now(KST).strftime("%Y-%m-%dT%H:%M:%S")

def main():
    print("🚀 Memo.md 데이터를 Neo4j DB에 삽입합니다...")
    
    # 1. Document 노드 삽입: Memo.md
    r1 = run_cypher(f"""
    MERGE (d:Document {{name: 'Memo.md'}})
    SET d.description = '데이터 수집 현황, Data Lake 아키텍처 및 AI 학습 파이프라인(LightGBM, SHAP, Asymmetric Loss)에 대한 핵심 메모',
        d.path = 'Docs/TrendTrading Development Strategy/Memo.md',
        d.created_at = coalesce(d.created_at, datetime("{TS}")),
        d.updated_at = datetime("{TS}")
    """)
    if r1.get("status") == "OK":
        print("✅ Document 노드 (Memo.md) 삽입 완료")
    else:
        print(f"❌ Document 노드 오류: {r1.get('errors')}")

    # 2. Insight 노드 삽입 및 관계 연결
    insights = [
        {
            "name": "Feature Pruning before SHAP",
            "desc": "SHAP 중요도 분산 왜곡 방지를 위해 상관계수 0.85~0.95 이상인 중복 피처를 사전에 제거(Pruning)해야 함"
        },
        {
            "name": "Asymmetric Focal Loss",
            "desc": "거짓 양성(섣부른 진입)에 더 큰 페널티를 부여하는 비대칭 손실 함수를 적용하여 AI가 고확률 자리에서만 진입하도록 유도"
        },
        {
            "name": "Walk-Forward Continual Learning",
            "desc": "레짐 변화에 적응하기 위해 전체 기간 K-Fold 대신 최근 3년 학습 -> 6개월 검증 형태로 윈도우를 미는 연속적 Walk-Forward 교차 검증 적용"
        }
    ]

    for insight in insights:
        r2 = run_cypher(f"""
        MERGE (i:Insight {{name: "{insight['name']}"}})
        SET i.description = "{insight['desc']}",
            i.status = '확정',
            i.created_at = coalesce(i.created_at, datetime("{TS}")),
            i.updated_at = datetime("{TS}")
        """)
        if r2.get("status") == "OK":
            print(f"✅ Insight 노드 ({insight['name']}) 삽입 완료")
        else:
            print(f"❌ Insight 노드 오류: {r2.get('errors')}")

        # 관계 연결 (Insight -> Document)
        r3 = run_cypher(f"""
        MATCH (i:Insight {{name: "{insight['name']}"}})
        MATCH (d:Document {{name: 'Memo.md'}})
        MERGE (i)-[r:DEFINED_IN]->(d)
        SET r.created_at = coalesce(r.created_at, datetime("{TS}"))
        """)
        if r3.get("status") != "OK":
            print(f"❌ DEFINED_IN 관계 오류: {r3.get('errors')}")
            
    print("🎉 Memo.md DB 삽입 작업 완료!")

if __name__ == "__main__":
    main()
