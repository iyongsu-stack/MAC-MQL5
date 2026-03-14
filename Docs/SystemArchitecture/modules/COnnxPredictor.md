# COnnxPredictor — 클래스 설계서

> 모듈 ID: 1-3 | Phase 1 | 의존성: ONNX Runtime (MQL5 내장)

---

## 1. 단일 책임

**ONNX 모델 추론 래퍼**.
- LightGBM 이진 분류 모델(`.onnx`)을 로드하고, 피처 벡터 입력 → 확률(P(Win)) 출력
- **NaN/INF 방어 게이트**: 입력 피처에 NaN 발견 시 추론 거부 → `-1.0` 반환
- 재시도 로직(1회) + 연속 NaN 카운터 + Alert(500봉 연속 시)

---

## 2. 클래스 다이어그램

```
┌──────────────────── COnnxPredictor ────────────────────┐
│                                                         │
│ [상수]                                                   │
│   NAN_ALERT_THRESHOLD = 500  // ≈8시간 연속 NaN 시 Alert│
│                                                         │
│ [멤버 변수]                                              │
│   long   m_handle          // ONNX 세션 핸들            │
│   int    m_featureCount    // 입력 피처 수 (80/77)      │
│   bool   m_ready           // 모델 로드 성공 여부       │
│   string m_modelPath       // 모델 파일 경로             │
│   string m_lastError       // 최근 에러 설명            │
│   int    m_nanRejectCount  // 연속 NaN 거부 카운터      │
│   bool   m_nanAlerted      // Alert 발행 여부 (1회 제한)│
│                                                         │
│ [공개 메서드]                                            │
│   bool   Init(string modelPath, int featureCount)       │
│   void   Deinit()                                       │
│   double Predict(float &features[])  // → P(Win) or -1  │
│   bool   IsReady()                                      │
│   string GetLastError()                                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 3. 입출력 인터페이스

### 3.1 Init — 모델 로드

```
Init("models/model_long_ABC.onnx", 80)
  ├── OnnxCreate(modelPath, 0)
  │   └── 실패 → Print CRITICAL, return false
  ├── OnnxSetInputShape(handle, 0, {1, 80})  // [batch=1, features]
  │   └── 실패 → Release + return false
  ├── OnnxSetOutputShape(handle, 1, {1, 2})  // [P(0), P(1)]
  │   └── 실패 → Print Warning (auto-detect 시도)
  └── m_ready = true
```

### 3.2 Predict — 추론 파이프라인

```
Predict(float features[80])
  │
  ├── Gate 1: m_ready 확인
  │   └── false → return -1.0
  │
  ├── Gate 2: 피처 수 검증 (sizeof != 80)
  │   └── 불일치 → return -1.0
  │
  ├── Gate 3: NaN/INF 방어 ★
  │   ├── MathIsValidNumber(features[i]) 전수 검사
  │   ├── NaN 발견 → m_nanRejectCount++
  │   ├── 500봉 연속 → Alert("파이프라인 점검 필요")
  │   └── return -1.0 (prob < 0.20 → 자연스럽게 진입 스킵)
  │
  ├── NaN 해소 시 → 카운터 리셋 + Print("resolved")
  │
  ├── OnnxRun(handle, ONNX_NO_CONVERSION, inputVec, outLabel, outProba)
  │   ├── 실패 → 1회 재시도 → 재실패 → return -1.0
  │   └── 성공 → P(Win) = outProba[1]
  │
  └── Sanity check: 0.0 ≤ prob ≤ 1.0 → 클리핑
      return prob
```

### 3.3 LightGBM ONNX 출력 구조

| Output | 타입 | 내용 |
|:---|:---|:---|
| `output[0]` | `int64` | 예측 라벨 (0 or 1) |
| `output[1]` | `float[2]` | `[P(class=0), P(class=1)]` |

→ `P(class=1)` = 승리 확률 = Entry/AddOn 판단 기준

---

## 4. 에러 처리

| 시나리오 | 대응 |
|:---|:---|
| 모델 파일 미존재 | `OnnxCreate` 실패 → `INIT_FAILED` 전파, EA 정지 |
| 입력 shape 불일치 | `OnnxSetInputShape` 실패 → 세션 해제 |
| NaN/INF 입력 | Reject → `-1.0` 반환 → 자연 스킵 (다음 봉 재시도) |
| 500봉 연속 NaN | `Alert()` 1회 발행 → 운영자 개입 유도 |
| `OnnxRun` 실패 | 1회 재시도 → 재실패 시 `-1.0` + 로그 |
| 확률 범위 초과 | `MathMax(0, MathMin(1, prob))` 클리핑 |

---

## 5. 성능 고려사항

| 항목 | 설계 |
|:---|:---|
| **추론 시간** | LightGBM 트리 모델 ≈ 0.05ms (피처 80개) |
| **NaN 검사** | O(N) — 80개 피처 전수 스캔. 무시 가능 |
| **메모리** | ONNX 세션 + 입출력 버퍼 ≈ 수 MB |
| **호출 빈도** | 봉당 2회 (Entry + AddOn 모델) = M1 기준 분당 2회 |
| **float 정밀도** | 모델 입력 `FloatTensorType` → MQL5 `float[]` 사용 (double 아님) |

---

## 6. 의존성

```
COnnxPredictor
  ├── ONNX Runtime (MQL5 내장: OnnxCreate, OnnxRun, OnnxRelease)
  └── Files/models/model_long_ABC.onnx   — Entry 모델
      Files/models/model_addon_ABC.onnx  — AddOn 모델

호출 관계:
  BSP_Long_v1.mq5 → COnnxPredictor.Init()
                   → CFeatureEngine.GetEntryFeatures()
                   → COnnxPredictor.Predict(features)
                   → CSignalGenerator.Evaluate(prob, ...)
```
