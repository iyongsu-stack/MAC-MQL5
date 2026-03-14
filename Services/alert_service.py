#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
alert_service.py — 텔레그램 Bot 알림 서비스
============================================
- 다른 서비스에서 import하여 send_alert() 호출
- CLI: python alert_service.py --setup  (초기 설정)
- CLI: python alert_service.py --test   (연결 테스트)

의존성: requests, pyyaml
"""

import os
import sys
import csv
import argparse
import time
from datetime import datetime
from pathlib import Path

import requests
import yaml


# ─────────────────────────── 경로 설정 ───────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_PATH = SCRIPT_DIR / "Config" / "service_config.yaml"
MQL5_ROOT = SCRIPT_DIR.parent  # MQL5/


def load_config():
    """service_config.yaml 로드"""
    if not CONFIG_PATH.exists():
        print(f"[ERROR] 설정 파일 없음: {CONFIG_PATH}")
        sys.exit(1)
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def save_config(config):
    """service_config.yaml 저장"""
    with open(CONFIG_PATH, "w", encoding="utf-8") as f:
        yaml.dump(config, f, allow_unicode=True, default_flow_style=False, sort_keys=False)


# ─────────────────────── 텔레그램 API ────────────────────────────

def send_telegram(message: str, config: dict, msg_type: str = "system") -> bool:
    """
    텔레그램 Bot API를 통한 메시지 전송.

    Args:
        message:  전송할 텍스트
        config:   service_config.yaml 전체 dict
        msg_type: "entry" | "close" | "daily_pnl" | "system"
                  사용자 선택형 알림은 config에서 on/off 확인

    Returns:
        True=성공, False=실패 또는 비활성
    """
    tg = config.get("telegram", {})

    # 텔레그램 비활성
    if not tg.get("enabled", False):
        return False

    # 사용자 선택형 알림 on/off 체크
    type_map = {
        "entry":     "notify_entry",
        "close":     "notify_close",
        "daily_pnl": "notify_daily_pnl",
    }
    if msg_type in type_map:
        if not tg.get(type_map[msg_type], True):
            return False  # 사용자가 꺼놓음

    bot_token = tg.get("bot_token", "")
    chat_id = tg.get("chat_id", "")
    if not bot_token or not chat_id:
        return False

    # 별칭 접두사
    alias = tg.get("alias", "BSP_Bot")
    full_message = f"[{alias}] {message}"

    # 4096자 제한
    if len(full_message) > 4096:
        full_message = full_message[:4090] + "\n..."

    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": full_message,
        "parse_mode": "HTML",
    }

    for attempt in range(3):
        try:
            resp = requests.post(url, json=payload, timeout=10)
            if resp.status_code == 200:
                log_alert(message, msg_type, "OK")
                return True
            else:
                log_alert(message, msg_type, f"HTTP {resp.status_code}")
        except requests.RequestException as e:
            log_alert(message, msg_type, f"ERR: {e}")
        time.sleep(2)

    return False


def send_alert(message: str, msg_type: str = "system"):
    """간편 호출 — config 자동 로드"""
    config = load_config()
    return send_telegram(message, config, msg_type)


# ──────────────────────── 알림 로그 기록 ──────────────────────────

def log_alert(message: str, msg_type: str, status: str):
    """alert_log.csv에 알림 이력 기록"""
    log_path = SCRIPT_DIR / "Logs" / "alert_log.csv"
    log_path.parent.mkdir(parents=True, exist_ok=True)

    file_exists = log_path.exists()
    with open(log_path, "a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow(["timestamp", "type", "message", "status"])
        writer.writerow([
            datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"),
            msg_type,
            message[:200],  # 로그 길이 제한
            status,
        ])


# ──────────────────── 초기 설정 (--setup) ─────────────────────────

def setup_telegram():
    """최초 실행 시 텔레그램 설정 — 대화형 input"""
    config = load_config()
    tg = config.get("telegram", {})

    print("=" * 55)
    print("  🔔 텔레그램 알림 설정 (최초 1회)")
    print("  빈 값으로 Enter 시 설정을 건너뜁니다.")
    print("=" * 55)

    # 1. Bot Token
    current_token = tg.get("bot_token", "")
    token_display = f"(현재: ...{current_token[-10:]})" if current_token else "(미설정)"
    bot_token = input(f"\n  [1/3] Bot Token {token_display}\n  → ").strip()
    if bot_token:
        tg["bot_token"] = bot_token

    # 2. Chat ID
    current_chat = tg.get("chat_id", "")
    chat_display = f"(현재: {current_chat})" if current_chat else "(미설정)"
    chat_id = input(f"\n  [2/3] Chat ID {chat_display}\n  → ").strip()
    if chat_id:
        tg["chat_id"] = chat_id

    # 3. 별칭
    current_alias = tg.get("alias", "BSP_Bot")
    alias = input(f"\n  [3/3] 봇 별칭 (현재: {current_alias}, Enter=유지)\n  → ").strip()
    if alias:
        tg["alias"] = alias

    # 알림 유형 선택
    print("\n  📋 알림 유형 선택 (y/n, Enter=기본값 y)")
    for key, label in [
        ("notify_entry",     "거래 진입 알림"),
        ("notify_close",     "청산 알림"),
        ("notify_daily_pnl", "일일 PnL 리포트"),
    ]:
        current = "ON" if tg.get(key, True) else "OFF"
        choice = input(f"     {label} (현재: {current})? [y/n] → ").strip().lower()
        if choice == "n":
            tg[key] = False
        elif choice == "y":
            tg[key] = True

    # 연결 테스트
    if tg.get("bot_token") and tg.get("chat_id"):
        tg["enabled"] = True
        config["telegram"] = tg
        save_config(config)

        print("\n  ⏳ 연결 테스트 중...")
        success = test_connection(config)
        if success:
            print("  ✅ 연결 성공! 설정이 저장되었습니다.")
        else:
            print("  ❌ 연결 실패. Token/ChatID를 확인하세요.")
            tg["enabled"] = False
            config["telegram"] = tg
            save_config(config)
    else:
        print("\n  ⏩ Token/ChatID 미입력 → 텔레그램 알림 비활성 상태 유지")
        tg["enabled"] = False
        config["telegram"] = tg
        save_config(config)


def test_connection(config: dict) -> bool:
    """텔레그램 연결 테스트"""
    tg = config.get("telegram", {})
    alias = tg.get("alias", "BSP_Bot")
    test_msg = f"[{alias}] ✅ 테스트 메시지 — {datetime.now().strftime('%Y-%m-%d %H:%M')}"

    url = f"https://api.telegram.org/bot{tg['bot_token']}/sendMessage"
    payload = {"chat_id": tg["chat_id"], "text": test_msg}

    try:
        resp = requests.post(url, json=payload, timeout=10)
        return resp.status_code == 200
    except Exception:
        return False


# ──────────────────────── CLI 엔트리 ──────────────────────────

def main():
    parser = argparse.ArgumentParser(description="텔레그램 알림 서비스")
    parser.add_argument("--setup", action="store_true", help="텔레그램 초기 설정")
    parser.add_argument("--test", action="store_true", help="연결 테스트 메시지 전송")
    parser.add_argument("--send", type=str, help="직접 메시지 전송")
    args = parser.parse_args()

    if args.setup:
        setup_telegram()
    elif args.test:
        config = load_config()
        if test_connection(config):
            print("✅ 테스트 메시지 전송 성공")
        else:
            print("❌ 전송 실패")
    elif args.send:
        send_alert(args.send)
        print(f"📤 메시지 전송 완료: {args.send[:50]}...")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
