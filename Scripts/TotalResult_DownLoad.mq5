//+------------------------------------------------------------------+
//| TotalResult_DownLoad.mq5                                         |
//| Purpose : MT5에서 17개 인디케이터 값을 읽어 CSV로 저장           |
//|           Python build_total_result.py 출력과 비교 검증용         |
//| Symbol  : XAUUSD M1                                              |
//| Period  : 2018.05.01 ~ 2019.01.31 (웜업: 2017.11.01~)           |
//| Output  : Files/TotalResult_MQL5.csv                             |
//+------------------------------------------------------------------+
#property copyright "BSP Framework"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

//--- 입력 파라미터
input string InpSymbol     = "XAUUSD";         // 심볼
input string InpOutputFile = "TotalResult_MQL5.csv"; // 출력 파일명

//--- 기간 상수
datetime WARMUP_START  = D'2017.11.01 00:00'; // 웜업 시작 (Python과 동일)
datetime OUTPUT_START  = D'2018.05.01 00:00'; // 출력 시작
datetime OUTPUT_END    = D'2019.01.31 23:59'; // 출력 종료

//--- 전역 핸들 변수 (핸들 해제 함수에서 접근)
int g_h_bop        = INVALID_HANDLE;
int g_h_lra60      = INVALID_HANDLE;
int g_h_lra180     = INVALID_HANDLE;
int g_h_bopwma10   = INVALID_HANDLE;
int g_h_bopwma30   = INVALID_HANDLE;
int g_h_bspwma10   = INVALID_HANDLE;
int g_h_bspwma30   = INVALID_HANDLE;
int g_h_chv        = INVALID_HANDLE;
int g_h_tdi        = INVALID_HANDLE;
int g_h_qqe        = INVALID_HANDLE;
int g_h_adxs       = INVALID_HANDLE;
int g_h_ce         = INVALID_HANDLE;
int g_h_chop       = INVALID_HANDLE;
int g_h_adxmtf_h4  = INVALID_HANDLE;
int g_h_adxmtf_m5  = INVALID_HANDLE;
int g_h_bwmfi_h4   = INVALID_HANDLE;
int g_h_bwmfi_m5   = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| 핸들 해제 함수 (goto 대체)                                        |
//+------------------------------------------------------------------+
void ReleaseHandles()
{
   Print("[Step 6] 핸들 해제...");
   if(g_h_bop       != INVALID_HANDLE) { IndicatorRelease(g_h_bop);       g_h_bop       = INVALID_HANDLE; }
   if(g_h_lra60     != INVALID_HANDLE) { IndicatorRelease(g_h_lra60);     g_h_lra60     = INVALID_HANDLE; }
   if(g_h_lra180    != INVALID_HANDLE) { IndicatorRelease(g_h_lra180);    g_h_lra180    = INVALID_HANDLE; }
   if(g_h_bopwma10  != INVALID_HANDLE) { IndicatorRelease(g_h_bopwma10);  g_h_bopwma10  = INVALID_HANDLE; }
   if(g_h_bopwma30  != INVALID_HANDLE) { IndicatorRelease(g_h_bopwma30);  g_h_bopwma30  = INVALID_HANDLE; }
   if(g_h_bspwma10  != INVALID_HANDLE) { IndicatorRelease(g_h_bspwma10);  g_h_bspwma10  = INVALID_HANDLE; }
   if(g_h_bspwma30  != INVALID_HANDLE) { IndicatorRelease(g_h_bspwma30);  g_h_bspwma30  = INVALID_HANDLE; }
   if(g_h_chv       != INVALID_HANDLE) { IndicatorRelease(g_h_chv);       g_h_chv       = INVALID_HANDLE; }
   if(g_h_tdi       != INVALID_HANDLE) { IndicatorRelease(g_h_tdi);       g_h_tdi       = INVALID_HANDLE; }
   if(g_h_qqe       != INVALID_HANDLE) { IndicatorRelease(g_h_qqe);       g_h_qqe       = INVALID_HANDLE; }
   if(g_h_adxs      != INVALID_HANDLE) { IndicatorRelease(g_h_adxs);      g_h_adxs      = INVALID_HANDLE; }
   if(g_h_ce        != INVALID_HANDLE) { IndicatorRelease(g_h_ce);        g_h_ce        = INVALID_HANDLE; }
   if(g_h_chop      != INVALID_HANDLE) { IndicatorRelease(g_h_chop);      g_h_chop      = INVALID_HANDLE; }
   if(g_h_adxmtf_h4 != INVALID_HANDLE) { IndicatorRelease(g_h_adxmtf_h4); g_h_adxmtf_h4 = INVALID_HANDLE; }
   if(g_h_adxmtf_m5 != INVALID_HANDLE) { IndicatorRelease(g_h_adxmtf_m5); g_h_adxmtf_m5 = INVALID_HANDLE; }
   if(g_h_bwmfi_h4  != INVALID_HANDLE) { IndicatorRelease(g_h_bwmfi_h4);  g_h_bwmfi_h4  = INVALID_HANDLE; }
   if(g_h_bwmfi_m5  != INVALID_HANDLE) { IndicatorRelease(g_h_bwmfi_m5);  g_h_bwmfi_m5  = INVALID_HANDLE; }
}

