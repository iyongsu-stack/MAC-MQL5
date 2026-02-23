---
description: XAUUSD 시장 데이터 수집 (다중 소스)
---
// turbo-all

## 데이터 수집 워크플로우

### 방법 1: MT5 스크립트를 통한 데이터 다운로드
1. `Scripts/DataDownLoad.mq5`를 컴파일합니다:
```powershell
& "C:\Program Files\MetaTrader5\MetaEditor64.exe" /compile:"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Scripts\DataDownLoad.mq5" /log
```
2. MT5 터미널에서 해당 스크립트를 XAUUSD M1 차트에 부착하여 실행합니다.
3. `Files/` 디렉터리에 생성된 CSV 파일을 확인합니다.

### 방법 2: Python fetch_mt5_data.py 사용
1. MT5 터미널이 실행 중인지 확인합니다.
2. 스크립트를 실행합니다:
```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Tools\fetch_mt5_data.py" --symbol XAUUSD --timeframe M1 --output "Files\xauusd_latest.csv"
```
3. 결과 CSV 파일의 행 수와 날짜 범위를 검증합니다.

### 방법 3: Dukascopy / HistData 외부 소스
1. `Files/Instruction/Data_Fetch.md`의 3-Tier 가이드를 참조합니다.
2. 해당 Instruction에 정의된 스크립트를 실행합니다.
