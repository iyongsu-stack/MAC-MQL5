"""
15_longterm_backtest.py
======================
2010~2025 장기 백테스트: 전문가 전략 (트레일링스탑 눌림목)
월 목표 수익률 50% 기준 분석
"""
import pandas as pd
import numpy as np
import talib
import os
import sys
import time

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_FILE = os.path.join(BASE_DIR, 'Data', 'XAUUSD_M1_201001040000_202602131038.csv')

# 고정 기간
P_LRA_SHORT = 60
P_LRA_LONG = 180
P_ADX = 14
P_RSI = 14
P_BOP_AVG = 50
P_BOP_SMOOTH = 20
P_ACCEL_LOOKBACK = 10  # 기울기 변화율 룩백

def load_data():
    """대용량 CSV 로드 (MT5 Export 형식)"""
    print(f"Loading {DATA_FILE}...")
    t0 = time.time()
    
    # MT5 Export: TAB-separated, <DATE> <TIME> <OPEN> <HIGH> <LOW> <CLOSE> <TICKVOL> <VOL> <SPREAD>
    df = pd.read_csv(DATA_FILE, sep='\t', parse_dates=False, encoding='utf-8')
    
    # 컬럼명 매핑
    df['Time'] = pd.to_datetime(df['<DATE>'].astype(str) + ' ' + df['<TIME>'].astype(str))
    df['Open'] = df['<OPEN>'].astype('float64')
    df['High'] = df['<HIGH>'].astype('float64')
    df['Low'] = df['<LOW>'].astype('float64')
    df['Close'] = df['<CLOSE>'].astype('float64')
    
    # 불필요한 컬럼 제거
    df = df[['Time', 'Open', 'High', 'Low', 'Close']].copy()
    df = df.sort_values('Time').reset_index(drop=True)
    
    elapsed = time.time() - t0
    print(f"  로드 완료: {len(df):,} 행, {elapsed:.1f}초")
    print(f"  기간: {df['Time'].iloc[0]} ~ {df['Time'].iloc[-1]}")
    return df

def calculate_indicators(df):
    """지표 계산"""
    print("지표 계산 중...")
    t0 = time.time()
    
    c = df['Close'].values.astype('float64')
    h = df['High'].values.astype('float64')
    l = df['Low'].values.astype('float64')
    o = df['Open'].values.astype('float64')
    
    df['LRA_Short'] = talib.LINEARREG_SLOPE(c, timeperiod=P_LRA_SHORT)
    df['LRA_Long'] = talib.LINEARREG_SLOPE(c, timeperiod=P_LRA_LONG)
    df['ADX'] = talib.ADX(h, l, c, timeperiod=P_ADX)
    df['RSI'] = talib.RSI(c, timeperiod=P_RSI)
    
    bop_raw = np.where((h - l) != 0, (c - o) / (h - l), 0.0)
    bop_sma = talib.SMA(bop_raw, timeperiod=P_BOP_AVG)
    df['BOP_Smooth'] = talib.SMA(bop_sma, timeperiod=P_BOP_SMOOTH)
    
    df.fillna(0, inplace=True)
    
    # 전체 지표 가속도 (N봉 변화율)
    N = P_ACCEL_LOOKBACK
    for col_name, source_col in [
        ('LRA_Accel_S', 'LRA_Short'),
        ('LRA_Accel_L', 'LRA_Long'),
        ('ADX_Accel',   'ADX'),
        ('BOP_Accel',   'BOP_Smooth'),
        ('RSI_Accel',   'RSI'),
    ]:
        src = df[source_col].values
        accel = np.full_like(src, 0.0)
        accel[N:] = src[N:] - src[:-N]
        df[col_name] = accel
    
    elapsed = time.time() - t0
    print(f"  지표 계산 완료: {elapsed:.1f}초")
    return df

