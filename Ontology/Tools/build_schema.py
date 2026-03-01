"""
Neo4j Schema Builder — ontology_graph_db.md 기반 19종 엔티티 스키마 생성
===========================================================================
이 스크립트는 MCP 서버를 경유하지 않고 직접 HTTP API를 호출하여
Neo4j에 Uniqueness Constraint + Index를 일괄 등록합니다.
"""

import json
import base64
import urllib.request

# === Neo4j HTTP API Configuration ===
NEO4J_HTTP_URI = "http://127.0.0.1:7474/db/neo4j/tx/commit"
NEO4J_USER = "neo4j"
NEO4J_PASSWORD = "KIM10507"

def run_cypher(query: str):
    """Execute a single Cypher statement via Neo4j HTTP API."""
    auth_str = f"{NEO4J_USER}:{NEO4J_PASSWORD}".encode("utf-8")
    headers = {
        "Authorization": "Basic " + base64.b64encode(auth_str).decode("utf-8"),
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    payload = {"statements": [{"statement": query}]}
    req = urllib.request.Request(
        NEO4J_HTTP_URI,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers
    )
    with urllib.request.urlopen(req, timeout=10) as response:
        resp_data = json.loads(response.read().decode("utf-8"))
        if resp_data.get("errors"):
            return {"status": "ERROR", "query": query, "errors": resp_data["errors"]}
        return {"status": "OK", "query": query}


# ======================================================================
# 1. 19종 엔티티에 대한 Uniqueness Constraint 생성
#    - 모든 노드는 `name` 속성으로 고유하게 식별됩니다.
# ======================================================================

ENTITY_LABELS = [
    # A. 소프트웨어 & 코드
    "ExpertAdvisor",
    "FrameworkModule",
    "Indicator",
    "Script",
    # B. 데이터 & 성과
    "DataLayer",
    "DataArtifact",
    "Feature",
    "MacroSymbol",
    "PerformanceMetric",
    # C. 프로세스 & 거버넌스
    "Agent",
    "Role",
    "StrategyRule",
    "Workflow",
    "Document",
    # D. 운영 인프라
    "Environment",
    "MonitoringAlert",
    # E. 지식 및 아이디어
    "Idea",
    "Insight",
    # F. 프로젝트 로드맵
    "Phase",
    "Milestone",
]

print("=" * 60)
print("  Neo4j Schema Builder — 온톨로지 기반 19종 엔티티")
print("=" * 60)

# Step 1: Create Uniqueness Constraints
print("\n[STEP 1] Uniqueness Constraint 생성...")
for label in ENTITY_LABELS:
    constraint_name = f"unique_{label.lower()}_name"
    query = f"CREATE CONSTRAINT {constraint_name} IF NOT EXISTS FOR (n:{label}) REQUIRE n.name IS UNIQUE"
    result = run_cypher(query)
    status = "✅" if result["status"] == "OK" else "❌"
    print(f"  {status} {label:25s} → {constraint_name}")
    if result["status"] == "ERROR":
        print(f"     Error: {result['errors']}")

# Step 2: Create composite indexes for frequently queried properties
print("\n[STEP 2] 추가 인덱스 생성...")

INDEXES = [
    # Phase, Milestone 진행 상태 검색용
    ("idx_phase_status", "Phase", "status"),
    ("idx_milestone_status", "Milestone", "status"),
    # DataArtifact 계층 검색용
    ("idx_dataartifact_tier", "DataArtifact", "tier"),
    # Feature 카테고리 검색용
    ("idx_feature_category", "Feature", "category"),
    # StrategyRule 유형 검색용
    ("idx_strategyrule_type", "StrategyRule", "type"),
    # Idea/Insight 날짜 검색용
    ("idx_idea_date", "Idea", "created_date"),
    ("idx_insight_date", "Insight", "created_date"),
]

for idx_name, label, prop in INDEXES:
    query = f"CREATE INDEX {idx_name} IF NOT EXISTS FOR (n:{label}) ON (n.{prop})"
    result = run_cypher(query)
    status = "✅" if result["status"] == "OK" else "❌"
    print(f"  {status} {label}.{prop:20s} → {idx_name}")
    if result["status"] == "ERROR":
        print(f"     Error: {result['errors']}")

# Step 3: Verify schema
print("\n[STEP 3] 스키마 검증...")
result_raw = run_cypher("SHOW CONSTRAINTS")
print("  Constraints 쿼리 실행:", result_raw["status"])

result_raw2 = run_cypher("SHOW INDEXES")
print("  Indexes 쿼리 실행:", result_raw2["status"])

# Get actual counts
auth_str = f"{NEO4J_USER}:{NEO4J_PASSWORD}".encode("utf-8")
headers = {
    "Authorization": "Basic " + base64.b64encode(auth_str).decode("utf-8"),
    "Content-Type": "application/json",
    "Accept": "application/json"
}
payload = {"statements": [
    {"statement": "SHOW CONSTRAINTS YIELD name RETURN count(*) AS cnt"},
    {"statement": "SHOW INDEXES YIELD name RETURN count(*) AS cnt"}
]}
req = urllib.request.Request(
    NEO4J_HTTP_URI,
    data=json.dumps(payload).encode("utf-8"),
    headers=headers
)
with urllib.request.urlopen(req, timeout=10) as response:
    resp = json.loads(response.read().decode("utf-8"))
    constraints_count = resp["results"][0]["data"][0]["row"][0] if resp["results"][0]["data"] else 0
    indexes_count = resp["results"][1]["data"][0]["row"][0] if resp["results"][1]["data"] else 0

print(f"\n{'=' * 60}")
print(f"  🎉 스키마 생성 완료!")
print(f"     Constraints: {constraints_count}개")
print(f"     Indexes:     {indexes_count}개 (Constraint 자동 생성 포함)")
print(f"{'=' * 60}")
