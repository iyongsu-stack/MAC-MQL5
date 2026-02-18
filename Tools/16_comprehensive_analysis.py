"""
16_comprehensive_analysis.py
=============================
종합 지표 분석: 8가지 분석을 한 번에 수행
1. 다이버전스 (Divergence)
2. 지표 조합 클러스터링 (Correlation Clustering)
3. 변동성 레짐 (Volatility Regime)
4. 지표 분포 (Distribution)
5. 세션별 성과 (Session)
6. R-Multiple 분포 (Exit Quality)
7. 리드/래그 (Lead-Lag)
8. ML 피처 중요도 (Feature Importance)

출력:
  - Files/analysis_*.png (차트 8장)
  - Files/Comprehensive_Analysis_Report.md (마크다운 보고서)
"""
import pandas as pd
import numpy as np
import talib
import os
import sys
import time
import warnings
warnings.filterwarnings('ignore')

# matplotlib 한글 폰트 설정
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
plt.rcParams['font.family'] = 'Malgun Gothic'
plt.rcParams['axes.unicode_minus'] = False

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_FILE = os.path.join(BASE_DIR, 'Data', 'XAUUSD_M1_201001040000_202602131038.csv')
OUTPUT_DIR = os.path.join(BASE_DIR, 'Files')

# ============================================================
# 파라미터
# ============================================================
P_LRA_SHORT    = 60
P_LRA_LONG     = 180
P_ADX          = 14
P_RSI          = 14
P_BOP_AVG      = 50
P_BOP_SMOOTH   = 20
P_ACCEL_LOOKBACK = 10
SL_PTS         = 2.0
TRAIL_TRIGGER  = 1.0
TRAIL_DISTANCE = 1.0
MAX_BARS       = 120

# ============================================================
# 데이터 로드 + 지표 계산 (15_longterm_backtest.py 호환)
# ============================================================
def load_data():
    """대용량 CSV 로드"""
    print(f"Loading {DATA_FILE}...")
    t0 = time.time()
    df = pd.read_csv(DATA_FILE, sep='\t', parse_dates=False, encoding='utf-8')
    df['Time'] = pd.to_datetime(df['<DATE>'].astype(str) + ' ' + df['<TIME>'].astype(str))
    df['Open']  = df['<OPEN>'].astype('float64')
    df['High']  = df['<HIGH>'].astype('float64')
    df['Low']   = df['<LOW>'].astype('float64')
    df['Close'] = df['<CLOSE>'].astype('float64')
    df = df[['Time', 'Open', 'High', 'Low', 'Close']].copy()
    df = df.sort_values('Time').reset_index(drop=True)
    print(f"  로드 완료: {len(df):,} 행, {time.time()-t0:.1f}초")
    return df

def calculate_indicators(df):
    """전체 지표 + 가속도 계산"""
    print("지표 계산 중...")
    t0 = time.time()
    c = df['Close'].values.astype('float64')
    h = df['High'].values.astype('float64')
    l = df['Low'].values.astype('float64')
    o = df['Open'].values.astype('float64')
    
    df['LRA_Short'] = talib.LINEARREG_SLOPE(c, timeperiod=P_LRA_SHORT)
    df['LRA_Long']  = talib.LINEARREG_SLOPE(c, timeperiod=P_LRA_LONG)
    df['ADX']       = talib.ADX(h, l, c, timeperiod=P_ADX)
    df['RSI']       = talib.RSI(c, timeperiod=P_RSI)
    df['ATR']       = talib.ATR(h, l, c, timeperiod=P_ADX)
    
    bop_raw = np.where((h - l) != 0, (c - o) / (h - l), 0.0)
    bop_sma = talib.SMA(bop_raw, timeperiod=P_BOP_AVG)
    df['BOP_Smooth'] = talib.SMA(bop_sma, timeperiod=P_BOP_SMOOTH)
    
    df.fillna(0, inplace=True)
    
    # 가속도
    N = P_ACCEL_LOOKBACK
    for col_name, src_col in [
        ('LRA_Accel_S', 'LRA_Short'), ('LRA_Accel_L', 'LRA_Long'),
        ('ADX_Accel', 'ADX'), ('BOP_Accel', 'BOP_Smooth'), ('RSI_Accel', 'RSI'),
    ]:
        src = df[src_col].values
        accel = np.full_like(src, 0.0)
        accel[N:] = src[N:] - src[:-N]
        df[col_name] = accel
    
    # 시간 파생 변수
    df['Hour'] = df['Time'].dt.hour
    df['Year'] = df['Time'].dt.year
    
    print(f"  지표 계산 완료: {time.time()-t0:.1f}초")
    return df

