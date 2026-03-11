# 데이터 수집 현황 및 Data Lake 아키텍처 메모

> 최종 업데이트: 2026-03-09

---

## Data Lake 파일 구조

> 프로 퀀트 표준(Data Lake) 방식으로 역할별 분리 저장

| 파일 | 내용 | 행수 | 컬럼수 | 크기 | 업데이트 주기 |
|:---|:---|:---:|:---:|:---:|:---|
| [tech_features.parquet](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/tech_features.parquet) | M1 기술 지표 (ADX, QQE, BWMFI 등) | 3,150,208 | 63 | 1.0 GB | 매일 |
| [tech_features_derived.parquet](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/tech_features_derived.parquet) | 기술 지표 파생 변환 (Z-score+pct240 Shift+1) | 7,424,421 | 165 | ~4.5 GB | 파생 스크립트 실행 시 |
| [macro_features.parquet](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/macro_features.parquet) | 매크로 파생 피처 (변화율/멀티스케일 Z-score) | 8,651 | 652 | 14 MB | 매주 |
| [labels_barrier.parquet](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/labels_barrier.parquet) | Triple Barrier 정답지 (Long/Short 분리) | ~7,424,357 | 6 | - | 라벨링 로직 수정 시 |
| [AI_Study_Dataset.parquet](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/AI_Study_Dataset.parquet) | **최종 AI 학습 데이터셋** | 2,659,938 | 817 | 1.35 GB | 병합 워크플로우 실행 시 |

---

## 수집된 전체 데이터 목록

### A. 기술 지표 (MT5 M1 차트 기반)

> **소스**: IC Markets MT5 브로커 | **타임프레임**: M1 | **기간**: 2015~2026

| 지표 카테고리 | 컬럼명 예시 | 설명 |
|:---|:---|:---|
| OHLCV | Open, High, Low, Close, TickVolume | M1 기본 가격 데이터 |
| BOP 계열 | BOP_Diff, BOP_Up1, BOP_Scale | 매수/매도 압력 (Balance of Power) |
| LRAVGST | Avg(60)_StdS, Avg(180)_BSPScale | 선형회귀 평균 및 표준편차 스케일 |
| BOPWMA / BSPWMA | (10-3), (30-5) SmoothBOP/DiffRatio | WMA 평활화 BOP (기울기만 의미있음) |
| CHV | (10-10), (30-30) CHV/StdDev/CVScale | 변동성 지수 |
| TDI | (13-34-2-7), (14-90-35) TrSi/Signal | 추세 방향 지수 |
| QQE | (5-14), (12-32) RSI/RsiMa/TrLevel | QQ 지수 (RSI 파생) |
| CE | Upl1, Dnl1, Upl2, Dnl2 | 샹들리에 청산선 |
| CHOP | (14-14), (120-40) CSI/Avg/Scale | 쵸핑 인덱스 (추세/횡보 판별) |
| ADX MTF | H4/M5 × DiPlus/DiMinus/ADX | 멀티타임프레임 ADX |
| ADX Smooth | (14), (80) × ADX/Avg/Scale/Di+/Di- | 평활화 ADX |
| BWMFI MTF | H4/M5 × BWMFI/Color | 빌 윌리엄스 MFI (거래량+가격) |

---

### B. 매크로 데이터 (Yahoo Finance — 1D 일봉)

> **소스**: Yahoo Finance (`yfinance`) | **타임프레임**: 1D | **기간**: 최대 1998~2026

| # | 데이터 | 파일명 | 가용 기간 | 설명 |
|:---:|:---|:---|:---:|:---|
| 1 | S&P 500 | `SP500.csv` | 1998~2026 | 미국 주식 시장 벤치마크 |
| 2 | NASDAQ | `NASDAQ.csv` | 2003~2026 | 기술주 모멘텀 |
| 3 | Dow Jones | `DOW.csv` | 1998~2026 | 미국 대형주 지수 |
| 4 | Russell 2000 | `RUSSELL2000.csv` | 2001~2026 | 소형주 경기반응 지수 |
| 5 | 독일 DAX | `DAX.csv` | 1998~2026 | 런던 세션 벤치마크 |
| 6 | 일본 니케이 | `NIKKEI.csv` | 1998~2026 | 아시아 세션 벤치마크 |
| 7 | 영국 FTSE | `FTSE100.csv` | 1998~2026 | 유럽 시장 (London) |
| 8 | 프랑스 CAC | `CAC40.csv` | 1998~2026 | 유럽 주식시장 |
| 9 | Euro Stoxx 50 | `STOXX50.csv` | 2007~2026 | 유럽 대표 50개 종목 |
| 10 | 홍콩 항셍 | `HANGSENG.csv` | 1998~2026 | 아시아 리스크 온/오프 |
| 11 | 호주 ASX 200 | `ASX200.csv` | 1998~2026 | 아시아-태평양 벤치마크 |
| 12 | **달러 인덱스 (DXY)** | `DXY.csv` | 1998~2026 | 달러 강약 핵심 지표 ★★★ |
| 13 | **VIX 공포지수** | `VIX.csv` | 1998~2026 | 시장 위험 회피 지표 ★★★ |
| 14 | **EUR/USD** | `EURUSD.csv` | 2003~2026 | 달러 강약 반영 (역상관) |
| 15 | USD/JPY | `USDJPY.csv` | 1998~2026 | 안전자산 흐름 |
| 16 | USD/CHF | `USDCHF.csv` | 2003~2026 | 스위스 프랑 (안전통화) |
| 17 | GBP/USD | `GBPUSD.csv` | 2003~2026 | 파운드 |
| 18 | AUD/USD | `AUDUSD.csv` | 2006~2026 | 원자재 통화 |
| 19 | USD/CAD | `USDCAD.csv` | 2003~2026 | 원유 연동 통화 |
| 20 | USD/MXN | `USDMXN.csv` | 2003~2026 | EM 스트레스 지표 |
| 21 | USD/ZAR | `USDZAR.csv` | 2003~2026 | EM 스트레스 지표 |
| 22 | USD/TRY | `USDTRY.csv` | 2005~2026 | EM 스트레스 지표 |
| 23 | **금 선물 (GC=F)** | `GOLD.csv` | 2000~2026 | XAUUSD 보조 데이터 |
| 24 | 은 (SI=F) | `SILVER.csv` | 2000~2026 | 금/은 비율 계산 |
| 25 | 플래티넘 | `PLATINUM.csv` | 1998~2026 | 귀금속 섹터 모멘텀 |
| 26 | 팔라듐 | `PALLADIUM.csv` | 1998~2026 | 귀금속 섹터 모멘텀 |
| 27 | WTI 원유 | `OIL_WTI.csv` | 2000~2026 | 에너지/인플레 선행 |
| 28 | 브렌트유 | `OIL_BRENT.csv` | 2007~2026 | 글로벌 원유 기준 |
| 29 | 천연가스 | `NAT_GAS.csv` | 2000~2026 | 에너지 인플레 |
| 30 | 밀 | `WHEAT.csv` | 2000~2026 | 식품 인플레 선행 |
| 31 | 커피 | `COFFEE.csv` | 2000~2026 | 소프트 상품 |
| 32 | 옥수수 | `CORN.csv` | 2000~2026 | 식품 인플레 |
| 33 | 설탕 | `SUGAR.csv` | 2000~2026 | 소프트 상품 |
| 34 | 면화 | `COTTON.csv` | 2000~2026 | 소프트 상품 |
| 35 | 대두 | `SOYBEAN.csv` | 2000~2026 | 식품 인플레 |
| 36 | **구리 (HG=F)** | `COPPER.csv` | 2000~2026 | Dr.Copper 경기 선행 ★★ |
| 37 | **미국 10년물 금리** | `UST10Y.csv` | 1998~2026 | 금 역상관의 핵심 ★★★ |
| 38 | 미국 5년물 금리 | `UST5Y.csv` | 1998~2026 | 장단기 금리차 계산 |
| 39 | 미국 30년물 금리 | `UST30Y.csv` | 1998~2026 | 장기 금리 트렌드 |
| 40 | 미국 3개월물 금리 | `UST3M.csv` | 1998~2026 | 단기 금리 |
| 41 | 비트코인 | `BITCOIN.csv` | 2014~2026 | 리스크온/디지털 금 |

---

### C. 경제 데이터 (FRED 연방준비은행 — 영업일 기준)

> **소스**: FRED API (`fredapi`) | **타임프레임**: 영업일(D1) | **기간**: 1998~2026

