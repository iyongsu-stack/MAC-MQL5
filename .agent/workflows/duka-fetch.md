---
description: Dukascopy Bank SA에서 XAUUSD M1(1분봉) 틱 데이터 다운로드 — 글로벌 스탠다드 무료 소스
---
// turbo-all

# Dukascopy 데이터 수집 워크플로우 (/duka-fetch)

> **목적**: Dukascopy Bank SA 서버에서 XAUUSD M1(1분봉) 틱 데이터를 Python으로 다운로드하여 CSV/Parquet로 저장한다.
> 2003년 5월부터 현재까지의 데이터를 무료로 확보 가능.

> [!IMPORTANT]
> **데이터 특성 (MT5 데이터와의 차이점)**
> - **OHLC 가격**: MT5 브로커와 거의 동일 (인터뱅크 시장 기준)
> - **Tick Volume**: LP(유동성 공급자)가 다르므로 **수치는 다르지만 상관관계 존재**
> - **시간대**: Dukascopy = **UTC 기준** (MT5 브로커는 보통 UTC+2/+3)
> - **가격 기준**: **Bid 가격** 기준 OHLC

---

## 전제 조건 확인

1. 인터넷 연결이 되어 있어야 합니다.
2. `curl.exe`가 PATH에 있어야 합니다 (Windows 10+에 기본 포함):
```powershell
curl.exe --version
```
3. Python 3.14 + pandas/pyarrow 설치 확인:
```powershell
C:\Python314\python.exe -c "import pandas; import pyarrow; print('OK')"
```

---

## 스크립트 위치

| 파일 | 역할 |
|:---|:---|
| `Files/Tools/fetch_dukascopy_data.py` | Dukascopy M1 데이터 다운로더 (curl.exe 기반) |

---

## 실행 방법

### 방법 1: 테스트 다운로드 (3~5 거래일)

> 스크립트 동작 확인 및 가격 검증용

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\fetch_dukascopy_data.py" --start 2024-01-08 --end 2024-01-10
```

### 방법 2: 특정 기간 다운로드

```powershell
# 2020년부터 어제까지 (약 1,300 거래일, ~3.5시간)
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\fetch_dukascopy_data.py" --start 2020-01-01

# 2024년부터 어제까지 (약 300 거래일, ~50분)
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\fetch_dukascopy_data.py" --start 2024-01-01
```

### 방법 3: 전체 히스토리 다운로드

```powershell
# 2003년 5월부터 (Dukascopy 최초 데이터, ~5,700 거래일, ~16시간)
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\fetch_dukascopy_data.py" --start 2003-05-05
```

---

## 출력 파일

| 파일 | 경로 | 형식 |
|:---|:---|:---|
| CSV | `Files/raw/dukascopy/XAUUSD_M1_{start}_{end}.csv` | time, open, high, low, close, volume, tick_count |
| Parquet | `Files/raw/dukascopy/XAUUSD_M1_{start}_{end}.parquet` | 동일 컬럼, Snappy 압축 |

---

## 결과 검증

다운로드 완료 후 아래 명령으로 데이터를 빠르게 확인:

```powershell
# Parquet 스키마 확인
C:\Python314\python.exe -c "import pandas as pd; df=pd.read_parquet(r'c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\raw\dukascopy\XAUUSD_M1_2024-01-08_2024-01-10.parquet'); print(df.shape); print(df.head(3)); print(df.tail(3))"
```

> [!TIP]
> **예상 소요 시간 기준 (네트워크 상황에 따라 변동)**
> | 기간 | 거래일 수 | 예상 시간 |
> |:---|:---:|:---:|
> | 3일 (테스트) | 3 | ~30초 |
> | 1년 | ~260 | ~45분 |
> | 5년 (2020~) | ~1,300 | ~3.5시간 |
> | 전체 (2003~) | ~5,700 | ~16시간 |

---

## 기술 참고

- **데이터 소스 URL**: `http://datafeed.dukascopy.com/datafeed/XAUUSD/{year}/{month}/{day}/{hour}h_ticks.bi5`
- **월 인덱스**: 0-indexed (1월 = `00`, 12월 = `11`)
- **바이너리 포맷**: `.bi5` = LZMA 압축, 20바이트/틱 (uint32 ms_offset, uint32 ask, uint32 bid, float ask_vol, float bid_vol)
- **가격 제수**: XAUUSD = `/1000` (5자리 FX는 `/100000`)
- **네트워크 제한**: Python `requests`/`urllib`이 Dukascopy IP에서 hang → `curl.exe` subprocess로 해결
