import sys
import os
import json
from neo4j import GraphDatabase
import traceback

# === Neo4j Connection Configuration ===
# You can set these via environment variables or replace them with actual values.
# By default, Neo4j Desktop uses bolt://localhost:7687 and username 'neo4j'.
URI = os.getenv("NEO4J_URI", "bolt://127.0.0.1:7687")
USER = os.getenv("NEO4J_USER", "neo4j")
# Default password is set to 'password', please ensure the user updates this 
# or sets the NEO4J_PASSWORD environment variable.
PASSWORD = os.getenv("NEO4J_PASSWORD", "KIM10507")

def run_cypher(query, parameters=None):
    """
    Executes a Cypher query against the Neo4j database and returns the result as JSON.
    """
    try:
        # Initialize the Neo4j driver
        driver = GraphDatabase.driver(URI, auth=(USER, PASSWORD))
        
        # Verify connectivity
        driver.verify_connectivity()
        
        with driver.session() as session:
            result = session.run(query, parameters)
            # Fetch all records and convert them to a list of dicts
            records = [record.data() for record in result]
            
            # Print the result as formatted JSON to standard output
            print(json.dumps(records, ensure_ascii=False, indent=2))
            
        driver.close()
    except Exception as e:
        print(json.dumps({"error": str(e), "traceback": traceback.format_exc()}), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python execute_cypher.py \"<CYPHER_QUERY>\"", file=sys.stderr)
        sys.exit(1)
        
    query = sys.argv[1]
    run_cypher(query)
