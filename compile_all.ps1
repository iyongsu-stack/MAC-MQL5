
$MT = "C:\Program Files\MetaTrader5\MetaEditor64.exe"
$root = "C:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5"

$files = @(
    "Indicators\BOP\BOPAvgStdDownLoad.mq5",
    "Indicators\BOP\BOPWmaSmoothDownLoad.mq5",
    "Indicators\BSP105V9\BSPWmaSmoothDownLoad.mq5",
    "Indicators\BSP105V9\Chaikin VolatilityDownLoad.mq5",
    "Indicators\BSP105V9\LRAVGSTDownLoad.mq5",
    "Indicators\Test\ADXSmoothDownLoad.mq5",
    "Indicators\Test\ADXSmoothMTFDownLoad.mq5",
    "Indicators\Test\BWMFI_MTFDownLoad.mq5",
    "Indicators\Test\ChandelieExitDownLoad.mq5",
    "Indicators\Test\ChoppingIndexDownLoad.mq5",
    "Indicators\Test\TradesDynamicIndexDownLoad.mq5"
)

foreach ($f in $files) {
    $full = "$root\$f"
    & $MT /compile:"$full" /log | Out-Null
    Start-Sleep -Milliseconds 1500
    $logFile = "$full" -replace "\.mq5$", ".log"
    if (Test-Path $logFile) {
        $last = (Get-Content $logFile -Tail 1).Trim()
        if ($last -match "0 errors") {
            Write-Host "[PASS] $(Split-Path $f -Leaf)"
        } else {
            Write-Host "[FAIL] $(Split-Path $f -Leaf) : $last"
        }
    } else {
        Write-Host "[OK?] $(Split-Path $f -Leaf) (로그없음)"
    }
}
