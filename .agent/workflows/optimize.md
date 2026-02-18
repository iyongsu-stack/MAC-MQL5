---
description: Optuna 기반 전략 파라미터 자동 최적화
---
// turbo-all

## 파라미터 최적화 워크플로우

### 사전 조건
1. 필수 라이브러리가 설치되어 있는지 확인합니다:
```powershell
C:\Python314\python.exe -m pip list | findstr "optuna pandas numpy"
```
2. 미설치 시 설치합니다:
```powershell
C:\Python314\python.exe -m pip install optuna pandas numpy matplotlib seaborn
```

### 실행
1. 최적화 스크립트를 실행합니다:
```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Tools\5_auto_optimizer.py" --trials 1000 --parallel 4
```
2. 실행 중 진행률을 모니터링합니다.
3. 최적화 완료 후 결과 파일을 확인합니다:
   - `Docs/Optimization_Result.json` (최적 파라미터)
   - `Data/Optimization_*.md` (실행 로그)

### 결과 분석
1. 최적 파라미터 조합과 목적 함수 값을 보고합니다.
2. 파라미터 중요도(Feature Importance) 차트를 생성합니다 (특히 `LRA_Accel_Period` 영향도 확인).
3. 최적화 히스토리 차트를 생성합니다.
4. 상위 10개 Trial의 파라미터를 비교 테이블로 출력합니다.
5. 기울기 변화율(Accel) 필터 ON/OFF 비교 결과를 보고합니다.
