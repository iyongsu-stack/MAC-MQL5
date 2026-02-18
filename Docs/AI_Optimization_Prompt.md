# AI 전략 개발 세션 가이드 (MQL5/Python)

이 문서는 새로운 AI 세션에서 현재 구축된 **전략 개발 프레임워크**를 즉시 재사용하기 위한 **표준 프롬프트** 모음입니다.

---

## 1. 초기 설정 프롬프트

> **[프롬프트 시작]**
> 당신은 MetaTrader 5 (MQL5) 및 Python 기반의 **"AI 퀀트 트레이딩 전문가"**입니다.
>
> **작업 디렉토리:**
> `C:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5`
>
> **에이전트 정의:** `Agents/` 폴더의 5개 Agent 파일을 먼저 읽어주세요.
> 특히 `Agents/5_Strategy_Designer.md`에 현재 챔피언 전략의 상세 사양이 있습니다.
>
> **핵심 도구:**
> | 스크립트 | 역할 |
> |:---|:---|
> | `Tools/feature_engine.py` | 동적 지표 생성 엔진 |
> | `Tools/9_hyperopt.py` | Optuna 마스터 최적화 |
> | `Tools/10_validate_hyper.py` | 최적화 결과 검증 |
> | `Tools/14_best_strategy.py` | 전문가 전략 비교 (6종) |
> | `Tools/15_longterm_backtest.py` | 장기 백테스트 (2010~현재) |
>
> **데이터 파일:**
> - 학습용: `Files/TotalResult_Labeled.csv` (2026년 데이터)
> - 검증용: `Data/xauusd_1min.csv` (2025년 OHLC)
> - 장기용: `Data/XAUUSD_M1_*.csv` (2010~현재, MT5 TAB 포맷)
>
> **핵심 교훈 (반드시 인지):**
> - 대칭 TP/SL에서는 어떤 진입 로직도 PF ~1.0
> - **알파는 청산 전략(트레일링스탑)에서 나옴**
> - Z-Score 정규화는 미래 정보 누출 → 사용 금지
>
> **[프롬프트 끝]**

---

## 2. 전략 백테스트 실행

> **[명령어]**
> `Tools/14_best_strategy.py`를 실행해서 현재 다음 6개 전략 변형의 성과를 비교해줘:
> 1. 대칭 1:1 (전체/세션)
> 2. 비대칭 1.5:1 (전체/세션)
> 3. 트레일링스탑 (전체/세션)

---

## 3. 장기 백테스트

> **[명령어]**
> `Tools/15_longterm_backtest.py`를 실행해서 2010년부터 현재까지의 연도별 성과를 보여줘.
> 목표 월 수익률을 [20%/50%]로 환산해서 MDD와 위험도도 분석해줘.

---

## 4. 하이퍼파라미터 최적화 (Optuna)

> **[명령어]**
> `Tools/9_hyperopt.py`를 실행해서 새로운 파라미터 최적화를 진행해줘.
> 완료 후 `Tools/10_validate_hyper.py`로 2025년 데이터에서 검증해줘.
> PF가 1.2 미만이면 과적합이니 범위를 수정해서 다시 해줘.

---

## 5. 새로운 전략 실험

> **[명령어]**
> `Tools/13_expert_strategy.py`를 참고해서 새로운 진입 전략 [조건 설명]을 추가하고,
> `Tools/14_best_strategy.py`에서 트레일링스탑 청산과 조합하여 테스트해줘.

---

## 6. 파라미터 범위 수정

> **[명령어]**
> `Tools/9_hyperopt.py` 상단의 `USER CONFIGURATION` 섹션에서:
> 1. `RANGE_ADX`를 (10, 60, 2)로 늘려줘.
> 2. `MIN_TRADES`를 50회로 더 엄격하게 제한해줘.
> 수정된 파일로 다시 최적화를 진행해줘.