| # | 데이터 | 파일명 | 가용 기간 | 설명 |
|:---:|:---|:---|:---:|:---|
| 1 | **10년 실질금리 (TIPS)** | `REAL_RATE_10Y.csv` | 2003~2026 | 금 가격 가장 강한 역상관 ★★★ |
| 2 | 10년 명목 국채 수익률 | `NOMINAL_10Y.csv` | 1998~2026 | 금리 수준 기준 |
| 3 | 5년 명목 국채 수익률 | `NOMINAL_5Y.csv` | 1998~2026 | 장단기 금리차 계산 |
| 4 | 2년 명목 국채 수익률 | `NOMINAL_2Y.csv` | 1998~2026 | 경기침체 선행 지표 |
| 5 | 30년 명목 국채 수익률 | `NOMINAL_30Y.csv` | 1998~2026 | 장기 금리 추세 |
| 6 | VIX (FRED 버전) | `VIX_FRED.csv` | 1998~2026 | 공포지수 (FRED 소스) |
| 7 | 연방기준금리 | `FED_FUNDS_RATE.csv` | 1998~2026 | Fed 통화정책 방향 |
| 8 | **10년 기대인플레이션** | `BREAKEVEN_10Y.csv` | 2003~2026 | 금 보유 이유 핵심 ★★★ |
| 9 | **5년 기대인플레이션** | `BREAKEVEN_5Y.csv` | 2003~2026 | 단기 인플레 기대 |
| 10 | **10Y-2Y 장단기 금리차** | `YIELD_CURVE_10_2.csv` | 1998~2026 | 역전=경기침체 선행 ★★ |
| 11 | EUR/USD (FRED) | `EURUSD_FRED.csv` | 1999~2026 | 달러 강약 |
| 12 | WTI 원유 (FRED) | `OIL_WTI_FRED.csv` | 1998~2026 | 에너지 가격 |
| 13 | **하이일드 채권 스프레드** | `HY_SPREAD.csv` | 1998~2026 | 시장 리스크 프리미엄 ★★ |
| 14 | 투자등급 채권 스프레드 | `IG_SPREAD.csv` | 1998~2026 | 신용 리스크 |
| 15 | USD/MXN (FRED) | `USDMXN_FRED.csv` | 1998~2026 | EM 스트레스 |
| 16 | USD/CHF (FRED) | `USDCHF_FRED.csv` | 1998~2026 | 스위스 프랑 |
| 17 | USD/JPY (FRED) | `USDJPY_FRED.csv` | 1998~2026 | 엔화 |
| 18 | 미국 경기침체 더미 | `RECESSION.csv` | 1998~2026 | 경기침체 기간 (월별) |
| 19 | 미시간 소비자 심리지수 | `CONSUMER_SENT.csv` | 1998~2026 | 소비 심리 (월별) |

---

## 다음 단계 — 2026-03-09 갱신

1. ✅ **전처리 파이프라인**: `tech_features.parquet` → `tech_features_derived.parquet` 파생 완료 (pct240/pct1440 45개 피처 포함)
2. ✅ **ATR 동적 배리어 라벨링**: ATR(14)×2.5 TP/SL, 30봉, Friction $0.30, Long전용 → `labels_barrier.parquet` 완료
3. ✅ **피처 병합**: Macro Shift+1 + merge_asof + dropna → `AI_Study_Dataset.parquet` (817컬럼, 266만행) 완료
4. ✅ **무결성 검증**: 5/5 PASS
5. ✅ **AI 학습 1라운드**: Feature Pruning(811→419) + LightGBM 5-Fold(AUC=0.7967) + SHAP Top-60 (pct 피처 11개 선발)
6. ✅ **AI 학습 2라운드**: A+B+C 통합 모델 — AUC=0.8298, OOS 3/3 PASS, M30>35+thr=0.25 승률 **56.3%** (549건)
7. 👉 **ONNX 내보내기**: `model_long.onnx` → MQL5 EA 탑재 ← **현재 단계**

---

## 수집 스크립트 참조

| 스크립트 | 용도 |
|:---|:---|
| [fetch_macro_data.py](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/Tools/fetch_macro_data.py) | Yahoo Finance 41개 매크로 수집 |
| [fetch_fred_data.py](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/Tools/fetch_fred_data.py) | FRED 19개 경제 지표 수집 |
| [build_data_lake.py](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/Tools/build_data_lake.py) | CSV → Data Lake Parquet 빌드 |
| [peek_schema.py](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/Tools/peek_schema.py) | Parquet 스키마 초고속 확인 |






종합하면, XAUUSD 1랏(100온스) 거래 시 순수 진입/청산 마찰 비용(스프레드+커미션)은 18포인트 내외이나, **불리한 슬리피지 및 뉴스 이벤트를 감안하여 시스템 전체적으로 `Friction Cost = 30포인트($0.30)`를 보수적인 강제 표준으로 차감**해야 합니다. (AI 전략 개발 3대 핵심 원칙 중 2번째)

---

## macro_features.parquet 컬럼 사전

> **파일 위치**: `Files/processed/macro_features.parquet`
> **총 컬럼**: 360개 (60개 자산 × 6개 파생 피처) | **총 행수**: 8,651행 | **기간**: 1998-01-01 ~ 2026-02-23
> **검증일**: 2026-02-24 | **교차 검증**: SP500 기준 5개 파생 피처 전부 **PASS** (float32 허용 오차 < 0.01)

### 파생 피처 유형 (6가지)

모든 자산에 대해 아래 6가지 파생 피처가 동일하게 생성됩니다. 원본 절대값은 저장하지 않습니다.

| 접미사 | 설명 | 계산 로직 |
|:---|:---|:---|
| `_ret1d` | 1일 수익률 (%) | `pct_change(1) * 100` |
| `_ret5d` | 5일 수익률 (%) | `pct_change(5) * 100` |
| `_ret21d` | 21일 수익률 (%) | `pct_change(21) * 100` |
| `_zscore_60` | 60일 롤링 Z-Score (1시간) | `(Close - rolling(60).mean) / rolling(60).std` |
| `_zscore_240` | 240일 롤링 Z-Score (4시간) | `(Close - rolling(240).mean) / rolling(240).std` |
| `_zscore_1440` | 1440일 롤링 Z-Score (1일) | `(Close - rolling(1440).mean) / rolling(1440).std` |
| `_slope` | 10일 기울기 | `diff(10) / 10` |
| `_accel` | 가속도 (기울기의 변화) | `slope.diff(10)` |

### 자산 목록 (60종)

#### Yahoo Finance (41종)

| # | Prefix | 자산명 | 카테고리 |
|---:|:---|:---|:---|
| 1 | `SP500` | S&P 500 | 주가지수 |
| 2 | `NDX` | NASDAQ 100 | 주가지수 |
| 3 | `DOW` | Dow Jones 30 | 주가지수 |
| 4 | `RUT` | Russell 2000 | 주가지수 |
| 5 | `DAX` | 독일 DAX | 주가지수 |
| 6 | `NKY` | 일본 Nikkei 225 | 주가지수 |
| 7 | `FTSE` | 영국 FTSE 100 | 주가지수 |
| 8 | `CAC` | 프랑스 CAC 40 | 주가지수 |
| 9 | `SX5E` | Euro Stoxx 50 | 주가지수 |
| 10 | `HSI` | 홍콩 Hang Seng | 주가지수 |
| 11 | `ASX` | 호주 ASX 200 | 주가지수 |
| 12 | `DXY` | 달러 인덱스 | 외환 |
| 13 | `VIX` | CBOE 변동성 지수 | 변동성 |
| 14 | `EURUSD` | EUR/USD | 외환 |
| 15 | `USDJPY` | USD/JPY | 외환 |
| 16 | `USDCHF` | USD/CHF | 외환 |
| 17 | `GBPUSD` | GBP/USD | 외환 |
| 18 | `AUDUSD` | AUD/USD | 외환 |
| 19 | `USDCAD` | USD/CAD | 외환 |
| 20 | `USDMXN` | USD/MXN | 외환 (이머징) |
| 21 | `USDZAR` | USD/ZAR | 외환 (이머징) |
| 22 | `USDTRY` | USD/TRY | 외환 (이머징) |
| 23 | `GOLD` | 금 선물 (GC) | 원자재 |
| 24 | `SILVER` | 은 선물 (SI) | 원자재 |
| 25 | `PL` | 백금 선물 | 원자재 |
| 26 | `PA` | 팔라듐 선물 | 원자재 |
| 27 | `WTI` | WTI 원유 선물 | 에너지 |
| 28 | `BRENT` | 브렌트유 선물 | 에너지 |
| 29 | `GAS` | 천연가스 선물 | 에너지 |
| 30 | `WHEAT` | 밀 선물 | 농산물 |
| 31 | `COFFEE` | 커피 선물 | 농산물 |
| 32 | `CORN` | 옥수수 선물 | 농산물 |
| 33 | `SUGAR` | 설탕 선물 | 농산물 |
| 34 | `COTTON` | 면화 선물 | 농산물 |
| 35 | `SOYBEAN` | 대두 선물 | 농산물 |
| 36 | `COPPER` | 구리 선물 | 산업금속 |
| 37 | `UST10Y` | 미국 10년 국채 수익률 | 채권 |
| 38 | `UST5Y` | 미국 5년 국채 수익률 | 채권 |
| 39 | `UST30Y` | 미국 30년 국채 수익률 | 채권 |
| 40 | `UST3M` | 미국 3개월 T-Bill 수익률 | 채권 |
| 41 | `BTC` | 비트코인 (BTC-USD) | 암호화폐 |

#### FRED (19종)

