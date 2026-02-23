# Parquet Visualizer 간단 매뉴얼


1. 가장 나중 데이터 30개 보기 (역순 정렬)
SELECT * 
FROM read_parquet('c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/TotalResult_2026_02_19_2.parquet') 
ORDER BY time DESC 
LIMIT 30;

2. 가장 처음 데이터 30개 보기 (내림순 정렬)
SELECT * 
FROM read_parquet('c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/TotalResult_2026_02_19_2.parquet') 
ORDER BY time DESC 
LIMIT 30;

3. 특정 시간대를 보기 원한다면 
SELECT *
FROM read_parquet('c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/TotalResult_2026_02_19_2.parquet')
WHERE time BETWEEN '2024-01-01 00:00:00' AND '2024-01-31 23:59:59'
ORDER BY time ASC;

4. 특정 컬럼만 읽기 원한다면
SELECT time, close, volume
FROM read_parquet('c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/TotalResult_2026_02_19_2.parquet')
WHERE CAST(time AS TIMESTAMP) >= TIMESTAMP '2024-01-01 00:00:00'
ORDER BY time ASC;

5. 특정 컬럼만 읽기 원한다면(컬럼명이 특수문자나, 스페이스가 있는 경우)
SELECT time, close, "RSI 14", "MACD/Sig"
FROM read_parquet('c:/Users/gim-yongsu/AppData/Roaming/MetaQuotes/Terminal/5B326B03063D8D9C446E3637EFA32247/MQL5/Files/processed/TotalResult_2026_02_19_2.parquet')
WHERE time BETWEEN '2024-01-01 00:00:00' AND '2024-01-31 23:59:59'
ORDER BY time ASC;






## 1. 설치
VS Code 좌측 Extensions 아이콘 → `Parquet Visualizer` 검색 → **Install**

---

## 2. 파일 열기
`.parquet` 파일을 **VS Code 탐색기에서 더블클릭** → 자동으로 표 형태로 표시됨

> 좌측 EXPLORER 창에서 `Files/processed/` 폴더 열기 → `.parquet` 파일 클릭

---

## 3. 화면 구성

```
┌─────────────────────────────────────────────────────┐
│  [◀ 이전] [페이지: 1 / 234] [다음 ▶]  [행 수: 1,000]  │  ← 페이지 네비게이션
├──────┬──────────────────┬────────┬───────┬──────────┤
│  #   │ Time             │ Open   │ ADX   │ LRA_stdS │  ← 컬럼 헤더 (정렬 가능)
├──────┼──────────────────┼────────┼───────┼──────────┤
│  1   │ 2026-01-02 00:00 │ 2630.1 │ 28.41 │  0.0023  │
│  2   │ 2026-01-02 00:01 │ 2630.3 │ 28.55 │  0.0031  │
...
└──────┴──────────────────┴────────┴───────┴──────────┘
```

---

## 4. 주요 기능

| 기능 | 방법 |
|:---|:---|
| **컬럼 정렬** | 컬럼 헤더 클릭 (클릭마다 오름/내림 전환) |
| **페이지 이동** | 하단 `◀ ▶` 버튼 또는 페이지 번호 직접 입력 |
| **컬럼 숨기기** | 컬럼 헤더 우클릭 → Hide Column |
| **데이터 검색** | `Ctrl+F` → 검색어 입력 |
| **전체 파일 정보** | 우측 상단 `ℹ️` 버튼 (행 수, 컬럼 수, 파일 크기) |

---

## 5. 페이지 설정
한 페이지에 표시할 행 수 변경:
- VS Code 설정(`Ctrl+,`) → `parquet` 검색 → **Rows Per Page** 조정 (기본값: 1,000)

---

## 6. 한계 및 주의사항

> [!WARNING]
> 파일이 **500MB 이상**인 경우 로딩이 매우 느려지거나 멈출 수 있습니다.
> 대용량 파일은 아래 방법으로 원하는 컬럼/행만 추출 후 확인하세요.

```powershell
# 특정 컬럼만 추출해서 보기 (peek.py 활용)
python Files/Tools/peek.py Files/processed/TotalResult_2026_02_19_2.parquet Time ADX LRA_stdS --head 100
```

---

## 7. 자주 쓰는 파일 경로

| 파일 | 설명 |
|:---|:---|
| `Files/processed/TotalResult_2026_02_19_2.parquet` | 전체 지표 데이터 (메인) |
| `Files/labeled/TotalResult_Labeled.parquet` | 라벨링 완료 데이터 |
| `Files/processed/*_DownLoad.parquet` | 개별 지표 데이터 |
