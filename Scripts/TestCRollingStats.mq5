//+------------------------------------------------------------------+
//| TestCRollingStats.mq5 — Unit test for CRollingStats              |
//| Run as Script in MT5 → check Experts tab for output              |
//+------------------------------------------------------------------+
#property script_show_inputs
#include <AIEngine/CRollingStats.mqh>

//+------------------------------------------------------------------+
//| Helper: compare with tolerance                                    |
//+------------------------------------------------------------------+
bool AlmostEqual(double a, double b, double tol = 1e-6)
{
   return MathAbs(a - b) < tol;
}

void AssertAlmostEqual(string testName, double actual, double expected, double tol = 1e-4)
{
   if(AlmostEqual(actual, expected, tol))
      Print("  ✅ PASS: ", testName, " = ", DoubleToString(actual, 6),
            " (expected ", DoubleToString(expected, 6), ")");
   else
      Print("  ❌ FAIL: ", testName, " = ", DoubleToString(actual, 6),
            " (expected ", DoubleToString(expected, 6), ", diff=",
            DoubleToString(MathAbs(actual - expected), 8), ")");
}

//+------------------------------------------------------------------+
//| Test 1: Basic Push + Mean + Std                                  |
//+------------------------------------------------------------------+
void TestBasicStats()
{
   Print("=== Test 1: Basic Push + Mean + Std ===");
   
   CRollingStats stats;
   stats.Init(10);
   
   // Push values 1..10
   for(int i = 1; i <= 10; i++)
      stats.Push((double)i);
   
   // Mean of 1..10 = 5.5
   AssertAlmostEqual("Mean(10)", stats.GetMean(10), 5.5);
   
   // Mean of last 5 (6,7,8,9,10) = 8.0
   AssertAlmostEqual("Mean(5)", stats.GetMean(5), 8.0);
   
   // Std of 1..10 (population std) = sqrt(8.25) ≈ 2.8723
   AssertAlmostEqual("Std(10)", stats.GetStd(10), 2.8723, 0.001);
   
   // Latest = 10
   AssertAlmostEqual("Latest", stats.GetLatest(), 10.0);
   
   // Count = 10
   Print("  Count: ", stats.GetCount(), " (expected 10)");
   Print("  IsReady(10): ", stats.IsReady(10), " (expected true)");
   Print("  IsReady(11): ", stats.IsReady(11), " (expected false)");
}

//+------------------------------------------------------------------+
//| Test 2: Ring buffer overflow                                     |
//+------------------------------------------------------------------+
void TestRingOverflow()
{
   Print("\n=== Test 2: Ring Buffer Overflow ===");
   
   CRollingStats stats;
   stats.Init(5);  // capacity = 5
   
   // Push 1..10 → buffer should contain [6,7,8,9,10]
   for(int i = 1; i <= 10; i++)
      stats.Push((double)i);
   
   AssertAlmostEqual("Latest", stats.GetLatest(), 10.0);
   AssertAlmostEqual("Mean(5)", stats.GetMean(5), 8.0);  // (6+7+8+9+10)/5 = 8.0
   Print("  Count: ", stats.GetCount(), " (expected 5, capped at capacity)");
}

//+------------------------------------------------------------------+
//| Test 3: Z-score                                                  |
//+------------------------------------------------------------------+
void TestZScore()
{
   Print("\n=== Test 3: Z-score ===");
   
   CRollingStats stats;
   stats.Init(100);
   
   // Push 100 values: all 50.0 except last = 60.0
   for(int i = 0; i < 99; i++)
      stats.Push(50.0);
   stats.Push(60.0);
   
   // Mean ≈ (99*50 + 60) / 100 = 50.1
   // Std ≈ small but nonzero
   double z = stats.GetZScore(100);
   Print("  Z-score(100) = ", DoubleToString(z, 4), " (should be large positive, ~10)");
   
   // With window=10: last 10 values = [50,50,50,50,50,50,50,50,50,60]
   double z10 = stats.GetZScore(10);
   Print("  Z-score(10) = ", DoubleToString(z10, 4), " (should be ~3.0)");
   
   // More precise: mean=51, std=3.0, z=(60-51)/3=3.0
   AssertAlmostEqual("Z-score(10)", z10, 3.0, 0.01);
}

