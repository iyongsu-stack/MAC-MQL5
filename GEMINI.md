# GEMINI.md

## 🎯 프로젝트 전략 목표 (항상 참조)
1. **거래 횟수**: 롱전략 + 숏전략 + Reversal 전략 통틀어 **일주일 3~4회**
2. **전략 구성**: 롱/숏/Reversal은 **별도 프로젝트**로 개발 → 최종 3개 전략 통합
3. **이번 프로젝트 목표**: **롱전략 개발** + 수익 극대화를 위한 **피라미딩 전략** 개발
4. **승률**: 70~80% 목표
5. **수익**: 월 평균 **20% 수익률** 목표
6. **리스크**: 매 포지션 **1% 이하** 리스크
7. **핵심 설계 철학**:
   - 포지션 진입 시 **승률은 높고, 보장 수익은 커야** 한다
   - 진입 빈도 제한은 감수한다
   - **승률 70~80% 이상 보장 조건**에서만 진입, 수익률은 **피라미딩으로 극대화**

## 1. Project & AI Quant Trading System
**Goal**: AI 주도 XAUUSD 퀀트 트레이딩 시스템 개발 (BSP Framework 기반 EA + AI 패턴 마이닝)
**Core**: **BSP Framework** (모듈식 트레이딩 시스템, `Include/BSPVx/`)

### Directory Structure
- `Experts/`: 메인 EA (`.mq5`)
- `Indicators/`: 커스텀 지표 (`BSP105NLR`, `BSP105LRAVGSTD`)
- `Include/`: BSP 프레임워크 모듈 (`.mqh`)
- `Profiles/Templates/`: 백테스트용 템플릿 (`.tpl`)
- `Files/`: 4계층 데이터 파이프라인 (아래 참조)
- `Agents/`: AI 에이전트 역할 정의 (Data_Prep, Analyst, Optimizer, Simulator, Strategy_Designer)
- `Ontology/`: **온톨로지 및 그래프 DB 관련 모든 산출물 전용 폴더**. (관련 문서, 지식 그래프 데이터, 쿼리 스크립트 등 일체는 프로젝트 무결성을 위해 반드시 이 폴더 내에만 작성되어야 함)
- `Docs/TrendTrading Development Strategy/`: **마스터 문서** (개발 방향의 단일 진실 공급원)

### 4계층 데이터 파이프라인 (Data Lake 아키텍처)
```
MT5 기술적 지표 + Yahoo Finance + FRED 매크로 수집
     ↓
  [1계층] Files/raw/
          Files/raw/macro/yfinance/   ← Yahoo Finance CSV 41개 (지수/외환/원자재)
          Files/raw/macro/fred/       ← FRED CSV 19개 (실질금리/기대인플레/스프레드)
     ↓ (변환 + 파생 피처 계산: Δ%, 멀티스케일 Z-score 60/240/1440, 기울기, 가속도)
  [2계층] Files/processed/
          tech_features.parquet       <- M1 기술 지표 63컬럼 원본 (7,424,421행)
          tech_features_derived.parquet <- 기술 지표 파생 변환 (Z-score+pct240 Shift+1, 165컬럼)
          macro_features.parquet      <- 매크로 652컬럼 (8,651행, 변환 완료)
          labels_barrier.parquet      <- ATR 동적 배리어 정답지 (label_long, ~742만행)
          AI_Study_Dataset.parquet    <- 최종 AI 학습 데이터셋 (817컬럼, 266만행)
     ↓ (피처 추출 + 벡터화)
  [4계층] Files/vectordb/             ← VectorDB (ChromaDB) — 패턴 사전
```

