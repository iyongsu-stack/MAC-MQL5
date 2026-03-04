"""
Cypher CLI — SQL Server Graph Tables 용 Cypher→T-SQL 자동 변환 CLI
====================================================================
기존 Neo4j Cypher 쿼리를 SQL Server Graph Tables T-SQL로 자동 변환합니다.
기존 insert_*.py 스크립트가 수정 없이 동작하도록 호환 레이어를 제공합니다.

Usage:
    python cypher_cli.py "MERGE (r:StrategyRule {name:'Test'}) RETURN r.name"
    python cypher_cli.py --file queries.cypher
"""
import sys
import os
import json
import re
import pyodbc

# === SQL Server 연결 설정 ===
CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;"
    "DATABASE=OntologyGraph;"
    "Trusted_Connection=yes;"
)

# ======================================================================
# Cypher → T-SQL 변환 엔진
# ======================================================================

def _parse_props(props_str):
    """Cypher 속성 문자열 {key: 'val', key2: datetime('...')} → dict"""
    result = {}
    if not props_str:
        return result
    # 1단계: datetime('...') 또는 datetime("...") 먼저 추출 후 원본에서 제거
    cleaned = props_str
    for m in re.finditer(r"(\w+)\s*:\s*datetime\(\s*['\"]([^'\"]*)['\"]?\s*\)", props_str):
        result[m.group(1)] = m.group(2)
        cleaned = cleaned.replace(m.group(0), "")  # 원본에서 제거
    # 2단계: 나머지에서 key: 'value' / key: "value" / key: 123 파싱
    for m in re.finditer(r"(\w+)\s*:\s*(?:'([^']*)'|\"([^\"]*)\"|(\d+(?:\.\d+)?))", cleaned):
        key = m.group(1)
        if key in result:
            continue
        val = m.group(2) if m.group(2) is not None else (m.group(3) if m.group(3) is not None else m.group(4))
        result[key] = val
    return result


def _parse_set_clause(set_str):
    """SET n.prop = 'value', n.prop2 = datetime("...") → dict"""
    result = {}
    if not set_str:
        return result
    # n.prop = 'value' 또는 n.prop = "value" 또는 n.prop = datetime("...") 또는 n.prop = 123
    for m in re.finditer(
        r"(\w+)\.(\w+)\s*=\s*(?:datetime\(['\"]([^'\"]*)['\"]?\)|'([^']*)'|\"([^\"]*)\"|(\d+(?:\.\d+)?))",
        set_str
    ):
        alias = m.group(1)
        key = m.group(2)
        if m.group(3) is not None:
            val = m.group(3)  # datetime → string
        elif m.group(4) is not None:
            val = m.group(4)
        elif m.group(5) is not None:
            val = m.group(5)
        else:
            val = m.group(6)
        result[key] = val
    return result


def _sql_val(val):
    """Python 값을 SQL 리터럴로 변환"""
    if val is None:
        return "NULL"
    try:
        int(val)
        return str(val)
    except (ValueError, TypeError):
        pass
    try:
        float(val)
        return str(val)
    except (ValueError, TypeError):
        pass
    return f"N'{val}'"


def _convert_merge_node(cypher):
    """MERGE (alias:Label {props}) SET ... → MERGE (T-SQL)"""
    # MERGE (alias:Label {key: 'val'}) 패턴
    m = re.match(
        r"\s*MERGE\s+\((\w+):(\w+)\s*\{([^}]+)\}\)\s*(SET\s+.+)?",
        cypher, re.IGNORECASE | re.DOTALL
    )
    if not m:
        return None

    alias = m.group(1)
    label = m.group(2)
    props = _parse_props(m.group(3))
    set_clause = _parse_set_clause(m.group(4)) if m.group(4) else {}

    # 식별 키 (보통 name)
    id_key = list(props.keys())[0] if props else "name"
    id_val = props.get(id_key, "")

    # 모든 속성 합치기 (props + set)
    all_props = {**props, **set_clause}

    # 컬럼/값 리스트 (테이블에 존재하는 컬럼만)
    cols = list(all_props.keys())
    vals = [_sql_val(all_props[c]) for c in cols]

    # MERGE INTO (T-SQL MERGE)
    # UPDATE 대상: SET 절의 속성만
    update_cols = list(set_clause.keys()) if set_clause else [c for c in cols if c != id_key]

    update_set = ", ".join([f"target.[{c}] = {_sql_val(all_props[c])}" for c in update_cols]) if update_cols else f"target.[{id_key}] = target.[{id_key}]"
    insert_cols = ", ".join([f"[{c}]" for c in cols])
    insert_vals = ", ".join(vals)

    sql = f"""MERGE [{label}] AS target
USING (SELECT {_sql_val(id_val)} AS [{id_key}]) AS source
ON target.[{id_key}] = source.[{id_key}]
WHEN MATCHED THEN UPDATE SET {update_set}
WHEN NOT MATCHED THEN INSERT ({insert_cols}) VALUES ({insert_vals});"""
    return sql


