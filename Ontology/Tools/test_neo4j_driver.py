import socket
import sys

# pandas 의존성 우회를 위한 더 강력한 dummy 모듈
class DummyPandas:
    def __getattr__(self, name):
        return None
    
sys.modules['pandas'] = DummyPandas()

print("1. import neo4j")
try:
    from neo4j import GraphDatabase
except Exception as e:
    print(f"Error importing neo4j: {e}")
    sys.exit(1)

print("2. create driver")
try:
    driver = GraphDatabase.driver('bolt://127.0.0.1:7687', auth=('neo4j', 'KIM10507'))
    print("3. verify connectivity")
    driver.verify_connectivity()
    print("4. driver connected successfully!")
    
    with driver.session() as session:
        result = session.run("RETURN 'Hello from Bolt' AS msg")
        for record in result:
            print("Query Result:", record["msg"])
            
    driver.close()
    print("5. Done")
except Exception as e:
    print(f"Driver Error: {e}")
