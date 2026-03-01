"""Commit 라벨 스키마 추가 + post-commit 테스트 실행"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from cypher_cli import run_cypher

# 1) Commit 라벨 스키마 등록
print("Commit 라벨 스키마 추가...")
r1 = run_cypher("CREATE CONSTRAINT unique_commit_hash IF NOT EXISTS FOR (c:Commit) REQUIRE c.hash IS UNIQUE")
print(f"  ✅ Uniqueness Constraint: {r1['status']}")

r2 = run_cypher("CREATE INDEX idx_commit_created IF NOT EXISTS FOR (c:Commit) ON (c.created_at)")
print(f"  ✅ created_at Index: {r2['status']}")

r3 = run_cypher("CREATE INDEX idx_commit_short IF NOT EXISTS FOR (c:Commit) ON (c.short_hash)")
print(f"  ✅ short_hash Index: {r3['status']}")
print("스키마 등록 완료!\n")

# 2) git_commit_analyzer.py 직접 실행 (최신 커밋 분석)
print("최신 커밋 분석 테스트...")
import subprocess
result = subprocess.run(
    ["C:\\Python314\\python.exe", os.path.join(os.path.dirname(__file__), "git_commit_analyzer.py")],
    capture_output=True, text=True, encoding="utf-8", errors="replace",
    cwd=os.path.join(os.path.dirname(__file__), "..", "..")
)
print(result.stdout)
if result.stderr:
    print("STDERR:", result.stderr[:200])
