"""
Session Memory 스키마 등록
===========================
Session, FileState, Decision 노드의 Uniqueness Constraint + Index를 SQL Server Graph DB에 등록.
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

def setup():
    steps = [
        # Session 노드
        ("Session unique id",
         "CREATE CONSTRAINT unique_session_id IF NOT EXISTS FOR (s:Session) REQUIRE s.id IS UNIQUE"),
        ("Session date index",
         "CREATE INDEX idx_session_date IF NOT EXISTS FOR (s:Session) ON (s.date)"),

        # FileState 노드
        ("FileState unique path",
         "CREATE CONSTRAINT unique_filestate_path IF NOT EXISTS FOR (f:FileState) REQUIRE f.path IS UNIQUE"),
        ("FileState updated_at index",
         "CREATE INDEX idx_filestate_updated IF NOT EXISTS FOR (f:FileState) ON (f.updated_at)"),

        # Decision 노드
        ("Decision unique id",
         "CREATE CONSTRAINT unique_decision_id IF NOT EXISTS FOR (d:Decision) REQUIRE d.id IS UNIQUE"),
        ("Decision created_at index",
         "CREATE INDEX idx_decision_created IF NOT EXISTS FOR (d:Decision) ON (d.created_at)"),
    ]

    print("[ Session Memory 스키마 등록 ]")
    for name, cypher in steps:
        try:
            r = run_cypher(cypher)
            status = r.get("status", "unknown")
            print(f"  ✅ {name}: {status}")
        except Exception as e:
            print(f"  ⚠️  {name}: {e}")
    print("\n스키마 등록 완료!")

if __name__ == "__main__":
    setup()
