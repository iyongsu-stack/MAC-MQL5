# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a MetaTrader 5 (MQL5) algorithmic trading system containing Expert Advisors (automated trading robots), custom indicators, and reusable libraries. The codebase is located in the standard MQL5 data folder structure.

## Build Commands

Compile MQL5 files using MetaEditor 64-bit:
```bash
"C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:<file_path> /log
```

VSCode is configured with a build task (Ctrl+Shift+B) that compiles the current file.

## Code Architecture

### Directory Structure
- `Experts/` - Expert Advisors (EAs) - automated trading robots
- `Indicators/` - Custom technical analysis indicators
- `Include/` - Reusable header files and libraries
- `Scripts/` - Utility scripts for one-time operations
- `Presets/` - Strategy parameter configurations (.set files)

### Core Libraries (Include/)

**Trade.mqh** - `CTrade` class for order management
- Methods: `Buy()`, `Sell()`, `BuyStop()`, `SellStop()`, `BuyLimit()`, `SellLimit()`
- Position modification: `ModifyPosition()`, `ModifyPending()`
- Includes retry logic with `MAX_RETRIES=5` and `RETRY_DELAY=3000ms`

**Indicators.mqh** - `CIndicator` base class and wrappers
- Subclasses: `CiMA`, `CiRSI`, `CiStochastic`, `CiBollinger`, `CiMACD`, `CiSAR`, `CiADX`
- Pattern: Call `Init()` with symbol/timeframe/parameters, then `Main(shift)` to get values

**TrailingStops.mqh** - `CTrailing` class for trailing stop management

**MoneyManagement.mqh** - Risk-based position sizing functions

**EasyAndFastGUI/** - Complete GUI framework for interactive dashboards
- `CWndContainer` - Window container for UI elements
- `CWindow` - Main window class
- `CWndEvents` - Event handling system
- Controls: Button, TextBox, ComboBox, Calendar, Table, TreeView, etc.

### Coding Conventions

- File headers use `#property copyright` and `#property link`
- Section dividers: `//+------------------------------------------------------------------+`
- Tab size: 3 spaces
- MQL files (.mq5, .mqh) are treated as C++ for IntelliSense
- Compiled files (.ex4, .ex5) are excluded from version control

### Common Patterns

```cpp
// Initialize structs with ZeroMemory
MqlTradeRequest request;
ZeroMemory(request);

// Array as series for indicator buffers
ArraySetAsSeries(buffer, true);

// Error handling
if(GetLastError() != 0) { /* handle error */ }
```

## MQL5 Reference

- Official documentation: https://www.mql5.com/en/book
- Code examples: https://www.mql5.com/en/code
- Main site: https://www.mql5.com/en

## File Types

- `.mq5` - MQL5 source files (Expert Advisors, Indicators, Scripts)
- `.mqh` - MQL5 header/include files
- `.ex5` - Compiled MQL5 files (binary, not editable)
- `.set` - Strategy parameter presets