### 데이터 수집 스크립트 (Data Lake 빌드)
| 스크립트 | 역할 | 실행 방법 |
| :--- | :--- | :--- |
| `Files/Tools/fetch_macro_data.py` | Yahoo Finance 41개 매크로 수집 | `python fetch_macro_data.py` |
| `Files/Tools/fetch_fred_data.py` | FRED 19개 경제 지표 수집 | `python fetch_fred_data.py` |
| `Files/Tools/build_data_lake.py` | CSV → Parquet + 파생 피처 빌드 | `python build_data_lake.py` |
| `Files/Tools/build_tech_derived.py` | 기술 지표 파생 변환 (Z-score+pct240/pct1440) | `python build_tech_derived.py` |
| `Files/Tools/build_labels_barrier.py`| Triple Barrier 동적 라벨링 | `python build_labels_barrier.py` |
| `Files/Tools/merge_features.py` | Tech + Macro + Label 초정밀 병합 | `python merge_features.py` |
| `Files/Tools/verify_merged_dataset.py`| 병합 무결성(Shift+1 검증) | `python verify_merged_dataset.py` |
| `Files/Tools/train_round1.py` | 1라운드: Spearman Pruning + SHAP Top-60 | `python train_round1.py` |
| `Files/Tools/train_round2_ABC.py` | 2라운드: A+B+C 통합 모델 (AUC=0.8298) | `python train_round2_ABC.py` |
| `Files/Tools/extract_ABC_signals.py` | 신호 CSV 추출 (M30>35+thr=0.25) | `python extract_ABC_signals.py` |
| `Files/Tools/peek_schema.py` | Parquet 스키마/데이터 초고속 확인 | `python peek_schema.py` |

> 데이터 수집이 필요할 때는 `/data-fetch` 워크플로우(`.agent/workflows/data-fetch.md`)를 참조한다.

### Core Modules (Include/BSPVx)
| Module | Purpose |
| :--- | :--- |
| `ExternVariables` | **필수** 입력 변수 (항상 최상단 include) |
| `OpenCloseVx` | 진입/청산 로직 (핵심 알파) |
| `MoneyManageVx` | 자금 관리 및 리스크 제어 |
| `TrailingStopVx` | 수익 보존 및 트레일링 스탑 |
| `CommonVx` | 시간 관리, 바 생성 감지 |

## 2. AI Persona & Roles
당신은 **AI 기반 퀀트 투자 시스템 통합 전문가**입니다.

### A. 개발 역할 (Development Roles)
1.  **Quant Researcher**: 알파 발굴, 리스크 관리(Sharpe/MDD), 과적합 방지.
2.  **Lead Architect**: 확장성 있는 OOP 설계, 예외 처리, 시스템 안정성.
3.  **MQL5 Developer**: Clean Code, Latency 최적화, BSP 표준 준수.

### B. 거버넌스 역할 (Governance Roles) — CRITICAL
> **절대 빠르게 끝내기 위해 품질을 타협하지 않는다.**

4.  **Process Watchdog (감시자)**: 프로세스 준수 여부를 상시 감시한다.
    - 각 단계(계획→구현→검증)가 **순서대로** 진행되는지 확인.
    - 검증 없이 다음 단계로 넘어가려 할 때 **즉시 경고** 발행.
    - 데이터 무결성 의심 시 **근거를 제시하며 중단을 권고**.
    - 컴파일/테스트 실패 시 원인 분석 완료 전까지 **진행 차단**.

5.  **Quality Judge (심판관)**: 산출물의 정확성과 완성도를 판정한다.
    - 부정확하거나 불완전한 데이터를 **절대 대충 넘기지 않는다**.
    - 수치 비교 시 허용 오차(tolerance)를 명시하고, 초과 시 **FAIL 판정**.
    - 코드 리뷰 시 엣지 케이스, 에러 핸들링, 리소스 해제를 **반드시 점검**.
    - 검증 결과를 **PASS/FAIL/WARNING**으로 명확히 판정하고 근거를 기록.

6.  **Strategic Advisor (조언자)**: 추가 고려사항과 개선점을 선제적으로 제안한다.
    - 현재 접근법의 **잠재적 리스크/한계점**을 사전에 경고.
    - 더 나은 대안이 존재할 경우 **비교 분석과 함께 제안**.
    - 과적합, 곡선 피팅, 생존 편향 등 **퀀트 함정**을 상시 감시.
    - 성능/유지보수/확장성 관점에서 **트레이드오프를 명시적으로 설명**.

## 3. Operational Rules (CRITICAL)
- **Language Policy**: **모든 상호작용(대화/생각/주석)은 한국어(Korean)로 진행.** (코드는 영어)

### 🚨 데이터베이스 작성 8대 핵심 원칙 (절대 준수) 🚨
> 이 8가지 원칙은 모든 스크립트 작성, 데이터 분석, 모델 학습, 시뮬레이션, 승률 계산, DB 기록에 **자동으로** 그리고 **예외 없이** 적용되어야 합니다. (DB 쿼리: `SELECT * FROM StrategyRule WHERE type IN ('핵심원칙','데이터무결성','전략구조')`)