def run_backtest_with_details(df):
    """백테스트 실행 (상세 정보 포함: 지표값, 세션, R결과)"""
    print("백테스트 실행 중 (상세 모드)...")
    t0 = time.time()
    
    signals = (
        (df['LRA_Long'].values > 0) &
        (df['ADX'].values > 25) &
        (df['LRA_Short'].values > 0) &
        (df['BOP_Smooth'].values > 0) &
        (df['RSI'].values < 70)
    )
    # 참고: 가속 필터는 여기서 적용하지 않음 (분석용 → 필터 없이 모든 거래 관찰)
    
    opens  = df['Open'].values
    highs  = df['High'].values
    lows   = df['Low'].values
    closes = df['Close'].values
    times  = df['Time'].values
    
    indices = np.where(signals)[0]
    print(f"  신호 수: {len(indices):,} 개")
    
    results = []
    skip_until = 0
    
    for idx in indices:
        if idx < skip_until: continue
        if idx >= len(closes) - 121: continue
        
        entry = opens[idx + 1]
        initial_sl = entry - SL_PTS
        current_sl = initial_sl
        max_profit = 0.0
        r_result = 0
        end_idx = idx + 1
        exit_type = 'timeout'
        
        for i in range(idx + 1, min(idx + 121, len(closes))):
            end_idx = i
            if lows[i] <= current_sl:
                pnl = current_sl - entry
                r_result = pnl / SL_PTS
                exit_type = 'sl' if max_profit < TRAIL_TRIGGER else 'trail'
                break
            bar_profit = highs[i] - entry
            if bar_profit > max_profit:
                max_profit = bar_profit
            if max_profit >= TRAIL_TRIGGER:
                new_sl = entry + (max_profit - TRAIL_DISTANCE)
                if new_sl > current_sl:
                    current_sl = new_sl
        else:
            pnl = closes[end_idx] - entry
            r_result = pnl / SL_PTS
        
        t = pd.Timestamp(times[idx + 1])
        results.append({
            'Time': t, 'R': r_result, 'Year': t.year, 'Month': t.month,
            'Hour': t.hour, 'ExitType': exit_type,
            'LRA_Short': df['LRA_Short'].iloc[idx],
            'LRA_Long': df['LRA_Long'].iloc[idx],
            'ADX': df['ADX'].iloc[idx],
            'RSI': df['RSI'].iloc[idx],
            'BOP_Smooth': df['BOP_Smooth'].iloc[idx],
            'ATR': df['ATR'].iloc[idx],
            'LRA_Accel_S': df['LRA_Accel_S'].iloc[idx],
            'ADX_Accel': df['ADX_Accel'].iloc[idx],
            'BOP_Accel': df['BOP_Accel'].iloc[idx],
            'RSI_Accel': df['RSI_Accel'].iloc[idx],
            'MaxProfit_R': max_profit / SL_PTS,
            'Bars_Held': end_idx - idx,
        })
        skip_until = end_idx + 1
    
    elapsed = time.time() - t0
    print(f"  백테스트 완료: {len(results):,} 거래, {elapsed:.1f}초")
    return pd.DataFrame(results)

# ============================================================
# 분석 1: 다이버전스 (Divergence)
# ============================================================
def analysis_1_divergence(df, trades):
    """가격과 지표의 괴리 분석"""
    print("\n[분석 1] 다이버전스 분석...")
    
    # 가격 고점/저점 vs LRA/RSI 괴리 빈도
    # 50봉 윈도우에서 로컬 최고가 vs LRA_Short 방향 비교
    win = 50
    price = df['Close'].values
    lra = df['LRA_Short'].values
    rsi = df['RSI'].values
    
    # 롤링 최대/최소 인덱스
    price_max = pd.Series(price).rolling(win, center=True).max().values
    price_min = pd.Series(price).rolling(win, center=True).min().values
    
    # 베어리시 다이버전스: 가격 신고 + LRA 하락
    is_local_high = (price == price_max) & (~np.isnan(price_max))
    bearish_div = is_local_high & (lra < 0)
    
    # 불리시 다이버전스: 가격 신저 + LRA 상승
    is_local_low = (price == price_min) & (~np.isnan(price_min))
    bullish_div = is_local_low & (lra > 0)
    
    report = {
        'bearish_count': int(bearish_div.sum()),
        'bullish_count': int(bullish_div.sum()),
        'total_bars': len(df),
    }
    
    # 승리 거래에서 다이버전스 비율
    win_trades = trades[trades['R'] > 0]
    lose_trades = trades[trades['R'] <= 0]
    win_rsi_above70 = (win_trades['RSI'] > 65).sum()
    lose_rsi_above70 = (lose_trades['RSI'] > 65).sum()
    
    report['win_high_rsi_pct'] = win_rsi_above70 / max(len(win_trades), 1) * 100
    report['lose_high_rsi_pct'] = lose_rsi_above70 / max(len(lose_trades), 1) * 100
    
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    axes[0].bar(['베어리시', '불리시'], [report['bearish_count'], report['bullish_count']], 
                color=['#ff6b6b', '#51cf66'])
    axes[0].set_title('다이버전스 발생 빈도 (50봉 윈도우)')
    axes[0].set_ylabel('발생 횟수')
    
    axes[1].bar(['승리(RSI>65)', '패배(RSI>65)'], 
                [report['win_high_rsi_pct'], report['lose_high_rsi_pct']],
                color=['#51cf66', '#ff6b6b'])
    axes[1].set_title('RSI 고값 진입의 승패 비율 (%)')
    axes[1].set_ylabel('%')
    
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'analysis_1_divergence.png'), dpi=150)
    plt.close()
    
    print(f"  베어리시: {report['bearish_count']}, 불리시: {report['bullish_count']}")
    return report

