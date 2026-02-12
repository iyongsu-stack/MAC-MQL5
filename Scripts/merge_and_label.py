import pandas as pd
import numpy as np
import os

# 파일 경로 정의
file_pos = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\PositionCase2.csv"
file_total = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\TotalResult_2026_02_11_11.csv"
output_file = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\TotalResult_Labeled.csv"

def process_data():
    print("Loading CSV files...")
    # PositionCase2.csv 로드 (인코딩 문제 방지를 위해 utf-8-sig 시도)
    try:
        df_pos = pd.read_csv(file_pos)
    except UnicodeDecodeError:
        df_pos = pd.read_csv(file_pos, encoding='cp949')

    # TotalResult 로드
    df_total = pd.read_csv(file_total)

    print("Converting datetime formats...")
    # PositionCase2: 2026.01.02 04:45 -> YYYY-MM-DD HH:MM
    df_pos['OpenTime'] = pd.to_datetime(df_pos['OpenTime'], format='%Y.%m.%d %H:%M')
    df_pos['CloseTime'] = pd.to_datetime(df_pos['CloseTime'], format='%Y.%m.%d %H:%M')

    # TotalResult: 2025-12-31 15:00:00 -> datetime 객체로 변환
    df_total['Time'] = pd.to_datetime(df_total['Time'])

    # 인덱스 재설정 (Time 기준 정렬 보장)
    df_total.sort_values('Time', inplace=True)
    df_total.reset_index(drop=True, inplace=True)

    # 빠른 조회를 위해 Time을 key로, Index를 value로 하는 딕셔너리 생성
    time_to_idx = {t: i for i, t in enumerate(df_total['Time'])}

    # 타겟 컬럼 초기화 (One-Hot Encoding & Renaming)
    # Label_Open_Buy: 1 (Open Buy), 0
    # Label_Open_Sell: 1 (Open Sell), 0
    # Label_Close_Buy: 1 (Close Buy position), 0
    # Label_Close_Sell: 1 (Close Sell position), 0
    df_total['Label_Open_Buy'] = 0
    df_total['Label_Open_Sell'] = 0
    df_total['Label_Close_Buy'] = 0
    df_total['Label_Close_Sell'] = 0

    print("Applying labels...")
    
    # 윈도우 설정 (기존 유지)
    # 진입: 앞(과거), 뒤(미래) 4개 (총 9개 봉)
    ENTRY_BACK = 4
    ENTRY_FWD = 4
    
    # 청산: 과거 3개봉 ~ 청산 시점 (본인 포함 총 4개 봉)
    EXIT_BACK = 3 
    EXIT_FWD = 0

    count_entry = 0
    count_exit = 0

    for _, row in df_pos.iterrows():
        # 1. 진입 라벨링 (OpenTime)
        ot = row['OpenTime']
        if ot in time_to_idx:
            idx = time_to_idx[ot]
            start_idx = max(0, idx - ENTRY_BACK)
            end_idx = min(len(df_total) - 1, idx + ENTRY_FWD)
            
            if row['OpenType'] == 'Buy':
                df_total.loc[start_idx:end_idx, 'Label_Open_Buy'] = 1
            elif row['OpenType'] == 'Sell':
                df_total.loc[start_idx:end_idx, 'Label_Open_Sell'] = 1
            
            count_entry += 1
        
        # 2. 청산 라벨링 (CloseTime)
        ct = row['CloseTime']
        if ct in time_to_idx:
            idx = time_to_idx[ct]
            start_idx = max(0, idx - EXIT_BACK)
            end_idx = min(len(df_total) - 1, idx + EXIT_FWD)
            
            # CloseType은 진입과 반대되지만, '어떤 포지션을 청산하는지'가 중요하므로
            # OpenType을 기준으로 청산 라벨을 결정함.
            # OpenType == 'Buy' -> Closing Buy Position -> Label_Close_Buy
            if row['OpenType'] == 'Buy':
                df_total.loc[start_idx:end_idx, 'Label_Close_Buy'] = 1
            elif row['OpenType'] == 'Sell':
                df_total.loc[start_idx:end_idx, 'Label_Close_Sell'] = 1
                
            count_exit += 1

    print(f"Labeling complete: {count_entry} Entries, {count_exit} Exits labeled.")
    
    # 검증 출력
    cols_to_show = ['Time', 'Close', 'Label_Open_Buy', 'Label_Open_Sell', 'Label_Close_Buy', 'Label_Close_Sell']
    print("Sample output (Open Buy):")
    print(df_total[df_total['Label_Open_Buy'] == 1][cols_to_show].head(5))
    
    print("\nSample output (Close Buy):")
    print(df_total[df_total['Label_Close_Buy'] == 1][cols_to_show].head(5))

    # 결과 저장
    df_total.to_csv(output_file, index=False)
    print(f"Saved merged file to: {output_file}")

if __name__ == "__main__":
    process_data()
