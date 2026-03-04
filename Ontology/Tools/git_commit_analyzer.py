"""
Git Commit → Graph DB 자동 분석기
================================
post-commit Hook에서 호출되어, 변경 파일을 분석하고 SQL Server Graph DB에 저장합니다.
- 파일 경로 기반 엔티티 분류 (FrameworkModule, Indicator, Script 등)
- diff에서 파라미터 변경 감지 (숫자 변경 추적)
- include/import 추가/삭제 감지 (의존성 변화)
- 함수 추가/삭제 감지
"""

import subprocess
import sys
import os
import re
from datetime import datetime, timezone, timedelta

sys.path.insert(0, os.path.dirname(__file__))
from cypher_cli import run_cypher

KST = timezone(timedelta(hours=9))

# ======================================
# 1. Git 정보 수집
# ======================================

def git_cmd(args, cwd=None):
    """Run a git command and return stdout."""
    try:
        result = subprocess.run(
            ["git"] + args,
            capture_output=True, text=True, encoding="utf-8",
            cwd=cwd or os.getcwd()
        )
        return result.stdout.strip()
    except UnicodeDecodeError:
        result = subprocess.run(
            ["git"] + args,
            capture_output=True, text=True, encoding="cp949",
            cwd=cwd or os.getcwd()
        )
        return result.stdout.strip()

def get_commit_info():
    """최신 커밋 정보 수집"""
    commit_hash = git_cmd(["rev-parse", "HEAD"])
    short_hash = git_cmd(["rev-parse", "--short", "HEAD"])
    message = git_cmd(["log", "-1", "--pretty=%s"])
    author = git_cmd(["log", "-1", "--pretty=%an"])
    timestamp = git_cmd(["log", "-1", "--pretty=%aI"])
    return {
        "hash": commit_hash,
        "short": short_hash,
        "message": message,
        "author": author,
        "timestamp": timestamp,
    }

def get_changed_files():
    """변경된 파일 목록 (상태 포함)"""
    output = git_cmd(["diff", "--name-status", "HEAD~1", "HEAD"])
    if not output:
        return []
    files = []
    for line in output.splitlines():
        parts = line.split("\t", 1)
        if len(parts) == 2:
            status, filepath = parts
            files.append({"status": status, "path": filepath})
    return files

def get_file_diff(filepath):
    """특정 파일의 diff 내용"""
    return git_cmd(["diff", "HEAD~1", "HEAD", "--", filepath])

# ======================================
# 2. 파일 분류
# ======================================

def classify_path(filepath):
    """파일 경로로 엔티티 라벨 분류"""
    path_lower = filepath.lower().replace("\\", "/")
    ext = os.path.splitext(filepath)[1].lower()
    
    if ext == ".mq5" and "expert" in path_lower:
        return "ExpertAdvisor"
    if ext == ".mqh" and "include" in path_lower:
        return "FrameworkModule"
    if ext == ".mq5" and "indicator" in path_lower:
        return "Indicator"
    if ext == ".py":
        return "Script"
    if ext in (".parquet", ".csv") and "files" in path_lower:
        return "DataArtifact"
    if ext == ".md":
        return "Document"
    return None

# ======================================
# 3. Diff 분석 (규칙 기반)
# ======================================

def analyze_diff(diff_text, filepath):
    """diff 내용을 규칙 기반으로 분석하여 변경 요약 생성"""
    insights = []
    
    added_lines = [l[1:] for l in diff_text.splitlines() if l.startswith("+") and not l.startswith("+++")]
    removed_lines = [l[1:] for l in diff_text.splitlines() if l.startswith("-") and not l.startswith("---")]
    
    # (a) 파라미터/숫자 변경 감지
    num_pattern = re.compile(r'(\w+)\s*[=:]\s*([\d.]+)')
    old_params = {}
    new_params = {}
    for line in removed_lines:
        for m in num_pattern.finditer(line):
            old_params[m.group(1)] = m.group(2)
    for line in added_lines:
        for m in num_pattern.finditer(line):
            new_params[m.group(1)] = m.group(2)
    
    for key in set(old_params) & set(new_params):
        if old_params[key] != new_params[key]:
            insights.append(f"파라미터 변경: {key} {old_params[key]}→{new_params[key]}")
    
    # (b) include/import 변경 감지
    inc_pattern = re.compile(r'#include\s*[<"](.+?)[>"]|import\s+(\S+)|from\s+(\S+)\s+import')
    for line in added_lines:
        m = inc_pattern.search(line)
        if m:
            dep = m.group(1) or m.group(2) or m.group(3)
            insights.append(f"의존성 추가: {dep}")
    for line in removed_lines:
        m = inc_pattern.search(line)
        if m:
            dep = m.group(1) or m.group(2) or m.group(3)
            insights.append(f"의존성 제거: {dep}")
    
    # (c) 함수 추가/삭제 감지
    func_patterns = [
        re.compile(r'(?:void|int|double|bool|string)\s+(\w+)\s*\('),  # MQL5
        re.compile(r'def\s+(\w+)\s*\('),  # Python
    ]
    for line in added_lines:
        for fp in func_patterns:
            m = fp.search(line)
            if m:
                insights.append(f"함수 추가: {m.group(1)}()")
    for line in removed_lines:
        for fp in func_patterns:
            m = fp.search(line)
            if m:
                insights.append(f"함수 삭제: {m.group(1)}()")
    
    # (d) 줄 수 변경
    insights.append(f"+{len(added_lines)}줄 -{len(removed_lines)}줄")
    
    return insights