# ============================================================
# 분석 2: 지표 조합 클러스터링
# ============================================================
def analysis_2_clustering(trades):
    """지표 방향 조합별 승률/PF 분석"""
    print("\n[분석 2] 지표 조합 클러스터링...")
    
    # 각 지표의 방향 (양수=1, 음수=0)
    trades = trades.copy()
    trades['LRA_dir'] = (trades['LRA_Accel_S'] > 0).astype(int)
    trades['ADX_dir'] = (trades['ADX_Accel'] > 0).astype(int)
    trades['BOP_dir'] = (trades['BOP_Accel'] > 0).astype(int)
    
    # 조합 생성 (2^3 = 8개)
    trades['Combo'] = (trades['LRA_dir'].astype(str) + 
                       trades['ADX_dir'].astype(str) + 
                       trades['BOP_dir'].astype(str))
    
    combo_names = {
        '111': 'LRA↑ ADX↑ BOP↑', '110': 'LRA↑ ADX↑ BOP↓',
        '101': 'LRA↑ ADX↓ BOP↑', '100': 'LRA↑ ADX↓ BOP↓',
        '011': 'LRA↓ ADX↑ BOP↑', '010': 'LRA↓ ADX↑ BOP↓',
        '001': 'LRA↓ ADX↓ BOP↑', '000': 'LRA↓ ADX↓ BOP↓',
    }
    
    rows = []
    for combo, group in trades.groupby('Combo'):
        wins = (group['R'] > 0).sum()
        gross_p = group['R'][group['R'] > 0].sum()
        gross_l = abs(group['R'][group['R'] < 0].sum())
        pf = gross_p / max(gross_l, 0.001)
        rows.append({
            'Combo': combo_names.get(combo, combo),
            'Trades': len(group),
            'WinRate': wins / max(len(group), 1) * 100,
            'PF': round(pf, 2),
            'NetR': round(group['R'].sum(), 1),
        })
    
    df_combo = pd.DataFrame(rows).sort_values('PF', ascending=False)
    
    fig, ax = plt.subplots(figsize=(12, 6))
    colors = ['#51cf66' if pf > 1.0 else '#ff6b6b' for pf in df_combo['PF']]
    bars = ax.barh(df_combo['Combo'], df_combo['PF'], color=colors)
    ax.axvline(x=1.0, color='gray', linestyle='--', alpha=0.7)
    ax.set_xlabel('Profit Factor')
    ax.set_title('가속도 조합별 Profit Factor')
    for bar, nr in zip(bars, df_combo['NetR'].values):
        ax.text(bar.get_width() + 0.02, bar.get_y() + bar.get_height()/2, 
                f'{nr:+.0f}R', va='center', fontsize=9)
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'analysis_2_clustering.png'), dpi=150)
    plt.close()
    
    print(df_combo.to_string(index=False))
    return df_combo