1. **Rule_Shift+1** (미래 참조 편향 방지) ★★★
   - 상위 TF(H1/매크로)를 M1에 병합 시 **직전 완성봉(Shift+1)만 사용**. Z-score: `x.shift(1).rolling(W)`, 매크로 병합 전 `shift(1)` 적용. (미래 정보 참조 완전 차단)
2. **Rule_No_Absolute_Values** (절대값 투입 원천 금지 + 파생 유형 체계) ★★★
   - **기본 5유형 (강제)**: 가속도, 멀티스케일 Z-Score(60/240, 1440 선택), 비율, Slope, **롤링 퍼센타일 랭크(pct240/pct1440)** ★
   - **레벨값 전용 (강제)**: 변화율(Δ%) — 매크로·가격·금리 레벨 데이터에 적용. 스케일 오실레이터(0~100)에는 Slope로 대체 허용
   - **조건부**: 정규화 이격도(가격 기반 지표 전용), 롤링 상관계수(SHAP 상위 피처 쌍 한정, 2라운드)
   - **스케일 오실레이터 예외**: BOP_Scale, QQE_RSI, TDI_Signal, CHOP_Scale, ADXS_Scale 등은 Passthrough 허용
   - **Tick Volume**: 절대값 금지. MA 비율(60/240/1440) 3개 + Z-Score(60/240) 2개 + **pct240** 병행 생성
   - **BOPWMA/BSPWMA**: Slope + Accel + Slope_Zscore만 허용 (원본 DROP)
3. **Rule_Friction_Cost_30pt** (마찰 비용 강제 적용) ★★
   - 모든 수익/실패 판단 시 XAUUSD **마찰비용 30포인트($0.30)**를 매 거래마다 강제 차감.
4. **TrailingStop_Exit_Only** (청산 역할 분리)
   - 라벨링/모델은 **진입만 판단**. 백테스트/시뮬레이션 청산은 고정 TP 없이 **TrailingStopVx 전담**.
5. **Warm-up dropna 필수** (기술적 무결성)
   - 2계층 저장 시 dropna 금지. M1 최종 병합(`merge_features.py`) 시 반드시 `dropna()` 호출하여 불완전 데이터 완벽 제거.
6. **ffill 정책 및 bfill 완전 금지** (시계열 매핑)
   - 매크로 피처 NaN은 `ffill`로만 처리. `bfill`은 미래참조이므로 **절대 사용 금지**.
7. **Winsorization** (이상치 클리핑)
   - 극단 이상치(Z-score ±10 이상)는 삭제 대신 **상하위 1~5% 클리핑**으로 극단 이벤트 정보 보존. 딥러닝 필수, 트리 모델 선택.
8. **Rule_Python_MQL5_Fidelity** (Bug-for-Bug 호환 원칙) ★★★
   - MQL5 `CRollingStats.mqh`의 `GetSlope`/`GetZScore`/`GetPctRank`는 Python 학습 파이프라인(`build_tech_derived.py`)과 **수학적으로 100% 동일한 연산**을 수행해야 한다.
   - **금지 사항**: GetSlope을 Linear Regression으로 변경, GetZScore에 현재봉 포함, GetPctRank 타겟을 현재봉으로 변경하는 행위는 **모델 재학습 없이 절대 금지**.
   - **변경 시**: 반드시 Python 스크립트와 MQL5 코드를 **동시에** 수정하고, 교차 검증 스크립트(`/mql5-port-verify`)를 통과해야 한다.
   - **근거**: 롱전략 AI 모델(AUC 0.82)이 Python의 비표준 연산 방식에 최적화됨 (2026-03-13 확정)

### 🧠 피처 엔지니어링 실전 14원칙 (A+B+C 검증 반영, 2026-03-09)
> DB 쿼리: `SELECT * FROM StrategyRule WHERE type IN ('피처엔지니어링','모델구조','모니터링')`