# ======================================
# 4. Graph DB 저장
# ======================================

def save_to_db(commit_info, file_analyses):
    """커밋 정보와 파일 분석 결과를 SQL Server Graph DB에 저장"""
    safe_hash = commit_info["hash"]
    safe_short = commit_info["short"]
    safe_msg = commit_info["message"].replace("'", "\\'").replace('"', '\\"')
    safe_time = commit_info["timestamp"][:19]  # ISO 문자열의 날짜+시간 부분만
    
    # Commit 노드 생성 (hash를 name으로 사용)
    q = f"""
    MERGE (c:Commit {{name: '{safe_hash}'}})
    SET c.short_hash = '{safe_short}',
        c.message = '{safe_msg}',
        c.author = '{commit_info["author"]}',
        c.created_at = datetime('{safe_time}'),
        c.file_count = {len(file_analyses)}
    """
    run_cypher(q)
    
    # 각 파일별 관계 생성
    for fa in file_analyses:
        label = fa.get("label")
        fname = os.path.basename(fa["path"]).replace("'", "\\'")
        status_map = {"A": "ADDED", "M": "MODIFIED", "D": "DELETED"}
        rel_type = status_map.get(fa["status"], "MODIFIED")
        summary = "; ".join(fa.get("insights", []))[:500].replace("'", "\\'")
        
        target_label = label or "DataArtifact"
        safe_path = fa['path'].replace(chr(92), '/').replace("'", "\\'")
        # 파일 노드 생성/업데이트
        run_cypher(f"MERGE (f:{target_label} {{name: '{fname}'}}) SET f.path = '{safe_path}', f.updated_at = datetime('{safe_time}')")
        # Commit → 파일 관계
        q = f"MATCH (c:Commit {{name: '{safe_hash}'}}) MATCH (f:{target_label} {{name: '{fname}'}}) MERGE (c)-[:{rel_type}]->(f)"
        run_cypher(q)

# ======================================
# 5. 메인 실행
# ======================================

def main():
    print("=" * 50)
    print("  Git Commit → Graph DB 자동 분석기")
    print("=" * 50)
    
    commit = get_commit_info()
    print(f"\n📝 커밋: [{commit['short']}] {commit['message']}")
    
    files = get_changed_files()
    if not files:
        print("  변경 파일 없음 (최초 커밋이거나 단일 커밋)")
        return
    
    print(f"📂 변경 파일: {len(files)}개\n")
    
    file_analyses = []
    for f in files:
        label = classify_path(f["path"])
        label_str = label or "기타"
        
        insights = []
        if f["status"] != "D":  # 삭제된 파일은 diff 불가
            try:
                diff = get_file_diff(f["path"])
                if diff:
                    insights = analyze_diff(diff, f["path"])
            except Exception:
                insights = ["diff 분석 실패"]
        else:
            insights = ["파일 삭제됨"]
        
        status_icon = {"A": "🆕", "M": "✏️", "D": "🗑️"}.get(f["status"], "❓")
        print(f"  {status_icon} [{label_str:18s}] {os.path.basename(f['path'])}")
        for ins in insights[:5]:
            print(f"      → {ins}")
        
        file_analyses.append({
            "path": f["path"],
            "status": f["status"],
            "label": label,
            "insights": insights,
        })
    
    # Graph DB 저장
    print(f"\n💾 Graph DB 저장 중...")
    try:
        save_to_db(commit, file_analyses)
        print(f"  ✅ 커밋 [{commit['short']}] + {len(file_analyses)}개 파일 관계 저장 완료!")
    except Exception as e:
        print(f"  ⚠️ Graph DB 저장 실패 (DB 미실행?): {e}")
        # Hook은 실패해도 git commit을 안 막음
    
    print(f"{'=' * 50}")

if __name__ == "__main__":
    main()
