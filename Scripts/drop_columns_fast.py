"""
CSV 파일에서 특정 컬럼을 스트리밍 방식으로 제거합니다.
pandas 없이 csv 모듈 사용 → 메모리 효율적, 빠름.
"""
import csv
import os
import shutil

SRC = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\TotalResult_2026_02_18_1.csv"
TMP = SRC + ".tmp"
DROP_COLS = {'BWMFI', 'BWMFI_Color'}

print(f"입력: {SRC}")
print(f"제거 컬럼: {DROP_COLS}")
print("처리 중...")

with open(SRC, 'r', encoding='utf-8-sig', newline='') as fin, \
     open(TMP, 'w', encoding='utf-8-sig', newline='') as fout:

    reader = csv.DictReader(fin)
    # 유지할 컬럼 목록
    keep_cols = [c for c in reader.fieldnames if c not in DROP_COLS]
    print(f"  원본 컬럼 수: {len(reader.fieldnames)}")
    print(f"  제거 후 컬럼 수: {len(keep_cols)}")
    print(f"  제거 대상 확인: {[c for c in reader.fieldnames if c in DROP_COLS]}")

    writer = csv.DictWriter(fout, fieldnames=keep_cols, extrasaction='ignore')
    writer.writeheader()

    for i, row in enumerate(reader):
        writer.writerow(row)
        if i % 50000 == 0:
            print(f"  {i:,}행 처리 중...")

print("임시 파일 → 원본 교체 중...")
os.replace(TMP, SRC)
print("완료!")