| # | Prefix | 시리즈 ID | 카테고리 |
|---:|:---|:---|:---|
| 42 | `TIPS10Y` | DFII10 | 실질금리 |
| 43 | `DGS10` | DGS10 | 명목금리 10Y |
| 44 | `DGS5` | DGS5 | 명목금리 5Y |
| 45 | `DGS2` | DGS2 | 명목금리 2Y |
| 46 | `DGS30` | DGS30 | 명목금리 30Y |
| 47 | `VIX_FRED` | VIXCLS | 변동성 (FRED) |
| 48 | `FEDFUNDS` | FEDFUNDS | 연방기금금리 |
| 49 | `BEI10Y` | T10YIE | 기대인플레 10Y |
| 50 | `BEI5Y` | T5YIE | 기대인플레 5Y |
| 51 | `YC_10_2` | T10Y2Y | 수익률 곡선 (10Y-2Y 스프레드) |
| 52 | `EURUSD_FR` | DEXUSEU | EUR/USD (FRED) |
| 53 | `WTI_FRED` | DCOILWTICO | WTI 원유 (FRED) |
| 54 | `HY_SPRD` | BAMLH0A0HYM2 | 하이일드 스프레드 |
| 55 | `IG_SPRD` | BAMLC0A0CM | 투자등급 스프레드 |
| 56 | `MXUS_FR` | MXUS | MSCI 미국 |
| 57 | `SZUS_FR` | SZUS | MSCI 미국 소형주 |
| 58 | `JPUS_FR` | JPUS | MSCI 미국 (JPM) |
| 59 | `USREC` | USREC | 미국 경기침체 지표 |
| 60 | `UMCSENT` | UMCSENT | 미시간 소비자심리 |

### 교차 검증 결과 (2026-02-24 실행)

| 피처 | Parquet 값 | CSV 재계산 값 | 판정 |
|:---|---:|---:|:---:|
| `SP500_ret1d` | -1.038565 | -1.038565 | PASS |
| `SP500_ret5d` | 0.023114 | 0.023113 | PASS |
| `SP500_ret21d` | -1.093538 | -1.093538 | PASS |
| `SP500_zscore_60` | 0.401036 | 0.401036 | PASS |
| `SP500_zscore_240` | 0.231201 | 0.231201 | PASS |
| `SP500_zscore_1440`| 0.113401 | 0.113401 | PASS |
| `SP500_slope`  | -0.00164 | -0.00164 | PASS |

> **결론**: `build_data_lake.py`의 `calc_macro_features()` 함수가 원본 CSV에서 정확하게 파생 피처를 계산하여 Parquet에 저장하고 있음을 확인. float32 다운캐스팅에 의한 미세 오차(< 0.000001)만 존재하며 품질에 영향 없음.


## 5. [AI 모델 파이프라인] 피처 엔지니어링 실전 원칙 — 2026-03-09 갱신

> **갱신 근거**: A+B+C 모델 실험 (AUC=0.8298, OOS 3/3 PASS, M30>35+thr=0.25 승률 **56.3%**)
> Z-score만으로는 레짐 불일치(IS: 완만 상승, OOS: 폭등) 해결 불가 → 롤링 퍼센타일 랭크 + 단조 제약 + 레짐 피처 조합이 핵심

1. **공선성 검증**: 상관계수 **0.85** 이상인 피처 쌍은 하나로 합치거나 제거. Tie-Breaker: Target(Y)과의 MI가 낮은 쪽 제거. **실측: 811→419개 (Spearman 0.85 기준)**
2. **피처 선택 (2단계)**: 
   - **1라운드**: 메가 풀(~811개) → Spearman Pruning → LightGBM 5-Fold → SHAP Top-60 자동 선별
   - **2라운드**: Top-60 + 동적 퍼센타일(+16) + 레짐 피처(+4) = **80개 최종 피처** → A+B+C 통합 학습
3. **파생 피처 유형 (원본 절대값 금지)**:
   - **기본 5유형 (강제)**: 가속도, 멀티스케일 Z-Score(60/240, 1440 선택), 비율(MA 대비), Slope(기울기), **롤링 퍼센타일 랭크(pct240/pct1440)** ★
   - **롤링 퍼센타일 랭크 (검증 완료, 필수)**: `x.shift(1).rolling(W).rank(pct=True)` — Z-score의 레짐 불일치를 해결하는 핵심 보완 유형. `ADXMTF_H4_DiPlus_pct240`이 SHAP 전체 2위(0.233) 기록. **IS 전체 기준 rank 금지, 반드시 rolling(240) 사용** (실측: rolling이 IS기준 대비 OOS 승률 +7%p)
   - **레벨값 전용 (강제)**: 변화율(Δ%) — 가격·금리·환율 레벨 데이터에만 적용. 스케일 오실레이터(0~100)에는 Slope로 대체 허용
   - **조건부 (SHAP 기반)**: 정규화 이격도(가격 기반 지표 전용), 롤링 상관계수(SHAP 상위 쌍 한정)
   - **스케일 오실레이터 예외**: BOP_Scale, QQE_RSI, TDI_Signal, CHOP_Scale, ADXS_Scale 등 Passthrough 허용
4. **Tick Volume**: 절대값 금지. MA 비율(60/240/1440) 3개 + Z-Score(60/240) 2개 + **pct240 1개** 투입. SHAP이 유효 피처 선별
5. **세션 인코딩**: 트리 모델은 One-hot, 딥러닝은 sin/cos 순환 인코딩
6. **LightGBM 단조 제약 (방안 B, 검증 완료)** ★:
   - 도메인 지식 기반 `monotone_constraints` 적용: **+1=19개 / -1=8개 / 0(자유)=53개**
   - 예: DiPlus↑→Win(+1), DiMinus↑→Loss(-1), QQE_RSI→비선형(0)
   - **단독 사용 시 OOS FAIL (0/3)** — 반드시 퍼센타일 랭크와 조합 필수
   - `monotone_constraints_method = "advanced"` 사용
7. **레짐 인식 피처 (방안 C, 검증 완료)**:
   - 4개 피처: `regime_monthly_pct`, `regime_weekly_up_ratio`, `regime_above_ma20w`, `regime_bull_flag`
   - **2라운드 학습 스크립트 내에서 Close로부터 실시간 계산** (별도 파이프라인 불필요)
   - 중요도 하위 30%이나 **신호 수 +25% (437→549건)** 효과 — 진입 강도 미세 조절 역할
   - **모두 단조 +1 제약** (강세장일수록 Win 확률 높음)
   - `above_ma20w`, `bull_flag`는 binary 특성상 기여 미미 → 향후 연속값 대체 검토
8. **롱/숏 분리 학습 + 단일 EA 통합**:
   - Stage A: 분리 학습 → 방향별 SHAP 독립
   - Stage B: Walk-Forward 3단계 검증 (각 모델 독립)
   - Stage C: `model_long.onnx` + `model_short.onnx` → 단일 EA, 비대칭 임계치(롱 > 0.25 & 숏 > 0.70) ← **롱 임계치 0.55→0.25로 실측 기반 하향**
   - Stage D (선택): 매크로 게이트키퍼
9. **피처 안정성 모니터링**: PSI > 0.25 → 재학습 트리거. Walk-Forward Fold간 SHAP 급변 시 과적합 경고
10. **다중 검정 보정**: BH-FDR 필수. SHAP Top-60도 5-Fold 중 3회 이상 등장 피처만 채택
11. **이상치 처리**: Winsorization 상하 1~5% 클리핑. **X_train 기준 percentile만 적용** (미래 누수 방지)
12. **캘린더/이벤트 피처**: 요일·월·시간 sin/cos, 월말 플래그, FOMC/NFP 48시간 원핫
13. **피처 중요도 시간적 일관성**: 분기별 SHAP 비교. 레짐 의존 피처는 레짐 피처(방안 C)와 함께 조건부 투입
14. **Z-score 한계 인식 (실험적 확인)** ★: Z-score는 rolling(W) 기간의 평균/표준편차에 고정되어 **레짐 전환 시 스케일 불일치** 발생. IS(완만 상승)→OOS(폭등)에서 동일 Z값이 전혀 다른 시장 강도를 의미 → **pct240 병행 필수**. 실측: pct240 적용 후 OOS 승률 33%→52%

### 🗄️ 벡터 DB 임베딩 전략

**구축 로드맵**: Phase 1(기초 인프라 + 유사 패턴 검색) → Phase 2(메타 라벨링 강화) → Phase 3(에이전트 메모리 통합)

1. **차원 축소 (2단계 접근)**:  108개 전 피처를 윈도우(30봉) 벡터화하면 차원의 저주 발생 (108×30=3240차원)
   - **1라운드 (SHAP 이전)**: PCA 또는 Autoencoder로 차원 축소 (누적 분산 90% 이상 기준). 모델 학습 전 유사 패턴 탐색·메타 라벨링에 활용
   - **2라운드 (SHAP 이후)**: SHAP 상위 핵심 피처 세트로 재임베딩하여 정제된 VectorDB 구축
