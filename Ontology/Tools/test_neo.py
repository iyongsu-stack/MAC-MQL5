from neo4j import GraphDatabase
import traceback

URI = "neo4j://127.0.0.1:7687"
USER = "neo4j"
PASSWORD = "KIM10507&&"

try:
    print('Testing connection...')
    driver = GraphDatabase.driver(URI, auth=(USER, PASSWORD), max_connection_lifetime=5)
    driver.verify_connectivity()
    print('Connection successful!')
    driver.close()
except Exception as e:
    print('Connection failed:', str(e))
    traceback.print_exc()
