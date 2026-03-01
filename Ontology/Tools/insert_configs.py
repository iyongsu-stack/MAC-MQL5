"""기술 지표 설정값(Config) 22건을 Neo4j에 삽입 — Indicator -[CONFIGURED_WITH]-> Config 관계"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

# (지표 파일명, 설정 이름(고유), 파라미터 딕셔너리)
CONFIGS = [
    ("BOPAvgStdDownLoad.mq5", "BOPAvgStd_default", {}),
    ("LRAVGSTDownLoad.mq5", "LRAVGST_Avg60", {"AvgPeriod": 60}),
    ("LRAVGSTDownLoad.mq5", "LRAVGST_Avg180", {"AvgPeriod": 180}),
    ("BOPWmaSmoothDownLoad.mq5", "BOPWmaSmooth_W10_S3", {"inpWmaPeriod": 10, "inpSmoothPeriod": 3}),
    ("BOPWmaSmoothDownLoad.mq5", "BOPWmaSmooth_W30_S5", {"inpWmaPeriod": 30, "inpSmoothPeriod": 5}),
    ("BSPWmaSmoothDownLoad.mq5", "BSPWmaSmooth_W10_S3", {"inpWmaPeriod": 10, "inpSmoothPeriod": 3}),
    ("BSPWmaSmoothDownLoad.mq5", "BSPWmaSmooth_W30_S5", {"inpWmaPeriod": 30, "inpSmoothPeriod": 5}),
    ("Chaikin VolatilityDownLoad.mq5", "ChaikinVol_S10_C10", {"InpSmoothPeriod": 10, "InpCHVPeriod": 10}),
    ("TradesDynamicIndexDownLoad.mq5", "TDI_R13_V34_S2_Sig7", {"InpPeriodRSI": 13, "InpPeriodVolBand": 34, "InpPeriodSmRSI": 2, "InpPeriodSmSig": 7}),
    ("QQE DownLoad.mq5", "QQE_SF5_RSI14", {"SF": 5, "RSI_Period": 14}),
    ("ADXSmoothDownLoad.mq5", "ADXSmooth_P14", {"period": 14}),
    ("ChandelieExitDownLoad.mq5", "ChandelierExit_default", {}),
    ("ChoppingIndexDownLoad.mq5", "ChopIndex_C14_S14", {"inpChoPeriod": 14, "inpSmoothPeriod": 14}),
    ("ADXSmoothMTFDownLoad.mq5", "ADXSmoothMTF_H4", {"InpTimeframe": "H4", "chart": "M1"}),
    ("ADXSmoothMTFDownLoad.mq5", "ADXSmoothMTF_M5", {"InpTimeframe": "M5", "chart": "M1"}),
    ("BWMFI_MTFDownLoad.mq5", "BWMFI_MTF_H4", {"InpTimeframe": "H4", "chart": "M1"}),
    ("BWMFI_MTFDownLoad.mq5", "BWMFI_MTF_M5", {"InpTimeframe": "M5", "chart": "M1"}),
    ("Chaikin VolatilityDownLoad.mq5", "ChaikinVol_S30_C30", {"InpSmoothPeriod": 30, "InpCHVPeriod": 30}),
    ("TradesDynamicIndexDownLoad.mq5", "TDI_R14_S90_Sig35", {"InpPeriodRSI": 14, "InpPeriodSmRSI": 90, "InpPeriodSmSig": 35}),
    ("QQE DownLoad.mq5", "QQE_SF12_RSI32", {"SF": 12, "RSI_Period": 32}),
    ("ADXSmoothDownLoad.mq5", "ADXSmooth_P80", {"period": 80}),
    ("ChoppingIndexDownLoad.mq5", "ChopIndex_C120_S40", {"inpChoPeriod": 120, "inpSmoothPeriod": 40}),
]

print(f"기술 지표 설정값 {len(CONFIGS)}건 삽입...\n")

ok = 0
for indicator, config_name, params in CONFIGS:
    safe_ind = indicator.replace("'", "\\'")
    safe_cfg = config_name.replace("'", "\\'")
    
    # 파라미터를 SET 절로 변환
    param_sets = []
    for k, v in params.items():
        if isinstance(v, str):
            param_sets.append(f"c.{k} = '{v}'")
        else:
            param_sets.append(f"c.{k} = {v}")
    
    param_str = ", ".join(param_sets)
    set_clause = f", {param_str}" if param_str else ""
    
    # 파라미터 요약 문자열
    param_summary = ", ".join(f"{k}={v}" for k, v in params.items()) if params else "default"
    
    q = f"""
    MERGE (ind:Indicator {{name: '{safe_ind}'}})
    MERGE (c:DataArtifact {{name: '{safe_cfg}'}})
    SET c.type = 'indicator_config',
        c.indicator = '{safe_ind}',
        c.parameters = '{param_summary}',
        c.created_at = datetime("2026-03-01T12:08:00"),
        c.updated_at = datetime("2026-03-01T12:08:00"){set_clause}
    MERGE (ind)-[:PRODUCES]->(c)
    """
    r = run_cypher(q)
    s = "✅" if r["status"] == "OK" else "❌"
    print(f"  {s} {indicator:40s} → {config_name} [{param_summary}]")
    if r["status"] == "OK":
        ok += 1
    else:
        print(f"     {r.get('errors','')}")

print(f"\n완료! 성공: {ok}/{len(CONFIGS)}")
