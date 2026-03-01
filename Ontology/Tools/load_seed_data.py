"""
Seed Data Loader — seed_data.cypher 파일의 모든 쿼리를 Neo4j에 일괄 실행
"""
import sys
import os

# cypher_cli.py 의 run_cypher 함수를 재사용
sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

CYPHER_FILE = os.path.join(os.path.dirname(__file__), "seed_data.cypher")

with open(CYPHER_FILE, "r", encoding="utf-8") as f:
    raw = f.read()

# 세미콜론(;)으로 분리, 주석(//) 제거
queries = []
for block in raw.split(";"):
    lines = []
    for line in block.strip().splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("//"):
            lines.append(line)
    query = "\n".join(lines).strip()
    if query:
        queries.append(query)

print(f"총 {len(queries)}개 Cypher 쿼리 실행 시작...\n")

success = 0
fail = 0
for i, q in enumerate(queries, 1):
    result = run_cypher(q)
    label = q.split("\n")[0][:60]
    if result["status"] == "OK":
        print(f"  ✅ [{i:2d}/{len(queries)}] {label}")
        success += 1
    else:
        print(f"  ❌ [{i:2d}/{len(queries)}] {label}")
        print(f"     Error: {result['errors']}")
        fail += 1

print(f"\n{'='*50}")
print(f"  완료! 성공: {success}개 | 실패: {fail}개")
print(f"{'='*50}")
