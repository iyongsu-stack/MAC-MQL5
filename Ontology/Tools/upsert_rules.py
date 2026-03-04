"""StrategyRule 테이블 컬럼 추가 + 7대 원칙 UPSERT (단일 연결)"""
import pyodbc

CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;"
    "DATABASE=OntologyGraph;"
    "Trusted_Connection=yes;"
)

conn = pyodbc.connect(CONN_STR, autocommit=True)
cursor = conn.cursor()

# 1. 컬럼 추가 (이미 존재하면 무시)
for col in ["grade NVARCHAR(20)", "source_doc NVARCHAR(500)"]:
    col_name = col.split()[0]
    try:
        cursor.execute(f"SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='StrategyRule' AND COLUMN_NAME='{col_name}'")
        if not cursor.fetchone():
            cursor.execute(f"ALTER TABLE [StrategyRule] ADD [{col_name}] {col.split(' ',1)[1]}")
            print(f"  ✅ 컬럼 추가: {col_name}")
        else:
            print(f"  ✅ 컬럼 존재: {col_name}")
    except Exception as e:
        print(f"  ❌ {col_name}: {e}")

TS = "2026-03-04T11:24:00"

RULES = [
    ("Rule_Shift+1",
     "상위 TF(H1등)이나 매크로 데이터를 M1 기준에 병합 시 반드시 직전 완성봉(Shift+1)만 사용",
     "핵심원칙", "★★★"),
    ("Rule_No_Absolute_Values",
     "원본 절대값 투입 금지. 기본4유형(가속도/Z-Score/비율/Slope) 강제변환. 스케일오실레이터 Passthrough 허용",
     "핵심원칙", "★★★"),
    ("Rule_Friction_Cost_30pt",
     "모든 수익/실패 판단 시 XAUUSD 마찰비용 30포인트를 매 거래마다 강제 차감",
     "핵심원칙", "★★"),
    ("TrailingStop_Exit_Only",
     "라벨링/모델은 진입만 판단. 청산은 고정TP 없이 TrailingStopVx가 전담",
     "전략구조", "★★"),
    ("Rule_Warmup_Dropna",
     "2계층 macro_features 첫 구간은 NaN 포함. 최종 병합 시 dropna 필수. 2계층 저장 시 dropna 금지",
     "데이터무결성", "★"),
    ("Rule_ffill_Only_No_bfill",
     "매크로 피처 NaN은 ffill로만 처리. bfill은 미래참조이므로 절대 금지",
     "데이터무결성", "★"),
    ("Rule_Winsorization",
     "극단 이상치는 삭제 대신 상하위 1~5% 클리핑. 딥러닝 필수, 트리모델 선택",
     "데이터무결성", "★"),
]

SRC = "Docs/TrendTrading Development Strategy/Memo.md"

print("\n  원칙 7건 UPSERT:")
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
print("\n  DEFINED_IN 관계:")
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

# 최종 조회
print("\n📊 전체 StrategyRule:")
cursor.execute("SELECT [name],[type],[grade] FROM [StrategyRule] ORDER BY [grade] DESC, [name]")
for r in cursor.fetchall():
    print(f"  [{r[2] or '':3s}] [{r[1] or '':10s}] {r[0]}")

conn.close()