//+------------------------------------------------------------------+
//| 인디케이터 경로 상수 (Indicators/ 기준 상대경로)                  |
//+------------------------------------------------------------------+
#define IND_BOP_AVGSTD      "BOP\\BOPAvgStdDownLoad"
#define IND_LRAVGST         "BSP105V9\\LRAVGSTDownLoad"
#define IND_BOPWMA          "BOP\\BOPWmaSmoothDownLoad"
#define IND_BSPWMA          "BSP105V9\\BSPWmaSmoothDownLoad"
#define IND_CHV             "BSP105V9\\Chaikin VolatilityDownLoad"
#define IND_TDI             "Test\\TradesDynamicIndexDownLoad"
#define IND_QQE             "Test\\QQE DownLoad"
#define IND_ADXSMOOTH       "Test\\ADXSmoothDownLoad"
#define IND_CE              "Test\\ChandelieExitDownLoad"
#define IND_CHOP            "Test\\ChoppingIndexDownLoad"
#define IND_ADXMTF          "Test\\ADXSmoothMTFDownLoad"
#define IND_BWMFI           "Test\\BWMFI_MTFDownLoad"

//+------------------------------------------------------------------+
//| 유틸리티: 인디케이터 계산 완료 대기 (최대 60초)                   |
//+------------------------------------------------------------------+
bool WaitForCalc(int handle, int total_bars, string name)
{
   int prev_bc   = -999;
   int stable_cnt = 0;

   for(int i = 0; i < 1200; i++)   // 최대 600초(10분) 대기
   {
      int bc = BarsCalculated(handle);

      // 조건1: 전체 바 계산 완료
      if(bc >= total_bars) return true;

      // 조건2: BC >= 0이고 연속 3회 동일 → 인디케이터가 자체 저장 후 멈춘 경우 (BC=0 포함)
      if(bc >= 0 && bc == prev_bc)
      {
         stable_cnt++;
         if(stable_cnt >= 3)
         {
            Print("  [STABLE] ", name, " BC=", bc, " (안정화 감지 → 완료 처리)");
            return true;
         }
      }
      else
      {
         stable_cnt = 0;
      }
      prev_bc = bc;

      Print("  대기 중: ", name, " BC=", bc, "/", total_bars);
      Sleep(500);
   }
   Print("  [TIMEOUT] ", name, " 계산 미완료");
   return false;
}

//+------------------------------------------------------------------+
//| 유틸리티: CopyBuffer 안전 래퍼 (실패 시 0.0 채움)                |
//+------------------------------------------------------------------+
bool SafeCopyBuffer(int handle, int buf_idx, int start_pos, int count,
                    double &arr[], string name)
{
   int copied = CopyBuffer(handle, buf_idx, start_pos, count, arr);
   if(copied <= 0)
   {
      Print("  [WARN] CopyBuffer 실패: ", name, " buf=", buf_idx,
            " err=", GetLastError());
      // 실패해도 배열 크기를 count로 보장 (array out of range 방지)
      ArrayResize(arr, count);
      ArrayInitialize(arr, 0.0);
      return false;
   }
   // CopyBuffer는 Series(0=최신) 반환 → 반전하여 0=최오래된 순으로 변환
   ArraySetAsSeries(arr, false);
   return true;
}