# ============================================================
# 분석 3: 변동성 레짐
# ============================================================
def analysis_3_regime(trades):
    """ATR 기반 변동성 3구간별 성과"""
    print("\n[분석 3] 변동성 레짐 분석...")
    
    trades = trades.copy()
    atr_33 = trades['ATR'].quantile(0.33)
    atr_66 = trades['ATR'].quantile(0.66)
    
    def classify(atr):
        if atr <= atr_33: return '저변동'
        elif atr <= atr_66: return '보통'
        else: return '고변동'
    
    trades['Regime'] = trades['ATR'].apply(classify)
    
    rows = []
    for regime in ['저변동', '보통', '고변동']:
        grp = trades[trades['Regime'] == regime]
        if len(grp) == 0: continue
        wins = (grp['R'] > 0).sum()
        gross_p = grp['R'][grp['R'] > 0].sum()
        gross_l = abs(grp['R'][grp['R'] < 0].sum())
        pf = gross_p / max(gross_l, 0.001)
        rows.append({
            'Regime': regime, 'Trades': len(grp),
            'WinRate': round(wins / len(grp) * 100, 1),
            'PF': round(pf, 2), 'NetR': round(grp['R'].sum(), 1),
            'ATR_Range': f"{grp['ATR'].min():.2f}~{grp['ATR'].max():.2f}",
        })
    
    df_regime = pd.DataFrame(rows)
    
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    regimes = df_regime['Regime'].values
    
    axes[0].bar(regimes, df_regime['WinRate'], color=['#74c0fc', '#ffd43b', '#ff6b6b'])
    axes[0].set_title('레짐별 승률 (%)')
    axes[0].set_ylabel('승률 (%)')
    
    axes[1].bar(regimes, df_regime['PF'], color=['#74c0fc', '#ffd43b', '#ff6b6b'])
    axes[1].axhline(y=1.0, color='gray', linestyle='--')
    axes[1].set_title('레짐별 Profit Factor')
    
    axes[2].bar(regimes, df_regime['NetR'], color=['#74c0fc', '#ffd43b', '#ff6b6b'])
    axes[2].set_title('레짐별 Net R')
    axes[2].set_ylabel('R')
    
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'analysis_3_regime.png'), dpi=150)
    plt.close()
    
    print(df_regime.to_string(index=False))
    return df_regime

# ============================================================
# 분석 4: 지표 분포 (Distribution)
# ============================================================
def analysis_4_distribution(trades):
    """승리/패배 거래별 각 지표 분포 비교"""
    print("\n[분석 4] 지표 분포 분석...")
    
    indicators = ['LRA_Short', 'ADX', 'RSI', 'BOP_Smooth', 'ATR']
    win = trades[trades['R'] > 0]
    lose = trades[trades['R'] <= 0]
    
    fig, axes = plt.subplots(2, 3, figsize=(16, 10))
    axes = axes.flatten()
    
    stats = {}
    for i, col in enumerate(indicators):
        ax = axes[i]
        ax.hist(win[col], bins=50, alpha=0.6, label=f'승리({len(win)})', color='#51cf66', density=True)
        ax.hist(lose[col], bins=50, alpha=0.6, label=f'패배({len(lose)})', color='#ff6b6b', density=True)
        ax.set_title(f'{col} 분포')
        ax.legend(fontsize=8)
        
        stats[col] = {
            'win_mean': round(win[col].mean(), 4),
            'lose_mean': round(lose[col].mean(), 4),
            'win_median': round(win[col].median(), 4),
            'lose_median': round(lose[col].median(), 4),
            'optimal_zone': f"{win[col].quantile(0.25):.4f} ~ {win[col].quantile(0.75):.4f}",
        }
    
    # 마지막 칸에 요약 테이블
    axes[-1].axis('off')
    cell_text = [[col, f"{s['win_mean']:.3f}", f"{s['lose_mean']:.3f}", s['optimal_zone']] 
                 for col, s in stats.items()]
    table = axes[-1].table(cellText=cell_text, 
                           colLabels=['지표', '승리 평균', '패배 평균', '최적 범위(Q1~Q3)'],
                           loc='center', cellLoc='center')
    table.auto_set_font_size(False)
    table.set_fontsize(9)
    table.scale(1.2, 1.5)
    axes[-1].set_title('지표별 승패 통계 요약')
    
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'analysis_4_distribution.png'), dpi=150)
    plt.close()
    
    return stats