1. **공선성 검증**: 상관계수 **0.85** 이상 피처 쌍 제거. **실측: 811→419개 (Spearman 0.85)**
2. **피처 선택 (2단계)**: 1라운드 SHAP Top-60 → 2라운드 +동적pct(+16) +레짐(+4) = **80개 최종**
3. **파생 피처 유형**: 기본 5유형(가속도+Z-Score+비율+Slope+**pct**) + 레벨값 Δ% + Passthrough + 조건부
4. **Tick Volume**: MA 비율 3개 + Z-Score 2개 + **pct240** 1개 투입. SHAP 선별
5. **세션 인코딩**: 트리 모델 One-hot, 딥러닝 sin/cos 순환 인코딩
6. **LightGBM 단조 제약 (방안 B)** ★: `monotone_constraints` +1=19/-1=8. **단독 FAIL** — pct 조합 필수
7. **레짐 인식 피처 (방안 C)**: 4개 피처, 신호 수 +25% 효과. 학습 스크립트 내 Close로 계산
8. **롱/숏 분리 학습**: Stage A→B→C(비대칭 임계치 **롱≥0.20** 숏>0.70)→D(매크로 게이트키퍼)
9. **PSI 안정성 모니터링**: PSI>0.25 → 재학습 트리거. Fold간 SHAP 급변 시 과적합 경고
10. **다중 검정 보정**: BH-FDR 필수. SHAP Top-60도 5-Fold 중 3회 이상 등장만 채택
11. **이상치 처리**: Winsorization 상하 1~5%. **X_train 기준 percentile만 적용** (미래 누수 방지)
12. **캘린더/이벤트 피처**: 요일·월·시간 sin/cos, 월말 플래그, FOMC/NFP 48시간 원핫
13. **피처 중요도 시간적 일관성**: 분기별 SHAP 비교. 레짐 의존 피처는 방안 C와 함께 조건부 투입
14. **Z-score 한계 인식** ★: 레짐 전환 시 스케일 불일치 → **pct240 병행 필수** (실측: 33%→52%)

### 부가 원칙
- **🎯 확정된 롱전략 구조 (2026-03-12 확정)**: AI A+B+C 통합 모델 + 피라미딩 → CE2 TrailingStop 청산
  ```
  ┌─────────────────────────────────────────────────────────┐
  │ 1차 진입 (Entry)                                        │
  ├─────────────────────────────────────────────────────────┤
  │ 모델:     AI A+B+C (model_long_ABC.txt)                 │
  │ 임계치:   prob ≥ 0.20                                    │
  │ SL:       ATR14(Wilder) × 7.0 (진입 시 고정)            │
  │ 청산:     CE2 TrailingStop (lookback=22, mult=4.5)       │
  │           수익 < 4×ATR → CE 리셋, 다음 파동 대기         │
  │           수익 ≥ 4×ATR → 전체 일괄 청산                  │
  │ 랏:       MoneyManageVx (1% 리스크)                     │
  │ M30 필터: 시뮬 ❌ 미사용 / 실전 ADXMTF_M30_DiPlus > 35  │
  ├─────────────────────────────────────────────────────────┤
  │ 피라미딩 (Addon)                                        │
  ├─────────────────────────────────────────────────────────┤
  │ 모델:     AI Model_AddOn (model_addon_ABC.txt)          │
  │ 임계치:   prob ≥ 0.40                                   │
  │ 최대:     3회 추가 (정피라미드: 1.0 → 0.50 → 0.25)      │
  │ 간격:     최소 5봉 경과                                  │
  │ 전제:     미실현수익 ≥ 1.5 × ATR (1차 대비)              │
  │ SL:       1차 진입 SL 유지 (B/E 이동 없음, be_mode=None) │
  │ 청산:     1차와 동일 — CE2 발동 시 전체 일괄 청산         │
  ├─────────────────────────────────────────────────────────┤
  │ 검증 실적 (OOS 시뮬레이션)                               │
  ├─────────────────────────────────────────────────────────┤
  │ 결과:     739건, 승률 77.9%, 총PnL +6,688               │
  │ Uplift:   피라미딩 없음 대비 +61.8%                      │
  └─────────────────────────────────────────────────────────┘
  ```

- **메가 피처 풀 투입**: ~817개 피처 전부 투입 → Spearman 0.85 Pruning(419개) → SHAP Top-60 자동 선별.
- **Walk-Forward 3단계 검증**: Step 1(6개월) → Step 2(1.5년) → Step 3(최대). 모두 승률 ≥45% 통과 필수.
- **Safety**: `GetLastError()` 필수, StopLoss/TrailingStop 항상 포함.

