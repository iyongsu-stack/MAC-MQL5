import os
import sys
import json
import base64
import urllib.request
from mcp.server.fastmcp import FastMCP

# === FastMCP Server Initialization ===
mcp = FastMCP("Neo4j_HTTP_MCP")

# === Neo4j HTTP API Configuration ===
# Default port for Neo4j HTTP API is 7474
NEO4J_HTTP_URI = os.getenv("NEO4J_HTTP_URI", "http://127.0.0.1:7474/db/neo4j/tx/commit")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "KIM10507")

def _run_http_query(cypher_query: str, parameters: dict = None) -> list:
    """Internal helper to execute a Cypher query using Neo4j's transactional HTTP API."""
    auth_str = f"{NEO4J_USER}:{NEO4J_PASSWORD}".encode("utf-8")
    headers = {
        "Authorization": "Basic " + base64.b64encode(auth_str).decode("utf-8"),
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    
    payload = {
        "statements": [{
            "statement": cypher_query,
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
            
            # Neo4j HTTP API returns errors in the payload
            if "errors" in resp_data and resp_data["errors"]:
                error_msg = json.dumps(resp_data["errors"])
                raise Exception(f"Neo4j Cypher Error: {error_msg}")
            
            # Map columns to rows for human/AI readable JSON
            results = resp_data.get("results", [])
            formatted_output = []
            if results:
                columns = results[0].get("columns", [])
                for row_data in results[0].get("data", []):
                    row_values = row_data.get("row", [])
                    # create dictionary associating column names with row values
                    formatted_output.append(dict(zip(columns, row_values)))
            return formatted_output
            
    except urllib.error.URLError as e:
        raise Exception(f"Network error connecting to Neo4j HTTP API (7474): {str(e)}")

@mcp.tool()
def execute_cypher(query: str) -> str:
    """
    Executes a Cypher query on the Neo4j Graph Database and returns the results.
    Use this tool to read from or write to the project's ontology knowledge graph.
    
    Args:
        query: The correct and valid Cypher query string (e.g., "MATCH (n) RETURN n").
    """
    try:
        res = _run_http_query(query)
        # return as formatted JSON string so the AI can easily parse the exact fields
        return json.dumps(res, ensure_ascii=False, indent=2)
    except Exception as e:
        return json.dumps({"error": str(e)}, ensure_ascii=False)

if __name__ == "__main__":
    # Start the FastMCP stdio server protocol when executed
    mcp.run()