def run_backtest(df):
    """트레일링스탑 눌림목 백테스트"""
    print("백테스트 실행 중...")
    t0 = time.time()
    
    # 진입 신호 (전체 지표 가속도 포함)
    signals = (
        (df['LRA_Long'].values > 0) &
        (df['ADX'].values > 25) &
        (df['LRA_Short'].values > 0) &
        (df['BOP_Smooth'].values > 0) &
        (df['RSI'].values < 70) &
        (df['LRA_Accel_S'].values > 0) &  # 기울기 가속
        (df['ADX_Accel'].values > 0) &    # 추세강도 강화
        (df['BOP_Accel'].values > 0)      # 매수압력 증가
    )
    
    opens = df['Open'].values
    highs = df['High'].values
    lows = df['Low'].values
    closes = df['Close'].values
    times = df['Time'].values
    
    indices = np.where(signals)[0]
    print(f"  신호 수: {len(indices):,} 개")
    
    results = []  # (time, r_result, year, month)
    skip_until = 0
    
    for idx in indices:
        if idx < skip_until: continue
        if idx >= len(closes) - 121: continue
        
        entry = opens[idx + 1]
        sl_pts = 2.0
        initial_sl = entry - sl_pts
        current_sl = initial_sl
        max_profit = 0.0
        trail_trigger = 1.0
        trail_distance = 1.0
        
        r_result = 0
        end_idx = idx + 1
        
        for i in range(idx + 1, min(idx + 121, len(closes))):
            end_idx = i
            if lows[i] <= current_sl:
                pnl = current_sl - entry
                r_result = pnl / sl_pts
                break
            
            bar_profit = highs[i] - entry
            if bar_profit > max_profit:
                max_profit = bar_profit
            
            if max_profit >= trail_trigger:
                new_sl = entry + (max_profit - trail_distance)
                if new_sl > current_sl:
                    current_sl = new_sl
        else:
            pnl = closes[end_idx] - entry
            r_result = pnl / sl_pts
        
        t = pd.Timestamp(times[idx + 1])
        results.append({
            'Time': t,
            'R': r_result,
            'Year': t.year,
            'Month': t.month,
            'YM': f"{t.year}-{t.month:02d}"
        })
        skip_until = end_idx + 1
    
    elapsed = time.time() - t0
    print(f"  백테스트 완료: {len(results):,} 거래, {elapsed:.1f}초")
    return pd.DataFrame(results)

