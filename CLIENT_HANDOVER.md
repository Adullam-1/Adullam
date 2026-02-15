# BuffaloSpeed MT5 Client Handover Guide

## 1) What BuffaloSpeed does
BuffaloSpeed is an automated MetaTrader 5 (MT5) Expert Advisor (EA) that:
- scans multiple symbols from a configured symbol list,
- generates trade signals using EMA crossover logic,
- calculates lot size from account risk settings,
- opens trades with SL/TP checks against broker stop rules,
- manages open positions using break-even and trailing stop,
- blocks new trades if drawdown/daily loss limits are breached,
- displays a live dashboard on chart,
- validates license key before trading.

## 2) Installation (MT5)
1. Open MT5 -> File -> Open Data Folder.
2. Go to `MQL5/Experts/`.
3. Copy these files into that folder:
   - BuffaloSpeed.mq5
   - BuffaloLogger.mqh
   - BuffaloDashboard.mqh
   - BuffaloSymbolManager.mqh
   - BuffaloSignalEngine.mqh
   - BuffaloMoneyManager.mqh
   - BuffaloTradeManager.mqh
   - BuffaloRiskManager.mqh
4. Restart MT5 (or refresh Navigator).
5. Open `BuffaloSpeed.mq5` in MetaEditor and compile.

## 3) Setup before running
- Attach BuffaloSpeed to one chart.
- Enable **Algo Trading** in MT5.
- Set inputs:
  - License: `InpLicenseKey`
  - Symbols: `InpSymbols` (comma-separated, e.g. EURUSD,GBPUSD,USDJPY)
  - Signal: timeframe + MA periods
  - Risk: per-trade %, max daily loss %, max drawdown %
  - Protection: stop loss, take profit, break-even, trailing stop
  - Execution: magic number, slippage

## 4) How execution works
1. On init: license + symbol validation + module setup.
2. Every timer cycle:
   - risk check runs,
   - each configured symbol is processed,
   - duplicate same-candle entries are prevented,
   - signal is evaluated,
   - lot size is calculated,
   - order is sent only if broker stop-distance constraints are valid.
3. If position is open, SL is managed by break-even/trailing logic.

## 5) How to monitor it
Use the chart dashboard for:
- License status
- Symbol count
- Risk check state (OK/BLOCKED)
- Open positions
- Balance and Equity

Also check MT5 Journal/Experts tabs for warnings or rejected orders.

## 6) Testing path (recommended)
- Compile in MetaEditor with 0 errors.
- Run Strategy Tester by symbol/timeframe.
- Run forward demo testing 2-4 weeks.
- Confirm VPS uptime and reconnection behavior.
- Validate broker stop/freeze levels.

## 7) Live deployment policy
- Ready for demo testing: **Yes**.
- Ready for live trading: **Only after all validation checks above pass**.

## 8) Client operating checklist (quick)
- [ ] License key accepted
- [ ] Algo Trading enabled
- [ ] Correct symbols configured
- [ ] Risk parameters approved
- [ ] Demo validation completed
- [ ] Live go-ahead approved
