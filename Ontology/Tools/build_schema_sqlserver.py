"""
SQL Server Graph DB Schema Builder — 19종 노드 + 26종 엣지 테이블 생성
=========================================================================
OntologyGraph 데이터베이스에 Graph Tables (AS NODE / AS EDGE) 생성.
기존 Neo4j 온톨로지 스키마를 SQL Server Graph Tables로 1:1 매핑합니다.
"""
import pyodbc
import sys

# === SQL Server 연결 설정 ===
CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;"
    "Trusted_Connection=yes;"
)

def execute_sql(conn, sql, ignore_errors=False):
    """단일 SQL 문 실행"""
    try:
        cursor = conn.cursor()
        cursor.execute(sql)
        conn.commit()
        return True
    except Exception as e:
        if not ignore_errors:
            print(f"  ❌ Error: {e}")
        conn.rollback()
        return False

# ======================================================================
# 노드(Node) 테이블 — 19종
# 모든 노드는 name (NVARCHAR) PRIMARY KEY + 공통 속성
# ======================================================================
NODE_TABLES = [
    # A. 소프트웨어 & 코드
    ("ExpertAdvisor",    "version NVARCHAR(50), path NVARCHAR(500)"),
    ("FrameworkModule",  "responsibility NVARCHAR(500), path NVARCHAR(500)"),
    ("Indicator",        "path NVARCHAR(500)"),
    ("Script",           "path NVARCHAR(500)"),
    # B. 데이터 & 성과
    ("DataLayer",        ""),
    ("DataArtifact",     "format NVARCHAR(50), source NVARCHAR(200), path NVARCHAR(500), tier NVARCHAR(50)"),
    ("Feature",          "timeframe NVARCHAR(20), category NVARCHAR(100)"),
    ("MacroSymbol",      "provider NVARCHAR(100)"),
    ("PerformanceMetric","value NVARCHAR(200)"),
    # C. 프로세스 & 거버넌스
    ("Agent",            ""),
    ("Role",             ""),
    ("StrategyRule",     "type NVARCHAR(100), source NVARCHAR(200), created_date NVARCHAR(20)"),
    ("Workflow",         "path NVARCHAR(500)"),
    ("Document",         "path NVARCHAR(500)"),
    # D. 운영 인프라
    ("Environment",      ""),
    ("MonitoringAlert",  ""),
    # E. 지식 및 아이디어
    ("Idea",             "status NVARCHAR(50), created_date NVARCHAR(20), source NVARCHAR(200)"),
    ("Insight",          "created_date NVARCHAR(20)"),
    # F. 프로젝트 로드맵
    ("Phase",            "status NVARCHAR(50), [order] INT"),
    ("Milestone",        "status NVARCHAR(50)"),
]

# ======================================================================
# 엣지(Edge) 테이블 — 26종
# ======================================================================
EDGE_TABLES = [
    # 데이터 흐름
    "PRODUCES", "CONSUMES", "STORED_IN", "FEEDS", "DERIVES_FROM", "CALCULATED_BY",
    # 시스템 의존성
    "INCLUDES", "CALLS", "EVOLVES_FROM", "TRIGGERS",
    # 거버넌스
    "RESTRICTS", "GOVERNS", "DEFINED_IN", "IMPLEMENTS", "SUPERVISES",
    "MONITORED_BY", "GENERATED_BY", "RELATES_TO",
    # 로드맵
    "PRECEDES", "CONTAINS", "ACHIEVED_BY",
    # 전략 수명
    "VALIDATES", "YIELDS", "COMPARES", "EXPIRES", "DEPLOYED_IN", "REPORTED_IN",
    # 추가 (포팅 관계)
    "PORTED_TO",
]


def main():
    print("=" * 60)
    print("  SQL Server Graph DB Schema Builder")
    print("  19종 노드 + 27종 엣지 테이블")
    print("=" * 60)

    # Step 0: 연결
    print("\n[STEP 0] SQL Server 연결...")
    try:
        conn = pyodbc.connect(CONN_STR, autocommit=False)
        print("  ✅ 연결 성공")
    except Exception as e:
        print(f"  ❌ 연결 실패: {e}")
        sys.exit(1)

    # Step 1: 데이터베이스 생성
    print("\n[STEP 1] OntologyGraph 데이터베이스 생성...")
    conn.autocommit = True
    execute_sql(conn, "IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name='OntologyGraph') CREATE DATABASE OntologyGraph", ignore_errors=True)
    conn.autocommit = False

    # OntologyGraph DB로 전환
    conn.close()
    conn = pyodbc.connect(CONN_STR + "DATABASE=OntologyGraph;", autocommit=False)
    print("  ✅ OntologyGraph 데이터베이스 연결")

    # Step 2: 노드 테이블 생성
    print(f"\n[STEP 2] 노드 테이블 생성 ({len(NODE_TABLES)}종)...")
    ok_count = 0
    for table_name, extra_cols in NODE_TABLES:
        cols = [
            "name NVARCHAR(200) NOT NULL",
            "description NVARCHAR(MAX)",
        ]
        if extra_cols:
            cols.append(extra_cols)
        cols.append("created_at DATETIME2")
        cols.append("updated_at DATETIME2")

        cols_str = ",\n    ".join(cols)
        sql = f"""
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='{table_name}')
CREATE TABLE dbo.[{table_name}] (
    {cols_str},
    CONSTRAINT UQ_{table_name}_name UNIQUE (name)
) AS NODE;
"""
        ok = execute_sql(conn, sql, ignore_errors=False)
        if ok:
            ok_count += 1
            print(f"  ✅ {table_name}")
        else:
            # 이미 존재하는 경우
            execute_sql(conn, f"SELECT TOP 1 name FROM [{table_name}]", ignore_errors=True)
            print(f"  ⚠️  {table_name} (이미 존재 가능)")

    conn.commit()

    # Step 3: 엣지 테이블 생성
    print(f"\n[STEP 3] 엣지 테이블 생성 ({len(EDGE_TABLES)}종)...")
    edge_ok = 0
    for edge_name in EDGE_TABLES:
        sql = f"""
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='{edge_name}')
CREATE TABLE dbo.[{edge_name}] (
    description NVARCHAR(MAX),
    created_at DATETIME2
) AS EDGE;
"""
        ok = execute_sql(conn, sql, ignore_errors=False)
        if ok:
            edge_ok += 1
            print(f"  ✅ {edge_name}")
        else:
            print(f"  ⚠️  {edge_name} (이미 존재 가능)")

    conn.commit()

    # Step 4: 검증
    print("\n[STEP 4] 스키마 검증...")
    cursor = conn.cursor()

    cursor.execute("""
        SELECT t.name, CASE WHEN t.is_node = 1 THEN 'NODE' WHEN t.is_edge = 1 THEN 'EDGE' ELSE 'TABLE' END AS graph_type
        FROM sys.tables t
        WHERE t.is_node = 1 OR t.is_edge = 1
        ORDER BY graph_type, t.name
    """)
    rows = cursor.fetchall()
    node_count = sum(1 for r in rows if r[1] == 'NODE')
    edge_count = sum(1 for r in rows if r[1] == 'EDGE')

    print(f"\n{'=' * 60}")
    print(f"  🎉 스키마 생성 완료!")
    print(f"     노드 테이블: {node_count}개")
    print(f"     엣지 테이블: {edge_count}개")
    print(f"{'=' * 60}")

    conn.close()


if __name__ == "__main__":
    main()