def analyze_results(df_trades, target_monthly_pct=50.0):
    """월별 분석 및 50% 목표 수익률 환산"""
    
    # 연도별 월별 집계
    monthly = df_trades.groupby('YM').agg(
        Trades=('R', 'count'),
        Wins=('R', lambda x: (x > 0).sum()),
        NetR=('R', 'sum'),
        GrossProfit=('R', lambda x: x[x > 0].sum()),
        GrossLoss=('R', lambda x: abs(x[x < 0].sum()))
    ).reset_index()
    
    monthly['WR'] = monthly['Wins'] / monthly['Trades'] * 100
    monthly['PF'] = monthly['GrossProfit'] / monthly['GrossLoss'].replace(0, 0.0001)
    
    # 전체 통계
    total_r = df_trades['R'].sum()
    total_trades = len(df_trades)
    total_months = len(monthly)
    avg_monthly_r = total_r / total_months
    
    # 목표 수익률 환산
    risk_pct = target_monthly_pct / avg_monthly_r if avg_monthly_r > 0 else 0
    
    print(f"\n{'='*80}")
    print(f" 장기 백테스트 결과 (2010~2025)")
    print(f"{'='*80}")
    print(f"  총 거래: {total_trades:,}")
    print(f"  총 월 수: {total_months}")
    print(f"  총 Net R: {total_r:+,.1f} R")
    print(f"  월 평균 Net R: {avg_monthly_r:+.1f} R")
    print(f"  월 {target_monthly_pct:.0f}% 달성 위한 1R 리스크: {risk_pct:.4f}%")
    
    # 연도별 요약
    yearly = df_trades.groupby('Year').agg(
        Trades=('R', 'count'),
        Wins=('R', lambda x: (x > 0).sum()),
        NetR=('R', 'sum'),
        GrossProfit=('R', lambda x: x[x > 0].sum()),
        GrossLoss=('R', lambda x: abs(x[x < 0].sum()))
    ).reset_index()
    
    yearly['WR'] = yearly['Wins'] / yearly['Trades'] * 100
    yearly['PF'] = yearly['GrossProfit'] / yearly['GrossLoss'].replace(0, 0.0001)
    yearly['MonthlyRet'] = yearly['NetR'] * risk_pct / 12
    yearly['AnnualRet'] = yearly['NetR'] * risk_pct
    
    print(f"\n{'='*80}")
    print(f" 연도별 성과 (목표 월 {target_monthly_pct:.0f}%)")
    print(f"{'='*80}")
    print(f"  {'연도':<6} | {'거래수':>7} | {'승률':>7} | {'PF':>6} | {'Net R':>9} | {'연수익률':>9} | {'월평균':>8}")
    print(f"  {'-'*68}")
    
    for _, row in yearly.iterrows():
        print(f"  {int(row['Year']):<6} | {int(row['Trades']):>6}  | {row['WR']:>5.1f}% | {row['PF']:>5.2f} | {row['NetR']:>+8.1f} | {row['AnnualRet']:>+7.1f}% | {row['MonthlyRet']:>+6.1f}%")
    
    # 전체 MDD 계산
    monthly['Ret'] = monthly['NetR'] * risk_pct
    cumulative = np.cumsum(monthly['Ret'].values)
    running_max = np.maximum.accumulate(cumulative)
    drawdown = running_max - cumulative
    max_dd_idx = np.argmax(drawdown)
    max_dd = drawdown[max_dd_idx]
    
    # 전체 장중 MDD (R 단위)
    cum_r = np.cumsum(df_trades['R'].values)
    run_max_r = np.maximum.accumulate(cum_r)
    dd_r = run_max_r - cum_r
    max_dd_r = np.max(dd_r)
    intra_mdd_pct = max_dd_r * risk_pct
    
    print(f"  {'-'*68}")
    total_annual = total_r * risk_pct
    print(f"  {'합계':<6} | {total_trades:>6}  | {df_trades['R'].apply(lambda x: x > 0).mean()*100:>5.1f}% | {df_trades['R'][df_trades['R']>0].sum() / abs(df_trades['R'][df_trades['R']<0].sum()):>5.2f} | {total_r:>+8.1f} | {total_annual:>+7.1f}% | {total_annual/total_months*12/len(yearly):>+6.1f}%")
    
    print(f"\n  ⚠️  월간 MDD: {max_dd:.1f}% (발생 시점: {monthly.iloc[max_dd_idx]['YM']})")
    print(f"  ⚠️  장중 MDD: {intra_mdd_pct:.1f}% ({max_dd_r:.1f} R)")
    
    # $10,000 시나리오
    print(f"\n{'='*80}")
    print(f" $10,000 계좌 시나리오")
    print(f"{'='*80}")
    capital = 10000
    risk_usd = capital * risk_pct / 100
    print(f"  1R 리스크: ${risk_usd:.2f}")
    print(f"  적정 랏: {risk_usd/200:.4f} 랏")
    print(f"  월 평균 수익: ${capital * target_monthly_pct / 100:,.0f}")
    print(f"  연 평균 수익: ${capital * total_annual / len(yearly) / 100:,.0f}")
    print(f"  장중 MDD 손실: ${capital * intra_mdd_pct / 100:,.0f}")

def main():
    df = load_data()
    df = calculate_indicators(df)
    df_trades = run_backtest(df)
    
    if len(df_trades) > 0:
        analyze_results(df_trades, target_monthly_pct=50.0)
    else:
        print("거래 없음!")

if __name__ == "__main__":
    main()
