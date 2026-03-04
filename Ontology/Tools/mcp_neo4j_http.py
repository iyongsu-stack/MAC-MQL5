"""
MCP SQL Server Graph DB Server — SQL Server Graph Tables 연결
=============================================================
FastMCP 서버로 AI가 Cypher 쿼리를 실행할 수 있는 execute_cypher 도구 제공.
내부적으로 cypher_cli.py의 Cypher→T-SQL 변환 레이어를 사용합니다.
"""
import os
import sys
import json

sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher
from mcp.server.fastmcp import FastMCP

# === FastMCP Server Initialization ===
mcp = FastMCP("SQLServer_Graph_MCP")


@mcp.tool()
def execute_cypher(query: str) -> str:
    """
    Executes a Cypher query on the SQL Server Graph Database and returns the results.
    The Cypher query is automatically translated to T-SQL internally.
    Use this tool to read from or write to the project's ontology knowledge graph.

    Args:
        query: The Cypher query string (e.g., "MATCH (n:Script) RETURN n.name").
    """
    try:
        res = run_cypher(query)
        return json.dumps(res, ensure_ascii=False, indent=2, default=str)
    except Exception as e:
        return json.dumps({"error": str(e)}, ensure_ascii=False)


if __name__ == "__main__":
    mcp.run()
