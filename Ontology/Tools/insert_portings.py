"""MQL5 → Python 포팅 테이블 삽입"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from cypher_cli import run_cypher

TS = "2026-03-04T11:09:00"

PORTINGS = [
    ("BOPAvgStdDownLoad.mq5",           "Indicators/BOP/BOPAvgStdDownLoad.mq5",                    "BOPAvgStd_Verifier.py",             "Scripts/BOPAvgStd_Verifier.py"),
    ("LRAVGSTDownLoad.mq5",             "Indicators/BSP105V9/LRAVGSTDownLoad.mq5",                 "LRAVGSTD_Verifier.py",              "Scripts/LRAVGSTD_Verifier.py"),
    ("BOPWmaSmoothDownLoad.mq5",        "Indicators/BOP/BOPWmaSmoothDownLoad.mq5",                 "BOPWmaSmooth_Calc_and_Verify.py",   "Scripts/BOPWmaSmooth_Calc_and_Verify.py"),
    ("BSPWmaSmoothDownLoad.mq5",        "Indicators/BSP105V9/BSPWmaSmoothDownLoad.mq5",            "BSPWmaSmooth_Converter.py",         "Scripts/BSPWmaSmooth_Converter.py"),
    ("Chaikin VolatilityDownLoad.mq5",   "Indicators/BSP105V9/Chaikin VolatilityDownLoad.mq5",      "Chaikin_Verification.py",           "Scripts/Chaikin_Verification.py"),
    ("TradesDynamicIndexDownLoad.mq5",   "Indicators/Test/TradesDynamicIndexDownLoad.mq5",          "TDI_Verifier.py",                   "Scripts/TDI_Verifier.py"),
    ("QQE DownLoad.mq5",                "Indicators/Test/QQE DownLoad.mq5",                        "QQE_Verification.py",               "Scripts/QQE_Verification.py"),
    ("ADXSmoothDownLoad.mq5",           "Indicators/Test/ADXSmoothDownLoad.mq5",                   "adx_verifier.py",                   "Scripts/adx_verifier.py"),
    ("ChandelieExitDownLoad.mq5",       "Indicators/Test/ChandelieExitDownLoad.mq5",               "chandelier_exit_verifier.py",       "Scripts/chandelier_exit_verifier.py"),
    ("ChoppingIndexDownLoad.mq5",       "Indicators/Test/ChoppingIndexDownLoad.mq5",               "chopping_verifier.py",              "Scripts/chopping_verifier.py"),
    ("ADXSmoothMTFDownLoad.mq5",        "Indicators/Test/ADXSmoothMTFDownLoad.mq5",                "ADXSmoothMTF_Converter.py",         "Scripts/ADXSmoothMTF_Converter.py"),
    ("BWMFI_MTFDownLoad.mq5",           "Indicators/Test/BWMFI_MTFDownLoad.mq5",                   "BWMFI_MTF_Converter.py",            "Scripts/BWMFI_MTF_Converter.py"),
    ("ATRDownLoad.mq5",                 "Indicators/Test/ATRDownLoad.mq5",                         "ATR_Verifier.py",                   "Scripts/ATR_Verifier.py"),
]

print("=" * 70)
print("  MQL5 → Python 포팅 테이블 삽입 (13건)")
print("=" * 70)

ok = 0
for mq5_name, mq5_path, py_name, py_path in PORTINGS:
    # 1. Indicator 노드
    r1 = run_cypher(f"MERGE (i:Indicator {{name: '{mq5_name}'}}) SET i.path = '{mq5_path}', i.updated_at = datetime('{TS}')")
    # 2. Script 노드
    r2 = run_cypher(f"MERGE (s:Script {{name: '{py_name}'}}) SET s.path = '{py_path}', s.description = 'MQL5 포팅 검증 스크립트', s.updated_at = datetime('{TS}')")
    # 3. PORTED_TO 관계
    r3 = run_cypher(f"MATCH (i:Indicator {{name: '{mq5_name}'}}) MATCH (s:Script {{name: '{py_name}'}}) MERGE (i)-[:PORTED_TO {{created_at: datetime('{TS}')}}]->(s)")

    if r1["status"] == "OK" and r2["status"] == "OK" and r3["status"] == "OK":
        ok += 1
        print(f"  ✅ {mq5_name:40s} → {py_name}")
    else:
        print(f"  ❌ {mq5_name} → {py_name}")
        for r in [r1, r2, r3]:
            if r["status"] != "OK":
                print(f"     {r.get('errors','')}")

print(f"\n  → {ok}/{len(PORTINGS)} 완료")

# 검증: PORTED_TO 관계 조회
print("\n" + "=" * 70)
print("  📊 검증: PORTED_TO 관계 전체 조회")
print("=" * 70)

import pyodbc
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;"
    "DATABASE=OntologyGraph;"
    "Trusted_Connection=yes;"
)
cursor = conn.cursor()
cursor.execute("""
    SELECT i.name AS MQL5, s.name AS Python
    FROM Indicator i, PORTED_TO p, Script s
    WHERE MATCH(i-(p)->s)
    ORDER BY i.name
""")
rows = cursor.fetchall()
print(f"\n  {'#':>3s}  {'MQL5 Indicator':40s}  {'Python Script'}")
print(f"  {'---':>3s}  {'------------------------------------------':40s}  {'----------------------------------'}")
for idx, r in enumerate(rows, 1):
    print(f"  {idx:3d}  {r[0]:40s}  {r[1]}")
print(f"\n  합계: {len(rows)}건")
conn.close()
