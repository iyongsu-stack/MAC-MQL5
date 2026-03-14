#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
performance_tracker.py — 거래 성과 추적 서비스
===============================================
- trade_log.csv를 읽어 승률, PF, MDD, 에쿼티 커브 산출
- drift_monitor.py가 교차 판정에 사용할 recent_win_rate 제공
- CLI: python performance_tracker.py

의존성: pandas, pyyaml
"""

import os
import sys
import json
import time
import glob
from datetime import datetime, timedelta
from pathlib import Path

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
    """서비스 시작 시 .tmp 잔재 자동 삭제"""
    live_dir = MQL5_ROOT / "Files" / "live"
    for f in glob.glob(str(live_dir / "*.tmp")):
        try:
            os.remove(f)
        except OSError:
            pass


# ──────────────────── 파일 안전 읽기 (File Lock 방어) ───────────────

def safe_read_csv(path, max_retries=3, wait_sec=1):
    """EA가 쓰는 중일 때 충돌 방지"""
    for attempt in range(max_retries):
        try:
            df = pd.read_csv(path)
            return df
        except (PermissionError, OSError):
            if attempt < max_retries - 1:
                time.sleep(wait_sec)
            else:
                raise RuntimeError(f"파일 락 해제 실패 ({max_retries}회 시도): {path}")


# ──────────────────────── 성과 계산 ────────────────────────────────

def generate_report(trade_log_path: str) -> dict:
    """trade_log.csv → 성과 통계 dict"""
    df = safe_read_csv(trade_log_path)

    if df.empty or "event" not in df.columns:
        return None

    closes = df[df["event"] == "CLOSE"].copy()
    if len(closes) == 0:
        return None

    # ── 기본 통계 ──
    total = len(closes)
    wins = (closes["pnl_points"] > 0).sum()
    losses = total - wins
    win_rate = wins / total * 100

    # ── Profit Factor ──
    gross_profit = closes[closes["pnl_points"] > 0]["pnl_points"].sum()
    gross_loss = abs(closes[closes["pnl_points"] < 0]["pnl_points"].sum())
    pf = gross_profit / max(gross_loss, 1e-6)

    # ── 평균 수익/손실 ──
    avg_win = closes[closes["pnl_points"] > 0]["pnl_points"].mean() if wins > 0 else 0
    avg_loss = closes[closes["pnl_points"] < 0]["pnl_points"].mean() if losses > 0 else 0

    # ── MDD (포인트 기준) ──
    equity = closes["pnl_points"].cumsum()
    peak = equity.cummax()
    drawdown = equity - peak
    mdd = drawdown.min()

    # ── 최근 2주 승률 (drift_monitor 교차 판정용) ──
    recent_cutoff = datetime.utcnow() - timedelta(days=14)
    if "close_time" in closes.columns:
        closes_recent = closes.copy()
        closes_recent["close_time"] = pd.to_datetime(closes_recent["close_time"])
        recent = closes_recent[closes_recent["close_time"] >= recent_cutoff]
        if len(recent) > 0:
            recent_wr = (recent["pnl_points"] > 0).sum() / len(recent) * 100
        else:
            recent_wr = win_rate  # 최근 데이터 없으면 전체 승률 사용
    else:
        recent_wr = win_rate

    return {
        "report_date": datetime.utcnow().strftime("%Y-%m-%d"),
        "total_trades": int(total),
        "wins": int(wins),
        "losses": int(losses),
        "win_rate": round(win_rate, 1),
        "recent_win_rate": round(recent_wr, 1),
        "profit_factor": round(pf, 2),
        "avg_win": round(avg_win, 1),
        "avg_loss": round(avg_loss, 1),
        "max_drawdown": round(mdd, 1),
        "total_pnl": round(closes["pnl_points"].sum(), 1),
    }


def generate_equity_curve(trade_log_path: str, output_path: str):
    """에쿼티 커브 CSV 생성"""
    df = safe_read_csv(trade_log_path)
    closes = df[df["event"] == "CLOSE"].copy()

    if len(closes) == 0:
        return

    closes = closes.reset_index(drop=True)
    closes["equity"] = closes["pnl_points"].cumsum()

    cols = ["close_time", "pnl_points", "equity"] if "close_time" in closes.columns else ["pnl_points", "equity"]
    closes[cols].to_csv(output_path, index=False)


def format_report_text(stats: dict) -> str:
    """텔레그램용 텍스트 리포트"""
    return (
        "═══════════════════════════════\n"
        "  📊 BSP_Long_v1 Performance\n"
        f"  {stats['report_date']}\n"
        "═══════════════════════════════\n"
        f"  총 거래: {stats['total_trades']}건\n"
        f"  승률: {stats['win_rate']}% ({stats['wins']}승 {stats['losses']}패)\n"
        f"  최근2주: {stats['recent_win_rate']}%\n"
        f"  PF: {stats['profit_factor']}\n"
        f"  평균 수익: +{stats['avg_win']}pt\n"
        f"  평균 손실: {stats['avg_loss']}pt\n"
        f"  총 PnL: {stats['total_pnl']:+.1f}pt\n"
        f"  MDD: {stats['max_drawdown']}pt\n"
        "═══════════════════════════════"
    )


# ──────────────────────── 메인 ────────────────────────────────────

def main():
    cleanup_tmp()

    config = load_config()
    paths = config.get("paths", {})

    trade_log_path = str(MQL5_ROOT / paths.get("trade_log", "Files/live/trade_log.csv"))
    report_path = str(MQL5_ROOT / paths.get("performance_report", "Files/live/performance_report.csv"))
    equity_path = str(MQL5_ROOT / paths.get("equity_curve", "Files/live/equity_curve.csv"))

    if not os.path.exists(trade_log_path):
        print(f"[WARN] trade_log.csv 없음: {trade_log_path}")
        print("  → EA가 아직 거래 기록을 생성하지 않았습니다.")
        return

    # 1. 성과 통계 계산
    stats = generate_report(trade_log_path)
    if stats is None:
        print("[INFO] 청산 기록 없음 — 보고서 생성 생략")
        return

    # 2. 리포트 CSV 저장
    pd.DataFrame([stats]).to_csv(report_path, index=False)
    print(f"[OK] 성과 리포트 저장: {report_path}")

    # 3. 에쿼티 커브 CSV
    generate_equity_curve(trade_log_path, equity_path)
    print(f"[OK] 에쿼티 커브 저장: {equity_path}")

    # 4. 콘솔 출력
    print(format_report_text(stats))

    # 5. 텔레그램 일일 PnL (선택)
    try:
        from alert_service import send_telegram
        send_telegram(format_report_text(stats), config, msg_type="daily_pnl")
    except ImportError:
        pass


if __name__ == "__main__":
    main()
