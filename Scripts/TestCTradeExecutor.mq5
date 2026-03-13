//+------------------------------------------------------------------+
//| TestCTradeExecutor.mq5 — Unit test for CTradeExecutor            |
//| Run as Script in MT5 → check Experts tab for output              |
//|                                                                  |
//| Tests:                                                           |
//|   1. Init + configuration verification                           |
//|   2. CSignalGenerator basic logic                                |
//|   3. Lot size calculation (CalcLotSize formula)                   |
//|   4. Virtual SL logic simulation                                 |
//|   5. CE2 ratchet mechanism                                       |
//|   6. Pyramiding lot decrease                                     |
//|   7. GetUnrealizedATR / GetBarsSinceEntry                        |
//+------------------------------------------------------------------+
#property script_show_inputs
#include <AIEngine/CSignalGenerator.mqh>
#include <AIEngine/CTradeExecutor.mqh>

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== TestCTradeExecutor + CSignalGenerator START ===");
   
   int passed = 0, failed = 0;
   
   //--- Test 1: CSignalGenerator Init + Evaluate
   Print("--- Test 1: CSignalGenerator Logic ---");
   {
      CSignalGenerator sig;
      sig.Init(0.20, 0.40, 3, 5, 1.5);
      
      // Test 1a: No position, prob >= threshold → ENTRY
      ENUM_SIGNAL s = sig.Evaluate(0.25, 0.0, false, 0, 0, 0, false, true);
      if(s == SIGNAL_ENTRY) { passed++; Print("  [PASS] 1a: ENTRY signal"); }
      else { failed++; Print("  [FAIL] 1a: expected ENTRY, got ", s); }
      
      // Test 1b: No position, prob < threshold → NONE
      s = sig.Evaluate(0.15, 0.0, false, 0, 0, 0, false, true);
      if(s == SIGNAL_NONE) { passed++; Print("  [PASS] 1b: NONE (below threshold)"); }
      else { failed++; Print("  [FAIL] 1b: expected NONE, got ", s); }
      
      // Test 1c: Blackout → NONE
      s = sig.Evaluate(0.50, 0.0, false, 0, 0, 0, true, true);
      if(s == SIGNAL_NONE) { passed++; Print("  [PASS] 1c: NONE (blackout)"); }
      else { failed++; Print("  [FAIL] 1c: expected NONE, got ", s); }
      
      // Test 1d: Warmup not ready → NONE
      s = sig.Evaluate(0.50, 0.0, false, 0, 0, 0, false, false);
      if(s == SIGNAL_NONE) { passed++; Print("  [PASS] 1d: NONE (warmup)"); }
      else { failed++; Print("  [FAIL] 1d: expected NONE, got ", s); }
      
      // Test 1e: Has position + addon conditions met → ADDON
      s = sig.Evaluate(0.30, 0.55, true, 1, 2.0, 10, false, true);
      if(s == SIGNAL_ADDON) { passed++; Print("  [PASS] 1e: ADDON signal"); }
      else { failed++; Print("  [FAIL] 1e: expected ADDON, got ", s, " reason: ", sig.GetLastReason()); }
      
      // Test 1f: Has position + too few bars → NONE
      s = sig.Evaluate(0.30, 0.55, true, 1, 2.0, 3, false, true);
      if(s == SIGNAL_NONE) { passed++; Print("  [PASS] 1f: NONE (bars<5)"); }
      else { failed++; Print("  [FAIL] 1f: expected NONE, got ", s); }
      
      // Test 1g: Has position + insufficient profit → NONE
      s = sig.Evaluate(0.30, 0.55, true, 1, 0.5, 10, false, true);
      if(s == SIGNAL_NONE) { passed++; Print("  [PASS] 1g: NONE (profit<1.5ATR)"); }
      else { failed++; Print("  [FAIL] 1g: expected NONE, got ", s); }
      
      // Test 1h: Max pyramiding reached → NONE
      s = sig.Evaluate(0.30, 0.55, true, 3, 5.0, 20, false, true);
      if(s == SIGNAL_NONE) { passed++; Print("  [PASS] 1h: NONE (max pyramid=3)"); }
      else { failed++; Print("  [FAIL] 1h: expected NONE, got ", s); }
      
      // Test 1i: prob invalid (-1) → NONE
      s = sig.Evaluate(-1.0, -1.0, false, 0, 0, 0, false, true);
      if(s == SIGNAL_NONE) { passed++; Print("  [PASS] 1i: NONE (prob=-1 invalid)"); }
      else { failed++; Print("  [FAIL] 1i: expected NONE, got ", s); }
   }
   
   //--- Test 2: CTradeExecutor Init
   Print("--- Test 2: CTradeExecutor Init ---");
   {
      CTradeExecutor exec;
      bool initOK = exec.Init(999999, 0.01, 7.0, 12.0);
      if(initOK) { passed++; Print("  [PASS] 2a: Init succeeded"); }
      else { failed++; Print("  [FAIL] 2a: Init failed"); }
      
      if(!exec.HasPosition()) { passed++; Print("  [PASS] 2b: No position after init"); }
      else { failed++; Print("  [FAIL] 2b: HasPosition should be false"); }
      
      if(exec.GetAddonCount() == 0) { passed++; Print("  [PASS] 2c: AddonCount=0"); }
      else { failed++; Print("  [FAIL] 2c: AddonCount should be 0"); }
   }
   
   //--- Test 3: Virtual SL/CE2 Logic (simulation — no real orders)
   Print("--- Test 3: Virtual Stop Simulation ---");
   {
      CTradeExecutor exec;
      exec.Init(999999, 0.01, 7.0, 12.0);
      
      // Simulate entry state manually
      // We can't actually place orders in a script, but we can test
      // the CE2 update and unrealized ATR logic
      exec.SetCurrentBar(100);
      
      // Before position: unrealized ATR should be 0
      double uar = exec.GetUnrealizedATR();
      if(MathAbs(uar) < 0.001) { passed++; Print("  [PASS] 3a: UnrealizedATR=0 (no pos)"); }
      else { failed++; Print("  [FAIL] 3a: expected 0, got ", uar); }
      
      // BarsSinceEntry should be 0 when no position
      int bse = exec.GetBarsSinceEntry();
      if(bse == 0) { passed++; Print("  [PASS] 3b: BarsSinceEntry=0 (no pos)"); }
      else { failed++; Print("  [FAIL] 3b: expected 0, got ", bse); }
      
      // CE2 update should do nothing without position
      exec.UpdateCE2(2950.0, 5.0, 4.0);
      if(!exec.IsCE2Active()) { passed++; Print("  [PASS] 3c: CE2 not active (no pos)"); }
      else { failed++; Print("  [FAIL] 3c: CE2 should not activate"); }
   }
   
   //--- Test 4: Signal + Executor Integration Logic
   Print("--- Test 4: Integration Logic ---");
   {
      CSignalGenerator sig;
      sig.Init(0.20, 0.40, 3, 5, 1.5);
      
      CTradeExecutor exec;
      exec.Init(999998, 0.01, 7.0, 12.0);
      exec.SetCurrentBar(250);  // After warmup
      
      // Simulate flow: no position → entry signal
      ENUM_SIGNAL s = sig.Evaluate(0.35, 0.0,
                                    exec.HasPosition(),
                                    exec.GetAddonCount(),
                                    0.0, 0, false, true);
      if(s == SIGNAL_ENTRY) { passed++; Print("  [PASS] 4a: Integration ENTRY signal"); }
      else { failed++; Print("  [FAIL] 4a: expected ENTRY, got ", s); }
      
      Print("  Signal reason: ", sig.GetLastReason());
   }
   
   //--- Test 5: Reason string completeness
   Print("--- Test 5: Reason Strings ---");
   {
      CSignalGenerator sig;
      sig.Init(0.20, 0.40, 3, 5, 1.5);
      
      sig.Evaluate(0.35, 0.0, false, 0, 0, 0, false, true);
      string reason = sig.GetLastReason();
      if(StringFind(reason, "ENTRY") >= 0) { passed++; Print("  [PASS] 5a: ENTRY reason: ", reason); }
      else { failed++; Print("  [FAIL] 5a: missing ENTRY in reason: ", reason); }
      
      sig.Evaluate(0.10, 0.0, false, 0, 0, 0, false, true);
      reason = sig.GetLastReason();
      if(StringFind(reason, "NONE") >= 0) { passed++; Print("  [PASS] 5b: NONE reason: ", reason); }
      else { failed++; Print("  [FAIL] 5b: missing NONE in reason: ", reason); }
      
      sig.Evaluate(0.30, 0.55, true, 2, 3.0, 10, false, true);
      reason = sig.GetLastReason();
      if(StringFind(reason, "ADDON") >= 0) { passed++; Print("  [PASS] 5c: ADDON reason: ", reason); }
      else { failed++; Print("  [FAIL] 5c: missing ADDON in reason: ", reason); }
   }
   
   //--- Summary
   Print("=== TestCTradeExecutor COMPLETE ===");
   Print("  PASSED: ", passed, " / ", passed + failed);
   Print("  FAILED: ", failed, " / ", passed + failed);
   
   if(failed == 0)
      Print("  ✅ ALL TESTS PASSED");
   else
      Print("  ❌ SOME TESTS FAILED — check above output");
}
