# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "mcp",
#     "pyodbc"
# ]
# ///
import os
import sys
import json
import pyodbc
from mcp.server.fastmcp import FastMCP

# === FastMCP Server Initialization ===
mcp = FastMCP("SQLServer_Raw_MCP")

def get_db_connection():
    """SQL Server DB(OntologyGraph) 연결 객체 반환"""
    conn_str = (
        r"DRIVER={ODBC Driver 17 for SQL Server};"
        r"SERVER=localhost\SQLEXPRESS;"
        r"DATABASE=OntologyGraph;"
        r"Trusted_Connection=yes;"
    )
    return pyodbc.connect(conn_str)

@mcp.tool()
def execute_tsql(query: str) -> str:
    """
    Executes a raw T-SQL query on the MS SQL Server Database (OntologyGraph) and returns the results.
    Use this tool to read from or write to the database using standard ANSI SQL / T-SQL.

    Args:
        query: The T-SQL query string (e.g., "SELECT TOP 10 * FROM Indicator", "EXEC sp_help").
    """
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # 쿼리 실행
        cursor.execute(query)
        
        # INSERT/UPDATE/DELETE 등 결과셋이 없는 쿼리 처리
        if cursor.description is None:
            conn.commit()
            return json.dumps({
                "status": "success",
                "message": f"Query executed successfully. Rows affected: {cursor.rowcount}"
            }, ensure_ascii=False)
            
        # SELECT 등 결과셋이 있는 쿼리 처리
        columns = [column[0] for column in cursor.description]
        results = []
        
        for row in cursor.fetchall():
            # row 값들을 dict로 변환 (날짜 등은 문자열로 변환)
            row_dict = {}
            for i, col in enumerate(columns):
                val = row[i]
                if val is not None and not isinstance(val, (int, float, str, bool)):
                    val = str(val)
                row_dict[col] = val
            results.append(row_dict)
            
        conn.commit()
        return json.dumps({
            "status": "success",
            "row_count": len(results),
            "results": results
        }, ensure_ascii=False, indent=2)
        
    except Exception as e:
        if conn:
            conn.rollback()
        return json.dumps({
            "status": "error",
            "message": str(e)
        }, ensure_ascii=False)
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    mcp.run()
