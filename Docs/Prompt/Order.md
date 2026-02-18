# 📋 AI 프롬프트 명령어 가이드

## 핵심 프롬프트 (한 줄)

| 목적 | 프롬프트 |
|:---|:---|
| **8가지 종합 분석** | `Tools/16_comprehensive_analysis.py 실행해` |
| **전략 비교 (8종)** | `Tools/14_best_strategy.py 실행해` |
| **장기 백테스트** | `Tools/15_longterm_backtest.py 실행해` |
| **위 3개 전부** | `14, 15, 16번 스크립트 순서대로 다 실행해` |
| **새 데이터로 전체 재분석** | `새 데이터 파일은 Files/xxx.csv야. 16번 스크립트 데이터 경로 바꿔서 실행해` |
| **특정 분석만** | `16번 스크립트에서 세션 분석만 따로 돌려줘` |
| **결과 해석** | `Files/Comprehensive_Analysis_Report.md 읽고 핵심만 요약해` |

---

## 워크플로우 슬래시 명령어

| 명령어 | 용도 |
|:---|:---|
| `/compile` | MQL5 소스 파일 컴파일 |
| `/backtest-analysis` | CSV 백테스트 결과 분석 + 차트 |
| `/optimize` | Optuna 파라미터 최적화 |
| `/data-fetch` | XAUUSD 시장 데이터 수집 |
| `/indicator-verify` | MQL5 지표 ↔ Python 검증 |

---

## 추천 실행 순서 (전체 사이클)

| 순서 | 명령어 | 하는 일 |
|:---|:---|:---|
| 1 | `/data-fetch` | 최신 데이터 수집 |
| 2 | `16번 종합분석 실행해` | 8가지 지표 분석 |
| 3 | `/optimize` | 파라미터 최적화 |
| 4 | `15번 장기 백테스트 실행해` | 장기 검증 |

---

## 16번 종합 분석 상세 (8가지)

| # | 분석 | 출력 파일 | 인사이트 |
|:---|:---|:---|:---|
| 1 | 다이버전스 | `analysis_1_divergence.png` | 가격 vs 지표 괴리 빈도 |
| 2 | 조합 클러스터링 | `analysis_2_clustering.png` | 가속도 조합별 PF |
| 3 | 변동성 레짐 | `analysis_3_regime.png` | 저/중/고 변동성별 승률 |
| 4 | 지표 분포 | `analysis_4_distribution.png` | 최적 지표 범위(Zone) |
| 5 | 세션 분석 | `analysis_5_session.png` | 24시간별 KPI |
| 6 | R-Multiple | `analysis_6_rmultiple.png` | 청산 품질 + 캡처율 |
| 7 | 리드/래그 | `analysis_7_leadlag.png` | 선행 지표 순위 |
| 8 | ML 피처 중요도 | `analysis_8_feature_importance.png` | RF 기여도 |

**종합 보고서**: `Files/Comprehensive_Analysis_Report.md`

---

## 기타 유용한 프롬프트

| 상황 | 프롬프트 |
|:---|:---|
| 새 전략 실험 | `Agents/5_Strategy_Designer.md 참고해서 [조건] 전략 추가해` |
| 문서 일괄 수정 | `Agents/ 포함, 관련 파일 전부 수정해` |
| 프로젝트 현황 파악 | `Agents/ 폴더를 먼저 읽고 프로젝트를 파악해` |
| MQL5 코드 작성 | `Agents/5_Strategy_Designer.md 기반으로 EA 코드 작성해` |