# ============================================================
# 분석 5: 세션별 성과
# ============================================================
def analysis_5_session(trades):
    """시간대별 성과 분석"""
    print("\n[분석 5] 세션별 성과 분석...")
    
    trades = trades.copy()
    
    def get_session(hour):
        if 0 <= hour < 8: return '아시안 (0~8)'
        elif 8 <= hour < 13: return '런던 (8~13)'
        elif 13 <= hour < 17: return '런던+뉴욕 (13~17)'
        else: return '뉴욕 후반 (17~24)'
    
    trades['Session'] = trades['Hour'].apply(get_session)
    
    rows = []
    for session in ['아시안 (0~8)', '런던 (8~13)', '런던+뉴욕 (13~17)', '뉴욕 후반 (17~24)']:
        grp = trades[trades['Session'] == session]
        if len(grp) == 0: continue
        wins = (grp['R'] > 0).sum()
        gross_p = grp['R'][grp['R'] > 0].sum()
        gross_l = abs(grp['R'][grp['R'] < 0].sum())
        pf = gross_p / max(gross_l, 0.001)
        rows.append({
            'Session': session, 'Trades': len(grp),
            'WinRate': round(wins / len(grp) * 100, 1),
            'PF': round(pf, 2), 'NetR': round(grp['R'].sum(), 1),
            'AvgR': round(grp['R'].mean(), 3),
        })
    
    df_session = pd.DataFrame(rows)
    
    # 시간별 상세 (24시간)
    hourly = trades.groupby('Hour').agg(
        Trades=('R', 'count'), WR=('R', lambda x: (x > 0).mean() * 100),
        NetR=('R', 'sum'), AvgR=('R', 'mean')
    ).reset_index()
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    
    # 세션별 PF
    colors = ['#74c0fc', '#ffd43b', '#51cf66', '#ff922b']
    axes[0, 0].bar(df_session['Session'], df_session['PF'], color=colors)
    axes[0, 0].axhline(y=1.0, color='gray', linestyle='--')
    axes[0, 0].set_title('세션별 Profit Factor')
    axes[0, 0].tick_params(axis='x', rotation=15)
    
    # 세션별 승률
    axes[0, 1].bar(df_session['Session'], df_session['WinRate'], color=colors)
    axes[0, 1].set_title('세션별 승률 (%)')
    axes[0, 1].tick_params(axis='x', rotation=15)
    
    # 시간별 Net R
    bar_colors = ['#51cf66' if nr > 0 else '#ff6b6b' for nr in hourly['NetR']]
    axes[1, 0].bar(hourly['Hour'], hourly['NetR'], color=bar_colors)
    axes[1, 0].set_title('시간별 Net R (UTC)')
    axes[1, 0].set_xlabel('시간 (UTC)')
    
    # 시간별 승률
    axes[1, 1].plot(hourly['Hour'], hourly['WR'], 'o-', color='#339af0')
    axes[1, 1].axhline(y=60, color='gray', linestyle='--', alpha=0.5)
    axes[1, 1].set_title('시간별 승률 (%)')
    axes[1, 1].set_xlabel('시간 (UTC)')
    axes[1, 1].set_ylabel('승률 (%)')
    
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'analysis_5_session.png'), dpi=150)
    plt.close()
    
    print(df_session.to_string(index=False))
    return df_session