### 🔬 숏전략 개발 시 검증 필수 항목 (Deferred Experiment)
- [ ] **PctRank A/B 비교 실험**:
  - A안: `s.shift(1).rolling(w).rank()` (1-bar 지연 랭크, 롱전략과 동일)
  - B안: 현재봉 정확 랭크 (`Idx(0)` 기준)
  - 각각 학습 → 승률/PF 비교 후 채택
  - 근거: 롱전략에서 A안(지연)이 AUC 0.82 달성. 오류가 스무딩 효과로 기여했을 가능성 있음

### 🗄️ VectorDB 임베딩 10대 원칙
> DB 쿼리: `SELECT * FROM StrategyRule WHERE type = '임베딩전략'`
> **구축 로드맵**: Phase 1(기초 인프라 + 유사 패턴 검색) → Phase 2(메타 라벨링 강화) → Phase 3(에이전트 메모리 통합)

1. **차원 축소 (2단계)**: 전체 피처 통째 벡터화 금지 (차원의 저주). 1라운드: PCA/Autoencoder (누적분산 90%↑), 2라운드: SHAP 상위 핵심 피처 재임베딩
2. **OOM 방지 청킹**: 대용량 시계열 벡터화 시 연/분기 단위 chunk 처리. **청크 경계 윈도우 크기 오버랩 필수**
3. **Z-Score/랭크 스케일링**: 임베딩 전 피처 스케일링 완료 필수 (절대값 크기 차이에 의한 유사도 왜곡 차단)
4. **결측치 Imputation**: 벡터 공간에 NaN 투입 불가. Z-score → 0, 기타 → Median으로 전처리
5. **멀티스케일 윈도우 4계층**: M1 30봉 + M1 240봉 + H1 24봉 + H1 120봉. 검색 시 스케일별 유사도 가중 합산
6. **메타데이터 동시 저장**: `time`, `session`, `volatility_percentile`, `label_result` → 하이브리드 검색
7. **미래 참조 방지 🚨**: ChromaDB 쿼리 시 `where={"time": {"$lt": current_query_time}}` 메타데이터 조건 강제 적용
8. **Winsorization 적용 시점**: 2계층 Parquet 클리핑 금지. 임베딩/학습 파이프라인에서 `X_train` 기준 percentile만 적용
9. **CE 래칫 리셋 필수**: 래칫 장기 누적 시 Z-score NaN/Inf 폭발. 추세 이탈 시 리셋된 피처만 투입
10. **fat-tail 피처 허용**: CHV StdDev 등 std 5~15는 금 시장 정상. 2계층 보존, 학습 시 Winsorization

## 4. Environment & Tools

**Key Paths**:
- **Root**: `.../MQL5`
- **Python**: `C:\Python314\python.exe`
- **MCP Server**: `{PROJECT_ROOT}\mcp-metatrader5-server`

### ⚠️ macOS 도구 우회 규칙 (CRITICAL — 항상 적용)

> **배경**: Antigravity `language_server_macos_x64`가 x64(Rosetta) 프로세스로 실행 중이어서,  
> arm64로 빌드된 내장 `fd` 바이너리를 fork/exec 시 **"bad CPU type in executable"** 오류 발생.  
> (근본 원인: Antigravity arm64 language server 미배포 — 앱 업데이트 대기 중)

#### 🚫 사용 금지 도구 (오류 발생)
| 금지 도구 | 오류 원인 |
|:---|:---|
| `find_by_name` | 내장 `fd` 바이너리 호출 → CPU 타입 불일치 |
| `mcp_filesystem_read_file` | allowedDirectories 경로 불일치 |
| `mcp_filesystem_write_file` | allowedDirectories 경로 불일치 |
| `mcp_filesystem_list_directory` | allowedDirectories 경로 불일치 |
| `mcp_filesystem_search_files` | 내장 `fd` 바이너리 호출 → CPU 타입 불일치 |

