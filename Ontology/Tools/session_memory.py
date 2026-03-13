"""
Session Memory — Neo4j HTTP API 직접 연동 CRUD
================================================
대화 세션, 파일 상태, 결정 사항을 Neo4j Graph DB에 저장/조회합니다.
(cypher_cli.py SQL Server 레이어 우회 → Neo4j HTTP API 직접 호출)

사용 예:
    from session_memory import save_session, upsert_file_state, save_decision, get_recent_sessions
"""
import sys, os, json, uuid, base64
import urllib.request, urllib.error
from datetime import datetime, timezone, timedelta, date

KST       = timezone(timedelta(hours=9))
NEO4J_URL = os.getenv("NEO4J_URI", "http://127.0.0.1:7474/db/neo4j/tx/commit")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASS = os.getenv("NEO4J_PASSWORD", "KIM10507")

def _now_kst():
    return datetime.now(KST).strftime("%Y-%m-%dT%H:%M:%S+09:00")

def _today_kst():
    return datetime.now(KST).strftime("%Y-%m-%d")

def _run_cypher(statement: str, params: dict = None) -> dict:
    """Neo4j HTTP Transactional API로 Cypher 실행"""
    cred = base64.b64encode(f"{NEO4J_USER}:{NEO4J_PASS}".encode()).decode()
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": f"Basic {cred}"
    }
    body = json.dumps({
        "statements": [{"statement": statement, "parameters": params or {}}]
    }).encode("utf-8")
    req = urllib.request.Request(NEO4J_URL, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            errors = result.get("errors", [])
            if errors:
                return {"status": "ERROR", "errors": errors}
            # rows 추출
            rows = []
            for r in result.get("results", []):
                cols = r.get("columns", [])
                for data in r.get("data", []):
                    row = dict(zip(cols, data.get("row", [])))
                    rows.append(row)
            return {"status": "OK", "rows": rows}
    except urllib.error.HTTPError as e:
        return {"status": "ERROR", "errors": [{"message": f"HTTP {e.code}: {e.reason}"}]}
    except Exception as e:
        return {"status": "ERROR", "errors": [{"message": str(e)}]}

# ─────────────────────────────────────────────
# WRITE
# ─────────────────────────────────────────────

def save_session(summary: str, topics=None, files_touched=None) -> dict:
    """대화 세션 요약을 Neo4j에 저장합니다."""
    session_id = str(uuid.uuid4())[:8]
    result = _run_cypher(
        "MERGE (s:Session {id: $id}) "
        "SET s.date = $date, s.created_at = $created_at, "
        "    s.summary = $summary, s.topics = $topics, s.files_touched = $files_touched "
        "RETURN s.id AS id",
        {
            "id": session_id,
            "date": _today_kst(),
            "created_at": _now_kst(),
            "summary": summary[:500],
            "topics": "|".join(topics or []),
            "files_touched": "|".join(files_touched or []),
        }
    )
    if result["status"] == "OK":
        print(f"  ✅ Session 저장: {session_id} — {summary[:60]}...")
    else:
        print(f"  ❌ Session 저장 실패: {result}")
    return result

def upsert_file_state(path: str, action: str, description: str = "") -> dict:
    """파일 상태를 Neo4j에 업서트합니다."""
    name = os.path.basename(path)
    result = _run_cypher(
        "MERGE (f:FileState {path: $path}) "
        "SET f.name = $name, f.last_action = $action, "
        "    f.description = $description, f.updated_at = $updated_at "
        "RETURN f.path AS path",
        {
            "path": path,
            "name": name,
            "action": action,
            "description": description[:300],
            "updated_at": _today_kst(),
        }
    )
    if result["status"] == "OK":
        print(f"  ✅ FileState 업서트: {name} [{action}]")
    else:
        print(f"  ❌ FileState 실패: {result}")
    return result

def save_decision(what: str, why: str, result_: str = "confirmed") -> dict:
    """중요 결정 사항을 Neo4j에 저장합니다."""
    decision_id = str(uuid.uuid4())[:8]
    result = _run_cypher(
        "MERGE (d:Decision {id: $id}) "
        "SET d.what = $what, d.why = $why, d.result = $result, d.created_at = $created_at "
        "RETURN d.id AS id",
        {
            "id": decision_id,
            "what": what[:300],
            "why": why[:300],
            "result": result_,
            "created_at": _now_kst(),
        }
    )
    if result["status"] == "OK":
        print(f"  ✅ Decision 저장: {decision_id} — {what[:60]}")
    else:
        print(f"  ❌ Decision 저장 실패: {result}")
    return result

# ─────────────────────────────────────────────
# READ
# ─────────────────────────────────────────────

def get_recent_sessions(n: int = 4) -> list:
    """최근 N개 Session 조회"""
    r = _run_cypher(
        "MATCH (s:Session) RETURN s.date AS date, s.summary AS summary, "
        "s.topics AS topics, s.files_touched AS files_touched "
        "ORDER BY s.date DESC LIMIT $n",
        {"n": n}
    )
    return r.get("rows", [])

def get_recent_file_states(days: int = 7) -> list:
    """최근 N일 수정된 FileState 조회"""
    cutoff = (date.today() - timedelta(days=days)).strftime("%Y-%m-%d")
    r = _run_cypher(
        "MATCH (f:FileState) WHERE f.updated_at >= $cutoff "
        "RETURN f.name AS name, f.path AS path, f.last_action AS last_action, "
        "f.description AS description, f.updated_at AS updated_at "
        "ORDER BY f.updated_at DESC",
        {"cutoff": cutoff}
    )
    return r.get("rows", [])

def get_pending_decisions() -> list:
    """미결 Decision 조회"""
    r = _run_cypher(
        "MATCH (d:Decision) WHERE d.result = 'pending' "
        "RETURN d.what AS what, d.why AS why, d.created_at AS created_at"
    )
    return r.get("rows", [])

def build_resume_context(n_sessions: int = 4) -> str:
    """/resume 시 AI에 주입할 문맥 문자열 생성"""
    lines = ["=== 🧠 세션 메모리 복원 (/resume) ===\n"]

    sessions = get_recent_sessions(n_sessions)
    lines.append(f"[ 최근 {len(sessions)}개 대화 세션 ]")
    for s in sessions:
        lines.append(f"  📅 {s.get('date','')} | {s.get('summary','')[:80]}")
        topics = s.get("topics", "")
        if topics:
            topics_str = ", ".join(topics) if isinstance(topics, list) else topics.replace("|", ", ")
            lines.append(f"     주제: {topics_str}")
        ft = s.get("files_touched", "")
        if ft:
            ft_str = ", ".join(ft) if isinstance(ft, list) else ft.replace("|", ", ")
            lines.append(f"     파일: {ft_str}")

    files = get_recent_file_states(7)
    lines.append(f"\n[ 최근 7일 수정 파일 — {len(files)}개 ]")
    for f in files:
        lines.append(f"  📄 {f.get('name','')} [{f.get('last_action','')}] — {f.get('description','')[:60]}")

    decisions = get_pending_decisions()
    if decisions:
        lines.append(f"\n[ 미결 결정 사항 — {len(decisions)}개 ]")
        for d in decisions:
            lines.append(f"  ⚡ {d.get('what','')[:80]}")

    lines.append("\n=== 문맥 복원 완료 ===")
    return "\n".join(lines)

# ─────────────────────────────────────────────
# CLI 진입점
# ─────────────────────────────────────────────
if __name__ == "__main__":
    if "--test" in sys.argv:
        print("[ session_memory.py 자가 테스트 ]")
        save_session(
            summary="GitHub 새 리파지토리(MAC-MQL5) 연결, .gitignore 업데이트, git filter-repo로 PAT 제거",
            topics=["git", "GitHub", "repository"],
            files_touched=[".gitignore", "Ontology/Tools/session_memory.py"]
        )
        upsert_file_state(
            path="Ontology/Tools/session_memory.py",
            action="created",
            description="세션 메모리 CRUD 헬퍼 신규 생성"
        )
        save_decision(
            what="CSV/Parquet 파일을 .gitignore에서 영구 제외",
            why="Data/2025_Featured.csv가 71MB로 GitHub 권장 크기 초과"
        )
        print()
    if "--resume" in sys.argv or "--test" in sys.argv:
        print(build_resume_context(4))