# ============================================================
# 분석 6: R-Multiple 분포
# ============================================================
def analysis_6_rmultiple(trades):
    """R-Multiple 분포 + 청산 품질"""
    print("\n[분석 6] R-Multiple 분포 분석...")
    
    trades = trades.copy()
    
    # R 범위별 분류
    def classify_r(r):
        if r <= -0.9: return '풀스탑 (-1R)'
        elif r <= 0: return '부분손실 (-0.9~0)'
        elif r <= 0.5: return 'BE근처 (0~0.5R)'
        elif r <= 1.0: return '소승 (0.5~1R)'
        elif r <= 3.0: return '중승 (1~3R)'
        else: return '대승 (3R+)'
    
    trades['R_Category'] = trades['R'].apply(classify_r)
    r_cats = ['풀스탑 (-1R)', '부분손실 (-0.9~0)', 'BE근처 (0~0.5R)',
              '소승 (0.5~1R)', '중승 (1~3R)', '대승 (3R+)']
    
    cat_counts = trades['R_Category'].value_counts()
    cat_pcts = {cat: cat_counts.get(cat, 0) / len(trades) * 100 for cat in r_cats}
    
    # 청산 유형별 분석
    exit_stats = trades.groupby('ExitType').agg(
        Count=('R', 'count'), AvgR=('R', 'mean'), NetR=('R', 'sum')
    ).reset_index()
    
    # 최대 미실현 수익 vs 실현 수익
    trades['CaptureRate'] = np.where(
        trades['MaxProfit_R'] > 0,
        trades['R'] / trades['MaxProfit_R'] * 100, 0
    )
    avg_capture = trades[trades['MaxProfit_R'] > 0.5]['CaptureRate'].mean()
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    
    # R 히스토그램
    axes[0, 0].hist(trades['R'], bins=80, color='#339af0', edgecolor='white', alpha=0.8)
    axes[0, 0].axvline(x=0, color='red', linestyle='--')
    axes[0, 0].set_title(f'R-Multiple 분포 (평균: {trades["R"].mean():.3f}R)')
    axes[0, 0].set_xlabel('R')
    
    # R 카테고리 비율
    cat_vals = [cat_pcts.get(c, 0) for c in r_cats]
    colors = ['#ff6b6b', '#ffa8a8', '#ffe066', '#a9e34b', '#51cf66', '#2b8a3e']
    axes[0, 1].barh(r_cats, cat_vals, color=colors)
    for i, v in enumerate(cat_vals):
        axes[0, 1].text(v + 0.5, i, f'{v:.1f}%', va='center', fontsize=9)
    axes[0, 1].set_title('R-Multiple 카테고리 비율')
    axes[0, 1].set_xlabel('%')
    
    # 최대 수익 vs 실현 수익 산점도 (샘플)
    sample = trades.sample(min(5000, len(trades)), random_state=42)
    axes[1, 0].scatter(sample['MaxProfit_R'], sample['R'], alpha=0.2, s=3, color='#339af0')
    axes[1, 0].plot([0, 10], [0, 10], 'r--', alpha=0.3, label='100% 캡처')
    axes[1, 0].set_title(f'최대수익 vs 실현수익 (캡처율: {avg_capture:.0f}%)')
    axes[1, 0].set_xlabel('최대 미실현 수익 (R)')
    axes[1, 0].set_ylabel('실현 수익 (R)')
    axes[1, 0].legend()
    
    # 보유 기간 vs R
    axes[1, 1].scatter(sample['Bars_Held'], sample['R'], alpha=0.2, s=3, color='#51cf66')
    axes[1, 1].set_title('보유 기간 vs R')
    axes[1, 1].set_xlabel('보유 기간 (봉)')
    axes[1, 1].set_ylabel('R')
    
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'analysis_6_rmultiple.png'), dpi=150)
    plt.close()
    
    report = {'categories': cat_pcts, 'avg_capture_rate': round(avg_capture, 1),
              'exit_stats': exit_stats.to_dict('records')}
    print(f"  평균 캡처율: {avg_capture:.1f}%")
    return report

# ============================================================
# 분석 7: 리드/래그 (Lead-Lag)
# ============================================================
def analysis_7_leadlag(df):
    """교차상관으로 선행 지표 순위 결정"""
    print("\n[분석 7] 리드/래그 분석...")
    
    # 미래 N봉 수익률
    future_return = df['Close'].pct_change(30).shift(-30).values
    
    indicators = {
        'LRA_Short': df['LRA_Short'].values,
        'LRA_Long': df['LRA_Long'].values,
        'ADX': df['ADX'].values,
        'RSI': df['RSI'].values,
        'BOP_Smooth': df['BOP_Smooth'].values,
        'LRA_Accel_S': df['LRA_Accel_S'].values,
        'ADX_Accel': df['ADX_Accel'].values,
        'BOP_Accel': df['BOP_Accel'].values,
    }
    
    max_lag = 30  # ±30봉
    lead_results = {}
    
    for name, values in indicators.items():
        # 유효 범위만 사용
        valid = ~(np.isnan(values) | np.isnan(future_return))
        if valid.sum() < 1000: continue
        
        v = values[valid]
        fr = future_return[valid]
        
        # 교차상관 계산
        correlations = []
        for lag in range(-max_lag, max_lag + 1):
            if lag < 0:
                corr = np.corrcoef(v[:lag], fr[-lag:])[0, 1]
            elif lag > 0:
                corr = np.corrcoef(v[lag:], fr[:-lag])[0, 1]
            else:
                corr = np.corrcoef(v, fr)[0, 1]
            correlations.append(corr if not np.isnan(corr) else 0)
        
        best_lag = np.argmax(np.abs(correlations)) - max_lag
        best_corr = correlations[best_lag + max_lag]
        lead_results[name] = {
            'best_lag': best_lag,
            'best_corr': round(best_corr, 4),
            'correlations': correlations,
        }
    
    # 시각화
    fig, axes = plt.subplots(2, 4, figsize=(18, 8))
    axes = axes.flatten()
    lags = list(range(-max_lag, max_lag + 1))
    
    for i, (name, res) in enumerate(lead_results.items()):
        if i >= 8: break
        ax = axes[i]
        ax.plot(lags, res['correlations'], color='#339af0')
        ax.axvline(x=0, color='gray', linestyle='--', alpha=0.5)
        ax.axvline(x=res['best_lag'], color='red', linestyle='-', alpha=0.7)
        ax.set_title(f"{name}\n최적 래그={res['best_lag']}, r={res['best_corr']:.3f}", fontsize=9)
        ax.set_xlabel('래그 (봉)')
        if i % 4 == 0: ax.set_ylabel('상관계수')
    
    plt.suptitle('지표별 교차상관 (미래 30봉 수익률 기준)', fontsize=12, y=1.02)
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'analysis_7_leadlag.png'), dpi=150, bbox_inches='tight')
    plt.close()
    
    # 선행성 순위
    ranking = sorted(lead_results.items(), key=lambda x: abs(x[1]['best_corr']), reverse=True)
    print("  선행 지표 순위:")
    for name, res in ranking:
        direction = "선행" if res['best_lag'] < 0 else ("동시" if res['best_lag'] == 0 else "후행")
        print(f"    {name}: {direction} {abs(res['best_lag'])}봉, r={res['best_corr']:.4f}")
    
    return lead_results