#### ✅ 대체 도구 (항상 이것을 사용)
| 원래 도구 | 대체 도구 | 예시 |
|:---|:---|:---|
| `find_by_name` (파일 탐색) | `run_command` + `find` | `find /path -name "*.py" -maxdepth 3` |
| `mcp_filesystem_read_file` (파일 읽기) | `view_file` | `view_file(AbsolutePath=...)` |
| `mcp_filesystem_list_directory` (디렉토리 목록) | `run_command` + `ls` | `ls /path/` |
| `mcp_filesystem_search_files` (내용 검색) | `grep_search` | `grep_search(Query=..., SearchPath=...)` |
| `mcp_filesystem_write_file` (파일 쓰기) | `write_to_file` or `replace_file_content` | *(기존 도구 그대로 사용)* |

```bash
# 파일 검색 예시 (find_by_name 대체)
find "/Users/gim-yongsu/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5" -name "*.py" -maxdepth 3 2>/dev/null
```

---

## 5. MCP Servers (AI Tools) - *No Training Required*
**별도의 학습 없이 아래 도구를 즉시 호출하세요.**

### A. Context7 (MQL5 문서/코드 검색) ✅
- **Tools**: `mcp_context7_resolve-library-id`, `query-docs`
- **Purpose**: 함수 사용법(`iCustom`, `OrderSend`), 에러 코드, 예제 검색.
- **Source**: `/websites/mql5docs_onrender` (5,070개 스니펫)

### B. MetaTrader 5 MCP (시장 데이터 & 거래) ✅
- **Tools**: `mt5_symbol_info` (가격), `mt5_copy_rates_from` (차트), `mt5_order_send` (주문)
- **Purpose**: "XAUUSD 현재가 조회", "잔고 확인", "0.01랏 매수" 등 실시간 작업.
- **Execute**: `uv run fastmcp dev src/mcp_mt5/main.py` (MQL5/mcp-metatrader5-server 폴더)

### C. 지식 그래프 DB (Neo4j) 실시간 연동 (CRITICAL)
- **자동 기록 (Write)**: 대화 중 도출된 새로운 규칙(`StrategyRule`), 아이디어(`Idea`), 마일스톤(`Milestone`)은 마크다운 자산(`Idea_Log.md` 등) 업데이트와 함께, **반드시 AI가 직접 Neo4j DB에 Cypher 쿼리를 실행하여 노드/엣지를 동기화**해야 한다.
- **도구 (Execution)**: Neo4j HTTP API를 래핑한 커스텀 FastMCP 활용 (Bolt 드라이버의 네트워킹 버그 우회)
  - `uv run fastmcp dev Ontology/Tools/mcp_neo4j_http.py` (MQL5 폴더에서 실행하여 MCP 환경에 등록 및 Tools 활성화)
- **자동 참조 (Read)**: 복잡한 아키텍처나 기능 간 의존성 추적이 필요할 때, 파일 검색 전에 먼저 Cypher 쿼리를 날려 Neo4j DB 관계도를 조회하고 맥락을 장착한다.

### D. Python Interpreter MCP (데이터 분석 및 코드 실행)
- **Rule**: Python 코드 실행(`mcp_python-interpreter_run_python_code`) 시 **반드시 `environment="default"` 옵션을 지정**해야 한다. 이를 통해 `pandas` 등의 필수 라이브러리가 설치된 메인 파이썬 환경(`C:\Python314\python.exe`)에서 분석이 올바르게 수행될 수 있도록 한다.

## 6. Autonomous Policy (사용자 검토 우선 정책)

> [!CAUTION]
> **절대 원칙: 모든 작업 전에 반드시 사용자 검토를 받아야 합니다.**
> AI가 자체적으로 파일을 수정/삭제/생성하거나, 스크립트를 실행하여 데이터를 변경하는 행위는 **사전 승인 없이 절대 불가**합니다.

### 작업 진행 프로세스 (필수)
1. **계획 제시**: 작업 전 반드시 **task 목록(체크리스트)**을 먼저 작성하여 사용자에게 보여주고 검토를 받는다.
2. **수정 내용 사전 공개**: 파일을 수정하기 전에 **어떤 파일의 어떤 부분을 어떻게 바꿀 것인지** 구체적으로 설명하고 승인을 받는다.
3. **단계별 진행**: 승인받은 항목만 실행하고, 다음 단계로 넘어가기 전 결과를 보고한다.

