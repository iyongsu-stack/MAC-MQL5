# 📋 AI 프롬프트 명령어 가이드

## 마스터 문서 (단일 진실 공급원)

| # | 문서 | 역할 |
|:---:|:---|:---|
| 1 | `Docs/TrendTrading Development Strategy/ DB Framework.md` | 4계층 데이터 파이프라인 + ETL + VectorDB |
| 2 | `Docs/TrendTrading Development Strategy/XAUUSD_AI_전략개발_종합_로드맵.md` | AI 주도 패턴 마이닝 + Walk-Forward 3단계 |
| 3 | `Docs/TrendTrading Development Strategy/XAUUSD_AI_피처_완전_가이드.md` | 메가 피처 풀 + SHAP + 랏사이즈 결정 |

---

> [!CAUTION]
> **🚨 AI 전략 개발 3대 핵심 원칙 (프롬프트 실행 전 절대 준수)**
> 1. **Shift+1 원칙**: Time-Series 병합(M1 맵핑)을 지시받을 때, 무조건 `shift(1)` 적용 로직을 포함시켜 Look-ahead Bias를 원천 차단하십시오.
> 2. **Friction Cost 30포인트**: 성과/수익 등 KPI 계산용 파이썬 스크립트 작성 시, XAUUSD 편도 거래마다 최소 30포인트를 마찰 비용(`friction_cost`)으로 강제 차감하도록 코딩하십시오.
> 3. **절대값 사용 금지**: 가격 등 절대값을 로직의 분기 변수로 삼도록 코딩하지 말고, 반드시 변화율(Δ%)이나 Z-Score 등 파생 피처로 변환 후 판별하도록 설계하십시오.

---

| 목적 | 프롬프트 |
|:---|:---|
| **Triple Barrier 라벨링** | `로드맵 문서 기준으로 Triple Barrier 라벨링 스크립트 작성해` |
| **SHAP 피처 분석** | `메가 피처 풀 넣고 LightGBM + SHAP 분석 돌려줘` |
| **Walk-Forward 검증** | `Step 2 모의고사 검증 (1년 데이터) 실행해` |
| **8가지 종합 분석** | `Tools/16_comprehensive_analysis.py 실행해` |
| **전략 비교 (8종)** | `Tools/14_best_strategy.py 실행해` |
| **장기 백테스트** | `Tools/15_longterm_backtest.py 실행해` |
| **위 3개 전부** | `14, 15, 16번 스크립트 순서대로 다 실행해` |
| **결과 해석** | `Files/Comprehensive_Analysis_Report.md 읽고 핵심만 요약해` |

---

## AI 전략 개발 워크플로우 (새 로드맵 기반)

| 순서 | 작업 | 설명 |
|:---|:---|:---|
| 1 | 수동 라벨링 | 100~200개 진입점 라벨(진입 근거 기록) |
| 2 | Triple Barrier 채점 | ATR×1.5/1.0, 30분, 스프레드 차감 |
| 3 | 자동 라벨 확장 | 전체 1분봉에 Triple Barrier 자동 적용 |
| 4 | 매크로 데이터 수집 | UST10Y, EURUSD, US500 등 → 변화율/Z-score 변환 |
| 5 | 메가 피처 풀 구성 | 기술 + 매크로 + 세션 피처 전부 결합 |
| 6 | LightGBM + SHAP | 핵심 피처 3~5개 자동 추출 |
| 7 | 패턴 도출 | Centroid Vector → 벡터 DB 등록 |
| 8 | Walk-Forward Step 2 | 1년 검증 (Fail-Fast) |
| 9 | Walk-Forward Step 3 | 10년 최종 검증 (연도별 분해) |
| 10 | 실전 투입 | 0.01랏부터 단계적 증액 |

---

## 워크플로우 슬래시 명령어

| 명령어 | 용도 |
|:---|:---|
| `/compile` | MQL5 소스 파일 컴파일 |
| `/backtest-analysis` | CSV 백테스트 결과 분석 + 차트 |
| `/data-fetch` | XAUUSD 시장 데이터 수집 |
| `/indicator-verify` | MQL5 지표 ↔ Python 검증 |
| `/mql5-port-verify` | MQL5 지표 변경 → Python 포팅 + 교차 검증 |

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
| 마스터 문서 학습 | `Docs/TrendTrading Development Strategy/ 의 3개 마스터 문서 학습해` |
| 프로젝트 현황 파악 | `Agents/ 폴더를 먼저 읽고 프로젝트를 파악해` |
| 새 전략 실험 | `Agents/5_Strategy_Designer.md 참고해서 [조건] 전략 추가해` |
| MQL5 코드 작성 | `Agents/5_Strategy_Designer.md 기반으로 EA 코드 작성해` |
| 문서 일괄 수정 | `Agents/ 포함, 관련 파일 전부 수정해` |
