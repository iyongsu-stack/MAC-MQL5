"""피처 엔지니어링 실전 원칙 11건 — DB UPSERT"""
import pyodbc

CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;"
    "DATABASE=OntologyGraph;"
    "Trusted_Connection=yes;"
)

conn = pyodbc.connect(CONN_STR, autocommit=True)
cursor = conn.cursor()

TS = "2026-03-04T11:33:00"
SRC = "Docs/TrendTrading Development Strategy/Memo.md"

# Memo.md L257-L276 기반 11대 원칙
RULES = [
    ("FE_Collinearity_Check",
     "상관계수 0.85 이상 피처 쌍은 합치거나 제거. Tie-Breaker: Target(Y) MI가 낮은 쪽 제거",
     "피처엔지니어링", "★★"),
    ("FE_Feature_Selection_SHAP",
     "메가 풀 → SHAP 자동 추출(주력) + Ablation Study(새 지표 검증용 보조)",
     "피처엔지니어링", "★★★"),
    ("FE_Derived_Feature_Types",
     "기본4유형(가속도/Z-Score/비율/Slope) 강제. 레벨값 Δ% 필수. 스케일오실레이터 Passthrough. 조건부: 정규화이격도, 롤링상관계수(SHAP 상위 한정)",
     "피처엔지니어링", "★★★"),
    ("FE_TickVolume_Transform",
     "절대값 금지. MA비율(60/240/1440) 3개 + Z-Score(60/240) 2개 모두 생성. 비율=세션계절성, Z-Score=극단거래량 탐지",
     "피처엔지니어링", "★★"),
    ("FE_Session_Encoding",
     "트리 모델은 One-hot, 딥러닝은 sin/cos 순환 인코딩",
     "피처엔지니어링", "★"),
    ("FE_Long_Short_Split_Training",
     "Stage A: 롱/숏 분리학습(SHAP 희석 방지). Stage B: Walk-Forward 독립검증. Stage C: 단일EA 비대칭 임계치(롱>0.55 숏>0.70). Stage D: 매크로 게이트키퍼 선택",
     "모델구조", "★★★"),
    ("FE_PSI_Monitoring",
     "PSI로 피처 분포 변화 추적. PSI>0.25이면 불안정→재학습 트리거. Walk-Forward 간 피처 중요도 급변 시 과적합 경고",
     "모니터링", "★★"),
    ("FE_Multiple_Testing_BH_FDR",
     "수백 피처 동시 테스트 시 BH-FDR 보정 필수. SHAP 상위도 5-Fold 중 3회 이상 등장하는 것만 채택(순위 안정성)",
     "피처엔지니어링", "★★"),
    ("FE_Outlier_Winsorization",
     "금 시장 꼬리 리스크 극단적. Winsorization 상하 1~5% 클리핑. 제거 아닌 클리핑으로 극단 이벤트 보존. 딥러닝 필수, 트리 선택",
     "피처엔지니어링", "★★"),
    ("FE_Calendar_Event_Features",
     "요일/월/시간 sin/cos 순환 인코딩. 월말 리밸런싱 플래그(is_month_end_5days). FOMC/NFP 전후 48시간 원핫 플래그",
     "피처엔지니어링", "★"),
    ("FE_Temporal_SHAP_Consistency",
     "전체 기간 SHAP 1회가 아닌 분기별 SHAP 비교. 특정 분기에만 중요한 피처는 레짐 의존적→항상 투입 vs 조건부 투입 결정",
     "피처엔지니어링", "★★"),
]

print("=" * 70)
print("  피처 엔지니어링 실전 원칙 11건 — DB UPSERT")
print("=" * 70)

for name, desc, typ, grade in RULES:
    safe_desc = desc.replace("'", "''")
    sql = f"""MERGE [StrategyRule] AS t
USING (SELECT N'{name}' AS [name]) AS s ON t.[name]=s.[name]
WHEN MATCHED THEN UPDATE SET t.[description]=N'{safe_desc}', t.[type]=N'{typ}', t.[grade]=N'{grade}', t.[source_doc]=N'{SRC}', t.[updated_at]=N'{TS}'
WHEN NOT MATCHED THEN INSERT ([name],[description],[type],[grade],[source_doc],[updated_at]) VALUES (N'{name}',N'{safe_desc}',N'{typ}',N'{grade}',N'{SRC}',N'{TS}');"""
    try:
        cursor.execute(sql)
        print(f"  ✅ [{grade:3s}] {name}")
    except Exception as e:
        print(f"  ❌ {name}: {e}")

# DEFINED_IN → Memo.md
print("\n  📎 DEFINED_IN 관계 (→ Memo.md)...")
cursor.execute(f"""MERGE [Document] AS t USING (SELECT N'Memo.md' AS [name]) AS s ON t.[name]=s.[name]
WHEN MATCHED THEN UPDATE SET t.[path]=N'{SRC}'
WHEN NOT MATCHED THEN INSERT ([name],[path]) VALUES (N'Memo.md',N'{SRC}');""")
for name, _, _, _ in RULES:
    try:
        cursor.execute(f"""IF NOT EXISTS (SELECT 1 FROM [DEFINED_IN] e, [StrategyRule] r, [Document] d WHERE MATCH(r-(e)->d) AND r.name=N'{name}' AND d.name=N'Memo.md')
INSERT INTO [DEFINED_IN] ($from_id, $to_id) SELECT r.$node_id, d.$node_id FROM [StrategyRule] r, [Document] d WHERE r.name=N'{name}' AND d.name=N'Memo.md';""")
    except:
        pass
print("  ✅ 완료")

# 전체 현황
print("\n📊 전체 StrategyRule:")
cursor.execute("SELECT [name],[type],[grade] FROM [StrategyRule] ORDER BY [type], [grade] DESC, [name]")
for r in cursor.fetchall():
    print(f"  [{r[2] or '':3s}] [{r[1] or '':14s}] {r[0]}")
cursor.execute("SELECT COUNT(*) FROM [StrategyRule]")
print(f"\n  합계: {cursor.fetchone()[0]}건")
conn.close()
