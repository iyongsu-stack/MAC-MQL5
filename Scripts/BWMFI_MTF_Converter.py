import pandas as pd
import numpy as np

# MQL5 to Pandas Timeframe Mapping
MQL5_TO_PANDAS_TF = {
    'PERIOD_M1': '1min',
    'PERIOD_M5': '5min',
    'PERIOD_M15': '15min',
    'PERIOD_M30': '30min',
    'PERIOD_H1': '1h',
    'PERIOD_H4': '4h',
    'PERIOD_D1': '1D',
    'PERIOD_W1': '1W',
    'PERIOD_MN1': '1ME'
}

def calculate_bwmfi_mtf(df_original, target_timeframe='PERIOD_CURRENT', volume_col='TickVolume', point=0.01):
    """
    Calculates Bill Williams Market Facilitation Index (BWMFI) with MTF support.
    
    Parameters:
    df_original (pd.DataFrame): DataFrame with 'High', 'Low', and volume_col. Index must be Datetime.
    target_timeframe (str): MQL5 timeframe string (e.g., 'PERIOD_H1') or pandas offset alias.
                            'PERIOD_CURRENT' or None means no resampling.
    volume_col (str): Name of the volume column (default 'TickVolume').
    point (float): Point value to scale MFI (MQL5 formula: Range / Volume / Point). 
                   Set to 0.01 or 0.0001 usually. Default 1.0 (no scaling).
    
    Returns:
    pd.DataFrame: DataFrame with 'BWMFI' and 'BWMFI_Color' columns, reindexed to df_original.
                  Colors: 0=Green, 1=Fade, 2=Fake, 3=Squat.
                  
    Usage Note:
    For "M1 Chart with Target Timeframe" scenario:
    - Passing df_original as 1-minute data
    - Passing target_timeframe='PERIOD_H1' (or other)
    - The logic will: Resample M1 -> H1, Calculate BWMFI on H1, Map (ffill) H1 results back to M1 index.
    """
    
    # 1. Determine Timeframe
    pd_tf = target_timeframe
    if target_timeframe in MQL5_TO_PANDAS_TF:
        pd_tf = MQL5_TO_PANDAS_TF[target_timeframe]
        
    if target_timeframe == 'PERIOD_CURRENT' or pd_tf is None:
        df = df_original.copy()
    else:
        # Resample logic
        # Map generic volume name if needed
        agg_dict = {
            'High': 'max',
            'Low': 'min'
        }
        if volume_col in df_original.columns:
            agg_dict[volume_col] = 'sum' # Volume is usually summed
        
        # Check if 'Close' and 'Open' exist for completeness, though not used in BWMFI
        if 'Close' in df_original.columns: agg_dict['Close'] = 'last'
        if 'Open' in df_original.columns: agg_dict['Open'] = 'first'
            
        df = df_original.resample(pd_tf).agg(agg_dict).dropna()

    # 2. Calculate BWMFI
    # MFI = (High - Low) / Volume
    # To avoid division by zero, replace 0 volume with 1 or handle accordingly (MQL5 returns prev MFI or 0)
    
    # MQL5 logic: if Volume=0, if i>0 MFI=prev, else 0.
    # Vectorized approach:
    # We can mask volume=0
    
    df['Range'] = (df['High'] - df['Low']) 
    # MQL5 divides by _Point.
    
    # Let's clean volume
    vol = df[volume_col].astype(float) # Ensure float
    
    # Calculate Raw MFI with Point scaling
    with np.errstate(divide='ignore', invalid='ignore'):
        mfi = (df['Range'] / point) / vol
        
    # Fix Infinite/NaN (where Volume was 0)
    # MQL5: if vol=0, take prev MFI.
    # Pandas ffill handles "prev MFI".
    mfi = mfi.replace([np.inf, -np.inf], np.nan)
    mfi = mfi.ffill().fillna(0.0)
    
    df['BWMFI'] = mfi
    
    # 3. Calculate Colors
    # Green (0): MFI Up, Vol Up
    # Fade (1): MFI Down, Vol Down
    # Fake (2): MFI Up, Vol Down
    # Squat (3): MFI Down, Vol Up
    
    # Calculate deltas
    mfi_diff = df['BWMFI'].diff()
    vol_diff = vol.diff()
    
    # Define Conditions
    # We use > 0 and < 0. What about = 0?
    # MQL5 logic: > is Up, < is Down. Equal?
    # Original MQL5 code:
    # if > prev: up=true
    # if < prev: up=false
    # else: (equal) -> continues from prev state (implied).
    
    # In vectorized, diff=0.
    # MFI Up = (diff > 0) OR (diff == 0 AND prev_up)
    # This state persistence is hard to vectorise perfectly without loop or C-extension.
    # Approximation: Treat Equal as Down? Or Treat Equal as Previous?
    # Let's uses simple comparison for now.
    
    mfi_up = mfi_diff > 0
    mfi_down = mfi_diff < 0
    # If 0, it's neither.
    
    vol_up = vol_diff > 0
    vol_down = vol_diff < 0
    
    colors = np.zeros(len(df))
    
    # Assign (Default 0 Green? No, default should be calculated)
    # Conditions:
    # Green: MFI+, Vol+
    # Fade: MFI-, Vol-
    # Fake: MFI+, Vol-
    # Squat: MFI-, Vol+
    
    # We need to handle the "Equal" case.
    # Simplest valid approximation: treat Equal as "Not Up" (False).
    # MQL5: if(mfi > prev) up=true; if(mfi < prev) up=false;
    # It keeps 'up' state if equal.
    
    # Let's iterate for correctness if performance allows (it does for indicators).
    mfi_arr = df['BWMFI'].values
    vol_arr = vol.values
    color_arr = np.zeros(len(df))
    
    mfi_state_up = True
    vol_state_up = True
    
    for i in range(1, len(df)):
        if mfi_arr[i] > mfi_arr[i-1]:
            mfi_state_up = True
        elif mfi_arr[i] < mfi_arr[i-1]:
            mfi_state_up = False
        # else keep state
        
        if vol_arr[i] > vol_arr[i-1]:
            vol_state_up = True
        elif vol_arr[i] < vol_arr[i-1]:
            vol_state_up = False
            
        if mfi_state_up and vol_state_up:
            color_arr[i] = 0.0 # Green
        elif not mfi_state_up and not vol_state_up:
            color_arr[i] = 1.0 # Fade
        elif mfi_state_up and not vol_state_up:
            color_arr[i] = 2.0 # Fake
        elif not mfi_state_up and vol_state_up:
            color_arr[i] = 3.0 # Squat
            
    df['BWMFI_Color'] = color_arr
    
    # 4. Map back to Original Index (if resampled)
    if target_timeframe != 'PERIOD_CURRENT' and pd_tf is not None:
        # Reindex to original
        # Method: reindex(original.index, method='ffill')
        # This matches "current bar gets latest known higher TF value"
        
        result = df[['BWMFI', 'BWMFI_Color']].reindex(df_original.index, method='ffill')
        return result
    else:
        return df[['BWMFI', 'BWMFI_Color']]
