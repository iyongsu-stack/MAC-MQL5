"""마이크로 피처 테이블 — 지표별 설정값 삽입 (23건)"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher
import pyodbc

TS = "2026-03-04T11:14:00"

# (indicator_name, config_label, params_str)
# config_label = indicator + params 조합으로 고유 식별
CONFIGS = [
    ("BOPAvgStdDownLoad.mq5",           "BOPAvgStd_default",          "default"),
    ("LRAVGSTDownLoad.mq5",             "LRAVGST_Avg60",              "AvgPeriod=60"),
    ("LRAVGSTDownLoad.mq5",             "LRAVGST_Avg180",             "AvgPeriod=180"),
    ("BOPWmaSmoothDownLoad.mq5",        "BOPWmaSmooth_W10_S3",        "inpWmaPeriod=10, inpSmoothPeriod=3"),
    ("BOPWmaSmoothDownLoad.mq5",        "BOPWmaSmooth_W30_S5",        "inpWmaPeriod=30, inpSmoothPeriod=5"),
    ("BSPWmaSmoothDownLoad.mq5",        "BSPWmaSmooth_W10_S3",        "inpWmaPeriod=10, inpSmoothPeriod=3"),
    ("BSPWmaSmoothDownLoad.mq5",        "BSPWmaSmooth_W30_S5",        "inpWmaPeriod=30, inpSmoothPeriod=5"),
    ("Chaikin VolatilityDownLoad.mq5",   "ChaikinVol_S10_C10",         "InpSmoothPeriod=10, InpCHVPeriod=10"),
    ("TradesDynamicIndexDownLoad.mq5",   "TDI_R13_V34_S2_Sig7",       "InpPeriodRSI=13, InpPeriodVolBand=34, InpPeriodSmRSI=2, InpPeriodSmSig=7"),
    ("QQE DownLoad.mq5",                "QQE_SF5_RSI14",              "SF=5, RSI_Period=14"),
    ("ADXSmoothDownLoad.mq5",           "ADXSmooth_P14",              "period=14"),
    ("ChandelieExitDownLoad.mq5",       "ChandelierExit_default",     "default"),
    ("ChoppingIndexDownLoad.mq5",       "ChopIndex_C14_S14",          "inpChoPeriod=14, inpSmoothPeriod=14"),
    ("ADXSmoothMTFDownLoad.mq5",        "ADXSmoothMTF_H4",            "InpTimeframe=H4 (M1봉 기준)"),
    ("ADXSmoothMTFDownLoad.mq5",        "ADXSmoothMTF_M5",            "InpTimeframe=M5 (M1봉 기준)"),
    ("BWMFI_MTFDownLoad.mq5",           "BWMFI_MTF_H4",               "InpTimeframe=H4 (M1봉 기준)"),
    ("BWMFI_MTFDownLoad.mq5",           "BWMFI_MTF_M5",               "InpTimeframe=M5 (M1봉 기준)"),
    ("Chaikin VolatilityDownLoad.mq5",   "ChaikinVol_S30_C30",         "InpSmoothPeriod=30, InpCHVPeriod=30"),
    ("TradesDynamicIndexDownLoad.mq5",   "TDI_R14_S90_Sig35",          "InpPeriodRSI=14, InpPeriodSmRSI=90, InpPeriodSmSig=35"),
    ("QQE DownLoad.mq5",                "QQE_SF12_RSI32",             "SF=12, RSI_Period=32"),
    ("ADXSmoothDownLoad.mq5",           "ADXSmooth_P14_v2",           "period=14"),
    ("ADXSmoothDownLoad.mq5",           "ADXSmooth_P80",              "period=80"),
    ("ChoppingIndexDownLoad.mq5",       "ChopIndex_C120_S40",         "inpChoPeriod=120, inpSmoothPeriod=40"),
    ("ATRDownLoad.mq5",                 "ATR_default",                "default"),
]

print("=" * 70)
print("  마이크로 피처 테이블 — 지표 설정값 삽입 (24건)")
print("=" * 70)

ok = 0
for ind_name, config_label, params in CONFIGS:
    # 1. Indicator 노드 확인/생성
    run_cypher(f"MERGE (i:Indicator {{name: '{ind_name}'}}) SET i.updated_at = datetime('{TS}')")
    # 2. Feature 노드 (설정 인스턴스)
    r = run_cypher(f"MERGE (f:Feature {{name: '{config_label}'}}) SET f.description = '{params}', f.category = 'micro_tech', f.updated_at = datetime('{TS}')")
    # 3. CALCULATED_BY 관계 (Feature ← Indicator)
    r2 = run_cypher(f"MATCH (f:Feature {{name: '{config_label}'}}) MATCH (i:Indicator {{name: '{ind_name}'}}) MERGE (f)-[:CALCULATED_BY]->(i)")

    if r["status"] == "OK" and r2["status"] == "OK":
        ok += 1
        print(f"  ✅ {config_label:35s} ({params})")
    else:
        print(f"  ❌ {config_label}: {r.get('errors','')}{r2.get('errors','')}")

print(f"\n  → {ok}/{len(CONFIGS)} 완료")

# 검증
print("\n" + "=" * 70)
print("  📊 마이크로 피처 설정 전체 조회")
print("=" * 70)

conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;"
    "DATABASE=OntologyGraph;"
    "Trusted_Connection=yes;"
)
cursor = conn.cursor()
cursor.execute("""
    SELECT f.name AS Config, f.description AS Params, i.name AS Indicator
    FROM Feature f, CALCULATED_BY cb, Indicator i
    WHERE MATCH(f-(cb)->i) AND f.category = 'micro_tech'
    ORDER BY i.name, f.name
""")
rows = cursor.fetchall()
print(f"\n  {'#':>3s}  {'Indicator':40s}  {'Config':35s}  {'Params'}")
print(f"  {'---':>3s}  {'----------------------------------------':40s}  {'-----------------------------------':35s}  {'--------------------'}")
for idx, r in enumerate(rows, 1):
    print(f"  {idx:3d}  {r[2]:40s}  {r[0]:35s}  {r[1]}")
print(f"\n  합계: {len(rows)}건")
conn.close()
