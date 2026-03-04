"""Neo4j Aura 접속 테스트 — 비밀번호 인코딩 수정"""
import sys

# pandas 차단
keys_to_remove = [k for k in sys.modules if k == 'pandas' or k.startswith('pandas.')]
for k in keys_to_remove:
    del sys.modules[k]

class PandasBlocker:
    def find_module(self, name, path=None):
        if name == 'pandas' or name.startswith('pandas.'):
            return self
    def load_module(self, name):
        raise ImportError(f"Blocked: {name}")

sys.meta_path.insert(0, PandasBlocker())

from neo4j import GraphDatabase

AURA_URI = "neo4j+s://824847a1.databases.neo4j.io"
AURA_USER = "824847a1"
AURA_PASS = r"O3PnXe8Fhk3VLxG8h8wC98g4AZrY-4C61jaGyXMcz6w"
AURA_DB = "824847a1"

print(f"URI: {AURA_URI}", flush=True)
print(f"User: {AURA_USER}", flush=True)
print(f"Pass length: {len(AURA_PASS)}", flush=True)

driver = GraphDatabase.driver(AURA_URI, auth=(AURA_USER, AURA_PASS))

try:
    driver.verify_connectivity()
    print("Connected to Aura!", flush=True)

    with driver.session() as session:
        result = session.run('RETURN "Hello Aura!" AS msg')
        for record in result:
            print(f"Result: {record['msg']}", flush=True)
    print("Success!", flush=True)
except Exception as e:
    print(f"Error: {e}", flush=True)
finally:
    driver.close()