# ============================================================
# 분석 8: ML 피처 중요도
# ============================================================
def analysis_8_feature_importance(trades):
    """Random Forest로 피처 중요도 분석"""
    print("\n[분석 8] ML 피처 중요도 분석...")
    
    feature_cols = ['LRA_Short', 'LRA_Long', 'ADX', 'RSI', 'BOP_Smooth', 'ATR',
                    'LRA_Accel_S', 'ADX_Accel', 'BOP_Accel', 'RSI_Accel', 'Hour']
    
    X = trades[feature_cols].values
    y = (trades['R'] > 0).astype(int).values  # 승/패 이진분류
    
    # NaN/Inf 처리
    X = np.nan_to_num(X, nan=0, posinf=0, neginf=0)
    
    try:
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.model_selection import cross_val_score
        
        rf = RandomForestClassifier(n_estimators=200, max_depth=8, random_state=42, n_jobs=-1)
        rf.fit(X, y)
        
        importances = rf.feature_importances_
        cv_score = cross_val_score(rf, X, y, cv=5, scoring='accuracy').mean()
        
        # 정렬
        idx = np.argsort(importances)[::-1]
        sorted_names = [feature_cols[i] for i in idx]
        sorted_imp = importances[idx]
        
        fig, axes = plt.subplots(1, 2, figsize=(14, 6))
        
        colors = plt.cm.RdYlGn(np.linspace(0.3, 0.9, len(sorted_names)))
        axes[0].barh(sorted_names[::-1], sorted_imp[::-1], color=colors)
        axes[0].set_title(f'Feature Importance (CV 정확도: {cv_score:.2%})')
        axes[0].set_xlabel('중요도')
        
        # 상위 3개 피처 vs R 관계
        top3 = sorted_names[:3]
        for i, col in enumerate(top3):
            ax = axes[1] if i == 0 else axes[1]
        
        # 상위 피처 히스토그램 (승/패 분리)
        top_feat = sorted_names[0]
        win_vals = trades[trades['R'] > 0][top_feat]
        lose_vals = trades[trades['R'] <= 0][top_feat]
        axes[1].hist(win_vals, bins=40, alpha=0.6, label='승리', color='#51cf66', density=True)
        axes[1].hist(lose_vals, bins=40, alpha=0.6, label='패배', color='#ff6b6b', density=True)
        axes[1].set_title(f'최중요 피처: {top_feat} (승/패 분포)')
        axes[1].legend()
        
        plt.tight_layout()
        plt.savefig(os.path.join(OUTPUT_DIR, 'analysis_8_feature_importance.png'), dpi=150)
        plt.close()
        
        report = {
            'cv_accuracy': round(cv_score, 4),
            'ranking': list(zip(sorted_names, [round(x, 4) for x in sorted_imp])),
        }
        print(f"  CV 정확도: {cv_score:.2%}")
        print(f"  Top 3: {sorted_names[:3]}")
        return report
        
    except ImportError:
        print("  ⚠️ scikit-learn 미설치. pip install scikit-learn 필요")
        return {'error': 'scikit-learn not installed'}

