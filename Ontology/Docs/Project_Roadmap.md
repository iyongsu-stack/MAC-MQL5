# 🗺️ 프로젝트 로드맵 (Project Roadmap)

> **용도**: 프로젝트의 대단계(Phase)와 마일스톤(Milestone)의 진행 상태를 추적하는 파일.
> 이 파일에 기록된 내용은 그래프 DB 생성 스크립트에 의해 파싱되어 `Phase`/`Milestone` 노드로 변환됩니다.
> **상태 기호**: ✅ 완료 | 🚀 진행중 | ⬜ 미착수

---

## 📌 작성 규칙
- `### [Phase_ID] Phase 이름` 형식으로 대단계를 정의합니다.
- `- **Status**`: `✅완료`, `🚀진행중`, `⬜미착수`
- `- **Precedes**`: 이 Phase의 다음 단계 ID
- 각 Phase 안에 `#### [MS_ID] 마일스톤 이름`으로 세부 체크포인트를 작성합니다.
- `- **Achieved_By**`: 이 마일스톤을 충족시키는 산출물(스크립트, 데이터 파일, EA 등)

---

## Phase 1: Data Lake 구축 ✅

### [Phase1_DataLake]
- **Status**: ✅완료
- **Precedes**: `Phase2_AI_Training`
- **기간**: ~2026-02-24
- **요약**: 원시 데이터 수집부터 파생 피처 계산, 라벨링, 최종 병합까지 4계층 파이프라인 완성.

#### [MS_매크로수집완료] Yahoo Finance + FRED 매크로 데이터 수집
- **Status**: ✅완료
- **Achieved_By**: `fetch_macro_data.py`, `fetch_fred_data.py`, `Yahoo_CSVs(41종)`, `FRED_CSVs(19종)`

#### [MS_기술지표수집완료] MT5 M1 63개 컬럼 기술 지표 추출
- **Status**: ✅완료
- **Achieved_By**: `tech_features.parquet`

#### [MS_파생피처빌드완료] Z-Score/기울기/가속도 파생 변환
- **Status**: ✅완료
- **Achieved_By**: `build_tech_derived.py`, `build_data_lake.py`, `tech_features_derived.parquet`, `macro_features.parquet`

#### [MS_라벨링완료] ATR 동적 Triple Barrier 라벨링
- **Status**: ✅완료
- **Achieved_By**: `build_labels_barrier.py`, `labels_barrier.parquet`

#### [MS_최종병합완료] AI 학습 데이터셋 병합 (Shift+1 적용)
- **Status**: ✅완료
- **Achieved_By**: `merge_features.py`, `verify_merged_dataset.py`, `AI_Study_Dataset.parquet`

---

## Phase 2: AI 모델 학습 & 패턴 마이닝 🚀

### [Phase2_AI_Training]
- **Status**: 🚀진행중
- **Precedes**: `Phase3_WalkForward`
- **기간**: 2026-03~ (예정)
- **요약**: LightGBM으로 Long/Short 분리 학습 후 SHAP으로 핵심 피처를 추출하는 단계.

#### [MS_피처프루닝완료] 중복 피처 제거 (Spearman > 0.95)
- **Status**: ⬜미착수
- **Achieved_By**: *(미정 — feature_pruning.py 작성 필요)*

#### [MS_LightGBM학습완료] Long/Short 분리 이진 분류 모델 학습
- **Status**: ⬜미착수
- **Achieved_By**: *(미정 — train_lgbm.py 작성 필요)*

#### [MS_비대칭손실적용] Asymmetric Focal Loss 커스텀 목적 함수
- **Status**: ⬜미착수
- **Achieved_By**: *(미정 — custom_loss.py 작성 필요)*

#### [MS_SHAP분석완료] Top-5 핵심 피처 추출 및 안정성 검증
- **Status**: ⬜미착수
- **Achieved_By**: *(미정 — shap_analysis.py 작성 필요)*

---

## Phase 3: Walk-Forward 3단계 교차 검증 ⬜

### [Phase3_WalkForward]
- **Status**: ⬜미착수
- **Precedes**: `Phase4_LiveDeploy`
- **기간**: (미정)
- **요약**: 시계열 무결성을 유지한 롤링 윈도우 방식의 3단계 검증.

#### [MS_Step1통과] 2개월 패턴 마이닝 검증 (최신 레짐 확인)
- **Status**: ⬜미착수
- **Achieved_By**: *(미정)*

#### [MS_Step2통과] 1년 모의고사 검증 (다양한 레짐 생존 확인)
- **Status**: ⬜미착수
- **Achieved_By**: *(미정)*

#### [MS_Step3통과] 최대 가용 데이터 실전 검증 (10년+)
- **Status**: ⬜미착수
- **Achieved_By**: *(미정)*

---

## Phase 4: BSP Framework 실전 배포 ⬜

### [Phase4_LiveDeploy]
- **Status**: ⬜미착수
- **Precedes**: *(없음 — 최종 단계)*
- **기간**: (미정)
- **요약**: 학습된 AI 모델을 ONNX로 추출하여 MT5 EA에 탑재, 실계좌에 0.01랏으로 안전 배포.

#### [MS_ONNX추출완료] LightGBM → ONNX 모델 변환
- **Status**: ⬜미착수
- **Achieved_By**: *(미정)*

#### [MS_EA통합완료] OpenCloseV9.mqh에 AI 진입 로직 탑재
- **Status**: ⬜미착수
- **Achieved_By**: `BSP105V9.mq5`, `OpenCloseV9.mqh`

#### [MS_실전배포완료] IC Markets 라이브 계좌 0.01랏 배포
- **Status**: ⬜미착수
- **Achieved_By**: `BSP105V9.mq5` → `Live_Trading_ICMarkets`

---
*(새로운 Phase나 Milestone이 추가되면 이 아래에 계속 작성해 주세요!)*