def _convert_merge_edge(cypher):
    """
    MATCH (a:Label {name: 'X'})
    MATCH (b:Label {name: 'Y'})
    MERGE (a)-[:REL {props}]->(b)
    """
    # MATCH (a:L1 {name: 'X'}) MATCH (b:L2 {name: 'Y'}) MERGE (a)-[:REL ...]->(b)
    pattern = (
        r"\s*MATCH\s+\((\w+):(\w+)\s*\{([^}]+)\}\)\s*"
        r"MATCH\s+\((\w+):(\w+)\s*\{([^}]+)\}\)\s*"
        r"MERGE\s+\(\1\)-\[:(\w+)(?:\s*\{([^}]*)\})?\]\s*->\s*\(\4\)"
    )
    m = re.match(pattern, cypher, re.IGNORECASE | re.DOTALL)
    if not m:
        return None

    a_alias, a_label = m.group(1), m.group(2)
    a_props = _parse_props(m.group(3))
    b_alias, b_label = m.group(4), m.group(5)
    b_props = _parse_props(m.group(6))
    edge_type = m.group(7)
    edge_props = _parse_props(m.group(8)) if m.group(8) else {}

    a_key = list(a_props.keys())[0]
    a_val = a_props[a_key]
    b_key = list(b_props.keys())[0]
    b_val = b_props[b_key]

    # 엣지 속성
    edge_cols = ""
    edge_vals = ""
    if edge_props:
        edge_cols = ", " + ", ".join([f"[{k}]" for k in edge_props.keys()])
        edge_vals = ", " + ", ".join([_sql_val(v) for v in edge_props.values()])

    sql = f"""IF NOT EXISTS (
    SELECT 1 FROM [{edge_type}] e, [{a_label}] a, [{b_label}] b
    WHERE MATCH(a-(e)->b) AND a.[{a_key}] = {_sql_val(a_val)} AND b.[{b_key}] = {_sql_val(b_val)}
)
INSERT INTO [{edge_type}] ($from_id, $to_id{edge_cols})
SELECT a.$node_id, b.$node_id{edge_vals}
FROM [{a_label}] a, [{b_label}] b
WHERE a.[{a_key}] = {_sql_val(a_val)} AND b.[{b_key}] = {_sql_val(b_val)};"""
    return sql


def _convert_match_return(cypher):
    """
    MATCH (n:Label) RETURN ...  또는
    MATCH (n) WHERE ... RETURN ...
    """
    # 간단한 전체 노드 조회: MATCH (n) RETURN labels(n)[0], count(n)
    m = re.match(
        r"\s*MATCH\s+\((\w+)\)\s+RETURN\s+(.+)",
        cypher, re.IGNORECASE | re.DOTALL
    )
    if m:
        ret_clause = m.group(2).strip()
        # labels(n)[0] AS Label, count(n) AS Count 패턴
        if "labels(" in ret_clause and "count(" in ret_clause:
            return """SELECT t.name AS Label, SUM(p.rows) AS Count
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE t.is_node = 1
GROUP BY t.name
ORDER BY Count DESC;"""

    # MATCH (n:Label) WHERE ... RETURN ...
    m = re.match(
        r"\s*MATCH\s+\((\w+):(\w+)\s*(?:\{([^}]*)\})?\)\s*"
        r"(?:WHERE\s+(.+?))?\s*"
        r"(?:RETURN|RETURN\s+)(.+?)(?:\s+ORDER\s+BY\s+(.+?))?(?:\s+LIMIT\s+(\d+))?\s*$",
        cypher, re.IGNORECASE | re.DOTALL
    )
    if m:
        alias = m.group(1)
        label = m.group(2)
        props = _parse_props(m.group(3)) if m.group(3) else {}
        where = m.group(4)
        ret = m.group(5).strip()
        order = m.group(6)
        limit = m.group(7)

        # SELECT 변환: n.name → [name]
        select_parts = []
        for part in ret.split(","):
            part = part.strip()
            col_m = re.match(r"(\w+)\.(\w+)(?:\s+AS\s+(\w+))?", part, re.IGNORECASE)
            if col_m:
                col = col_m.group(2)
                alias_name = col_m.group(3) or col
                select_parts.append(f"[{col}] AS [{alias_name}]")
            else:
                select_parts.append(part)

        top = f"TOP {limit} " if limit else ""
        select = ", ".join(select_parts)

        # WHERE 절
        where_parts = []
        if props:
            for k, v in props.items():
                where_parts.append(f"[{k}] = {_sql_val(v)}")
        if where:
            # n.name CONTAINS 'keyword' → [name] LIKE N'%keyword%'
            w = re.sub(r"(\w+)\.(\w+)\s+CONTAINS\s+'([^']*)'", r"[\2] LIKE N'%\3%'", where)
            w = re.sub(r"(\w+)\.(\w+)", r"[\2]", w)
            where_parts.append(w)

        where_sql = f" WHERE {' AND '.join(where_parts)}" if where_parts else ""
        order_sql = f" ORDER BY {re.sub(r'(\w+)\.(\w+)', r'[\\2]', order)}" if order else ""

        return f"SELECT {top}{select} FROM [{label}]{where_sql}{order_sql};"

    return None


