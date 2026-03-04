import sys, os
from datetime import datetime, timezone, timedelta

sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

KST = timezone(timedelta(hours=9))
TS = datetime.now(KST).strftime("%Y-%m-%dT%H:%M:%S")

def main():
    print("🚀 QQE 라벨링 리포트를 DB에 Document 노드로 저장합니다...")
    
    file_path = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Docs\TrendTrading Development Strategy\qqe_labeling_optimization_report.md"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    safe_content = content.replace('\\', '\\\\').replace('"', '\\"')

    r1 = run_cypher(f"""
    MERGE (d:Document {{title: "QQE 정밀 타점 라벨링 및 파라미터 최적화 요약 보고서"}})
    SET d.path = "Docs/TrendTrading Development Strategy/qqe_labeling_optimization_report.md",
        d.content = "{safe_content}",
        d.type = "AnalysisReport",
        d.created_at = coalesce(d.created_at, datetime("{TS}")),
        d.updated_at = datetime("{TS}")
    """)
    
    if r1.get("status") == "OK":
        print("  ✅ Document 노드 생성/업데이트 완료")
    else:
        print(f"  ❌ Document 생성 실패: {r1.get('errors')}")

    r2 = run_cypher(f"""
    MATCH (d:Document {{title: "QQE 정밀 타점 라벨링 및 파라미터 최적화 요약 보고서"}})
    MATCH (i:Idea {{name: "Idea_Pullback_Setup_Labeling"}})
    MERGE (d)-[r:DOCUMENTS]->(i)
    SET r.created_at = coalesce(r.created_at, datetime("{TS}"))
    """)

    if r2.get("status") == "OK":
        print("  ✅ Document -> Idea 관계 생성 완료")
    else:
        print(f"  ❌ 관계 생성 실패: {r2.get('errors')}")
    
    r3 = run_cypher(f"""
    MERGE (sr:StrategyRule {{name: "Label_QQE_GoldenCross_3Barrier"}})
    SET sr.description = "QQE(5-14) 골든크로스와 1.0 황금구간을 결합한 정밀 진입 타점 규칙 (+ Chandelier_Upl2 SL, 30~60봉/2~3ATR TP 배리어)",
        sr.status = 'proposed',
        sr.created_at = coalesce(sr.created_at, datetime("{TS}")),
        sr.updated_at = datetime("{TS}")
    """)
    
    if r3.get("status") == "OK":
        print("  ✅ StrategyRule 노드(Label_QQE_GoldenCross_3Barrier) 생성 완료")
    else:
        print(f"  ❌ StrategyRule 생성 실패: {r3.get('errors')}")
        
    r4 = run_cypher(f"""
    MATCH (i:Idea {{name: "Idea_Pullback_Setup_Labeling"}})
    MATCH (sr:StrategyRule {{name: "Label_QQE_GoldenCross_3Barrier"}})
    MERGE (i)-[r:RESULTS_IN]->(sr)
    SET r.created_at = coalesce(r.created_at, datetime("{TS}"))
    """)
    
    if r4.get("status") == "OK":
        print("  ✅ Idea -> StrategyRule 관계 생성 완료")
    else:
        print(f"  ❌ 관계 생성 실패: {r4.get('errors')}")

if __name__ == "__main__":
    main()
