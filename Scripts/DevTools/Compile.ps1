param (
   [Parameter(Mandatory = $true)]
   [string]$TargetFile,
    
   [string]$MetaEditorPath = "C:\Program Files\MetaTrader5\MetaEditor64.exe"
)

# 0. Path Adjustments & Validation
$Paths = @(
   "C:\Program Files\MetaTrader5\MetaEditor64.exe",
   "C:\Program Files\MetaTrader5\metaeditor64.exe",
   "C:\Program Files\MetaTrader 5\MetaEditor64.exe",
   "C:\Program Files\MetaTrader 5\metaeditor64.exe"
)

$MetaEditorExe = ""
foreach ($p in $Paths) {
   if (Test-Path $p) {
      $MetaEditorExe = $p
      break
   }
}

if ($MetaEditorExe -eq "") {
   Write-Warning "MetaEditor not found in standard paths. Trying default: $MetaEditorPath"
   $MetaEditorExe = $MetaEditorPath
}

# Resolve absolute path for target
$TargetFile = Resolve-Path $TargetFile
$LogFile = Join-Path "C:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Logs" "$((Split-Path $TargetFile -Leaf).Replace('.mq5','.log'))"

# Clean old log
if (Test-Path $LogFile) { Remove-Item $LogFile -Force }

Write-Host "Compiling: $TargetFile"
Write-Host "Using: $MetaEditorExe"
Write-Host "Log: $LogFile"

# 1. Execute Compilation (Direct Call)
# We use & operator. Note that MetaEditor is a GUI app, so it might return immediately or wait.
# /log argument should make it write to file.
$arg1 = "/compile:$TargetFile"
$arg2 = "/log:$LogFile"

Write-Host "Executing..."
& $MetaEditorExe $arg1 $arg2

# Wait a bit for file to appear effectively
Start-Sleep -Seconds 3

# 2. Check and Output Log
if (Test-Path $LogFile) {
   Write-Host "--- LOG START ---"
   Get-Content $LogFile
   Write-Host "--- LOG END ---"
}
else {
   Write-Error "Log file not found after execution."
}