def _convert_match_path(cypher):
    """
    MATCH path = (start)-[*1..3]->(end)
    WHERE start.name = '대상_노드_이름'
    RETURN ... — 리니지 추적 등 복잡한 패턴
    → 지원 불가 → 원본 쿼리 반환 (사용자에게 안내)
    """
    if re.search(r"\[\*\d+\.\.\d+\]", cypher):
        return None  # 복잡한 경로 탐색은 미지원
    return None


def cypher_to_tsql(cypher):
    """Cypher 쿼리를 T-SQL로 변환 (메인 래퍼)"""
    cypher = cypher.strip().rstrip(";")

    # SHOW 명령어
    if re.match(r"\s*SHOW\s+CONSTRAINTS", cypher, re.IGNORECASE):
        return "SELECT name, type_desc FROM sys.key_constraints WHERE type_desc = 'UNIQUE_CONSTRAINT';"
    if re.match(r"\s*SHOW\s+INDEXES", cypher, re.IGNORECASE):
        return "SELECT name, type_desc FROM sys.indexes WHERE name IS NOT NULL AND name != '' ORDER BY name;"

    # MERGE 노드
    result = _convert_merge_node(cypher)
    if result:
        return result

    # MERGE 엣지 (MATCH...MATCH...MERGE)
    result = _convert_merge_edge(cypher)
    if result:
        return result

    # MATCH...RETURN
    result = _convert_match_return(cypher)
    if result:
        return result

    # 변환 불가 → 원본 반환 (직접 T-SQL일 수 있음)
    return cypher


# ======================================================================
# 실행 엔진
# ======================================================================

def run_cypher(query, parameters=None):
    """Cypher 쿼리를 T-SQL로 변환 후 실행 (호환 API)"""
    try:
        tsql = cypher_to_tsql(query)
        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()
        cursor.execute(tsql)

        # SELECT 쿼리인 경우 결과 반환
        if cursor.description:
            columns = [desc[0] for desc in cursor.description]
            records = [dict(zip(columns, row)) for row in cursor.fetchall()]
            conn.close()
            return {"status": "OK", "results": records, "tsql": tsql}
        else:
            conn.commit()
            conn.close()
            return {"status": "OK", "results": [], "tsql": tsql}
    except Exception as e:
        return {"status": "ERROR", "errors": [{"message": str(e), "tsql": tsql if 'tsql' in dir() else query}]}


def run_multi_cypher(queries):
    """여러 Cypher 문 순차 실행"""
    return [run_cypher(q.strip()) for q in queries if q.strip()]


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print('Usage: python cypher_cli.py "<QUERY>"')
        print('       python cypher_cli.py --file <FILE.cypher>')
        sys.exit(1)

    if sys.argv[1] == "--file":
        with open(sys.argv[2], "r", encoding="utf-8") as f:
            query = f.read()
    else:
        query = sys.argv[1]

    result = run_cypher(query)
    print(json.dumps(result, ensure_ascii=False, indent=2, default=str), flush=True)