2. **청크 단위 메모리 최적화 (OOM 방지 필수)**: 742만 개 대용량 시계열 벡터화 시 OOM 발생. 연/분기 또는 봉 개수(예: 50만개) 단위 chunking 적용. **⚠️ 청크 경계에서 윈도우 크기만큼 오버랩(overlap) 필수** (예: 30봉 윈도우 시 29봉 오버랩하여 경계 벡터 불완전 방지)
3. **Z-Score/랭크 스케일링 (왜곡 방지)**: 임베딩 전에 반드시 피처 스케일링 완료 필수 (원본값 크기 차이에 의한 벡터 유사도 왜곡 차단)
4. **결측치 사전 Imputation**: 벡터 공간에는 NaN 투입 불가. 부득이한 NaN(웜업 등)은 중앙값(Median) 또는 0(Z-score인 경우)으로 완벽히 전처리 후 임베딩 통과
5. **멀티스케일 윈도우 4계층**: M1 30봉(30분, 즉시 진입) + M1 240봉(4시간, 세션 방향) + H1 24봉(1일, 일간 추세) + H1 120봉(1주, 레짐/매크로) 4계층 병렬 저장. 검색 시 스케일별 유사도 가중 합산
6. **메타데이터 동시 저장**: `time`(생성 시점), `session`(장세), `volatility_percentile`, `label_result` → 시맨틱+구조적 하이브리드 검색. 레짐 판별은 추후 복합 지표(ADX+ChopIndex+ATR Z-Score) 기반 별도 설계
7. **미래 참조 방지 (Time-Series Leakage 차단) 🚨**: 유사도 검색 시 쿼리 시점보다 미래 봉 반환은 심각한 편향 누수. ChromaDB 쿼리 시 반드시 `where={"time": {"$lt": current_query_time}}` 메타데이터 조건 강제 적용
8. **⚠️ Winsorization 적용 시점**: 2계층 Parquet에는 클리핑 **절대 적용 금지**. 임베딩/학습 파이프라인에서만 `X_train` 기준 percentile로 적용 (아래 원칙 #7 참조)
9. **CE 트레일링 SL 래칫 리셋**: 래칫 장기 누적 시 Z-score NaN/Inf 폭발. 추세 이탈(`close < SL`) 시 리셋 로직(`CE_TrailingStop.py`) 적용된 피처만 임베딩 투입
10. **fat-tail 피처 허용**: `CHV StdDev` 등 금 시장 특유 두꺼운 꼬리(std 5~15)는 정상. 2계층 보존 후 학습/임베딩 시 Winsorization으로 통제

📊 데이터베이스 작성 핵심 10원칙 (Strategy Rules + Feature Engineering 통합)
1. **Rule_Shift+1** (미래 참조 편향 방지 원칙) ★★★
상위 타임프레임(H1 등)이나 매크로 데이터를 M1(1분봉) 기준 데이터와 병합할 때, 반드시 직전 완성봉(Shift+1)의 데이터만 사용해야 합니다. Z-score 계산 시 `x.shift(1).rolling(W)`, Macro 병합 전 `shift(1)` 적용. (미래 정보 참조 완전 차단)
2. **Rule_No_Absolute_Values** (절대값 사용 엄격 금지 + 파생 유형 체계) ★★★
매크로 지표, 가격, 금리 환율 등의 데이터 원본은 절대 그대로 투입 금지. 다음 체계에 따라 변환 후 저장/투입:
   - **기본 4유형 (강제)**: 가속도, 멀티스케일 Z-Score(60/240, 1440 선택), 비율, Slope
   - **레벨값 전용 (강제)**: 변화율(Δ%) — 매크로·가격·금리 레벨 데이터에 적용. 스케일 오실레이터(0~100 범위)에는 Slope로 대체 허용
   - **조건부**: 정규화 이격도(가격 기반 지표 전용), 롤링 상관계수(SHAP 상위 피처 쌍 한정, 2라운드)
   - **스케일 오실레이터 예외**: BOP_Scale, QQE_RSI, TDI_Signal, CHOP_Scale, ADXS_Scale 등은 Passthrough 허용
   - **Tick Volume**: 절대값 금지. MA 비율(60/240/1440) 3개 + Z-Score(60/240) 2개 병행 생성
   - **BOPWMA/BSPWMA**: Slope + Accel + Slope_Zscore만 허용 (원본 DROP)
3. **Rule_Friction_Cost_30pt** (마찰 비용 강제 적용 원칙) ★★
데이터 기반 수익성 평가나 실패 판단 시, XAUUSD 거래 평균 슬리피지 및 수수료를 감안한 **마찰비용 30포인트($0.30)**를 매 거래마다 강제로 차감한 보수적 기준을 적용해야 합니다.
4. **TrailingStop_Exit_Only** (청산 역할 분리 원칙)
라벨링 정답지나 모델은 진입만 판단하도록 설계되며, 백테스트/시뮬레이션 청산 시에는 고정 TP(Take Profit) 개입 없이 TrailingStopVx가 청산을 전담하도록 분리해야 합니다.
5. **Warm-up dropna 필수** (기술적 무결성 원칙)
2계층 macro_features.parquet의 각 자산별 첫 데이터 구간(~1440행)은 rolling(1440) 등의 지표 웜업으로 인해 필연적으로 NaN이 포함됨. M1 데이터와 병합하는 최종 스크립트에서는 반드시 dropna()를 호출하여 찌꺼기(불완전) 데이터를 완벽히 제거해야 함. (단, 2계층 저장 단계에서는 dropna 금지)
6. **ffill 정책 및 bfill 완전 금지** (시계열 매핑 원칙)
국가별 휴장일 차이 등으로 발생한 매크로 피처 빈 공간(NaN)은 직전 거래일 값을 유지하는 ffill(Forward Fill) 로만 처리해야 함. 미래 데이터를 끌어다 채우는 bfill은 미래참조이므로 절대 사용 금지.
7. **Winsorization** (이상치 클리핑 원칙)
극단적 이상치(Z-score ±10 이상 가능) 발생 시 삭제 대신 **상하위 1%~5% 클리핑(Winsorization)** 으로 극단 이벤트 정보 보존. 딥러닝 모델은 필수 적용, 트리 모델(LightGBM)은 선택 적용.
   - **⚠️ 적용 시점 (절대 원칙)**: 2계층 Parquet 저장 시 클리핑 **금지**. 반드시 **모델 학습 파이프라인 내에서 `X_train` 기준 percentile**로 적용. 전체 데이터 기준 percentile 사용 시 Walk-Forward 미래 정보 누수 발생.
   - 적용 코드: `clip_lo = X_train.quantile(0.01)` → `X_train.clip(clip_lo, clip_hi)` → 동일 기준으로 `X_valid`도 클리핑

---



### 학습/검증/백테스트 구간 (AI_Study_Dataset 기준: 2018-08 ~ 2026)

> **데이터 제약**: BTC_zscore_1440 등 매크로 rolling(1440) 웜업으로 인해
> 2018-08 이전 데이터는 NaN으로 dropna 제거됨. 클린 데이터 265만 행.

```
[학습 구간 (IS)]
  2018-08~2022-12 (약 4.5년) ← COVID 전후 + 금리인상 초기
[검증 구간 (OOS)]
  2023-01~2024-06 (약 1.5년) ← 금리 고점 / 신고가 레짐
[최종 백테스트]
  2024-07~2026 (약 1.5~2년) ← 완전 미보유 최신 데이터
```

> **Walk-Forward 3단계 검증**은 위 구간 내에서 Expanding Window로 수행.
> 2005~2017 데이터는 매크로 결측으로 사용 불가 (대안③ 채택, NaN 과적합 방지).


[QQE 눌림목 정밀 타점 라벨링 (3-Barrier) 요약](qqe_labeling_optimization_report.md)




## 후보 A (LightGBM + Purged K-Fold) ← 학습방법 — 2026-03-07 갱신

### 1. SHAP 분산 왜곡 방지 (다중공선성 사전 제거 - Feature Pruning) ✅ 필수
**문제점**: 772개 피처 중 상당수가 수리적으로 유사 (예: ADX_Slope↔ADX_Accel, Z-score 60↔240). 트리 모델 예측엔 영향 없으나, SHAP 중요도에서 핵심 피처 기여도가 유사 피처군으로 분산(100% → 33%×3)되어 하위권으로 밀리는 왜곡 발생.
**대안 (필수)**: SHAP 분석 직전, 스피어만 상관계수 또는 **계층적 군집화(Ward linkage)**로 상관계수 **0.85 이상** 중복 피처군을 찾아 대표 1개만 잔존. (0.95는 완전 복사본만 잡아내므로 불충분, GEMINI.md 원칙과 일치하는 0.85 적용)

### 2. 비대칭 손실 함수 (Custom Asymmetric Loss) ⏳ 2라운드에서 적용
**문제점**: 표준 Logloss는 FP(섣부른 진입→손절)와 FN(기회 놓침)에 동일 페널티. 트레이딩에서는 FP가 실자본 손실이므로 비대칭.
**판단**: 1라운드 목표는 "핵심 피처 발굴"이므로 표준 Logloss 사용. 비대칭 손실을 1라운드에 넣으면 모델이 보수적으로 학습 → "안전한 피처"가 상위로 올라가 SHAP 왜곡.
**적용 순서**:
```
1라운드: 표준 Logloss + SHAP → 핵심 피처 60개 선별
2라운드: 핵심 60개 + 비대칭 포컬 로스 → 최종 스나이퍼 모델
```

### 3. Walk-Forward 연속 학습 (Expanding Window) ✅ 필수 — 윈도우 조정됨
**문제점**: 전체 데이터를 K-Fold로 섞으면 레짐(Regime) 변화 무시. 데이터 7.5년이므로 원래 3년 학습 윈도우 조정 필요.
**대안**: Expanding Window 방식 (시작점 고정, 끝점 확장) — 7.5년 데이터를 버리지 않고 점진 확장:

| 항목 | 설정 |
|:---|:---|
| 학습 | 2~2.5년 시작 → Expanding |
| 검증 | 6개월 고정 |
| 총 검증 | ~8~10회 |

> Rolling(고정 폭 슬라이딩)보다 Expanding이 적합: 7.5년이라 학습 데이터를 버리기 아까움.




## 📅 데이터 최대 활용 전략 (2018-08~2026, 약 7.5년) — 2026-03-07 갱신

> **데이터 제약사항**: BTC/FEDFUNDS/UMCSENT 매크로 rolling 웜업으로 2018-08 이전 NaN.
> 대안③ 채택 (NaN 과적합 방지를 위해 클린 데이터만 사용).

### XAUUSD 시장 레짐 맵 (2018~2026)

| 구간 | 기간 | 레짐 특징 |
|:---|:---|:---|
| 🟡 2018-08~2019-06 | ~1년 | 횡보/완만 상승 (미중 무역전쟁) |
| 🟡 2019-07~2020-08 | ~1년 | COVID 전후 급등 ($1,500→$2,075) |
| 🔴 2020-08~2022-09 | ~2년 | 조정/횡보 ($2,075→$1,615, 금리인상) |
| 🟡 2022-10~2024-10 | ~2년 | 중앙은행 매수 + 지정학 신고가 ($2,800) |
| 🟡 2024-11~2026 | ~1.5년 | 최신 데이터 (검증용) |

### 확장된 파이프라인 설계

```
[롱 모델 — 클린 데이터 활용]

┌─ 학습 데이터 (IS) ──────────────────────────────
│  2018-08~2022-12 (약 4.5년)
│  ← 횡보 + COVID 급등 + 금리인상 조정 레짐 포함
│
├─ Purged Walk-Forward 튜닝 ──────────────────────
│  시간순 Expanding Window:
│  Fold1: 2018-08~2019-12 학습 → 2020-01~06 검증
│  Fold2: 2018-08~2020-06 학습 → 2020-07~12 검증
│  Fold3: 2018-08~2020-12 학습 → 2021-01~06 검증
│  Fold4: 2018-08~2021-06 학습 → 2021-07~2022-06 검증
│  Fold5: 2018-08~2022-06 학습 → 2022-07~12 검증
│  → COVID 전후 + 금리전환기 등 서로 다른 레짐 5회 교차 검증
│
└─ Walk-Forward 최종 검증 (완전 OOS) ──────────────
   Step1: 2023-01~2023-06 (6개월) → 최소 생존
   Step2: 2023-01~2024-06 (1.5년) → 안정성
   Step3: 2024-07~2026    (1.5~2년) → 최신 실전 신뢰
```

```
[숏 모델 — 클린 데이터 활용]

┌─ 학습 데이터 (IS) ──────────────────────────────
│  2020-08~2022-09 (약 2년, 주 하락/조정 구간)
│  + 2018-08~2019-06 (약 1년, 횡보 숏 기회)
│
├─ Purged Walk-Forward 튜닝 ──────────────────────
│  Fold1: 2018-08~2020-12 학습 → 2021-01~06 검증
│  Fold2: 2018-08~2021-06 학습 → 2021-07~2022-06 검증
│  Fold3: 2018-08~2022-06 학습 → 2022-07~12 검증
│
└─ Walk-Forward 최종 검증 ────────────────────────
   2024-2025 하락/조정 구간에서 검증
```

### AI 학습 전체 흐름 — 2026-03-07 갱신

```
Step 0-2. 데이터 빌드 (/data-build 워크플로우)
   └─ build_micro_tech.py → build_tech_derived.py → build_labels_barrier.py
   └─ merge_features.py → verify_merged_dataset.py
   └─ 결과: AI_Study_Dataset.parquet (772컬럼, 265만행, 2018-08~2026)

Step 3. AI 학습 — 완료 ✅ (2026-03-08)
   ┌─ [1라운드] train_round1.py
   │   └─ Feature Pruning: 811→419개 (Spearman 0.85)
   │   └─ 5-Fold AUC=0.7967±0.0211
   │   └─ SHAP Top-60 (pct240 피처 11개 선발)
   │
   └─ [2라운드] train_round2_ABC.py (A+B+C 통합)
       └─ 방안A: pct 동적 랭크 | 방안B: 단조 제약 | 방안C: 레짐 4피처
       └─ 총 80피처, AUC=0.8298
       └─ OOS 3/3 PASS (49.5%/47.8%/45.0%)
       └─ M30>35+thr=0.25: **56.3% 승률 (549건)**

Step 4. Walk-Forward 검증 — 완료 ✅
   └─ Step1: 2023-01~06 → 49.5% PASS
   └─ Step2: 2023-01~2024-06 → 47.8% PASS
   └─ Step3: 2024-07~2026 → 45.0% PASS
   └─ 모델 파일: models/round2_ABC/model_long_ABC.txt
```

### 기대 수익 (승률 70%, TP=3ATR, SL=CE_Upl2, 0.01랏)

| 항목 | 롱 단독 | 롱+숏 병행 |
|:---|:---:|:---:|
| EV/건 | +$3.42 | +$3.42 |
| 연간 매매 | 20회 | **40회** |
| 연간 수익 (0.01랏) | $68 | **$137** |
| 연간 수익 (0.5랏) | $3,420 | **$6,840** |
| Profit Factor | 2.28 | 2.28 |
| Sharpe (추정) | ~1.5 | **~2.0+** |

### 주의사항
- 데이터 범위: 2018-08 ~ 2026 (약 7.5년, 265만 M1봉). BTC/FEDFUNDS/UMCSENT의 rolling(1440/240) 웜업으로 이전 데이터 사용 불가 (대안③ 적용)
- 매크로 rolling(1440) 이상 파생 컬럼 중 100% NaN 4개 자동 제거됨 (FEDFUNDS/UMCSENT `_1440`)
- 롱/숏 모델은 **완전 분리 학습** (라벨, 모델, SHAP 모두 독립)

## 8. 근본 문제 인식: Z-Score의 한계와 레짐 불일치

> 기록일: 2026-03-08

### 문제의 핵심

> "학습기간과 OOS 기간의 금 상승 기울기(레짐)가 근본적으로 다르다"

```
학습기간 (2018~2022): XAUUSD $1,200 ~ $2,000 (완만한 상승/하락 반복)
OOS 기간  (2023~2026): XAUUSD $1,800 → $3,100+ (역사적 폭등, 기울기 2~3배)

모델이 학습한 것:  "이런 기울기 패턴이면 Win이다" (패턴 매칭, 유사도 검색)
실제로 필요한 것: "기울기가 X 이상이면 Win이다" (방향성 조건, 크다/작다)
```

**결과**: OOS에서 기울기가 학습 시절보다 훨씬 커져도, 모델은 "학습에서 본 적 없는 패턴"으로 인식 → 신호 미발생 또는 승률 하락.

### Z-Score가 만들어내는 왜곡

```python
# Z-score (현재 방식): 절대 스케일에 고정됨
z = (x - x.rolling(240).mean()) / x.rolling(240).std()

# 학습 시절: 기울기 = 5.0, rolling mean = 4.0, std = 1.0 → z = 1.0 (정상 범위)
# OOS 기간:  기울기 = 12.0, rolling mean = 10.0, std = 1.5 → z = 1.33 (모델은 "비슷하다"고 판단)
# 실제로는 훨씬 강한 추세인데 Z-score는 비슷한 수치!

# 더 심한 경우:
# OOS 기간:  기울기 = 20.0, rolling mean = 16.0, std = 2.0 → z = 2.0 → 학습 분포 경계
# 모델: "이런 극단값은 학습 때 없었다" → 예측 신뢰도 낮음
```

---

## 9. 해결 방안: 3가지 접근법

### 방안 A. 롤링 퍼센타일 랭크 (1순위 권장)

Z-score 대신 **"최근 N봉 중 몇 %보다 강한가"** 로 피처 재정의.

```python
# 현재 (절대 스케일에 고정 — 레짐 변화에 취약):
z_score = (x - x.rolling(240).mean()) / x.rolling(240).std()

# 개선 (상대 서열, 스케일 독립 — 폭등장에도 유효):
pct_rank = x.rolling(240).rank(pct=True)   # 0.0~1.0
# 0.90 → "최근 240봉 중 상위 10% 강도"
# 0.95 → "최근 240봉 중 상위 5% 강도"  ← 폭등장에서도 항상 유효!
```

**핵심 장점**:
- OOS에서 금이 역대급으로 치솟아도 **"최근 기준으로 얼마나 강한가"** 는 항상 유효
- 모델이 "비슷한 값 검색"이 아닌 **"X보다 크다"** 조건을 자연스럽게 학습
- 레짐이 바뀌어도 피처 분포 0~1 고정 → 학습/OOS 동일한 스케일

#### Top-60 기준 퍼센타일 랭크 적용 대상 (상세)

**그룹 1 — 절대값 피처 → 퍼센타일 필수** (레짐 스케일 완전 의존)

| 현재 피처명 | 문제 | 개선 피처명 |
|:---|:---|:---|
| `ADXMTF_M5_DiPlus` | 절대값, 레짐별 스케일 다름 | `ADXMTF_M5_DiPlus_pct240` |
| `ADXMTF_H4_DiPlus` | 절대값 | `ADXMTF_H4_DiPlus_pct240` |
| `ADXS_(14)_DiPlus` | 절대값 | `ADXS_(14)_DiPlus_pct240` |
| `ADXS_(80)_DiPlus` | 절대값 | `ADXS_(80)_DiPlus_pct240` |
| `ADXS_(14)_ADX` | 절대값 | `ADXS_(14)_ADX_pct240` |
| `ADXS_(80)_ADX` | 절대값 | `ADXS_(80)_ADX_pct240` |
| `ADXS_(14)_DiMinus` | 절대값 | `ADXS_(14)_DiMinus_pct240` |
| `ADXS_(80)_DiMinus` | 절대값 | `ADXS_(80)_DiMinus_pct240` |
| `ATR14` | 절대값 ($단위) | `ATR14_pct240` |
| `CHOP_(120-40)_Scale` | 0~100 고정범위이나 레짐 영향 | `CHOP_Scale_pct240` |

**그룹 2 — Z-score 피처 → 퍼센타일로 전환** (극단 OOS 값 처리 불가)

| 현재 피처명 | 문제 | 개선 피처명 |
|:---|:---|:---|
| `BWMTF_H4_BWMFI_zscore20cp` | OOS 극단값 = 학습 분포 밖 | `BWMTF_H4_BWMFI_pct240` |
| `BWMTF_M5_BWMFI_zscore60cp` | 동일 | `BWMTF_M5_BWMFI_pct240` |
| `CE_Dist1_zscore60` | 동일 | `CE_Dist1_pct240` |
| `LRAVGST_Avg(180)_StdS_zscore60` | 동일 | `LRAVGST_180_StdS_pct240` |
| `LRAVGST_Avg(60)_StdS_zscore60` | 동일 | `LRAVGST_60_StdS_pct240` |
| `CHV_(10-10)_StdDev_zscore1440` | 동일 | `CHV_StdDev_pct1440` |
| `TickVolume_zscore1440` | 동일 | `TickVolume_pct1440` |
| `ATR14_zscore30` | 창 너무 짧음(30봉) | `ATR14_pct240` 로 대체 |

**그룹 3 — 기울기(slope) 피처 → 퍼센타일 병행 생성**

| 현재 피처명 | 이유 | 추가 피처명 |
|:---|:---|:---|
| `CE_Dist2_slope14` | 폭등장 기울기가 IS보다 2~3배 클 수 있음 | `CE_Dist2_slope_pct240` |
| `CE_SL1_slope5` | 동일 | `CE_SL1_slope_pct240` |
| `BOP_(30-5)_slope14` | 동일 | `BOP_slope_pct240` |
| `BSP_(10-3)_slope14` | 동일 | `BSP_slope_pct240` |
| `ADXMTF_H4_DiPlus_slope5cp` | 동일 | `H4_DiPlus_slope_pct240` |
| `ADXMTF_M5_DiPlus_slope14cp` | 동일 | `M5_DiPlus_slope_pct240` |

**작업**: `build_tech_derived.py`에 `_pct240`, `_pct1440` 파생 피처 생성 코드 추가 → 데이터 재빌드 → 재학습.

---

### 방안 B. LightGBM 단조 제약 (2순위, 즉시 실험 가능)

"DiPlus가 높을수록 → Win 확률이 높아야 한다"를 모델에 강제.  
**`train_round2.py` 파라미터 수정만으로 즉시 실험 가능**.

#### 단조 제약 설계 원칙

| 적용 범위 | 결과 | 권장 |
|:---|:---|:---:|
| 너무 적게 (4~5개) | 효과 미미 | ❌ |
| 너무 많이 (전체) | 잘못된 방향 → 성능 악화 | ❌ |
| **도메인 지식 기반 (20~25개)** | 검증된 방향만 강제 | **✅** |

> **주의**: Z-score 피처에 함부로 제약을 걸면 역효과.  
> 예: `CE_Dist1_zscore60 = +1` 하면 극단 Z-score에서 강제 Win 예측 → FP 증가

#### Top-60 피처 단조 분류

**✅ +1 (클수록 Win, 17개) — 확실**

```python
# ADX 방향성 강도
"ADXMTF_M5_DiPlus":           +1,   # M5 매수 방향 강도 ↑ → Win
"ADXMTF_H4_DiPlus":           +1,   # H4 매수 방향 강도 ↑ → Win
"ADXS_(14)_DiPlus":           +1,   # ADX M1 매수 강도 ↑ → Win
"ADXS_(80)_DiPlus":           +1,   # ADX M1 장기 매수 강도 ↑ → Win

# ADX 기울기
"ADXMTF_H4_DiPlus_slope5cp":  +1,   # H4 DiPlus 기울기 ↑ → Win
"ADXMTF_M5_DiPlus_slope14cp": +1,   # M5 DiPlus 기울기 ↑ → Win

# ADX 전체 강도
"ADXS_(14)_ADX":              +1,   # ADX 강도 ↑ → Win (추세 강함)
"ADXS_(80)_ADX":              +1,   # ADX 장기 강도 ↑ → Win

# CE 거리 (Chandelier Exit)
"CE_SL2_dist_ATR":            +1,   # CE2 SL과 거리 멀수록 → Win
"CE_Dist2_slope14":           +1,   # CE2 거리 기울기 ↑ → Win
"CE_SL1_slope5":              +1,   # CE1 기울기 ↑ → Win

# BOP/BSP (매수/매도 압력)
"BOP_Scale":                  +1,   # BOP 매수 압력 ↑ → Win
"BOP_(30-5)_slope14":         +1,   # BOP 기울기 ↑ → Win
"BSP_(10-3)_slope14":         +1,   # BSP 기울기 ↑ → Win
"BSP_(10-3)_accel14":         +1,   # BSP 가속도 ↑ → Win

# 거래량
"TickVolume_ratio_MA240":     +1,   # 거래량 증가 → Win
"TickVolume_ratio_MA60":      +1,
```

**✅ -1 (클수록 Loss, 8개) — 확실**

```python
# ADX 반대방향 강도
"ADXMTF_M5_DiMinus":          -1,   # M5 매도 방향 강도 ↑ → Loss
"ADXS_(14)_DiMinus":          -1,   # ADX M1 매도 강도 ↑ → Loss
"ADXS_(80)_DiMinus":          -1,   # ADX M1 장기 매도 강도 ↑ → Loss
"ADXMTF_M5_DiMinus_slope14cp":-1,   # M5 DiMinus 기울기 ↑ → Loss

# CE 스퀴즈 (추세 압축 = 불확실)
"CE_SL2_squeeze":             -1,   # Squeeze 심할수록 → Loss
"CE_SL1_squeeze":             -1,

# CHOP (횡보 지수)
"CHOP_(120-40)_Scale":        -1,   # CHOP ↑ = 횡보 → Loss
"CHOP_(14-14)_CSI":           -1,
```

**⛔ 0 (제약 금지, 35개) — 비선형/불확실**

```python
# QQE RSI — 과매수/과매도 양방향 비선형
"QQE_(5-14)_TrLevel":  0
"QQE_(12-32)_RSI":     0

# CHV StdDev — 변동성 고점 = 기회이기도, 위험이기도
"CHV_(10-10)_StdDev_*": 0

# CE Z-score — 극단값에서 방향 불명확
"CE_Dist1_zscore60":   0

# 매크로 피처 — 복합/비선형 관계
"USDTRY_ret5d", "WHEAT_ret1d", "COFFEE_ret1d", ... : 0
```

**기대 효과**: "강한 추세 = Win" 강제 학습 → 폭등장에서 신호 증가, Z-score 왜곡 완화.

---

### 방안 C. 레짐 인식 피처 추가 (3순위)

현재 레짐(폭등/횡보/하락)을 명시적 피처로 투입.

```python
# 월간 수익률 퍼센타일
monthly_ret = close.resample('1M').last().pct_change()
monthly_pct = monthly_ret.rolling(24).rank(pct=True)   # 최근 24개월 중 순위

# 주간 상승 비율 (최근 20주 중 상승한 주 비율)
weekly_up_ratio = (close.resample('1W').last().diff() > 0).rolling(20).mean()

# 레짐 플래그
regime = pd.cut(monthly_pct, bins=[0, 0.3, 0.7, 1.0],
                labels=["하락레짐", "중립레짐", "상승레짐"])
```

**기대 효과**: 폭등 레짐에서 다른 진입 기준 적용 가능 (레짐별 AI 분리 학습).

---

## 10. 실행 우선순위 로드맵

### 단계별 실행 계획

| 순서 | 방안 | 효과 | 작업량 | 시작 시점 |
|:---:|:---|:---:|:---:|:---:|
| **1** | **A+B 동시 적용 (Combined)** | **매우 높음** | **중간** | **즉시** |
| 2 | B 단독: 단조 제약만 | 중간 | 매우 낮음 | 즉시 |
| 3 | A 단독: 퍼센타일 랭크 추가 | 매우 높음 | 중간 | 단기 |
| 4 | C: 레짐 피처 추가 | 높음 | 높음 | 중기 |

---

### ⭐ A+B 동시 적용 (가장 강력한 접근)

**아이디어**: 퍼센타일 랭크를 학습 스크립트 내에서 실시간 계산하여 새 피처로 추가 + 단조 제약 동시 적용

> 데이터 파이프라인 재빌드 없이 `train_round2.py` 수정만으로 가능

```python
# train_round2_AB.py 핵심 로직

# Step 1: 기존 Top-60 피처 로드
X_tr, X_val, X_oos = ... (기존 방식)

# Step 2: 방안 A — 퍼센타일 랭크 피처 실시간 추가
# (학습 데이터 기준 rolling rank → 미래 참조 없음)
PCT_FEATURES = [
    "ADXMTF_M5_DiPlus", "ADXMTF_H4_DiPlus",
    "ADXS_(14)_DiPlus", "ADXS_(80)_DiPlus",
    "ADXS_(14)_ADX",    "ADXS_(80)_ADX",
    "CE_SL2_dist_ATR",  "CE_Dist2_slope14",
    "BOP_(30-5)_slope14", "BSP_(10-3)_slope14",
    "ATR14", "TickVolume_ratio_MA240",
]
for col in PCT_FEATURES:
    # IS 기준 rolling 240봉 퍼센타일 계산 후 OOS도 같은 IS 분포로 변환
    pct_col = col + "_pct240"
    X_tr[pct_col]  = X_tr[col].rank(pct=True)       # IS 내 상대 서열
    X_val[pct_col] = X_val[col].rank(pct=True)
    X_oos[pct_col] = X_oos[col].rank(pct=True)      # OOS도 OOS 내 서열 (독립)

# Step 3: 방안 B — 단조 제약 (원본 + 퍼센타일 양쪽 적용)
MONOTONE_MAP = {
    "ADXMTF_M5_DiPlus":         +1,
    "ADXMTF_M5_DiPlus_pct240":  +1,   # 퍼센타일 버전도 동일 제약
    "ADXMTF_H4_DiPlus":         +1,
    "ADXMTF_H4_DiPlus_pct240":  +1,
    "ADXMTF_M5_DiMinus":        -1,
    "ADXS_(14)_DiMinus":        -1,
    "CE_SL2_dist_ATR":          +1,
    "CE_SL2_dist_ATR_pct240":   +1,
    "CHOP_(120-40)_Scale":      -1,
    # ... (전체 25개 + 퍼센타일 버전)
}
params["monotone_constraints"] = [MONOTONE_MAP.get(f, 0) for f in feature_cols]
```

**예상 효과 조합**:

| 단독 방안 B | 단독 방안 A | **A+B 동시** |
|:---:|:---:|:---:|
| 레짐 방향성 강제 | 스케일 정규화 | **방향성 강제 + 스케일 적응** |
| OOS 신호 증가 예상 | 레짐 전환 적응 | **가장 강력한 OOS 일반화** |

---

### 실행 순서

```
[즉시] A+B 동시: train_round2_AB.py 작성 → 재학습 (~30분)
  → 기대: OOS 실승률 50%+ 달성 가능성

[비교] B 단독: train_round2_mono.py → 단조 제약만 효과 측정

[단기] A 풀버전: build_tech_derived.py → 전체 파이프라인 재빌드
  → 더 정밀한 rolling(240) 퍼센타일 (지금은 IS 전체 기준)

[중기] A+B+C 완전 통합: 레짐 피처 추가 → 가장 강력한 최종 모델
```

---

### 방안 C. 레짐 인식 피처 (중기, A+B+C 완전 통합)

**핵심 아이디어**: 모델이 "지금이 폭등장인지, 횡보장인지"를 직접 알 수 있게 피처로 명시.

```python
# 매크로 데이터(GOLD_ret, M1 Close) 기반 레짐 피처 (train 스크립트 내 계산)
import pandas as pd

# ── 레짐 피처 1: 월간 수익률 퍼센타일 (최근 24개월 중 이번 달이 얼마나 강한가)
monthly_close = df["Close"].resample("1ME").last()   # 월봉 Close
monthly_ret   = monthly_close.pct_change()
monthly_pct   = monthly_ret.rolling(24).rank(pct=True)   # 0~1
df["regime_monthly_pct"] = monthly_pct.reindex(df.index, method="ffill").shift(1)

# ── 레짐 피처 2: 주간 상승 비율 (최근 20주 중 상승한 주 비율)
weekly_close  = df["Close"].resample("1W").last()
weekly_up     = (weekly_close.diff() > 0).astype(float)
weekly_up_ma  = weekly_up.rolling(20).mean()
df["regime_weekly_up_ratio"] = weekly_up_ma.reindex(df.index, method="ffill").shift(1)

# ── 레짐 피처 3: 20주 이동평균 대비 현재 가격 위치 (퍼센타일)
ma20w         = weekly_close.rolling(20).mean()
above_ma20w   = (weekly_close > ma20w).astype(float)
df["regime_above_ma20w"] = above_ma20w.reindex(df.index, method="ffill").shift(1)

# ── 레짐 피처 4: 현재 월 수익률이 상위 70% 이상이면 "강세 레짐" 플래그
df["regime_bull_flag"] = (df["regime_monthly_pct"] >= 0.70).astype(float)
```

**레짐 피처의 단조 제약 (방안 B와 결합)**:

```python
MONOTONE_MAP.update({
    "regime_monthly_pct":   +1,   # 더 강한 달 = Win 가능성 높음
    "regime_weekly_up_ratio": +1, # 상승주 많을수록 = Win
    "regime_above_ma20w":   +1,   # MA 위 = 강세 레짐 = Win
    "regime_bull_flag":     +1,   # 강세 레짐 플래그 = Win
})
```

**예상 효과**:
- **2023+ 폭등장**: `regime_monthly_pct ≈ 0.95`, `regime_bull_flag = 1` → 모델이 폭등 레짐을 인식 → 더 적극적 진입
- **2018~2019 횡보장**: `regime_monthly_pct ≈ 0.50`, `regime_bull_flag = 0` → 신중한 진입
- 레짐 플래그가 **OOS 레짐 불일치를 직접 설명**하는 피처로 작동

---

### A+B+C 완전 통합 비교표 (실측치 반영, 2026-03-08)

| 구성 | 핵심 개선 | OOS 실승률 (thr=0.20) | M30>35+thr=0.25 | 비고 |
|:---|:---|:---:|:---:|:---|
| 기존 (필터만) | M30>35 하드필터 | 50.4% (573건) | 52.7% (91건) | 1라운드 모델 |
| **B 단독** | 단조 제약만 | **33~39% ❌ (3/3 FAIL)** | — | 단조만으로는 부족 |
| **A+B 동적** | 방향성 + IS기준 pct | 38~45% (1/3 PASS) | 54.7% (181건) | 학습 시 pct 계산 |
| **A+B 풀버전** | 방향성 + rolling(240) pct | **45~52% ✅ (3/3 PASS)** | **56.1% (437건)** | **파이프라인 사전 계산** |
| A+B+C (예정) | + 레짐 인식 | 추정 55~65% | — | 미실행 |

> 방안 C는 train_round2_ABC.py 한 파일에서 A+B와 함께 동시 적용 가능 — 별도 파이프라인 필요 없음.

---

## 11. 실험 결과 요약 (2026-03-08)

### 11.1 실험 목적

2라운드 모델의 OOS(2023~2026) 일반화 성능 개선을 위해 3가지 접근법을 비교 실험:
1. **B 단독**: 단조 제약(Monotone Constraints)만 적용
2. **A+B 동적**: 단조 제약 + 학습 시 IS 전체 기준 퍼센타일 랭크 동적 생성
3. **A+B 풀버전**: 단조 제약 + `build_tech_derived.py`에서 rolling(240) 퍼센타일 사전 계산

### 11.2 실험 절차

#### (1) B 단독 (`train_round2_mono.py`)
- Top-60 기존 피처 + 단조 제약(+1=17, -1=8, 0=35)
- 학습: IS 1.54M행, AUC 0.8143 (iter=532)
- 소요: 149초

#### (2) A+B 동적 (`train_round2_AB.py` — 첫 실행)
- Top-60에 IS 전체 기준 `.rank(pct=True)` 동적 생성 → 60→83개
- 단조 제약: +1=25, -1=10, 0=48
- 학습: AUC 0.8124 (iter=346)
- 소요: 131초

#### (3) A+B 풀버전 파이프라인 재빌드
```
build_tech_derived.py (pct240/pct1440 45개 피처 추가, ~2시간)
  → merge_features.py (817컬럼, 2,659,938행, 1.35GB)
  → train_round1.py (811피처 → Spearman 제거 → 419피처 → 5-Fold WF → SHAP Top-60)
  → train_round2_AB.py (새 Top-60 기반, 60→76개, 단조 +1=15/-1=8)
```
- Spearman 상관행렬 계산: 3,682초 (811×811)
- 5-Fold 평균 AUC: 0.7967 ± 0.0211
- 2라운드 학습: AUC **0.8290** (iter=540)
- 총 소요: ~5,068초

### 11.3 OOS Walk-Forward 전체 비교 (thr=0.20)

| 방법 | Step1 (6mo) | Step2 (1.5y) | Step3 (new) | PASS |
|:---|:---:|:---:|:---:|:---:|
| **B 단독** | 33.2% (797) ❌ | 39.1% (1,736) ❌ | 35.8% (2,057) ❌ | **0/3** |
| **A+B 동적** | 38.1% (299) ❌ | 45.4% (652) ✅ | 42.5% (819) ❌ | **1/3** |
| **A+B 풀버전** | **52.4% (1,128)** ✅ | **48.8% (3,380)** ✅ | **45.1% (4,821)** ✅ | **3/3** 🏆 |

### 11.4 M30_DiPlus>35 결합 비교

| 임계치 | B 단독 | A+B 동적 | A+B 풀버전 |
|:---:|:---:|:---:|:---:|
| 0.15 | — | 40.6% (3,322) | **45.5% (4,360)** ✅ |
| 0.20 | — | 46.7% (722) ✅ | **46.6% (1,443)** ✅ |
| 0.25 | — | 54.7% (181) ✅ | **56.1% (437)** ✅ |
| 0.30 | — | 71.4% (35) ✅ | **68.5% (146)** ✅ |

### 11.5 SHAP Top-60 변화 (풀버전 재학습)

파이프라인 재빌드 후 SHAP Top-60에 **pct 피처 16개 선발**:

| 순위 | 피처 | SHAP |
|:---:|:---|:---:|
| 상위 | `ADXMTF_H4_DiPlus_pct240` | **0.233** |
| 상위 | `ADXMTF_H4_DiPlus_slope5cp_pct240` | 0.172 |
| 중위 | `ADXS_(14)_DiPlus_pct240` | 0.029 |
| 중위 | `ADXS_(80)_DiMinus_pct240` | 0.018 |
| 중위 | `BOP_(30-5)_slope14_pct240` | 0.016 |
| 중위 | `ADXS_(14)_DiMinus_pct240` | 0.012 |
| 중위 | `ADXS_(80)_ADX_pct240` | 0.013 |
| 하위 | `ATR14_pct240`, `TickVolume_zscore1440_pct1440` 등 | 0.009 |

> `ADXMTF_H4_DiPlus_pct240`이 SHAP=0.233으로 **전체 2위**에 랭크 — "H4 DiPlus가 최근 240봉 중 상위 몇%인가?"가 모델에게 가장 중요한 레짐 적응 신호.

### 11.6 핵심 분석

#### 왜 풀버전이 동적보다 압도적으로 좋은가?

1. **IS 전체 vs rolling(240) 차이**: 동적 방식은 IS 전체(~150만행)로 퍼센타일 계산 → 2019년과 2023년 데이터가 섞인 평균. rolling(240)은 직전 4시간만 보는 **국소 적응** → 레짐 전환을 실시간 반영.

2. **SHAP 선별 효과**: build_tech_derived 단계에서 pct 피처를 사전 계산 → train_round1 SHAP가 pct 피처를 Top-60에 **자연 선발** → train_round2에서 이 피처들이 핵심 역할.

3. **신호 수 폭증**: 동적 방식 722건 → 풀버전 **1,443건** (thr=0.20 기준 2배). 더 정밀한 퍼센타일이 더 많은 구간에서 유효한 신호를 생성.

#### B 단독이 실패한 이유

단조 제약만으로는 Z-score의 스케일 불일치 문제를 해결 못함. "DiPlus가 높을수록 Win"이라는 방향은 맞지만, **"높다"의 기준이 레짐마다 다른** 문제는 여전. → 퍼센타일 랭크 피처가 필수.

### 11.7 실전 추천 조합

| 전략 유형 | 조합 | 월 신호 | 실승률 | 모델 |
|:---|:---|---:|:---:|:---:|
| 균형형 | M30>35 + thr=0.20 | ~45건 | **49.0%** | A+B+C |
| **추천 ⭐** | **M30>35 + thr=0.25** | **~15건** | **56.3%** | **A+B+C** |
| 스나이퍼 | M30>35 + thr=0.30 | ~5건 | 63.4% | A+B+C |

---

## 12. 피라미딩 데이터셋 빌드 교훈 (2026-03-11)

> 피라미딩(Model_AddOn) 전용 데이터 파이프라인 구축 시 발견된 설계 함정 3건.
> **진입 학습(Model_Entry, Part A) 파이프라인에는 해당 없음** — α 피처는 "포지션 보유 중" 전제 위에 설계.

| # | 항목 | 원인 | 해결 |
|:---:|:---|:---|:---|
| **W-1** | α 피처 중복 (`price_vs_entry`) | `unrealized_pnl_atr`과 수식 동일 → SHAP 분산 낭비 | `atr_expansion` (현재ATR/1차진입ATR) 으로 교체 — 완전히 다른 차원(변동성 레짐) 정보 투입 |
| **W-2** | `bsp_scale_delta` 참조 컬럼 불일치 | 코드에서 `BOP_Scale`(매수 압력)을 읽었으나 변수명은 `bsp_scale_delta` | `LRAVGST_Avg(60)_BSPScale`(추세 안정성)로 통일 — 기존 파이프라인에 없는 고유 α 정보 |
| **W-3** | 병합 Join 방식 | Left Join 시 대부분 행이 label=NaN → 불필요한 메모리 낭비 | **Inner Join** 채택 — Model_AddOn은 라벨 존재 봉만 학습 필요(조건부 의사결정) |

> **추가 발견**: 라벨 Parquet에서 원본 OHLC/CE_CE2 컬럼이 병합 시 유입되는 누수 발생 → `merge_features_pyramid.py`에서 라벨 DF 컬럼 필터링(Time + label + α 피처만 선택) 추가로 해결.









① FP_PENALTY 인하 고려 (3.0 → 1.5~2.0)
롱전략 맥락: "시장에 들어갈지 말지"를 결정합니다. 잘못 들어가면 SL에 걸려 1% 손실. 따라서 오탐(False Positive)이 직접적인 손실입니다. FP_PENALTY = 3.0은 "차라리 기회를 놓치더라도 틀린 진입을 줄여라"라는 강력한 보수 전략입니다.

피라미딩 맥락: "이미 수익 중인 포지션에 추가할지 말지"를 결정합니다.

이미 1차 진입이 2ATR 이상 수익 → 추세가 강하게 확인된 상태
추가 진입 실패 시 손실 규모: 원래 진입보다 작음 (이미 이익 쿠션 존재)
FP_PENALTY = 3.0이면 → 모델이 "99% 확실할 때만 추가해" → 불타기를 거의 못 함
피라미딩의 존재 이유가 **"강한 추세에서 수익을 극대화"**하는 것인데, 너무 보수적이면 그 목적 자체가 무력화됩니다. 그래서 일단 3.0으로 돌려보고, 신호가 너무 적으면 1.5~2.0으로 내리는 것이 합리적이라고 제안해 드린 것입니다.

물론 이건 학습 결과를 본 후 판단할 사항이지, 지금 바꾸자는 건 아닙니다.

② addon_count 단조 제약 (-1)
이건 퀀트 직관에 기반한 설계입니다.

addon_count = 0 → 아직 추가 진입 안 함 → 추세 가능성 열려 있음
addon_count = 1 → 1번 추가 → 추세가 꽤 진행됨
addon_count = 2 → 2번 추가 → 추세 소진 위험 증가
금 시장(XAUUSD)에서 강한 추세가 영원히 지속되는 경우는 드뭅니다. 추가 진입 횟수가 늘어날수록 평균 회귀(Mean Reversion) 압력이 커지므로, 모델이 "이미 2번 추가했으면 3번째는 조심해라"라고 학습하는 것이 합리적입니다. 단조 제약 -1이 이 역학을 강제합니다.

③ Threshold 0.20 (롱전략 0.25 대비)
롱전략은 THRESHOLD = 0.25(모델이 25% 이상 확신해야 진입)를 씁니다. 피라미딩은 0.20으로 낮췄습니다.

이유: 피라미딩 데이터는 이미 필터링된 상황(1차 진입 성공 + 2ATR 수익)이므로, 전체 시장 데이터에 비해 base rate가 높을 수 있습니다. 같은 0.25를 쓰면 신호가 너무 적을 수 있고, 0.20으로 시작해서 OOS 결과를 보며 올리는 것이 실험적으로 안전합니다.

최적화 범위는 0.15 ~ 0.35가 적당하고, Walk-Forward 검증에서 기대수익 × 신호 수가 최대인 지점을 찾으시면 됩니다.

요약: 수정사항은 실제로 돌리면 터질 수 있는 구조적 결함 방어였고, 전략 의견 3가지는 **"일단 현재대로 돌려보고, 결과에 따라 튜닝"**하시는 것이 가장 현실적입니다. 학습 결과가 나오면 그때 다시 판단해 드리겠습니다. 🚀