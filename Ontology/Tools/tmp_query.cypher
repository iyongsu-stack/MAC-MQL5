MERGE (w:Workflow {name: 'data-build.md'})
MERGE (r:StrategyRule {name: 'Rule_No_Absolute_Values'})
MERGE (a:Action {id: 'build_tech_features_derived_20260304'})
SET a.type = 'Data_Pipeline_Execution',
    a.title = '기술 지표 파생 데이터 재빌드 및 규칙 검증 완료',
    a.description = 'tech_features.parquet (63컬럼, 7.42M행) 기반 파생 피처 빌드 완료. P1 결측봉 사전 검증(45,574개 결측봉 탐지), P2 세션 갭 플래그(is_session_start, gap_hours) 적용, TickVolume MA비율 및 Z-Score 병행. 총 104개 피처, 2.8GB 데이터 생성 완료. 14개 절대값 원본 데이터 모두 DROP 됨을 이중 검증 통과(PASS).',
    a.date = '2026-03-04'
MERGE (a)-[:EXECUTED]->(w)
MERGE (a)-[:VALIDATED]->(r)
RETURN a.title, a.description, a.date
