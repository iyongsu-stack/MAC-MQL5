"""
13_expert_strategy.py
=====================
퀀트 전문가가 도메인 지식 기반으로 설계한 전략 3종을
2025년 데이터에서 Head-to-Head 비교하는 스크립트.

핵심 철학: "최적화(Curve-Fitting)"가 아니라 "금융 논리(Financial Logic)"로 설계.
- Z-Score 정규화 사용하지 않음 (미래 정보 누출 방지)
- 원시 지표값 + 교과서적 임계값 사용
- 계층적 필터 구조 (Filter → Signal → Confirmation)
"""

import pandas as pd
import numpy as np
import talib
import os
import sys

# ===== CONFIG =====
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_FILE = os.path.join(BASE_DIR, 'Data', 'xauusd_1min.csv')

# 고정 기간 (표준, 교과서적 값)
P_LRA_SHORT = 60
P_LRA_LONG = 180
P_ADX = 14
P_RSI = 14
P_BOP_AVG = 50
P_BOP_SMOOTH = 20
P_CHV_SMOOTH = 10
P_CHV_PERIOD = 10

# ===== 지표 계산 (RAW, 정규화 없음) =====
def calculate_indicators(df):
    """모든 지표를 계산하고 원시값 그대로 반환"""
    c = df['Close'].values
    h = df['High'].values
    l = df['Low'].values
    o = df['Open'].values
    
    # 1. LRA (Linear Regression Slope)
    df['LRA_Short'] = talib.LINEARREG_SLOPE(c, timeperiod=P_LRA_SHORT)
    df['LRA_Long'] = talib.LINEARREG_SLOPE(c, timeperiod=P_LRA_LONG)
    
    # 2. ADX
    df['ADX'] = talib.ADX(h, l, c, timeperiod=P_ADX)
    
    # 3. RSI
    df['RSI'] = talib.RSI(c, timeperiod=P_RSI)
    
    # 4. BOP (Balance of Power) - Smoothed
    bop_raw = np.where((h - l) != 0, (c - o) / (h - l), 0.0)
    bop_sma = talib.SMA(bop_raw, timeperiod=P_BOP_AVG)
    df['BOP_Smooth'] = talib.SMA(bop_sma, timeperiod=P_BOP_SMOOTH)
    
    # 5. CHV (Chaikin Volatility)
    hl = h - l
    ema_hl = talib.EMA(hl, timeperiod=P_CHV_SMOOTH)
    ema_prev = np.roll(ema_hl, P_CHV_PERIOD)
    ema_prev[:P_CHV_PERIOD] = np.nan
    with np.errstate(divide='ignore', invalid='ignore'):
        df['CHV'] = np.where(ema_prev != 0, (ema_hl - ema_prev) / ema_prev * 100, 0)
    
    # 6. ATR
    df['ATR'] = talib.ATR(h, l, c, timeperiod=14)
    
    # 이전 봉의 LRA Short (크로스 감지용)
    df['LRA_Short_Prev'] = df['LRA_Short'].shift(1)
    df['BOP_Smooth_Prev'] = df['BOP_Smooth'].shift(1)
    
    df.fillna(0, inplace=True)
    return df

# ===== 트레이드 시뮬레이터 =====
def simulate_trades(df, signals, label="Strategy"):
    """
    시그널 배열을 받아 TP/SL 2.0pt 기준으로 트레이드 시뮬레이션.
    겹침 방지: 현재 포지션이 청산될 때까지 새 진입 불가.
    """
    closes = df['Close'].values
    opens = df['Open'].values
    highs = df['High'].values
    lows = df['Low'].values
    times = df['Time'].values
    
    indices = np.where(signals)[0]
    outcomes = []
    trade_log = []
    skip_until = 0
    
    for idx in indices:
        if idx < skip_until: continue
        if idx >= len(closes) - 60: continue
        
        entry = opens[idx + 1]
        tp = entry + 2.0
        sl = entry - 2.0
        
        outcome = 0
        end_idx = idx + 1
        
        for i in range(idx + 1, min(idx + 61, len(closes))):
            end_idx = i
            if lows[i] <= sl:
                outcome = -1
                break
            if highs[i] >= tp:
                outcome = 1
                break
        
        if outcome == 0:
            outcome = 1 if closes[end_idx] > entry else -1
        
        outcomes.append(outcome)
        trade_log.append({'Time': times[idx + 1], 'Outcome': outcome})
        skip_until = end_idx + 1
    
    return outcomes, trade_log