//+------------------------------------------------------------------+
//| Test 4: Percentile Rank                                          |
//+------------------------------------------------------------------+
void TestPctRank()
{
   Print("\n=== Test 4: Percentile Rank ===");
   
   CRollingStats stats;
   stats.Init(100);
   
   // Push 1..100
   for(int i = 1; i <= 100; i++)
      stats.Push((double)i);
   
   // Latest=100, all 100 values ≤ 100 → pctRank = 100/100 = 1.0
   AssertAlmostEqual("PctRank(100) [max]", stats.GetPctRank(100), 1.0);
   
   // Push 50 → latest=50, 50 out of 100 values ≤ 50 → pctRank = 50/100 = 0.50
   stats.Push(50.0);
   // Now buffer: [2,3,...,100,50], window=100
   // Values ≤ 50: 2..50 = 49 values + 50 itself = 50 values. pctRank = 50/100 = 0.50
   AssertAlmostEqual("PctRank(100) [mid]", stats.GetPctRank(100), 0.50);
}

//+------------------------------------------------------------------+
//| Test 5: Slope (linear regression)                                |
//+------------------------------------------------------------------+
void TestSlope()
{
   Print("\n=== Test 5: Slope ===");
   
   CRollingStats stats;
   stats.Init(100);
   
   // Push perfectly linear: y = 2*x + 10
   for(int i = 0; i < 20; i++)
      stats.Push(2.0 * i + 10.0);
   
   // Slope over 20 should be exactly 2.0
   AssertAlmostEqual("Slope(20) [linear]", stats.GetSlope(20), 2.0);
   
   // Push constant values
   CRollingStats stats2;
   stats2.Init(100);
   for(int i = 0; i < 20; i++)
      stats2.Push(42.0);
   
   AssertAlmostEqual("Slope(20) [constant]", stats2.GetSlope(20), 0.0);
}

//+------------------------------------------------------------------+
//| Test 6: Acceleration                                             |
//+------------------------------------------------------------------+
void TestAccel()
{
   Print("\n=== Test 6: Acceleration ===");
   
   CRollingStats stats;
   stats.Init(100);
   
   // Push linear y=x → constant slope → accel ≈ 0
   for(int i = 0; i < 50; i++)
      stats.Push((double)i);
   
   double accel = stats.GetAccel(10, 10);
   Print("  Accel(10,10) [linear] = ", DoubleToString(accel, 6), " (should be ~0)");
   AssertAlmostEqual("Accel(10,10) [linear]", accel, 0.0, 0.001);
}

//+------------------------------------------------------------------+
//| Test 7: PushArray (history preload)                              |
//+------------------------------------------------------------------+
void TestPushArray()
{
   Print("\n=== Test 7: PushArray (preload) ===");
   
   CRollingStats stats;
   stats.Init(10);
   
   double vals[];
   ArrayResize(vals, 5);
   vals[0] = 1.0; vals[1] = 2.0; vals[2] = 3.0; vals[3] = 4.0; vals[4] = 5.0;
   
   stats.PushArray(vals, 5);
   
   AssertAlmostEqual("Latest after PushArray", stats.GetLatest(), 5.0);
   AssertAlmostEqual("Mean(5) after PushArray", stats.GetMean(5), 3.0);
   Print("  Count: ", stats.GetCount(), " (expected 5)");
}

//+------------------------------------------------------------------+
//| Test 8: FillRatio for warm-up display                            |
//+------------------------------------------------------------------+
void TestFillRatio()
{
   Print("\n=== Test 8: FillRatio ===");
   
   CRollingStats stats;
   stats.Init(240);
   
   for(int i = 0; i < 120; i++)
      stats.Push((double)i);
   
   AssertAlmostEqual("FillRatio(240)", stats.GetFillRatio(240), 0.5);
   AssertAlmostEqual("FillRatio(60)", stats.GetFillRatio(60), 1.0);  // 120 >= 60
}

//+------------------------------------------------------------------+
//| Script entry point                                               |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("╔═══════════════════════════════════════════════╗");
   Print("║   CRollingStats Unit Test Suite               ║");
   Print("╚═══════════════════════════════════════════════╝");
   
   TestBasicStats();
   TestRingOverflow();
   TestZScore();
   TestPctRank();
   TestSlope();
   TestAccel();
   TestPushArray();
   TestFillRatio();
   
   Print("\n═══════════════════════════════════════════════");
   Print("  All tests completed. Check PASS/FAIL above.");
   Print("═══════════════════════════════════════════════");
}
