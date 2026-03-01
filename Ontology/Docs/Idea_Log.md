# 💡 지식 및 아이디어 기록 리스트 (Idea & Insight Log)

> **용도**: AI와의 대화, 백테스트 결과, 문득 떠오른 아이디어 등을 기록하는 전용 파일.
> 이 파일에 기록된 내용은 향후 그래프 DB 생성 스크립트에 의해 자동으로 파싱되어 지식 그래프의 노드(`Idea`, `Insight`)로 변환됩니다.

---

## 📌 작성 규칙 (Markdown 포맷)
- `## [YYYY-MM-DD] 아이디어/인사이트 제목` 형식으로 새로운 항목을 추가합니다.
- `- **Type**`: `Idea` (새로운 제안/가설) 또는 `Insight` (검증된 사실/교훈)
- `- **Status**`: `TO-DO`, `IN-PROGRESS`, `APPLIED`, `DISCARDED`
- `- **Target**`: 연관된 엔티티 이름 (에이전트, 스크립트, 피처, 기능 모듈 등 다수 가능)
- `- **Content**`: 상세 내용 작성

---

## [2026-03-01] 비대칭 손실 함수 (Asymmetric Loss) 도입 검토
- **Type**: Idea
- **Status**: TO-DO
- **Target**: `LightGBM`, `3_Optimizer`
- **Content**: 트레이딩에서는 기회를 놓치는 것(FN)보다 잘못 진입해서 손실을 보는 것(FP)의 페널티가 훨씬 크다. 따라서 기본 Logloss 대신 섣부른 진입에 무거운 페널티를 주는 비대칭 포컬 로스를 모델 학습 시 커스텀 목적 함수로 도입해 볼 것.

## [2026-03-01] 상관계수 기반 Feature Pruning 전처리 추가
- **Type**: Idea
- **Status**: TO-DO
- **Target**: `2_Data_Analyst`, `build_data_lake.py`
- **Content**: 480여 개의 피처 중 계산 로직이 비슷한 중복 피처(예: ADX_Slope와 ADX_Accel)가 그대로 들어가면 SHAP 중요도가 분산되어 진짜 중요한 피처가 하위권으로 밀릴 수 있음. 모델 학습 직전에 스피어만 상관계수 > 0.95 인 중복 피처를 걸러내는 프루닝 파이프라인 추가 필요.

## [2026-03-01] 매크로 데이터와 기술 지표의 비대칭성 교훈
- **Type**: Insight
- **Status**: APPLIED
- **Target**: `Rule_Shift+1`
- **Content**: 1일 단위 매크로(FRED/Yahoo)를 1분 단위 기술 지표와 병합할 때, 반드시 M1 타임스탬프 기준으로 전일(Shift+1) 매크로만 붙여야 미래 참조 편향을 막을 수 있음. 이 원칙은 향후 모든 벡터라이징 과정에서 0순위 무결성 체크 대상임.

---
*(새로운 아이디어는 이 아래에 계속 추가해 주세요!)*
