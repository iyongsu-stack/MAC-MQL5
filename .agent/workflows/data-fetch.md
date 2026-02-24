---
description: XAUUSD 백테스트용 매크로+기술 데이터 수집 — 다중 소스 자동화 파이프라인
---
// turbo-all

# 데이터 수집 워크플로우 (/data-fetch)

> **목적**: XAUUSD AI 전략 개발에 필요한 전체 데이터(기술 지표 + 매크로)를 1998-01-01부터 현재까지 수집하여 Data Lake 아키텍처로 저장한다.

> [!IMPORTANT]
> **🚨 AI 전략 개발 3대 핵심 원칙 (절대 준수)**
> 1. **Shift+1 원칙**: 이 워크플로우로 수집된 상위 타임프레임(매크로) 데이터는 M1에 매핑 시 무조건 직전 완성봉만 사용해야 함. (`build_data_lake.py`에서 `macro.shift(1)`로 데이터단에서 자체 적용 완료)
> 2. **Friction Cost 30포인트**: 수집된 데이터로 AI 학습 데이터 생성 시 `friction_cost`를 최하 30포인트 차감 적용 필수.
> 3. **절대값 사용 금지**: 원본 환율/금리를 그대로 쓰지 않고 `build_data_lake.py`에서 변화율(Δ%)/Z-score/가속도 파생 피처로 자체 변환되어 저장됨.

---

## 전제 조건 확인

1. MT5 터미널이 실행 중이어야 합니다 (기술 지표 수집용).
2. 인터넷 연결이 되어 있어야 합니다 (Yahoo Finance, FRED 수집용).
3. Python 3.14 설치 확인:
```powershell
C:\Python314\python.exe --version
```
4. 필수 패키지 설치:
```powershell
C:\Python314\python.exe -m pip install yfinance fredapi pyarrow pandas numpy --quiet
```

---

## 방법 1: 매크로 데이터 수집 (Yahoo Finance + FRED)

> **소스**: Yahoo Finance (무료, 무키), FRED (무료 API 키 필요)
> **기간**: 1998-01-01 ~ 현재
> **타임프레임**: 일봉(1D)
> **저장**: `Files/raw/macro/yfinance/*.csv`, `Files/raw/macro/fred/*.csv`

```powershell
# Yahoo Finance + FRED 전체 수집 (총 60개 파일)
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\fetch_macro_data.py"
```

```powershell
# FRED만 별도 수집 (API 키 필요: FRED_API_KEY 변수에 입력)
# FRED API 키 발급: https://fredaccount.stlouisfed.org/apikey (무료, 1분)
# 현재 키: 1d5e09b7dcc74795825486551d4cea4b
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\fetch_fred_data.py"
```

---

## 방법 2: 기술 지표 데이터 수집 (MT5 → CSV)

> **소스**: MetaTrader5 (IC Markets 브로커)
> **기간**: 브로커 보유 히스토리 (보통 2012~현재)
> **타임프레임**: M1 (1분봉) 기준
> **저장**: `Files/raw/*.csv` → `Files/processed/TotalResult_*.parquet`

```powershell
# MT5 스크립트 컴파일 후 MT5에서 실행
& "C:\Program Files\MetaTrader5\MetaEditor64.exe" /compile:"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Scripts\DataDownLoad.mq5" /log
```

> MT5 터미널에서 Scripts/DataDownLoad.mq5를 XAUUSD M1 차트에 부착하여 실행합니다.

---

## 방법 3: Data Lake 아키텍처로 빌드

> **수집 완료 후 반드시 실행** — CSV → Parquet 변환 + 파생 피처 계산(변화율/Z-score/기울기)

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\build_data_lake.py"
```

**출력 파일**:
| 파일 | 내용 | 업데이트 |
|:---|:---|:---|
| `Files/processed/macro_features.parquet` | 매크로 60종 × 파생 피처 (변화율/Z-score/기울기/가속도) | 매주 |
| `Files/processed/tech_features.parquet` | M1 기술 지표 63컬럼 (ADX, QQE, BWMFI 등) | 매일 |
| `Files/processed/labels_barrier.parquet` | Triple Barrier 정답지 (AI 학습용 Y) | 라벨링 로직 변경 시 |

---

## 방법 4: MT5 MCP 서버를 통한 실시간 조회

> **용도**: 탐색적 분석, 빠른 이상치 확인, 최신 가격 조회
> **주의**: 대량 수집에는 적합하지 않음 — 방법 1~3 사용

```powershell
# MT5 MCP 서버 기동 (백그라운드)
uv run --directory "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\mcp-metatrader5-server" fastmcp run src/mcp_mt5/main.py:mcp --transport http --host 127.0.0.1 --port 8000
```

이후 AI에게 자연어로 요청:
- `"US500 최근 5봉 보여줘"` → `copy_rates_from_pos` 호출
- `"XAUUSD 현재가"` → `get_symbol_info_tick` 호출

---

## 수집 우선순위 및 데이터 소스 매핑

| 우선순위 | 데이터 | 소스 | 스크립트 |
|:---:|:---|:---:|:---|
| ⭐⭐⭐ | XAUUSD M1 기술 지표 | MT5 | `DataDownLoad.mq5` |
| ⭐⭐⭐ | 미국 국채 수익률 (3M/5Y/10Y/30Y) | Yahoo Finance | `fetch_macro_data.py` |
| ⭐⭐⭐ | 10년 실질금리 (TIPS) | FRED | `fetch_fred_data.py` |
| ⭐⭐⭐ | S&P 500, DXY, VIX | Yahoo Finance | `fetch_macro_data.py` |
| ⭐⭐⭐ | 기대인플레이션 (BEI 10Y/5Y) | FRED | `fetch_fred_data.py` |
| ⭐⭐ | EUR/USD, USD/JPY, 귀금속 | Yahoo Finance | `fetch_macro_data.py` |
| ⭐⭐ | 하이일드 스프레드, 장단기 금리차 | FRED | `fetch_fred_data.py` |
| ⭐ | EM 통화, 소프트 상품, 비트코인 | Yahoo Finance | `fetch_macro_data.py` |

---

## 결과 검증

수집 완료 후 아래 명령으로 파일 스키마를 빠르게 확인:
```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\peek_schema.py"
```