//+------------------------------------------------------------------+
//| Script 메인 함수                                                  |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("==========================================================");
   Print("  TotalResult_DownLoad.mq5 시작");
   Print("  심볼: ", InpSymbol, "  타임프레임: M1");
   Print("  웜업 시작: ", TimeToString(WARMUP_START));
   Print("  출력 범위: ", TimeToString(OUTPUT_START), " ~ ", TimeToString(OUTPUT_END));
   Print("==========================================================");

   //--- 1. M1 OHLCV 데이터 로드 (웜업 포함)
   Print("[Step 1] M1 OHLCV 데이터 로드...");
   MqlRates rates[];
   ArraySetAsSeries(rates, false); // 0=가장 오래된 순

   // 현재 시간부터 OUTPUT_END까지의 바 수 계산
   int total_bars = CopyRates(InpSymbol, PERIOD_M1, WARMUP_START, OUTPUT_END, rates);
   if(total_bars <= 0)
   {
      Print("  [ERROR] CopyRates 실패! err=", GetLastError());
      Print("  MT5 차트에 XAUUSD M1이 열려 있어야 합니다.");
      return;
   }
   Print("  로드된 바 수: ", total_bars, " (", TimeToString(rates[0].time),
         " ~ ", TimeToString(rates[total_bars-1].time), ")");

   //--- 2. 인디케이터 핸들 생성
   Print("[Step 2] 인디케이터 핸들 생성...");

   // [1] BOPAvgStd (디폴트 파라미터)
   g_h_bop = iCustom(InpSymbol, PERIOD_M1, IND_BOP_AVGSTD,
                     50, 50, 5000, 1.0, 2.0, 3.0,  // smooth, avg, std, multi1,2,3
                     1, 30, 23, 30);                 // time filter
   if(g_h_bop == INVALID_HANDLE) { Print("  [ERROR] BOPAvgStd 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] BOPAvgStd");

   // [2] LRAVGST Avg(60)
   g_h_lra60 = iCustom(InpSymbol, PERIOD_M1, IND_LRAVGST,
                        25, 60, 5000, 2,              // lwma, avg, stdL, stdS
                        1.0, 2.0, 3.0,                // multi1,2,3
                        1, 30, 23, 30,                // time filter
                        20.0);                        // maxBSPMult
   if(g_h_lra60 == INVALID_HANDLE) { Print("  [ERROR] LRAVGST(60) 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] LRAVGST Avg(60)");

   // [3] LRAVGST Avg(180)
   g_h_lra180 = iCustom(InpSymbol, PERIOD_M1, IND_LRAVGST,
                         25, 180, 5000, 2,
                         1.0, 2.0, 3.0,
                         1, 30, 23, 30,
                         20.0);
   if(g_h_lra180 == INVALID_HANDLE) { Print("  [ERROR] LRAVGST(180) 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] LRAVGST Avg(180)");

   // [4] BOPWMA (10, 3)
   g_h_bopwma10 = iCustom(InpSymbol, PERIOD_M1, IND_BOPWMA, 10, 3);
   if(g_h_bopwma10 == INVALID_HANDLE) { Print("  [ERROR] BOPWMA(10,3) 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] BOPWMA(10,3)");

   // [5] BOPWMA (30, 5)
   g_h_bopwma30 = iCustom(InpSymbol, PERIOD_M1, IND_BOPWMA, 30, 5);
   if(g_h_bopwma30 == INVALID_HANDLE) { Print("  [ERROR] BOPWMA(30,5) 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] BOPWMA(30,5)");

   // [6] BSPWMA (10, 3)
   g_h_bspwma10 = iCustom(InpSymbol, PERIOD_M1, IND_BSPWMA, 10, 3);
   if(g_h_bspwma10 == INVALID_HANDLE) { Print("  [ERROR] BSPWMA(10,3) 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] BSPWMA(10,3)");

   // [7] BSPWMA (30, 5)
   g_h_bspwma30 = iCustom(InpSymbol, PERIOD_M1, IND_BSPWMA, 30, 5);
   if(g_h_bspwma30 == INVALID_HANDLE) { Print("  [ERROR] BSPWMA(30,5) 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] BSPWMA(30,5)");

   // [8] CHV (10, 10)
   g_h_chv = iCustom(InpSymbol, PERIOD_M1, IND_CHV,
                     10, 10, 2,                     // smooth, chv, smoothType(WMA=2)
                     5000, 1.0, 2.0, 3.0);          // std, multi1,2,3
   if(g_h_chv == INVALID_HANDLE) { Print("  [ERROR] CHV(10,10) 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] CHV(10,10)");

   // [9] TDI (13, 34, 2, 7)
   g_h_tdi = iCustom(InpSymbol, PERIOD_M1, IND_TDI,
                     13, PRICE_CLOSE, 34, 2, MODE_SMA, 7, MODE_SMA,
                     68, 32, 0, 0);                 // ob, os, showBase, showVBL
   if(g_h_tdi == INVALID_HANDLE) { Print("  [ERROR] TDI(13,34,2,7) 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] TDI(13,34,2,7)");

   // [10] QQE (SF=5, RSI=14)
   g_h_qqe = iCustom(InpSymbol, PERIOD_M1, IND_QQE, 14, 5);
   if(g_h_qqe == INVALID_HANDLE) { Print("  [ERROR] QQE(5,14) 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] QQE(5,14)");

   // [11] ADXSmooth (period=10, alpha1=0.25, alpha2=0.33)
   g_h_adxs = iCustom(InpSymbol, PERIOD_M1, IND_ADXSMOOTH,
                      10, 0.25, 0.33, 0,            // period, alpha1, alpha2, priceType
                      1000, 4000);                   // avgPeriod, stdPeriod
   if(g_h_adxs == INVALID_HANDLE) { Print("  [ERROR] ADXSmooth(10) 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] ADXSmooth(10)");

   // [12] ChandelierExit (디폴트)
   g_h_ce = iCustom(InpSymbol, PERIOD_M1, IND_CE,
                    22, 3.0, 4.5, 22);              // atrPeriod, mult1, mult2, lookback
   if(g_h_ce == INVALID_HANDLE) { Print("  [ERROR] ChandelierExit 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] ChandelierExit");

   // [13] ChoppingIndex (14, 14)
   g_h_chop = iCustom(InpSymbol, PERIOD_M1, IND_CHOP,
                      14, 14, 1000, 4000, 0.0);     // cho, smooth, avg, std, phase
   if(g_h_chop == INVALID_HANDLE) { Print("  [ERROR] CHOP(14,14) 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] CHOP(14,14)");

   // [14] ADXSmoothMTF H4
   g_h_adxmtf_h4 = iCustom(InpSymbol, PERIOD_M1, IND_ADXMTF,
                            PERIOD_H4, 14, 0.25, 0.33, 0, false);
   if(g_h_adxmtf_h4 == INVALID_HANDLE) { Print("  [ERROR] ADXSmoothMTF H4 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] ADXSmoothMTF H4");

   // [15] ADXSmoothMTF M5
   g_h_adxmtf_m5 = iCustom(InpSymbol, PERIOD_M1, IND_ADXMTF,
                            PERIOD_M5, 14, 0.25, 0.33, 0, false);
   if(g_h_adxmtf_m5 == INVALID_HANDLE) { Print("  [ERROR] ADXSmoothMTF M5 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] ADXSmoothMTF M5");

   // [16] BWMFI_MTF H4
   g_h_bwmfi_h4 = iCustom(InpSymbol, PERIOD_M1, IND_BWMFI,
                           PERIOD_H4, VOLUME_TICK);
   if(g_h_bwmfi_h4 == INVALID_HANDLE) { Print("  [ERROR] BWMFI_MTF H4 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] BWMFI_MTF H4");

   // [17] BWMFI_MTF M5
   g_h_bwmfi_m5 = iCustom(InpSymbol, PERIOD_M1, IND_BWMFI,
                           PERIOD_M5, VOLUME_TICK);
   if(g_h_bwmfi_m5 == INVALID_HANDLE) { Print("  [ERROR] BWMFI_MTF M5 핸들 실패"); ReleaseHandles(); return; }
   Print("  [OK] BWMFI_MTF M5");

   //--- 3. 계산 완료 대기
   Print("[Step 3] 인디케이터 계산 완료 대기...");
   int handles[] = {g_h_bop, g_h_lra60, g_h_lra180, g_h_bopwma10, g_h_bopwma30,
                    g_h_bspwma10, g_h_bspwma30, g_h_chv, g_h_tdi, g_h_qqe,
                    g_h_adxs, g_h_ce, g_h_chop, g_h_adxmtf_h4, g_h_adxmtf_m5,
                    g_h_bwmfi_h4, g_h_bwmfi_m5};
   string names[] = {"BOPAvgStd", "LRAVGST(60)", "LRAVGST(180)", "BOPWMA(10,3)", "BOPWMA(30,5)",
                     "BSPWMA(10,3)", "BSPWMA(30,5)", "CHV(10,10)", "TDI", "QQE",
                     "ADXSmooth", "CE", "CHOP", "ADXMTF_H4", "ADXMTF_M5",
                     "BWMFI_H4", "BWMFI_M5"};
   for(int n = 0; n < ArraySize(handles); n++)
   {
      if(!WaitForCalc(handles[n], total_bars, names[n]))
      {
         Print("  [WARNING] ", names[n], " 계산 미완료 - 0으로 채움");
      }
   }

   //--- 4. 버퍼 읽기
   Print("[Step 4] 버퍼 데이터 읽기...");

   // 버퍼 배열 선언
   double buf_bop_diff[], buf_bop_up1[], buf_bop_scale[];
   double buf_lra60_stds[], buf_lra60_bsp[];
   double buf_lra180_stds[], buf_lra180_bsp[];
   double buf_bopwma10[], buf_bopwma30[];
   double buf_bspwma10[], buf_bspwma30[];
   double buf_chv_chv[], buf_chv_std[], buf_chv_scale[];
   double buf_tdi_trsi[], buf_tdi_sig[];
   double buf_qqe_rsi[], buf_qqe_rsima[], buf_qqe_trl[];
   double buf_adxs_adx[], buf_adxs_avg[], buf_adxs_scale[];
   double buf_ce_upl1[], buf_ce_dnl1[], buf_ce_upl2[], buf_ce_dnl2[];
   double buf_chop_csi[], buf_chop_avg[], buf_chop_scale[];
   double buf_adxmtf_h4_dp[], buf_adxmtf_h4_dm[], buf_adxmtf_h4_adx[];
   double buf_adxmtf_m5_dp[], buf_adxmtf_m5_dm[], buf_adxmtf_m5_adx[];
   double buf_bwmfi_h4[], buf_bwmfi_h4_col[];
   double buf_bwmfi_m5[], buf_bwmfi_m5_col[];

   // CopyBuffer: 0=가장 최신 기준으로 total_bars개 복사
   // BOPAvgStd: Diff=buf[6], Up1=buf[2], Scale=buf[10]
   SafeCopyBuffer(g_h_bop, 6, 0, total_bars, buf_bop_diff, "BOP_Diff");
   SafeCopyBuffer(g_h_bop, 2, 0, total_bars, buf_bop_up1,  "BOP_Up1");
   SafeCopyBuffer(g_h_bop, 10, 0, total_bars, buf_bop_scale, "BOP_Scale");

   // LRAVGST(60): stdS=buf[6], BSPScale=buf[11]
   SafeCopyBuffer(g_h_lra60, 6, 0, total_bars, buf_lra60_stds, "LRAVGST60_StdS");
   SafeCopyBuffer(g_h_lra60, 11, 0, total_bars, buf_lra60_bsp, "LRAVGST60_BSP");

   // LRAVGST(180): stdS=buf[6], BSPScale=buf[11]
   SafeCopyBuffer(g_h_lra180, 6, 0, total_bars, buf_lra180_stds, "LRAVGST180_StdS");
   SafeCopyBuffer(g_h_lra180, 11, 0, total_bars, buf_lra180_bsp, "LRAVGST180_BSP");

   // BOPWMA: SmoothBOP=buf[0]
   SafeCopyBuffer(g_h_bopwma10, 0, 0, total_bars, buf_bopwma10, "BOPWMA10");
   SafeCopyBuffer(g_h_bopwma30, 0, 0, total_bars, buf_bopwma30, "BOPWMA30");

   // BSPWMA: SmoothDiffRatio=buf[0]
   SafeCopyBuffer(g_h_bspwma10, 0, 0, total_bars, buf_bspwma10, "BSPWMA10");
   SafeCopyBuffer(g_h_bspwma30, 0, 0, total_bars, buf_bspwma30, "BSPWMA30");

   // CHV: CHV=buf[4], StdDev=buf[9], CVScale=buf[8]
   SafeCopyBuffer(g_h_chv, 4, 0, total_bars, buf_chv_chv,   "CHV_CHV");
   SafeCopyBuffer(g_h_chv, 9, 0, total_bars, buf_chv_std,   "CHV_StdDev");
   SafeCopyBuffer(g_h_chv, 8, 0, total_bars, buf_chv_scale, "CHV_Scale");

   // TDI: TrSi=buf[0], Signal=buf[1] (AsSeries=true → 이미 반전됨)
   {
      double tmp_trsi[], tmp_sig[];
      CopyBuffer(g_h_tdi, 0, 0, total_bars, tmp_trsi);
      CopyBuffer(g_h_tdi, 1, 0, total_bars, tmp_sig);
      ArrayResize(buf_tdi_trsi, total_bars);
      ArrayResize(buf_tdi_sig,  total_bars);
      ArraySetAsSeries(tmp_trsi, false);
      ArraySetAsSeries(tmp_sig,  false);
      ArrayCopy(buf_tdi_trsi, tmp_trsi);
      ArrayCopy(buf_tdi_sig,  tmp_sig);
   }

   // QQE: RsiMa=buf[0], TrLevel=buf[1]
   SafeCopyBuffer(g_h_qqe, 0, 0, total_bars, buf_qqe_rsi,   "QQE_RsiMa");
   SafeCopyBuffer(g_h_qqe, 1, 0, total_bars, buf_qqe_rsima, "QQE_TrLevel");
   // buf_qqe_trl은 QQE에 없으므로 크기만 보장하고 0으로 채움
   ArrayResize(buf_qqe_trl, total_bars);
   ArrayInitialize(buf_qqe_trl, 0.0);

   // ADXSmooth: ADX=buf[2], Avg=buf[3], Scale=buf[6]
   SafeCopyBuffer(g_h_adxs, 2, 0, total_bars, buf_adxs_adx,   "ADXS_ADX");
   SafeCopyBuffer(g_h_adxs, 3, 0, total_bars, buf_adxs_avg,   "ADXS_Avg");
   SafeCopyBuffer(g_h_adxs, 6, 0, total_bars, buf_adxs_scale, "ADXS_Scale");

   // ChandelierExit: Upl1=buf[0], Dnl1=buf[1], Upl2=buf[2], Dnl2=buf[3]
   SafeCopyBuffer(g_h_ce, 0, 0, total_bars, buf_ce_upl1, "CE_Upl1");
   SafeCopyBuffer(g_h_ce, 1, 0, total_bars, buf_ce_dnl1, "CE_Dnl1");
   SafeCopyBuffer(g_h_ce, 2, 0, total_bars, buf_ce_upl2, "CE_Upl2");
   SafeCopyBuffer(g_h_ce, 3, 0, total_bars, buf_ce_dnl2, "CE_Dnl2");

   // ChoppingIndex: CSI=buf[3], Avg=buf[1], Scale=buf[5]
   SafeCopyBuffer(g_h_chop, 3, 0, total_bars, buf_chop_csi,   "CHOP_CSI");
   SafeCopyBuffer(g_h_chop, 1, 0, total_bars, buf_chop_avg,   "CHOP_Avg");
   SafeCopyBuffer(g_h_chop, 5, 0, total_bars, buf_chop_scale, "CHOP_Scale");

   // ADXSmoothMTF H4: DiPlus=buf[0], DiMinus=buf[1], ADX=buf[2]
   SafeCopyBuffer(g_h_adxmtf_h4, 0, 0, total_bars, buf_adxmtf_h4_dp,  "ADXMTF_H4_DiPlus");
   SafeCopyBuffer(g_h_adxmtf_h4, 1, 0, total_bars, buf_adxmtf_h4_dm,  "ADXMTF_H4_DiMinus");
   SafeCopyBuffer(g_h_adxmtf_h4, 2, 0, total_bars, buf_adxmtf_h4_adx, "ADXMTF_H4_ADX");

   // ADXSmoothMTF M5: DiPlus=buf[0], DiMinus=buf[1], ADX=buf[2]
   SafeCopyBuffer(g_h_adxmtf_m5, 0, 0, total_bars, buf_adxmtf_m5_dp,  "ADXMTF_M5_DiPlus");
   SafeCopyBuffer(g_h_adxmtf_m5, 1, 0, total_bars, buf_adxmtf_m5_dm,  "ADXMTF_M5_DiMinus");
   SafeCopyBuffer(g_h_adxmtf_m5, 2, 0, total_bars, buf_adxmtf_m5_adx, "ADXMTF_M5_ADX");

   // BWMFI_MTF H4: BWMFI=buf[0], Color=buf[1]
   SafeCopyBuffer(g_h_bwmfi_h4, 0, 0, total_bars, buf_bwmfi_h4,     "BWMFI_H4");
   SafeCopyBuffer(g_h_bwmfi_h4, 1, 0, total_bars, buf_bwmfi_h4_col, "BWMFI_H4_Color");

   // BWMFI_MTF M5: BWMFI=buf[0], Color=buf[1]
   SafeCopyBuffer(g_h_bwmfi_m5, 0, 0, total_bars, buf_bwmfi_m5,     "BWMFI_M5");
   SafeCopyBuffer(g_h_bwmfi_m5, 1, 0, total_bars, buf_bwmfi_m5_col, "BWMFI_M5_Color");

   //--- 5. CSV 파일 저장 (OUTPUT_START ~ OUTPUT_END 필터링)
   Print("[Step 5] CSV 파일 저장...");

   int file_handle = FileOpen(InpOutputFile, FILE_CSV|FILE_WRITE|FILE_ANSI);
   if(file_handle == INVALID_HANDLE)
   {
      Print("  [ERROR] 파일 열기 실패: ", InpOutputFile, " err=", GetLastError());
      ReleaseHandles();
      return;
   }

   // 헤더 작성 (Python 출력과 동일한 컬럼 순서)
   FileWrite(file_handle,
      "Time", "Open", "Close", "High", "Low", "TickVolume",
      "BOP_Diff", "BOP_Up1", "BOP_Scale",
      "LRAVGST_Avg(60)_StdS", "LRAVGST_Avg(60)_BSPScale",
      "LRAVGST_Avg(180)_StdS", "LRAVGST_Avg(180)_BSPScale",
      "BOPWMA_(10,3)_SmoothBOP", "BOPWMA_(30,5)_SmoothBOP",
      "BSPWMA_(10,3)_SmoothDiffRatio", "BSPWMA_(30,5)_SmoothDiffRatio",
      "CHV_(10,10)_CHV", "CHV_(10,10)_StdDev", "CHV_(10,10)_CVScale",
      "TDI_(13,34,2,7)_TrSi", "TDI_(13,34,2,7)_Signal",
      "QQE_(5,14)_RSI", "QQE_(5,14)_RsiMa", "QQE_(5,14)_TrLevel",
      "ADXS_(10,5)_ADX", "ADXS_(10,5)_Avg", "ADXS_(10,5)_Scale",
      "CE_Upl1", "CE_Dnl1", "CE_Upl2", "CE_Dnl2",
      "CHOP_(14,14)_CSI", "CHOP_(14,14)_Avg", "CHOP_(14,14)_Scale",
      "ADXMTF_H4_DiPlus", "ADXMTF_H4_DiMinus", "ADXMTF_H4_ADX",
      "ADXMTF_M5_DiPlus", "ADXMTF_M5_DiMinus", "ADXMTF_M5_ADX",
      "BWMTF_H4_BWMFI", "BWMTF_H4_Color",
      "BWMTF_M5_BWMFI", "BWMTF_M5_Color");

   int written_rows = 0;
   for(int k = 0; k < total_bars; k++)
   {
      datetime bar_time = rates[k].time;

      // 출력 기간 필터
      if(bar_time < OUTPUT_START || bar_time > OUTPUT_END) continue;

      // EMPTY_VALUE 처리 함수 (인라인)
      #define FMT(v) ((v == EMPTY_VALUE || v == DBL_MAX) ? "NaN" : DoubleToString(v, 6))

      string timeStr = TimeToString(bar_time, TIME_DATE|TIME_MINUTES);

      FileWrite(file_handle,
         timeStr,
         DoubleToString(rates[k].open,  _Digits),
         DoubleToString(rates[k].close, _Digits),
         DoubleToString(rates[k].high,  _Digits),
         DoubleToString(rates[k].low,   _Digits),
         (string)rates[k].tick_volume,
         // BOP
         FMT(buf_bop_diff[k]),  FMT(buf_bop_up1[k]),   FMT(buf_bop_scale[k]),
         // LRAVGST 60
         FMT(buf_lra60_stds[k]), FMT(buf_lra60_bsp[k]),
         // LRAVGST 180
         FMT(buf_lra180_stds[k]), FMT(buf_lra180_bsp[k]),
         // BOPWMA
         FMT(buf_bopwma10[k]), FMT(buf_bopwma30[k]),
         // BSPWMA
         FMT(buf_bspwma10[k]), FMT(buf_bspwma30[k]),
         // CHV
         FMT(buf_chv_chv[k]), FMT(buf_chv_std[k]), FMT(buf_chv_scale[k]),
         // TDI
         FMT(buf_tdi_trsi[k]), FMT(buf_tdi_sig[k]),
         // QQE
         FMT(buf_qqe_rsi[k]), FMT(buf_qqe_rsima[k]), FMT(buf_qqe_trl[k]),
         // ADXSmooth
         FMT(buf_adxs_adx[k]), FMT(buf_adxs_avg[k]), FMT(buf_adxs_scale[k]),
         // ChandelierExit
         FMT(buf_ce_upl1[k]), FMT(buf_ce_dnl1[k]), FMT(buf_ce_upl2[k]), FMT(buf_ce_dnl2[k]),
         // CHOP
         FMT(buf_chop_csi[k]), FMT(buf_chop_avg[k]), FMT(buf_chop_scale[k]),
         // ADXSmoothMTF H4
         FMT(buf_adxmtf_h4_dp[k]), FMT(buf_adxmtf_h4_dm[k]), FMT(buf_adxmtf_h4_adx[k]),
         // ADXSmoothMTF M5
         FMT(buf_adxmtf_m5_dp[k]), FMT(buf_adxmtf_m5_dm[k]), FMT(buf_adxmtf_m5_adx[k]),
         // BWMFI H4
         FMT(buf_bwmfi_h4[k]), FMT(buf_bwmfi_h4_col[k]),
         // BWMFI M5
         FMT(buf_bwmfi_m5[k]), FMT(buf_bwmfi_m5_col[k])
      );
      written_rows++;
   }

   FileClose(file_handle);
   Print("  저장 완료: Files/", InpOutputFile);
   Print("  저장된 행 수: ", written_rows);

   //--- 6. 핸들 해제
   ReleaseHandles();

   Print("==========================================================");
   Print("  TotalResult_DownLoad.mq5 완료!");
   Print("  출력 파일: Files/", InpOutputFile);
   Print("==========================================================");
}
//+------------------------------------------------------------------+