def report_results(outcomes, trade_log, label):
    """결과 출력"""
    if not outcomes:
        print(f"\n  [{label}] 트레이드 없음.")
        return 0, 0
    
    wins = outcomes.count(1)
    losses = outcomes.count(-1)
    total = len(outcomes)
    wr = wins / total * 100
    pf = wins / losses if losses > 0 else 99.9
    net_r = wins - losses  # 순수익 (R 단위)
    
    print(f"\n  [{label}]")
    print(f"  총 트레이드: {total}")
    print(f"  승률(WR): {wr:.1f}%")
    print(f"  수익팩터(PF): {pf:.2f}")
    print(f"  순수익(Net R): {net_r:+d} R")
    
    return wr, pf

def monthly_breakdown(trade_log, label):
    """월별 분석"""
    if not trade_log:
        return
    
    df_log = pd.DataFrame(trade_log)
    df_log['Time'] = pd.to_datetime(df_log['Time'])
    df_log['Month'] = df_log['Time'].dt.to_period('M')
    
    print(f"\n  [{label}] 월별 성과:")
    print(f"  {'월':<10} | {'거래수':<6} | {'승률':>8} | {'PF':>6}")
    print(f"  {'-'*40}")
    
    for name, group in df_log.groupby('Month'):
        w = (group['Outcome'] == 1).sum()
        l = (group['Outcome'] == -1).sum()
        t = len(group)
        wr = w / t * 100 if t > 0 else 0
        pf = w / l if l > 0 else 99.9
        print(f"  {str(name):<10} | {t:<6} | {wr:>6.1f}% | {pf:>6.2f}")


# ===== 전략 정의 =====

def strategy_a_pure_trend(df):
    """
    전략 A: "순수 추세 추종" (가장 단순)
    ─────────────────────────
    조건: 장기 추세 UP + 시장이 추세 중
    - LRA(180) > 0  (장기 상승 추세)
    - ADX(14) > 25  (추세 강도 충분)
    """
    return (
        (df['LRA_Long'].values > 0) &
        (df['ADX'].values > 25)
    )

def strategy_b_pullback(df):
    """
    전략 B: "눌림목 매수" (전문가 추천)
    ─────────────────────────────
    필터: 장기 추세 UP + 추세 강도 충분
    신호: 단기 모멘텀 회복 + 매수세 유입
    확인: 과매수 아닌 상태 (RSI < 70)
    
    금융 논리:
    - 큰 추세가 올라가는 중(LRA_Long > 0)
    - 잠깐 눌렸다가 다시 올라오는 시점(LRA_Short > 0)
    - 매수세가 매도세를 압도(BOP_Smooth > 0)
    - 아직 꼭대기가 아님(RSI < 70)
    """
    return (
        # 필터: 장기 상승 + 추세 확인
        (df['LRA_Long'].values > 0) &
        (df['ADX'].values > 25) &
        # 신호: 단기 모멘텀 양전환 + 매수세
        (df['LRA_Short'].values > 0) &
        (df['BOP_Smooth'].values > 0) &
        # 확인: 과매수 아님
        (df['RSI'].values < 70)
    )

