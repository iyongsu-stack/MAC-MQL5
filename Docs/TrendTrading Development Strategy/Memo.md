# 데이터 수집 현황 및 Data Lake 아키텍처 메모

> 최종 업데이트: 2026-02-24

---

## Data Lake 파일 구조

> 프로 퀀트 표준(Data Lake) 방식으로 역할별 분리 저장

| 파일 | 내용 | 행수 | 컬럼수 | 크기 | 업데이트 주기 |
|:---|:---|:---:|:---:|:---:|:---|
| [tech_features.parquet](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/tech_features.parquet) | M1 기술 지표 (ADX, QQE, BWMFI 등) | 3,150,208 | 63 | 1.0 GB | 매일 |
| [tech_features_derived.parquet](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/tech_features_derived.parquet) | 기술 지표 파생 변환 (Z-score Shift+1 적용) | 3,150,208 | ~94 | 1.2 GB | 파생 스크립트 실행 시 |
| [macro_features.parquet](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/macro_features.parquet) | 매크로 파생 피처 (변화율/멀티스케일 Z-score) | 8,651 | 360 | 14 MB | 매주 |
| [labels_barrier.parquet](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/labels_barrier.parquet) | Triple Barrier 정답지 (Long/Short 분리) | ~240,000 | 9 | - | 라벨링 로직 수정 시 |
| [AI_Study_Dataset.parquet](file:///c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/AI_Study_Dataset.parquet) | **최종 AI 학습 데이터셋** | 3,150,208 | ~460 | 1.1 GB | 병합 워크플로우 실행 시 |

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

## 다음 단계

1. **전처리 파이프라인**: `tech_features.parquet`를 기반으로 `tech_features_derived.parquet` 파생, 이후 `macro_features.parquet`를 Shift+1으로 M1 타임스탬프 기준 병합.
2. **ATR 동적 배리어 라벨링(학습용)**: M1 데이터 + ATR(14) 기반 동적 TP/SL(1.0/1.2, 45봉)로 진입 타이밍 정답지 생성 (`labels_barrier.parquet`). 최종 `AI_Study_Dataset.parquet`로 모두 병합 완료. 실전 청산은 트레일링스탑 전담.
3. **LightGBM + SHAP**: 메가 피처 풀(360개 매크로 + 63개 기술) → 핵심 3~5개 피처 추출
4. **Walk-Forward 3단계 검증**: Step1(2개월 마이닝) → Step2(1년 OOS) → Step3(10년)

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


## 5. [AI 모델 파이프라인] 피처 엔지니어링 실전 원칙
1. 공선성 검증: 상관계수 **0.85** 이상인 피처 쌍은 하나로 합치거나 제거. Tie-Breaker: Target(Y)과의 MI가 낮은 쪽 제거
2. 피처 선택: 메가 풀 → SHAP 자동 추출(주력) + Ablation Study(새 지표 검증용 보조)
3. 파생 피처 유형 (원본 절대값 금지):
   - **기본 4유형 (강제)**: 가속도(Slope의 Diff), 멀티스케일 Z-Score(60/240, 1440은 선택), 비율(MA 대비 등), Slope(기울기)
   - **레벨값 전용 (강제)**: 변화율(Δ%) — 가격·금리·환율 등 레벨 데이터에만 적용. 이미 스케일화된 오실레이터(RSI, ADX, BOP_Scale 등 0~100 범위)에는 Slope로 대체 허용
   - **조건부 (SHAP 기반)**: 정규화 이격도 — 가격 기반 지표(CE 등)에 적용. 롤링 상관계수 — 1라운드 SHAP 상위 피처 쌍에 대해 2라운드에서 선별 추가 (무차별 투입 시 피처 폭발·SHAP 왜곡 위험)
   - **스케일 오실레이터 예외**: BOP_Scale, QQE_RSI, TDI_Signal, CHOP_Scale, ADXS_Scale 등 이미 정규화된 지표는 원본 Passthrough 허용 (가격 레벨값이 아님)
4. Tick Volume: 절대값 금지. MA 대비 비율(60/240/1440) 3개 + Z-Score(60/240) 2개를 모두 생성하여 투입. 비율은 세션별 계절성, Z-Score는 극단 거래량 탐지. SHAP이 유효 피처를 선별 (메가 풀 전략)
5. 세션 인코딩: 트리 모델은 One-hot, 딥러닝은 sin/cos 순환 인코딩
6. 롱/숏 분리 학습 + 단일 EA 통합:
   - Stage A: 롱 모델(label_long)과 숏 모델(label_short)을 처음부터 분리 학습 → 방향별 SHAP으로 피처 중요도 희석 방지
   - Stage B: Walk-Forward 3단계 검증 (각 모델 독립). 숏 모델 데이터 부족 시 scale_pos_weight 보정
   - Stage C: `model_long.onnx` + `model_short.onnx`를 하나의 MQL5 EA에 로드, 비대칭 임계치(롱 > 0.55 & 숏 > 0.70) + 상충 시 관망
   - Stage D (선택): 매크로 피처가 SHAP 상위권일 경우 게이트키퍼 레이어 추가
7. 피처 안정성 모니터링: PSI(Population Stability Index)로 분포 변화 추적, PSI > 0.25이면 불안정 → 재학습 트리거. Walk-Forward 단계 간 피처 중요도 순위 급변 시 과적합 경고
8. 다중 검정 보정: 수백 개 피처 동시 테스트 시 BH-FDR(Benjamini-Hochberg) 보정 적용 필수. SHAP 상위 피처도 5-Fold 중 3회 이상 상위권 등장하는 것만 채택 (순위 안정성)
9. 이상치 처리: 금 시장 꼬리 리스크 극단적(Z-Score ±10 이상 가능) → Winsorization 상하 1~5% 클리핑. 제거가 아닌 클리핑으로 극단 이벤트 정보 보존 (딥러닝은 필수, 트리 모델은 선택)
10. 캘린더/이벤트 피처: 요일·월·시간을 sin/cos 순환 인코딩. 월말 리밸런싱 플래그(is_month_end_5days), FOMC/NFP 전후 48시간 원핫 플래그 투입
11. 피처 중요도 시간적 일관성: 전체 기간 SHAP 1회가 아닌 분기별 SHAP 비교. 특정 분기에만 중요한 피처는 레짐 의존적 → 항상 투입 vs 레짐 조건부 투입 결정

### 🗄️ 벡터 DB 임베딩 전략
1. 스케일링된 피처를 슬라이딩 윈도우(기본 M1 30봉) 단위로 벡터화하여 ChromaDB에 저장
2. 기초 인프라 구축 → 메타 라벨링 강화 → 에이전트 메모리 통합 (단계적 활용)
3. 임베딩 전에 반드시 Z-Score/랭크 스케일링 완료 필수 (원본값 벡터화 시 유사도 왜곡)
4. 멀티스케일 윈도우 4계층: M1 30봉(30분, 즉시 진입 시그널) + M1 240봉(4시간, 세션 방향 확인) + H1 24봉(1일, 일간 추세) + H1 120봉(1주, 레짐/매크로 컨텍스트) 4계층 임베딩 병렬 저장, 검색 시 스케일별 유사도 가중 합산
5. 메타데이터 동시 저장: session(아시아/유럽/미국), volatility_percentile(ATR 백분위), label_result(TP/SL/Timeout) → 메타데이터 필터링 후 유사도 검색. 레짐 판별 방식은 추후 복합 지표(ADX+ChopIndex+ATR Z-Score) 기반으로 별도 설계

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

---



[학습 구간 (IS)]
  2012~2015 (하락장 숏) + 2019~2020 (상승장 롱)
[검증 구간 (OOS)]
  2004~2011 (약 8년)  ← 최초 유효 시점부터의 대상승/서브프라임 레짐
  2016~2018 (약 3년)  ← 횡보 레짐
  2022~2024 (약 3년)  ← 금리급등/신고가 레짐
[최종 백테스트]
  2004~2024 (약 20년 전체 구간)

  2017년 이후 데이터만 제대로 다운로드 됨....


[QQE 눌림목 정밀 타점 라벨링 (3-Barrier) 요약](qqe_labeling_optimization_report.md)




##후보 A(LightGBM + Purged K-Fold)  <---- 학습방법
1. SHAP 분산 왜곡 방지 (다중공선성 사전 제거 - Feature Pruning)
문제점: 우리가 생성한 460개의 피처 중 상당수는 수리적으로 매우 유사합니다. (예: ADX_Slope와 ADX_Accel, 혹은 특정 Z-score의 60주기와 240주기 등). 트리 모델(LightGBM)은 이런 중복 피처가 있어도 예측은 잘 해냅니다. 하지만 SHAP 중요도를 뽑을 때 심각한 왜곡이 발생합니다. 진짜 핵심 피처 1개의 기여도가 3개의 유사 피처로 분산(100% → 33%, 33%, 34%)되면서, 하위권으로 밀려나 버릴 수 있습니다.
대안 (필수): SHAP 분석을 돌리기 직전에, 피처 간의 스피어만 상관계수(Spearman Correlation)나 계층적 군집화(Hierarchical Clustering)를 통해 상관계수가 0.95 이상인 중복 피처군을 찾아내고, 그중 하나만 남기는 사전 프루닝(Pruning) 작업을 스크립트에 반드시 포함시켜야 합니다.
2. 비대칭 손실 함수 적용 (Custom Asymmetric Loss)
문제점: 일반적인 머신러닝의 목적 함수(Logloss)는 예측이 틀렸을 때의 페널티를 동일하게 매깁니다. 하지만 트레이딩에서는 그렇지 않습니다.
진입 기회를 놓친 경우 (False Negative): 계좌 타격 없음 (기회비용뿐)
섣불리 진입해서 손절친 경우 (False Positive): 실제 자본 손실 (-SL - 30pt Friction)
대안: LightGBM을 학습시킬 때 기본 손실 함수 대신, 섣부른 진입(거짓 양성)에 더 무거운 페널티를 부여하는 **비대칭 포컬 로스(Asymmetric Focal Loss)**나 사용자 정의 손실 함수를 깎아서(Custom Objective) 넣어야 합니다. 그래야 AI가 확실한 자리가 아니면 방아쇠를 당기지 않는 '진짜 스나이퍼'로 성장합니다.
3. 롤링 윈도우 기반 연속 학습 (Walk-Forward Continual Learning)
문제점: 2012년부터 2026년까지의 데이터를 한 번의 K-Fold(5등분)로 섞어버리면, 제로금리 시대(20122020)의 패턴이 고금리/인플레 시대(20222026)의 예측을 방해할 수 있습니다. 시장 레짐(Regime)은 변합니다.
대안: 전체 데이터를 한 번에 학습하는 것이 아니라, 최근 3년으로 학습 → 다음 6개월 예측(검증) 창을 14년간 계속 밀고 나가는 진정한 의미의 연속적 Walk-Forward 교차 검증 파이프라인을 짜야 합니다. (이는 메모에 적어주신 '상승장/하락장 승률이 다르다'는 통찰과도 정확히 맞닿아 있습니다.)




## 📅 데이터 최대 활용 전략 (2003~2025, 22년) — 2026-03-03

### XAUUSD 상승장/하락장 구간 맵

| 상승장 (롱 라벨링) | 기간 | 특징 |
|:---|:---|:---|
| 🟡 2005-2008 | 4년 | 금 슈퍼 사이클 시작 |
| 🟡 2009-2011 | 3년 | QE 시대 금 폭등 ($1,900) |
| 🟡 2016-2018 | 3년 | 완만한 회복 상승 |
| 🟡 **2019-2020** | 2년 | COVID 전후 급등 |
| 🟡 2023-2025 | 3년 | 중앙은행 매수 + 지정학 |

### 확장된 파이프라인 설계

```
[롱 모델 — 최대 데이터 활용]

┌─ 학습 데이터 (라벨링 구간) ─────────────────────────
│  2005-2008 + 2009-2011 + 2016-2018 + 2019-2020
│  = ~12년 상승장 (예상 샘플: 1,000~2,000건)
│
├─ Purged Walk-Forward 튜닝 ──────────────────────────
│  시간순으로 Expanding Window:
│  Fold1: 2005-2008 학습 → 2009 검증
│  Fold2: 2005-2009 학습 → 2010-2011 검증
│  Fold3: 2005-2011 학습 → 2016-2017 검증
│  Fold4: 2005-2017 학습 → 2018-2019 검증
│  Fold5: 2005-2019 학습 → 2020 검증
│  → 서로 다른 시장 체제를 5번 교차 검증 (강건!)
│
└─ Walk-Forward 최종 검증 (완전 미보유 데이터) ──────
   Step1: 2023-01~2023-06 (6개월) → 최소 생존
   Step2: 2023-01~2024-06 (1.5년) → 안정성
   Step3: 2023-01~2025-12 (3년) → 실전 신뢰
```

```
[숏 모델 — 최대 데이터 활용]

┌─ 학습 데이터 (라벨링 구간) ─────────────────────────
│  2012-2015 + 2008 금융위기 + 2020 COVID 급락 + 2022 금리인상
│  = ~7년 하락장/조정기
│
├─ Purged Walk-Forward 튜닝 ──────────────────────────
│  Fold1: 2008 학습 → 2012-2013 검증
│  Fold2: 2008+2012-2013 학습 → 2014-2015 검증
│  Fold3: 전체 학습 → 2020 검증
│  Fold4: 전체 학습 → 2022 검증
│
└─ Walk-Forward 최종 검증 ────────────────────────────
   2024-2025 하락 구간에서 검증
```

### AI 학습 전체 흐름

```
Step 1. 라벨링
   └─ 3-Barrier로 label_long 생성 (넓게: BSP>1.5 + QQE GC + TV>1.2×)

Step 2-3. 피처 병합
   └─ 마이크로(~200) + 매크로(~360) → 총 ~560개 피처 부착

Step 4. AI 학습 (2라운드)
   ┌─ [1라운드] 560개 전체 투입 → LightGBM 학습
   │   └─ SHAP 분석 → "이 60개가 핵심이다" 자동 선별
   │   └─ 나머지 500개는 노이즈 → 제거
   │
   └─ [2라운드] 핵심 60개만으로 재학습
       └─ Purged Walk-Forward로 모델 튜닝 (5 Fold, 서로 다른 시대)
       └─ OOS AUC > 0.7 확인

Step 5. Walk-Forward 3단계 최종 검증
   └─ 학습에 전혀 사용 안 한 미래 데이터로 실전 테스트
   └─ 2023~2025 (3년) 완전 OOS
   └─ 모두 통과 → 모델 완성 ✅
   └─ 실패 → Step 1(라벨링)부터 재조정
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
- 2003~2004는 XAUUSD 유동성이 낮아 마이크로 피처 품질 저하 가능 → 2005부터 시작 추천
- 매크로 데이터 가용성 확인 필요 — FRED/Yahoo 일부 지표가 2010년 이후부터만 존재할 수 있음
- 롱/숏 모델은 **완전 분리 학습** (라벨, 모델, SHAP 모두 독립)

