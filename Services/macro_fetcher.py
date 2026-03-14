#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
macro_fetcher.py — 매크로 데이터 일일 갱신 서비스
==================================================
- SHAP 선별 원본 심볼만 Yahoo Finance / FRED에서 수집
- 3단계 Sanity Check + Atomic Write
- CLI: python macro_fetcher.py

의존성: yfinance, pandas_datareader, pandas, numpy, pyyaml
"""

import os
import sys
import glob
import shutil
import time
import logging
from datetime import datetime, timedelta
from pathlib import Path

import numpy as np
import pandas as pd
import yaml

try:
    import yfinance as yf
except ImportError:
    yf = None
    print("[WARN] yfinance 미설치 — pip install yfinance")

try:
    from pandas_datareader import data as pdr
except ImportError:
    pdr = None
    print("[WARN] pandas_datareader 미설치 — pip install pandas-datareader")


# ─────────────────────────── 경로 설정 ───────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_PATH = SCRIPT_DIR / "Config" / "service_config.yaml"
MQL5_ROOT = SCRIPT_DIR.parent

logging.basicConfig(
    filename=str(SCRIPT_DIR / "Logs" / "service.log"),
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)


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


# ──────────────────────── 데이터 수집 ─────────────────────────────

def fetch_yahoo(symbols_list: list, days: int) -> pd.DataFrame:
    """Yahoo Finance에서 SHAP 선별 심볼만 수집"""
    if yf is None:
        raise ImportError("yfinance 미설치")

    end = datetime.today()
    start = end - timedelta(days=days)
    frames = {}

    for ticker, short_name, desc in symbols_list:
        try:
            data = yf.download(ticker, start=start, end=end, progress=False, auto_adjust=True)
            if data is not None and len(data) > 0:
                frames[short_name] = data["Close"]
                logging.info(f"YF OK: {short_name} ({ticker}) — {len(data)}행")
            else:
                logging.warning(f"YF 빈 결과: {short_name} ({ticker})")
        except Exception as e:
            logging.error(f"YF 실패: {short_name} ({ticker}) — {e}")

    if not frames:
        return pd.DataFrame()

    df = pd.DataFrame(frames)
    df.index = pd.to_datetime(df.index)
    return df


def fetch_fred(series_list: list, days: int) -> pd.DataFrame:
    """FRED에서 SHAP 선별 시리즈만 수집"""
    if pdr is None:
        raise ImportError("pandas_datareader 미설치")

    end = datetime.today()
    start = end - timedelta(days=days)
    frames = {}

    for series_id, short_name, desc in series_list:
        try:
            data = pdr.DataReader(series_id, "fred", start, end)
            if data is not None and len(data) > 0:
                frames[short_name] = data.iloc[:, 0]
                logging.info(f"FRED OK: {short_name} ({series_id}) — {len(data)}행")
            else:
                logging.warning(f"FRED 빈 결과: {short_name} ({series_id})")
        except Exception as e:
            logging.error(f"FRED 실패: {short_name} ({series_id}) — {e}")

    if not frames:
        return pd.DataFrame()

    df = pd.DataFrame(frames)
    df.index = pd.to_datetime(df.index)
    return df


# ──────────────────── 3단계 Sanity Check ──────────────────────────

def absolute_range_check(df: pd.DataFrame, sanity_rules: dict) -> pd.DataFrame:
    """[1단계] 절대 범위 검증 — 범위 밖이면 NaN으로 교체 후 ffill"""
    for col in df.columns:
        rule = sanity_rules.get(col)
        if rule is None:
            continue
        mask = (df[col] < rule["min"]) | (df[col] > rule["max"])
        outlier_count = mask.sum()
        if outlier_count > 0:
            logging.warning(f"[Sanity 1단계] {col}: {outlier_count}개 범위 밖 → ffill")
            df.loc[mask, col] = np.nan
    df = df.ffill()
    return df


def daily_change_alert(df: pd.DataFrame, sanity_rules: dict, send_alert_fn=None):
    """[2단계] 일일 변동률 검증 — 경고만, 값은 유지"""
    pct_change = df.pct_change().abs() * 100  # %
    alerts = []

    for col in df.columns:
        rule = sanity_rules.get(col)
        if rule is None:
            continue
        threshold = rule.get("max_daily_pct", 10.0)
        last_pct = pct_change[col].iloc[-1] if len(pct_change) > 0 else 0

        if last_pct > threshold:
            msg = f"[Sanity 2단계] {col}: 전일 대비 {last_pct:.1f}% 변동 (임계: ±{threshold}%)"
            logging.warning(msg)
            alerts.append(msg)

    if alerts and send_alert_fn:
        send_alert_fn("⚠️ 매크로 변동률 경고:\n" + "\n".join(alerts))


def nan_ratio_check(row: pd.Series, threshold: float = 0.50) -> bool:
    """[3단계] NaN 비율 검증 — True이면 저장 가능"""
    ratio = row.isna().mean()
    if ratio > threshold:
        logging.error(f"[Sanity 3단계] NaN 비율 {ratio:.0%} > {threshold:.0%} → 저장 중단")
        return False
    return True


# ────── 파생 변환 (build_data_lake.py calc_macro_features와 Bug-for-Bug 동기화) ──────
# ⚠️ 이 함수를 수정하면 반드시 build_data_lake.py의 calc_macro_features()도 함께 확인
# Rule_Python_MQL5_Fidelity: 학습 파이프라인과 수학적으로 100% 동일해야 함

def calc_macro_features(s: pd.Series, prefix: str) -> pd.DataFrame:
    """
    매크로 원본 시리즈 → 파생 피처 DataFrame
    build_data_lake.py의 calc_macro_features()와 동일 수식.

    변환 유형:
      ① Δ% (1d/5d/21d)  — 레벨값 변화율
      ② Z-score (60/240/1440) — 멀티스케일 롤링
      ③ MA 비율 (60/240/1440) — 이동평균 대비
      ④ Slope (10일 pct_change 기반)
      ⑤ Accel (Slope의 diff(10))
    """
    df = pd.DataFrame(index=s.index)

    # ① 변화율(Δ%) — 레벨값 전용 (강제)
    df[f"{prefix}_ret1d"]  = s.pct_change(1) * 100
    df[f"{prefix}_ret5d"]  = s.pct_change(5) * 100
    df[f"{prefix}_ret21d"] = s.pct_change(21) * 100

    # ② 멀티스케일 롤링 Z-score (60/240/1440)
    # 🚨 build_data_lake.py 원본: (s - s.rolling(w).mean()) / s.rolling(w).std()
    #    Data Lake 단계에서는 shift 미적용 → 병합(merge_features.py)에서 shift(1) 적용
    #    macro_fetcher는 "오늘 장 마감 후" 수집이므로 당일 값이 확정됨
    #    → rolling(w)에 당일 값 포함이 학습 파이프라인과 동일
    for w in [60, 240, 1440]:
        roll = s.rolling(w)
        df[f"{prefix}_zscore_{w}"] = (s - roll.mean()) / roll.std()

    # ③ MA 대비 비율 (60/240/1440)
    for w in [60, 240, 1440]:
        ma = s.rolling(w).mean()
        df[f"{prefix}_ma_ratio_{w}"] = s / ma.replace(0, np.nan) - 1

    # ④ 기울기 (10일 pct_change 기반 — 스케일 통일)
    df[f"{prefix}_slope"] = s.pct_change(10) * 100

    # ⑤ 가속도 (기울기의 변화)
    df[f"{prefix}_accel"] = df[f"{prefix}_slope"].diff(10)

    return df


def apply_macro_transforms(df: pd.DataFrame) -> pd.DataFrame:
    """
    매크로 원본 DataFrame → 전체 파생 피처 DataFrame
    각 컬럼별로 calc_macro_features() 적용 후 가로 결합
    """
    frames = []
    for col in df.columns:
        feat = calc_macro_features(df[col].dropna(), col)
        frames.append(feat)

    if not frames:
        return pd.DataFrame()

    result = pd.concat(frames, axis=1)
    # ffill 처리 (GEMINI.md: bfill 절대 금지)
    result = result.ffill()
    return result


# ──────────────────── Atomic Write ────────────────────────────────

def atomic_save(df: pd.DataFrame, target_path: str):
    """임시 파일에 먼저 쓰고 OS-level rename으로 교체"""
    tmp = target_path + ".tmp"
    bak = target_path + ".bak"

    df.to_csv(tmp, index=True)

    if os.path.exists(target_path):
        shutil.copy2(target_path, bak)

    os.replace(tmp, target_path)  # atomic operation


# ──────────────────── 하트비트 ────────────────────────────────────

def write_heartbeat(config: dict):
    """마지막 실행 타임스탬프 기록"""
    hb_path = str(MQL5_ROOT / config["paths"].get("heartbeat", "Files/live/heartbeat.txt"))
    os.makedirs(os.path.dirname(hb_path), exist_ok=True)
    with open(hb_path, "w") as f:
        f.write(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC"))


# ──────────────────────── 메인 ────────────────────────────────────

def main():
    cleanup_tmp()

    config = load_config()
    paths = config.get("paths", {})
    mf_config = config.get("macro_fetcher", {})

    output_path = str(MQL5_ROOT / paths.get("macro_latest", "Files/live/macro_latest.csv"))
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    yf_symbols = mf_config.get("yf_symbols", [])
    fred_series = mf_config.get("fred_series", [])
    fetch_days = mf_config.get("fetch_days", 90)
    retry_count = mf_config.get("retry_count", 5)
    retry_interval = mf_config.get("retry_interval_min", 10)
    sanity_rules = mf_config.get("sanity_rules", {})

    # 알림 함수 준비
    try:
        from alert_service import send_alert
    except ImportError:
        send_alert = lambda msg, **kw: print(f"[ALERT] {msg}")

    # ── 재시도 루프 (10분 간격 2회씩, 총 5회) ──
    raw_yf = pd.DataFrame()
    raw_fred = pd.DataFrame()

    for attempt in range(1, retry_count + 1):
        try:
            if raw_yf.empty and yf_symbols:
                raw_yf = fetch_yahoo(yf_symbols, fetch_days)

            if raw_fred.empty and fred_series:
                raw_fred = fetch_fred(fred_series, fetch_days)

            if not raw_yf.empty or not raw_fred.empty:
                break  # 최소 1개 소스 성공
        except Exception as e:
            logging.error(f"수집 시도 {attempt}/{retry_count} 실패: {e}")

        if attempt < retry_count:
            wait_min = retry_interval
            logging.info(f"재시도 대기: {wait_min}분 (시도 {attempt}/{retry_count})")
            time.sleep(wait_min * 60)

    if raw_yf.empty and raw_fred.empty:
        msg = f"❌ macro_fetcher: {retry_count}회 시도 모두 실패 → 전일 CSV 유지"
        logging.error(msg)
        send_alert(msg)
        return

    # ── 1단계: 절대 범위 검증 ──
    if not raw_yf.empty:
        raw_yf = absolute_range_check(raw_yf, sanity_rules)

    # ── 2단계: 일일 변동률 검증 (경고만) ──
    if not raw_yf.empty:
        daily_change_alert(raw_yf, sanity_rules, send_alert_fn=send_alert)

    # ── 파생 변환 ──
    combined = pd.concat([raw_yf, raw_fred], axis=1) if not raw_fred.empty else raw_yf
    combined = combined.ffill()  # 매크로 ffill (bfill 금지)

    derived = apply_macro_transforms(combined)

    # ── 3단계: NaN 비율 검증 ──
    latest_row = derived.iloc[-1]
    if not nan_ratio_check(latest_row):
        send_alert("❌ macro_fetcher: NaN 50%+ → 전일 CSV 유지")
        return

    # ── Atomic Write ──
    atomic_save(derived.iloc[[-1]], output_path)

    # ── 하트비트 ──
    write_heartbeat(config)

    print(f"[OK] macro_latest.csv 저장 완료 ({len(derived.columns)}개 피처)")
    logging.info(f"macro_fetcher 완료: {len(derived.columns)}개 피처, {output_path}")


if __name__ == "__main__":
    main()