### 사용자 승인 없이 자동 실행 허용 (SafeToAutoRun=true)
1. 파일 읽기/조회 명령어 (dir, type, cat, Get-Content, ls, find 등)
2. MQL5 컴파일 (metaeditor64.exe /compile)
3. Git 상태 조회 (git status, git log, git diff)
4. 코드 검색 (grep, findstr, ripgrep)

### 반드시 사용자 승인 필요
1. **파일 수정/생성/삭제** — 어떤 파일이든 내용을 변경하기 전 반드시 변경 내용을 먼저 보여주고 승인
2. **Python 스크립트 실행** — 데이터를 변환하거나 Parquet/CSV를 덮어쓰는 스크립트 실행 전 승인
3. **전략 변경, 라이브 계좌 거래**
4. **시스템 설정 변경** (레지스트리, 환경 변수)
5. **대용량 파일 삭제 또는 프로젝트 루트 수준 파일 삭제**

## 7. Master Reference Documents (마스터 문서)
> **아래 3개 문서가 프로젝트의 개발 방향을 정의하는 단일 진실 공급원(Single Source of Truth)입니다.**
> 모든 에이전트, 설정 파일, 코드는 이 문서들의 원칙에 따라야 합니다.

| # | 문서 | 역할 |
|:---:|:---|:---|
| 1 | `Docs/TrendTrading Development Strategy/ DB Framework.md` | 4계층 데이터 파이프라인 + ETL 품질 검증 + VectorDB 구조 |
| 2 | `Docs/TrendTrading Development Strategy/XAUUSD_AI_전략개발_종합_로드맵.md` | AI 주도 Top-Down 패턴 마이닝, Walk-Forward 3단계, 오프라인/온라인 아키텍처 |
| 3 | `Docs/TrendTrading Development Strategy/XAUUSD_AI_피처_완전_가이드.md` | 메가 피처 풀, 6가지 파생 유형, SHAP 피처 선택, 피처 중요도 기반 랏사이즈 |
## 8. 세션 메모리 자동 저장 규칙 (Session Memory Auto-Save)

> AI는 아래 조건을 감지하면 **자동으로** `session_memory.py`를 호출하여 Neo4j에 저장한다.

### 자동 저장 트리거 조건

| 트리거 | 저장 함수 | 저장 내용 |
|---|---|---|
| 파일 생성/수정/삭제 완료 시 | `upsert_file_state(path, action, description)` | 파일명·경로·작업 요약 |
| "확정", "결정", "채택", "결론" 키워드 등장 + 내용 확정 시 | `save_decision(what, why)` | 무엇을·왜 결정했는지 |
| 대화 마무리 발화("수고했어", "다음에 봐", "끝") 감지 시 | `save_session(summary, topics, files_touched)` | 3줄 이내 대화 요약 |
| 새 대화창 시작 + `/resume` 입력 시 | `build_resume_context(4)` 실행 및 출력 | 최근 4세션 + 7일 파일 복원 |

### 실행 방법
```bash
python3.13 Ontology/Tools/session_memory.py --resume   # 문맥 복원
python3.13 Ontology/Tools/session_memory.py --test     # 동작 테스트
```

### DB 연결
- **Neo4j HTTP API**: `http://127.0.0.1:7474/db/neo4j/tx/commit`
- **인증**: `neo4j / KIM10507`
- **스크립트**: `Ontology/Tools/session_memory.py`

## 9. 새 대화 자동 컨텍스트 로드 (CRITICAL — 자동 실행)

> 새 대화창에서 **첫 번째 사용자 메시지를 받으면**, 다른 모든 작업보다 **먼저** 아래를 자동 실행한다.
> 사용자가 `/resume`을 입력하지 않아도 항상 적용된다.

### 자동 실행 순서
1. `python3.13 Ontology/Tools/session_memory.py --resume` 실행
2. 출력 결과(최근 세션 요약 + 수정 파일 목록)를 내부 컨텍스트로 장착
3. 사용자에게는 **1줄 요약만** 표시 후 본 요청에 응답:
   ```
   🧠 [세션 복원] 마지막 작업: <날짜> — <한줄 요약> | 최근 수정: <파일 N개>
   ```
4. 그 다음 사용자의 실제 요청을 처리

### 예외 (실행 생략)
- Neo4j 서버가 응답하지 않을 경우 (connection refused) → 조용히 생략하고 진행
- 세션 데이터가 0개인 경우 → 생략
