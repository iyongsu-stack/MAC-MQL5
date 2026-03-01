// =====================================================
// 시나리오 1: 규칙/합의 저장 (StrategyRule)
// =====================================================
MERGE (r:StrategyRule {name: "Rule_Shift+1"})
SET r.description = "상위 TF 데이터 병합 시 반드시 직전 완성봉(Shift+1)만 사용하여 미래참조 방지",
    r.type = "핵심원칙",
    r.created_date = "2026-02-01",
    r.source = "GEMINI.md"

// =====================================================
// 시나리오 1: 규칙/합의 저장 (StrategyRule) - 추가
// =====================================================
;
MERGE (r:StrategyRule {name: "Rule_Friction_Cost_30pt"})
SET r.description = "모든 수익/실패 판단 시 XAUUSD 거래 마찰비용 30포인트를 반드시 차감",
    r.type = "핵심원칙",
    r.created_date = "2026-02-01",
    r.source = "GEMINI.md"

;
MERGE (r:StrategyRule {name: "Rule_No_Absolute_Values"})
SET r.description = "절대값 사용 금지. 모든 피처는 파생 변환(Δ%, Z-Score, 기울기 등)하여 사용",
    r.type = "핵심원칙",
    r.created_date = "2026-02-01",
    r.source = "GEMINI.md"

;
MERGE (r:StrategyRule {name: "TrailingStop_Exit_Only"})
SET r.description = "청산은 TrailingStopVx가 전담. 고정 TP 사용 안 함. AI는 진입만 학습",
    r.type = "전략구조",
    r.created_date = "2026-02-27",
    r.source = "GEMINI.md"

// =====================================================
// 시나리오 2: 아이디어 저장 (Idea)
// =====================================================
;
MERGE (i:Idea {name: "Asymmetric_Loss_도입"})
SET i.description = "롱/숏 비대칭 손실함수를 모델 학습에 적용하여 하락장 숏 정확도 향상",
    i.status = "검토중",
    i.created_date = "2026-03-01",
    i.source = "AI 대화"

;
MERGE (i:Idea {name: "Feature_Pruning_추가"})
SET i.description = "SHAP 기반 피처 중요도 하위 10% 자동 제거 파이프라인 추가",
    i.status = "검토중",
    i.created_date = "2026-03-01",
    i.source = "AI 대화"

// =====================================================
// 시나리오 3: 로드맵/마일스톤 저장 (Phase + Milestone)
// =====================================================
;
MERGE (p1:Phase {name: "Phase1_DataLake"})
SET p1.description = "Data Lake 구축 및 피처 엔지니어링",
    p1.status = "✅완료",
    p1.order = 1

;
MERGE (p2:Phase {name: "Phase2_AI_Training"})
SET p2.description = "AI 모델 학습 및 SHAP 피처 선택",
    p2.status = "🚀진행중",
    p2.order = 2

;
MERGE (p3:Phase {name: "Phase3_WalkForward"})
SET p3.description = "Walk-Forward 3단계 검증",
    p3.status = "⬜미착수",
    p3.order = 3

;
MERGE (p4:Phase {name: "Phase4_LiveDeploy"})
SET p4.description = "실전 배포 및 모니터링",
    p4.status = "⬜미착수",
    p4.order = 4

// Phase 순서 관계 (PRECEDES)
;
MATCH (p1:Phase {name: "Phase1_DataLake"}), (p2:Phase {name: "Phase2_AI_Training"})
MERGE (p1)-[:PRECEDES]->(p2)

;
MATCH (p2:Phase {name: "Phase2_AI_Training"}), (p3:Phase {name: "Phase3_WalkForward"})
MERGE (p2)-[:PRECEDES]->(p3)

;
MATCH (p3:Phase {name: "Phase3_WalkForward"}), (p4:Phase {name: "Phase4_LiveDeploy"})
MERGE (p3)-[:PRECEDES]->(p4)

// Phase 1 마일스톤
;
MERGE (m:Milestone {name: "MS_매크로수집완료"})
SET m.description = "Yahoo Finance 41개 + FRED 19개 매크로 CSV 수집 완료",
    m.status = "✅완료"

;
MERGE (m:Milestone {name: "MS_기술지표파생완료"})
SET m.description = "tech_features_derived.parquet 생성 (Z-score, 기울기, 가속도 등)",
    m.status = "✅완료"

;
MERGE (m:Milestone {name: "MS_라벨링완료"})
SET m.description = "ATR 동적 배리어 라벨링(labels_barrier.parquet) 완료",
    m.status = "✅완료"

;
MERGE (m:Milestone {name: "MS_데이터셋병합완료"})
SET m.description = "AI_Study_Dataset.parquet 최종 병합 및 Shift+1 무결성 검증 통과",
    m.status = "✅완료"

// Phase 1 → Milestone (CONTAINS)
;
MATCH (p:Phase {name: "Phase1_DataLake"}), (m:Milestone {name: "MS_매크로수집완료"})
MERGE (p)-[:CONTAINS]->(m)

;
MATCH (p:Phase {name: "Phase1_DataLake"}), (m:Milestone {name: "MS_기술지표파생완료"})
MERGE (p)-[:CONTAINS]->(m)

;
MATCH (p:Phase {name: "Phase1_DataLake"}), (m:Milestone {name: "MS_라벨링완료"})
MERGE (p)-[:CONTAINS]->(m)

;
MATCH (p:Phase {name: "Phase1_DataLake"}), (m:Milestone {name: "MS_데이터셋병합완료"})
MERGE (p)-[:CONTAINS]->(m)

// Milestone → 산출물 (ACHIEVED_BY)
;
MERGE (d:DataArtifact {name: "macro_features.parquet"})
SET d.tier = "Tier2_Processed"

;
MATCH (m:Milestone {name: "MS_매크로수집완료"}), (d:DataArtifact {name: "macro_features.parquet"})
MERGE (m)-[:ACHIEVED_BY]->(d)

;
MERGE (d:DataArtifact {name: "AI_Study_Dataset.parquet"})
SET d.tier = "Tier2_Processed"

;
MATCH (m:Milestone {name: "MS_데이터셋병합완료"}), (d:DataArtifact {name: "AI_Study_Dataset.parquet"})
MERGE (m)-[:ACHIEVED_BY]->(d)

// 규칙이 명시된 문서 연결 (DEFINED_IN)
;
MERGE (doc:Document {name: "GEMINI.md"})
SET doc.description = "프로젝트 마스터 설정 문서 (AI 페르소나, 환경, 규칙 등)"

;
MATCH (r:StrategyRule {name: "Rule_Shift+1"}), (doc:Document {name: "GEMINI.md"})
MERGE (r)-[:DEFINED_IN]->(doc)

;
MATCH (r:StrategyRule {name: "Rule_Friction_Cost_30pt"}), (doc:Document {name: "GEMINI.md"})
MERGE (r)-[:DEFINED_IN]->(doc)

;
MATCH (r:StrategyRule {name: "Rule_No_Absolute_Values"}), (doc:Document {name: "GEMINI.md"})
MERGE (r)-[:DEFINED_IN]->(doc)

// 아이디어 → 관련 대상 연결 (RELATES_TO)
;
MERGE (a:Agent {name: "3_Optimizer"})

;
MATCH (i:Idea {name: "Asymmetric_Loss_도입"}), (a:Agent {name: "3_Optimizer"})
MERGE (i)-[:RELATES_TO]->(a)
