"""MQL5 → Python 포팅 매핑 12건을 PORTED_TO 관계로 Neo4j에 삽입"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

PORTINGS = [
    ("BOPAvgStdDownLoad.mq5",              "BOPAvgStd_Verifier.py"),
    ("LRAVGSTDownLoad.mq5",                "LRAVGSTD_Verifier.py"),
    ("BOPWmaSmoothDownLoad.mq5",           "BOPWmaSmooth_Calc_and_Verify.py"),
    ("BSPWmaSmoothDownLoad.mq5",           "BSPWmaSmooth_Converter.py"),
    ("Chaikin VolatilityDownLoad.mq5",      "Chaikin_Verification.py"),
    ("TradesDynamicIndexDownLoad.mq5",      "TDI_Verifier.py"),
    ("QQE DownLoad.mq5",                    "QQE_Verification.py"),
    ("ADXSmoothDownLoad.mq5",              "adx_verifier.py"),
    ("ChandelieExitDownLoad.mq5",          "chandelier_exit_verifier.py"),
    ("ChoppingIndexDownLoad.mq5",          "chopping_verifier.py"),
    ("ADXSmoothMTFDownLoad.mq5",           "ADXSmoothMTF_Converter.py"),
    ("BWMFI_MTFDownLoad.mq5",              "BWMFI_MTF_Converter.py"),
]

print(f"MQL5 → Python 포팅 관계 {len(PORTINGS)}건 삽입...\n")

ok = 0
for mql, py in PORTINGS:
    safe_mql = mql.replace("'", "\\'")
    safe_py = py.replace("'", "\\'")
    q = f"""
    MERGE (a:Indicator {{name: '{safe_mql}'}})
    MERGE (b:Script {{name: '{safe_py}'}})
    MERGE (a)-[:PORTED_TO {{created_at: datetime("2026-03-01T12:05:00")}}]->(b)
    """
    r = run_cypher(q)
    s = "✅" if r["status"] == "OK" else "❌"
    print(f"  {s} {mql:40s} → {py}")
    if r["status"] == "OK":
        ok += 1
    else:
        print(f"     {r.get('errors','')}")

print(f"\n완료! 성공: {ok}/{len(PORTINGS)}")
