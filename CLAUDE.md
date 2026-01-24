# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

Compile MQL5 source files using MetaEditor64:
```bash
"C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:<filepath> /log
```

In VS Code, use the default build task (Ctrl+Shift+B) which is configured to compile the current file.

## MQL5 Reference

Always refer to official MQL5 documentation:
- Main site: https://www.mql5.com/en
- Language manual: https://www.mql5.com/en/book
- Code examples: https://www.mql5.com/en/code

## Codebase Architecture

### Directory Structure

- `Experts/` - Expert Advisors (trading robots), including BSP strategy family
- `Indicators/` - Custom technical indicators (BSP105*, SuperTrend, VolumeProfile, etc.)
- `Include/` - Header libraries organized by version and function
- `Scripts/` - Utility scripts for testing and data processing
- `Profiles/Templates/` - Trading templates (T1-T13 parameter configurations)
- `Files/` - Data files and CSV configurations

### BSP Framework (Core Trading System)

The BSP (Bollinger Squeeze Pressure) framework is the main trading system with 6 versions (BSPV4-BSPV9) in `Include/BSPVx/`. Each version uses modular component architecture:

| Module | Purpose |
|--------|---------|
| `ExternVariables.mqh` | Central parameter repository (include first) |
| `CommonVx.mqh` | Time management, bar detection, session filtering |
| `InitVx.mqh` | EA initialization logic |
| `IndicatorVx.mqh` | Indicator handle management and data retrieval |
| `OpenCloseVx.mqh` | Trade entry/exit logic |
| `MoneyManageVx.mqh` | Dynamic position sizing |
| `TrailingStopVx.mqh` | Profit protection mechanisms |
| `StopLossVx.mqh` | Initial risk management |
| `PyramidVx.mqh` | Position averaging/pyramiding |
| `SessionManVx.mqh` | Multi-session management |
| `MagicNumberVx.mqh` | EA identification system |
| `ReadyCheckVx.mqh` | Trading condition validation |
| `DeinitVx.mqh` | Cleanup on EA removal |

### Position Management

The framework uses enumerated position modes (26+ states):
- Base modes: `MiddleReverse`, `LongReverse`, `LongCounter`, `DoubleLongReverse`
- Variants with `Con` (Consolidation) and `Pyr` (Pyramiding) suffixes
- Band-based zones: BandM3 through BandP3 (7 price levels)
- Supports 10 parallel trading sessions, up to 100 positions per session

### Standard Libraries

The codebase uses MetaQuotes standard libraries from `Include/`:
- `Trade/Trade.mqh` - CTrade class for order execution
- `Trade/PositionInfo.mqh` - CPositionInfo for position tracking
- `Trade/SymbolInfo.mqh` - CSymbolInfo for market data
- `Expert/Expert.mqh` - CExpert base class for EA framework

### Custom Indicators

BSP strategies rely on these custom indicators in `Indicators/`:
- `BSP105NLR` - Non-Linear Regression
- `BSP105LRAVGSTD` - Linear Regression + Average + StDev
- `BSP105WMA` - Weighted Moving Average
- `BSP105BSP` - Pressure calculation

## Code Conventions

### File Structure
```mql5
//+------------------------------------------------------------------+
//| Filename.mq5                                                      |
//| Author: Yong-su, Kim                                              |
//| Link: https://www.mql5.com                                        |
//+------------------------------------------------------------------+
#property copyright "..."
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <BSPV9/ExternVariables.mqh>  // Include ExternVariables first
```

### Naming Patterns
- Indicator macros: `#define IND1 "BSP105V4\\BSP105NLR"`
- Input groups: `input group "Risk Management"`
- Version suffixes: Module files use Vx suffix (e.g., `OpenCloseV8.mqh`)

### Editor Settings
- Tab size: 3 spaces
- File associations: `.mq5`, `.mq4`, `.mqh` treated as C++

## Testing

Templates in `Profiles/Templates/` contain predefined parameter sets:
- Named as `BSP105Vx-Ty.tpl` where x=version, y=template number
- Test variants: `*Test`, `*test` suffixes
- Load templates in MetaTrader 5 Strategy Tester for backtesting
