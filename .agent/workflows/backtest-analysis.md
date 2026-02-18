---
description: CSV 백테스트 결과 분석 및 시각화
---
// turbo-all

## 백테스트 분석 워크플로우

1. 분석 대상 CSV 파일 경로를 확인합니다.
2. Python으로 데이터를 로드하고 기본 통계를 출력합니다:
```python
import pandas as pd
df = pd.read_csv('<CSV경로>')
print(f"총 거래 수: {len(df)}")
print(f"날짜 범위: {df['Time'].min()} ~ {df['Time'].max()}")
```
3. 핵심 성과 지표(KPI)를 계산합니다:
   - 총 수익률 (Total Return)
   - 최대 낙폭 (Maximum Drawdown, MDD)
   - 샤프 비율 (Sharpe Ratio)
   - 승률 (Win Rate)
   - 손익비 (Risk-Reward Ratio)
4. **기울기 변화율(Acceleration) 분석**: 진입 10~20봉 전의 LRA 기울기 변화를 산출하고, 가속/감속 진입의 승률 차이를 비교합니다.
5. 월별/연도별 수익률 히트맵을 생성합니다.
6. 에퀴티 커브와 드로다운 차트를 생성합니다.
7. 모든 차트를 PNG 파일로 저장합니다:
```python
import matplotlib.pyplot as plt
plt.savefig('Files/backtest_analysis.png', dpi=150, bbox_inches='tight')
```
8. 분석 결과 요약을 사용자에게 보고합니다.
