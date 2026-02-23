# 프로젝트 데이터베이스 프레임워크

> 최종 업데이트: 2026-02-23

---

## 1. 전체 구조 (3계층 파이프라인)

```
MT5 지표 실행
     ↓
  [1계층] Files/raw/         ← CSV 원본 (MT5 출력)
     ↓ (변환)
  [2계층] Files/processed/   ← Parquet 처리 데이터 (메인 저장소)
     ↓ (라벨링)
  [3계층] Files/labeled/     ← 학습용 라벨 데이터
```

---

## 2. 디렉터리별 역할

| 경로 | 포맷 | 설명 |
|:---|:---|:---|
| `Files/raw/` | CSV | MT5 다운로드 지표의 **원본 출력** (탭 구분자, ANSI) |
| `Files/processed/` | Parquet | **핵심 저장소** — 지표 계산값·OHLCV 통합 |
| `Files/labeled/` | Parquet | ML 학습용 **매매 라벨 데이터** |
| `Files/archive/csv_originals/` | CSV | 백업/보관용 원본 CSV |

---

## 3. 현재 저장된 주요 파일

### processed/ (Parquet, 메인)

| 파일 | 크기 | 설명 |
|:---|:---|:---|
| `TotalResult_2026_02_19_2.parquet` | 628 MB | 전체 지표 데이터 (메인, 최신) |
| `TotalResult_2026_02_19_1.parquet` | 53 MB | 이전 버전 |
| `TotalResult_MQL5.parquet` | 41 MB | MQL5 원본 기준값 |
| `BWMFI_MTF_DownLoad.parquet` | 41 MB | BWMFI 개별 지표 |

### raw/ (CSV, MT5 출력)

| 파일 | 크기 | 설명 |
|:---|:---|:---|
| `ADXSmoothMTF_DownLoad.csv` | 64 MB | ADX 멀티타임프레임 |
| `ChandelieExit_DownLoad.csv` | 15 MB | 샹들리에 청산 지표 |
| `xauusd_2026.csv` | 1.8 MB | 2026년 XAUUSD OHLCV |

---

## 4. 쿼리 도구

### DuckDB SQL (VS Code Parquet Visualizer)
```sql
-- 최근 30행 조회
SELECT *
FROM read_parquet('.../processed/TotalResult_2026_02_19_2.parquet')
ORDER BY time DESC
LIMIT 30;

-- 특정 기간 + 컬럼 선택
SELECT time, close, "ADX", "Scale"
FROM read_parquet('.../processed/TotalResult_2026_02_19_2.parquet')
WHERE time BETWEEN '2024-01-01' AND '2024-01-31'
ORDER BY time ASC;
```

### CLI peek 도구
```powershell
python Files/Tools/peek.py Files/processed/TotalResult_2026_02_19_2.parquet Time ADX --head 100
```

---

## 5. 설계 원칙

- **별도 DB 서버 없음** — 파일 기반(Parquet + DuckDB 인메모리 쿼리) 방식
- **Parquet 선택 이유**: 컬럼 압축 효율, 빠른 컬럼 선택 읽기, Python(pandas/pyarrow) 및 DuckDB 완전 지원
- **CSV → Parquet 변환**: MT5가 CSV로 출력 → Python 스크립트로 Parquet 변환 후 사용

---

## 6. 주의사항

> [!WARNING]
> `TotalResult_2026_02_19_2.parquet` 파일이 **628MB**로 매우 큽니다.
> Parquet Visualizer로 직접 열면 느릴 수 있으므로 DuckDB SQL 또는 `peek.py` 사용을 권장합니다.

> [!NOTE]
> `Files/labeled/` 폴더는 현재 비어 있습니다.
> 라벨 데이터(`PositionCase2.csv`)의 Parquet 변환이 필요합니다.