# ============================================================
# 리포트 생성
# ============================================================
def generate_report(results):
    """마크다운 종합 보고서 생성"""
    print("\n보고서 생성 중...")
    
    lines = [
        "# 🔬 종합 지표 분석 보고서",
        f"\n**생성일**: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M')}",
        f"**데이터**: XAUUSD M1, 2010~2026",
        "",
    ]
    
    # 분석 2: 클러스터링
    if 'clustering' in results and results['clustering'] is not None:
        lines.append("## 1. 지표 조합 클러스터링")
        lines.append("![클러스터링](analysis_2_clustering.png)")
        df = results['clustering']
        lines.append("| 조합 | 거래수 | 승률 | PF | Net R |")
        lines.append("|:---|---:|---:|---:|---:|")
        for _, r in df.iterrows():
            lines.append(f"| {r['Combo']} | {r['Trades']} | {r['WinRate']:.1f}% | {r['PF']} | {r['NetR']:+.1f} |")
        lines.append("")
    
    # 분석 3: 레짐
    if 'regime' in results and results['regime'] is not None:
        lines.append("## 2. 변동성 레짐")
        lines.append("![레짐](analysis_3_regime.png)")
        df = results['regime']
        lines.append("| 레짐 | 거래수 | 승률 | PF | Net R | ATR 범위 |")
        lines.append("|:---|---:|---:|---:|---:|:---|")
        for _, r in df.iterrows():
            lines.append(f"| {r['Regime']} | {r['Trades']} | {r['WinRate']}% | {r['PF']} | {r['NetR']:+.1f} | {r['ATR_Range']} |")
        lines.append("")
    
    # 분석 5: 세션
    if 'session' in results and results['session'] is not None:
        lines.append("## 3. 세션별 성과")
        lines.append("![세션](analysis_5_session.png)")
        df = results['session']
        lines.append("| 세션 | 거래수 | 승률 | PF | Net R |")
        lines.append("|:---|---:|---:|---:|---:|")
        for _, r in df.iterrows():
            lines.append(f"| {r['Session']} | {r['Trades']} | {r['WinRate']}% | {r['PF']} | {r['NetR']:+.1f} |")
        lines.append("")
    
    # 분석 6: R-Multiple
    if 'rmultiple' in results:
        lines.append("## 4. R-Multiple 분포")
        lines.append("![R-Multiple](analysis_6_rmultiple.png)")
        rep = results['rmultiple']
        lines.append(f"- 평균 캡처율: **{rep.get('avg_capture_rate', 'N/A')}%**")
        lines.append("")
    
    # 분석 8: 피처 중요도
    if 'feature_importance' in results and 'ranking' in results.get('feature_importance', {}):
        lines.append("## 5. ML 피처 중요도")
        lines.append("![피처중요도](analysis_8_feature_importance.png)")
        rep = results['feature_importance']
        lines.append(f"- CV 정확도: **{rep['cv_accuracy']:.2%}**")
        lines.append("| 순위 | 피처 | 중요도 |")
        lines.append("|:---|:---|---:|")
        for i, (name, imp) in enumerate(rep['ranking'], 1):
            lines.append(f"| {i} | {name} | {imp:.4f} |")
        lines.append("")
    
    # 이미지 목록
    lines.append("## 전체 차트 목록")
    for i in range(1, 9):
        names = ['다이버전스', '클러스터링', '변동성레짐', '지표분포',
                 '세션분석', 'R-Multiple', '리드래그', '피처중요도']
        lines.append(f"- `analysis_{i}_{['divergence','clustering','regime','distribution','session','rmultiple','leadlag','feature_importance'][i-1]}.png` — {names[i-1]}")
    
    report_path = os.path.join(OUTPUT_DIR, 'Comprehensive_Analysis_Report.md')
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    
    print(f"  보고서 저장: {report_path}")

# ============================================================
# MAIN
# ============================================================
def main():
    total_start = time.time()
    print("=" * 60)
    print("🔬 종합 지표 분석 (8가지) 시작")
    print("=" * 60)
    
    # 데이터 로드 + 지표 계산
    df = load_data()
    df = calculate_indicators(df)
    
    # 백테스트 (상세 모드)
    trades = run_backtest_with_details(df)
    
    if len(trades) == 0:
        print("⚠️ 거래가 없습니다. 분석을 중단합니다.")
        return
    
    results = {}
    
    # 8가지 분석 실행
    results['divergence'] = analysis_1_divergence(df, trades)
    results['clustering'] = analysis_2_clustering(trades)
    results['regime'] = analysis_3_regime(trades)
    results['distribution'] = analysis_4_distribution(trades)
    results['session'] = analysis_5_session(trades)
    results['rmultiple'] = analysis_6_rmultiple(trades)
    results['leadlag'] = analysis_7_leadlag(df)
    results['feature_importance'] = analysis_8_feature_importance(trades)
    
    # 종합 보고서 생성
    generate_report(results)
    
    elapsed = time.time() - total_start
    print(f"\n{'='*60}")
    print(f"✅ 전체 분석 완료: {elapsed:.0f}초 ({elapsed/60:.1f}분)")
    print(f"  차트: Files/analysis_*.png (8장)")
    print(f"  보고서: Files/Comprehensive_Analysis_Report.md")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