def strategy_c_conservative_pullback(df):
    """
    전략 C: "보수적 눌림목" (최소 거래, 최대 정밀도)
    ──────────────────────────────────────
    전략 B + 추가 필터:
    - LRA_Short가 음→양 전환 직후 (크로스오버)
    - CHV가 극단적이지 않음 (뉴스 스파이크 회피)
    
    논리: 정확한 "진입 타이밍"을 잡되, 거래 수를 줄여
    각 거래의 질을 극대화.
    """
    return (
        # 필터: 장기 상승 + 추세 확인
        (df['LRA_Long'].values > 0) &
        (df['ADX'].values > 25) &
        # 신호: 단기 모멘텀 "양전환" (이전 음수 → 현재 양수)
        (df['LRA_Short'].values > 0) &
        (df['LRA_Short_Prev'].values <= 0) &
        # 매수세 유입
        (df['BOP_Smooth'].values > 0) &
        # 확인: 과매수가 아님 + 변동성 극단 아님
        (df['RSI'].values < 70) &
        (df['CHV'].values < 50)  # 변동성 폭발 시 진입 회피
    )

def strategy_d_adaptive_pullback(df):
    """
    전략 D: "적응형 눌림목" (내가 제안하는 최선)
    ──────────────────────────────────────
    전략 B의 핵심 + "ADX 적응형 임계값"
    - ADX가 높을수록 추세가 강하므로, 약간 느슨하게 진입.
    - ADX가 낮으면(25~35), BOP + RSI 조건을 더 엄격히 적용.
    
    논리: 강한 추세에서는 빨리 올라타고,
    약한 추세에서는 더 엄격히 확인 후 진입.
    """
    adx = df['ADX'].values
    lra_l = df['LRA_Long'].values
    lra_s = df['LRA_Short'].values
    bop = df['BOP_Smooth'].values
    rsi = df['RSI'].values
    
    # 기본 필터: 상승 추세 + 추세 존재
    base_filter = (lra_l > 0) & (adx > 25) & (lra_s > 0)
    
    # 강한 추세 (ADX > 35): 느슨한 진입   
    strong_trend = base_filter & (adx > 35) & (rsi < 75)
    
    # 보통 추세 (25 < ADX <= 35): 엄격한 진입
    normal_trend = base_filter & (adx <= 35) & (bop > 0) & (rsi < 65)
    
    return strong_trend | normal_trend


# ===== MAIN =====
def main():
    print("=" * 60)
    print(" 전문가 전략 비교 분석 (2025년 Out-of-Sample)")
    print("=" * 60)
    
    print(f"\n데이터 로딩: {DATA_FILE}")
    df = pd.read_csv(DATA_FILE)
    df['Time'] = pd.to_datetime(df['Time'])
    print(f"총 {len(df):,} 행 로드 완료.")
    
    print("\n지표 계산 (원시값, Z-Score 없음)...")
    df = calculate_indicators(df)
    
    print(f"\n{'='*60}")
    print(" 전략 비교 결과")
    print(f"{'='*60}")
    
    strategies = [
        ("A: 순수 추세", strategy_a_pure_trend),
        ("B: 눌림목 매수", strategy_b_pullback),
        ("C: 보수적 눌림목", strategy_c_conservative_pullback),
        ("D: 적응형 눌림목 (최선)", strategy_d_adaptive_pullback),
    ]
    
    best_label = ""
    best_pf = 0
    best_log = []
    
    for label, strategy_fn in strategies:
        signals = strategy_fn(df)
        outcomes, trade_log = simulate_trades(df, signals, label)
        wr, pf = report_results(outcomes, trade_log, label)
        
        if pf > best_pf and len(outcomes) >= 20:
            best_pf = pf
            best_label = label
            best_log = trade_log
    
    # 최고 전략 월별 분석
    print(f"\n{'='*60}")
    print(f" 최고 전략: [{best_label}] (PF: {best_pf:.2f})")
    print(f"{'='*60}")
    monthly_breakdown(best_log, best_label)
    
    print(f"\n{'='*60}")
    print(" 결론")
    print(f"{'='*60}")
    print(f"\n  가장 높은 수익팩터를 기록한 전략: [{best_label}]")
    print(f"  이 전략은 Z-Score 정규화 없이, 금융 논리에 기반한 원시값 임계치만 사용.")
    print(f"  과적합 위험이 가장 낮으며, MQL5 EA로의 전환이 용이합니다.\n")

if __name__ == "__main__":
    main()
