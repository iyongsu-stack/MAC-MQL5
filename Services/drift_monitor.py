#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
drift_monitor.py — PSI + 실전 성과 교차 판정 서비스
====================================================
- 학습 데이터 vs 최근 실전 데이터의 피처 분포 비교 (PSI)
- performance_tracker의 실전 승률과 교차 판정
- CLI: python drift_monitor.py

의존성: pandas, numpy, pyyaml
선행 조건: performance_tracker.py 실행 완료 (performance_report.csv 필요)
"""

import os
import sys
import glob
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd
import yaml


# ─────────────────────────── 경로 설정 ───────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_PATH = SCRIPT_DIR / "Config" / "service_config.yaml"
MQL5_ROOT = SCRIPT_DIR.parent


def load_config():
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


# ──────────────────────── .tmp 잔재 정리 ──────────────────────────

def cleanup_tmp():
    live_dir = MQL5_ROOT / "Files" / "live"
    for f in glob.glob(str(live_dir / "*.tmp")):
        try:
            os.remove(f)
        except OSError:
            pass


# ──────────────────────── PSI 계산 ────────────────────────────────

def calculate_psi(expected: np.ndarray, actual: np.ndarray, bins: int = 10) -> float:
    """
    Population Stability Index 계산
    - expected: 학습 데이터 분포 (기준)
    - actual:   최근 실전 데이터 분포
    """
    if len(expected) < bins or len(actual) < bins:
        return 0.0  # 데이터 부족 시 정상으로 간주

    # 학습 데이터 기준 quantile binning
    breakpoints = np.quantile(expected, np.linspace(0, 1, bins + 1))
    breakpoints[0] = -np.inf
    breakpoints[-1] = np.inf

    expected_pct = np.histogram(expected, bins=breakpoints)[0] / len(expected)
    actual_pct = np.histogram(actual, bins=breakpoints)[0] / len(actual)

    # 0 방지 (log 발산 차단)
    expected_pct = np.clip(expected_pct, 1e-6, None)
    actual_pct = np.clip(actual_pct, 1e-6, None)

    psi = np.sum((actual_pct - expected_pct) * np.log(actual_pct / expected_pct))
    return float(psi)


# ──────────── PSI + 실전 성과 교차 판정 (핵심) ────────────────────

def combined_assessment(psi_results: list, performance_stats: dict) -> str:
    """
    PSI + 실전 성과 교차 판정

    판정 매트릭스:
               │ 성과 양호 (WR≥50) │ 성과 악화 (WR<50)
    ───────────┼───────────────────┼──────────────────
    PSI < 0.10 │ OK                │ MODEL_ISSUE
    PSI > 0.25 │ WATCH             │ RETRAIN_REQUIRED
    """
    psi_fail = any(r["psi"] > 0.25 for r in psi_results if r["status"] == "FAIL")
    recent_wr = performance_stats.get("recent_win_rate", 70)
    perf_bad = recent_wr < 50

    if psi_fail and perf_bad:
        return "RETRAIN_REQUIRED"    # 🔴 재학습 필수
    elif psi_fail and not perf_bad:
        return "WATCH"               # 🟡 관찰 (다음 주 재확인)
    elif not psi_fail and perf_bad:
        return "MODEL_ISSUE"         # ⚠️ 피처 외 원인 탐색
    else:
        return "OK"                  # ✅ 정상


def load_performance_report(config: dict) -> dict:
    """performance_tracker가 생성한 리포트 로드"""
    report_path = str(MQL5_ROOT / config["paths"].get(
        "performance_report", "Files/live/performance_report.csv"
    ))

    if not os.path.exists(report_path):
        print("[WARN] performance_report.csv 없음 — 전체 승률 70% 가정")
        return {"recent_win_rate": 70.0}

    df = pd.read_csv(report_path)
    if df.empty:
        return {"recent_win_rate": 70.0}

    return df.iloc[-1].to_dict()


# ──────────────────────── 메인 ────────────────────────────────────

def main():
    cleanup_tmp()

    config = load_config()
    paths = config.get("paths", {})
    dm_config = config.get("drift_monitor", {})

    psi_threshold = dm_config.get("psi_threshold", 0.25)
    compare_days = dm_config.get("compare_days", 30)
    bins = dm_config.get("bins", 10)
    top_features = dm_config.get("top_features", [])

    train_path = str(MQL5_ROOT / paths.get(
        "train_dataset", "Files/processed/AI_Study_Dataset.parquet"
    ))
    drift_report_path = str(MQL5_ROOT / paths.get(
        "drift_report", "Files/live/drift_report.csv"
    ))

    # 알림 함수
    try:
        from alert_service import send_alert
    except ImportError:
        send_alert = lambda msg, **kw: print(f"[ALERT] {msg}")

    # ── 1. 학습 데이터 로드 ──
    if not os.path.exists(train_path):
        print(f"[ERROR] 학습 데이터 없음: {train_path}")
        return

    print(f"[INFO] 학습 데이터 로드 중: {train_path}")
    train_df = pd.read_parquet(train_path)

    # ── 2. 최근 실전 데이터 구성 ──
    # 학습 데이터의 마지막 N일을 "실전 데이터"로 사용 (초기)
    # 실제 운용 시에는 CTradeLogger의 피처 로그 사용
    total_rows = len(train_df)
    recent_start = max(0, total_rows - compare_days * 1440)  # M1 기준
    recent_df = train_df.iloc[recent_start:]
    reference_df = train_df.iloc[:recent_start]

    if len(reference_df) < 1000:
        print("[WARN] 참조 데이터 부족 — 전체 데이터를 기준으로 사용")
        reference_df = train_df

    # ── 3. PSI 계산 ──
    results = []
    available_features = [f for f in top_features if f in train_df.columns]

    if not available_features:
        print("[WARN] 설정된 Top 피처가 데이터셋에 없음 — 처음 10개 수치 컬럼 사용")
        numeric_cols = train_df.select_dtypes(include=[np.number]).columns[:10]
        available_features = list(numeric_cols)

    print(f"[INFO] PSI 계산 대상: {len(available_features)}개 피처")

    for col in available_features:
        ref_data = reference_df[col].dropna().values
        recent_data = recent_df[col].dropna().values

        psi = calculate_psi(ref_data, recent_data, bins)
        status = "FAIL" if psi > psi_threshold else ("WARN" if psi > 0.10 else "OK")

        results.append({
            "feature": col,
            "psi": round(psi, 4),
            "status": status,
            "date": datetime.utcnow().strftime("%Y-%m-%d"),
        })

        icon = "🔴" if status == "FAIL" else ("⚠️" if status == "WARN" else "✅")
        print(f"  {icon} {col}: PSI={psi:.4f} [{status}]")

    # ── 4. 실전 성과 로드 + 교차 판정 ──
    perf = load_performance_report(config)
    verdict = combined_assessment(results, perf)

    print(f"\n[판정] 교차 판정 결과: {verdict}")
    print(f"  PSI FAIL: {sum(1 for r in results if r['status'] == 'FAIL')}개")
    print(f"  최근 2주 승률: {perf.get('recent_win_rate', 'N/A')}%")

    # ── 5. 리포트 저장 ──
    report = pd.DataFrame(results)
    report["verdict"] = verdict
    report["recent_win_rate"] = perf.get("recent_win_rate", "N/A")
    report.to_csv(drift_report_path, index=False)
    print(f"\n[OK] 드리프트 리포트 저장: {drift_report_path}")

    # ── 6. 텔레그램 알림 (판정별 차등) ──
    fail_count = sum(1 for r in results if r["status"] == "FAIL")

    if verdict == "RETRAIN_REQUIRED":
        detail = "\n".join([f"  • {r['feature']}: PSI={r['psi']}" for r in results if r["status"] == "FAIL"])
        send_alert(
            f"🔴 재학습 필요: PSI FAIL {fail_count}개 + 승률 {perf.get('recent_win_rate', 'N/A')}%\n{detail}"
        )
    elif verdict == "WATCH":
        send_alert(
            f"🟡 관찰: PSI FAIL {fail_count}개, 하지만 승률 {perf.get('recent_win_rate', 'N/A')}% (양호)"
        )
    elif verdict == "MODEL_ISSUE":
        send_alert(
            f"⚠️ 모델 외 문제: PSI 정상이나 승률 {perf.get('recent_win_rate', 'N/A')}% (하락)\n"
            "  → 슬리피지, 실행 오류, 시장 구조 변화 점검"
        )


if __name__ == "__main__":
    main()
