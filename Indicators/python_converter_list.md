# MQL5 to Python Converter Scripts

| 순번 | MQL5 File Path (Indicators) | Python Script Name (Scripts) | 비고 (Parameters) |
|:---:|:---|:---|:---|
| 1 | Indicators/BOP/BOPAvgStdDownLoad.mq5 | BOPAvgStd_Verifier.py | |
| 2 | Indicators/BSP105V9/LRAVGSTDownLoad.mq5 | LRAVGSTD_Verifier.py | AvgPeriod = 60 |
| 3 | Indicators/BSP105V9/LRAVGSTDownLoad.mq5 | LRAVGSTD_Verifier.py | AvgPeriod = 180 |
| 4 | Indicators/BOP/BOPWmaSmoothDownLoad.mq5 | BOPWmaSmooth_Calc_and_Verify.py | inpWmaPeriod = 10, inpSmoothPeriod = 3 |
| 5 | Indicators/BOP/BOPWmaSmoothDownLoad.mq5 | BOPWmaSmooth_Calc_and_Verify.py | inpWmaPeriod = 30, inpSmoothPeriod = 5 |
| 6 | Indicators/BSP105V9/BSPWmaSmoothDownLoad.mq5 | BSPWmaSmooth_Converter.py | inpWmaPeriod = 10, inpSmoothPeriod = 3 |
| 7 | Indicators/BSP105V9/BSPWmaSmoothDownLoad.mq5 | BSPWmaSmooth_Converter.py | inpWmaPeriod = 30, inpSmoothPeriod = 5 |
| 8 | Indicators/BSP105V9/Chaikin VolatilityDownLoad.mq5 | Chaikin_Verification.py | |
| 9 | Indicators/Test/TradesDynamicIndexDownLoad.mq5 | TDI_Verifier.py | |
| 10 | Indicators/Test/QQE DownLoad.mq5 | QQE_Verification.py | |
| 11 | Indicators/Test/ADXSmoothDownLoad.mq5 | adx_verifier.py | |
| 12 | Indicators/Test/ChandelieExitDownLoad.mq5 | chandelier_exit_verifier.py | |
| 13 | Indicators/Test/ChoppingIndexDownLoad.mq5 | chopping_verifier.py | |
| 14 | Indicators/Test/ADXSmoothMTFDownLoad.mq5 | ADXSmoothMTF_Converter.py | |
| 15 | Indicators/Test/ATRDownLoad.mq5 | ATR_Verifier.py | g_ATRPeriod = 14 |
15. **BWMFI MTF (Market Facilitation Index)**
    - **Script:** `BWMFI_MTF_Converter.py`
    - **MQL5:** `BWMFI_MTF.mq5` / `BWMFI_MTFDownLoad.mq5`
    - **Parameters:** `target_timeframe` (e.g., 'PERIOD_H1', 'PERIOD_M5'), `volume` (default 'TickVolume'), `point` (default 1.0, use 0.01 for XAUUSD)
    - **Verification:** Verified with MQL5 data (MAE: 0.0, Color Match: 100%). Supports "M1 Chart with Target Timeframe" output.
