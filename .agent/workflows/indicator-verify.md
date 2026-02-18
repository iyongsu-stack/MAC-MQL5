---
description: MQL5 지표를 Python으로 변환하고 정확도 검증
---
// turbo-all

## 지표 검증 워크플로우

### Phase 1: MQL5 기준 데이터 확보
1. 대상 MQL5 인디케이터의 소스 코드를 분석합니다 (`Indicators/` 디렉터리).
2. 필요시 데이터 익스포트 버전(`*DownLoad.mq5`)을 컴파일하고 MT5에서 실행하여 CSV 파일을 생성합니다.
3. 생성된 CSV 파일을 `Files/` 디렉터리에서 확인합니다.

### Phase 2: Python 구현
1. MQL5 지표의 계산 로직을 Python으로 정확히 이식합니다.
2. 동일한 입력 데이터(XAUUSD M1)를 사용하여 Python으로 계산합니다.
3. 핵심 구현 포인트:
   - 재귀적 이동평균(EMA, Wilder's Smoothing 등)의 초기값 처리
   - 버퍼 인덱싱 방향 (MQL5 역순 vs Python 정순) 확인
   - 부동소수점 누적 오차 보정

### Phase 3: 비교 검증
1. MQL5 CSV 값과 Python 계산 값을 정렬하여 비교합니다.
2. 허용 오차: 소수점 이하 6자리 이내 (< 1e-6).
3. 불일치 구간을 식별하고 원인을 분석합니다.
4. 비교 결과를 차트로 시각화합니다:
```python
plt.savefig('Files/indicator_verification.png', dpi=150)
```
5. 검증 완료 후 결과를 사용자에게 보고합니다.
