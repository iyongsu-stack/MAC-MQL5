import pandas as pd
import numpy as np
import talib

def _calc_accel(arr, period):
    """범용 가속도 계산: arr[현재] - arr[N봉전] (2차 미분)"""
    accel = np.full_like(arr, np.nan, dtype=np.float64)
    if period < len(arr):
        accel[period:] = arr[period:] - arr[:-period]
    return np.nan_to_num(accel)

def generate_features(df_input, params):
    """
    모든 기술적 지표 + 가속도(변화율) 생성.
    가속도 = 현재값 - N봉전 값 (N = Accel_Period, 기본 10)
    """
    df = df_input.copy()
    
    # OHLC 추출
    o = df['Open'].values
    h = df['High'].values
    l = df['Low'].values
    c = df['Close'].values
    
    # 가속도 룩백 기간 (모든 지표 공통)
    accel_n = params.get('Accel_Period', 10)
    
    # --- 1. LRA (Linear Regression Slope) ---
    per_lra_s = params.get('LRA_Small_Period', params.get('LRA_AvgPeriod', 60))
    per_lra_l = params.get('LRA_Large_Period', 180)
    slope_s = talib.LINEARREG_SLOPE(c, timeperiod=per_lra_s)
    slope_l = talib.LINEARREG_SLOPE(c, timeperiod=per_lra_l)
    
    # --- 2. BOP (Balance of Power) ---
    bop = (c - o) / (h - l)
    bop = np.nan_to_num(bop)
    per_bop_avg = params.get('BOP_AvgPeriod', 50)
    per_bop_smooth = params.get('BOP_SmoothPeriod', 20)
    bop_sma = talib.SMA(bop, timeperiod=per_bop_avg)
    bop_smooth = talib.SMA(bop_sma, timeperiod=per_bop_smooth)
    
    # --- 3. ADX ---
    per_adx = params.get('ADX_Period', 14)
    adx = talib.ADX(h, l, c, timeperiod=per_adx)
    
    # --- 4. TDI (Traders Dynamic Index) ---
    per_tdi_rsi = params.get('TDI_RSI_Period', 13)
    per_tdi_sm_rsi = params.get('TDI_RSI_Smooth', 2)
    per_tdi_sm_sig = params.get('TDI_Sig_Smooth', 7)
    rsi = talib.RSI(c, timeperiod=per_tdi_rsi)
    tdi_pl = talib.SMA(rsi, timeperiod=per_tdi_sm_rsi)
    tdi_sl = talib.SMA(tdi_pl, timeperiod=per_tdi_sm_sig)
    
    # --- 5. QQE (RSI Proxy) ---
    per_qqe_rsi = params.get('QQE_RSI_Period', 14)
    qqe_base = talib.RSI(c, timeperiod=per_qqe_rsi)
    
    # --- 6. Chaikin Volatility (CHV) ---
    per_chv_smooth = params.get('CHV_SmoothPeriod', 10)
    per_chv_period = params.get('CHV_Period', 10)
    hl = h - l
    ema_hl = talib.EMA(hl, timeperiod=per_chv_smooth)
    ema_hl_prev = np.roll(ema_hl, per_chv_period)
    ema_hl_prev[:per_chv_period] = np.nan
    with np.errstate(divide='ignore', invalid='ignore'):
        chv = (ema_hl - ema_hl_prev) / ema_hl_prev * 100
    chv = np.nan_to_num(chv)
    
    # --- 7. CSI (ATR Proxy) ---
    per_atr = params.get('ATR_Period', 14)
    atr = talib.ATR(h, l, c, timeperiod=per_atr)
    with np.errstate(divide='ignore', invalid='ignore'):
        csi = atr / c * 1000
    csi = np.nan_to_num(csi)
    
    # =============================================
    # 원본 지표 → DataFrame 할당
    # =============================================
    df['LRA_BSPScale'] = slope_s
    df['LRA_BSPScale(180)'] = slope_l
    df['BOP_Diff'] = bop_smooth
    df['ADX_Val'] = adx
    df['TDI_TrSi'] = tdi_sl
    df['QQE_TrLevel'] = qqe_base
    df['CHV_CVScale'] = chv
    df['CSI_Scale'] = csi
    
    # =============================================
    # 전체 지표 가속도 (N봉 변화율) 계산
    # Accel = 현재값 - N봉전 값
    #   양수 → 지표 상승 가속 (강화 중)
    #   음수 → 지표 하락 가속 (약화 중)
    # =============================================
    accel_targets = {
        'LRA_Accel_S':   np.nan_to_num(slope_s),   # 단기 기울기 가속도
        'LRA_Accel_L':   np.nan_to_num(slope_l),   # 장기 기울기 가속도
        'BOP_Accel':     np.nan_to_num(bop_smooth), # 매수압력 변화율
        'ADX_Accel':     np.nan_to_num(adx),        # 추세강도 변화율
        'TDI_Accel':     np.nan_to_num(tdi_sl),     # TDI 시그널 변화율
        'QQE_Accel':     np.nan_to_num(qqe_base),   # QQE RSI 변화율
        'CHV_Accel':     chv,                        # 변동성 변화율
        'CSI_Accel':     csi,                        # ATR 변화율
    }
    
    for col_name, source_arr in accel_targets.items():
        df[col_name] = _calc_accel(source_arr, accel_n)
    
    # =============================================
    # Z-Score 정규화 (가중합 최적화용)
    # =============================================
    features = [
        'LRA_BSPScale', 'LRA_BSPScale(180)',
        'LRA_Accel_S', 'LRA_Accel_L',
        'BOP_Diff', 'BOP_Accel',
        'ADX_Val', 'ADX_Accel',
        'TDI_TrSi', 'TDI_Accel',
        'QQE_TrLevel', 'QQE_Accel',
        'CHV_CVScale', 'CHV_Accel',
        'CSI_Scale', 'CSI_Accel',
    ]
    
    scaler_stats = {}
    for col in features:
        series = df[col]
        mean = np.nanmean(series)
        std = np.nanstd(series)
        if std == 0 or np.isnan(std): std = 1.0
        df[col] = (series - mean) / std
        scaler_stats[col] = {'mean': mean, 'std': std}
        df[col] = df[col].fillna(0.0)
        
    return df, scaler_stats
