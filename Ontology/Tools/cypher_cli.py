"""
Cypher CLI — AI가 대화 중 Neo4j에 즉시 쿼리를 실행하기 위한 경량 CLI
=====================================================================
Usage:
    python cypher_cli.py "MERGE (r:StrategyRule {name:'Rule_Test'}) RETURN r.name"
    python cypher_cli.py --file queries.cypher

내부적으로 Neo4j HTTP API(7474)를 사용하므로 Bolt 드라이버 행잉 문제가 없습니다.
"""

import sys
import os
import json
import base64
import urllib.request

# === Neo4j HTTP API Configuration ===
NEO4J_HTTP_URI = os.getenv("NEO4J_HTTP_URI", "http://127.0.0.1:7474/db/neo4j/tx/commit")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "KIM10507")


def run_cypher(query: str, parameters: dict = None) -> dict:
    """Execute a Cypher query via Neo4j HTTP Transactional API."""
    auth_str = f"{NEO4J_USER}:{NEO4J_PASSWORD}".encode("utf-8")
    headers = {
        "Authorization": "Basic " + base64.b64encode(auth_str).decode("utf-8"),
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    payload = {
        "statements": [{
            "statement": query,
            "parameters": parameters or {}
        }]
    }
    req = urllib.request.Request(
        NEO4J_HTTP_URI,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            resp_data = json.loads(response.read().decode("utf-8"))
            if resp_data.get("errors"):
                return {"status": "ERROR", "errors": resp_data["errors"]}
            results = resp_data.get("results", [])
            formatted = []
            if results:
                columns = results[0].get("columns", [])
                for row_data in results[0].get("data", []):
                    row_values = row_data.get("row", [])
                    formatted.append(dict(zip(columns, row_values)))
            return {"status": "OK", "results": formatted}
    except urllib.error.URLError as e:
        return {"status": "ERROR", "errors": [{"message": f"Connection failed: {e}"}]}


def run_multi_cypher(queries: list) -> list:
    """Execute multiple Cypher statements in a single HTTP transaction."""
    auth_str = f"{NEO4J_USER}:{NEO4J_PASSWORD}".encode("utf-8")
    headers = {
        "Authorization": "Basic " + base64.b64encode(auth_str).decode("utf-8"),
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    statements = [{"statement": q} for q in queries if q.strip()]
    payload = {"statements": statements}
    req = urllib.request.Request(
        NEO4J_HTTP_URI,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            resp_data = json.loads(response.read().decode("utf-8"))
            if resp_data.get("errors"):
                return [{"status": "ERROR", "errors": resp_data["errors"]}]
            all_results = []
            for result in resp_data.get("results", []):
                columns = result.get("columns", [])
                formatted = []
                for row_data in result.get("data", []):
                    row_values = row_data.get("row", [])
                    formatted.append(dict(zip(columns, row_values)))
                all_results.append({"status": "OK", "results": formatted})
            return all_results
    except urllib.error.URLError as e:
        return [{"status": "ERROR", "errors": [{"message": f"Connection failed: {e}"}]}]


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python cypher_cli.py \"<CYPHER_QUERY>\"")
        print("       python cypher_cli.py --file <FILE.cypher>")
        sys.exit(1)

    if sys.argv[1] == "--file":
        filepath = sys.argv[2]
        with open(filepath, "r", encoding="utf-8") as f:
            query = f.read()
    else:
        query = sys.argv[1]

    result = run_cypher(query)
    print(json.dumps(result, ensure_ascii=False, indent=2))
