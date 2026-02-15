#property strict
#property version   "1.20"
#property description "BuffaloSpeed multi-symbol autonomous EA"

#include "BuffaloLogger.mqh"
#include "BuffaloDashboard.mqh"
#include "BuffaloSymbolManager.mqh"
#include "BuffaloSignalEngine.mqh"
#include "BuffaloMoneyManager.mqh"
#include "BuffaloTradeManager.mqh"
#include "BuffaloRiskManager.mqh"

input string          InpLicenseKey="BUFFALO-TRIAL-123";
input string          InpSymbols="EURUSD,GBPUSD,USDJPY";
input ENUM_TIMEFRAMES InpSignalTF=PERIOD_M15;
input int             InpFastMAPeriod=20;
input int             InpSlowMAPeriod=50;
input double          InpRiskPerTradePct=1.0;
input double          InpMaxDailyLossPct=5.0;
input double          InpMaxDrawdownPct=20.0;
input double          InpStopLossPoints=300;
input double          InpTakeProfitPoints=600;
input double          InpBreakEvenPoints=200;
input double          InpTrailingStopPoints=250;
input long            InpMagicNumber=99001;
input int             InpSlippagePoints=20;
input bool            InpDebugLogs=true;

BuffaloLogger         g_logger;
BuffaloDashboard      g_dashboard;
BuffaloSymbolManager  g_symbols;
BuffaloSignalEngine   g_signals;
BuffaloMoneyManager   g_money;
BuffaloTradeManager   g_trader;
BuffaloRiskManager    g_risk;

datetime              g_lastSignalBarTimes[];
bool                  g_licenseValid=false;
string                g_licenseState="INVALID";

bool ValidateLicenseKey(const string key)
  {
   if(StringLen(key)<10)
      return false;

   if(StringFind(key,"BUFFALO-")!=0)
      return false;

   uint checksum=0;
   for(int i=0;i<StringLen(key);i++)
      checksum+=(uint)StringGetCharacter(key,i);

   return ((checksum%7)==0 || key=="BUFFALO-TRIAL-123");
  }

int CountOpenPositionsByMagic(const long magic)
  {
   int count=0;
   const int total=(int)PositionsTotal();
   for(int i=0;i<total;i++)
     {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      const long posMagic=(long)PositionGetInteger(POSITION_MAGIC);
      if(posMagic==magic)
         count++;
     }
   return count;
  }

void ProcessSymbol(const int index,const string symbol)
  {
   const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   const int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   const double bid=SymbolInfoDouble(symbol,SYMBOL_BID);
   const double ask=SymbolInfoDouble(symbol,SYMBOL_ASK);
   if(point<=0.0 || bid<=0.0 || ask<=0.0)
      return;

   g_trader.ManageBreakEvenAndTrailing(symbol,InpBreakEvenPoints,InpTrailingStopPoints);

   if(g_trader.HasOpenPosition(symbol))
      return;

   const datetime signalBarTime=iTime(symbol,InpSignalTF,1);
   if(signalBarTime<=0)
      return;

   if(index>=0 && index<ArraySize(g_lastSignalBarTimes) && g_lastSignalBarTimes[index]==signalBarTime)
      return;

   const BuffaloSignal signal=g_signals.Evaluate(symbol);
   if(signal==SIGNAL_NONE)
      return;

   const double volume=g_money.ComputeLotSize(symbol,InpStopLossPoints);

   bool submitted=false;
   if(signal==SIGNAL_BUY)
     {
      const double sl=NormalizeDouble(ask-(InpStopLossPoints*point),digits);
      const double tp=NormalizeDouble(ask+(InpTakeProfitPoints*point),digits);
      submitted=g_trader.OpenBuy(symbol,volume,sl,tp);
     }
   else if(signal==SIGNAL_SELL)
     {
      const double sl=NormalizeDouble(bid+(InpStopLossPoints*point),digits);
      const double tp=NormalizeDouble(bid-(InpTakeProfitPoints*point),digits);
      submitted=g_trader.OpenSell(symbol,volume,sl,tp);
     }

   if(index>=0 && index<ArraySize(g_lastSignalBarTimes) && (submitted || signal!=SIGNAL_NONE))
      g_lastSignalBarTimes[index]=signalBarTime;
  }

int OnInit()
  {
   g_logger.EnableDebug(InpDebugLogs);
   g_logger.Info("Initializing BuffaloSpeed...");

   g_licenseValid=ValidateLicenseKey(InpLicenseKey);
   g_licenseState=(g_licenseValid?"VALID":"INVALID");
   if(!g_licenseValid)
     {
      g_logger.Error("License key validation failed.");
      return INIT_FAILED;
     }

   g_symbols.SetLogger(g_logger);
   g_signals.SetLogger(g_logger);
   g_money.SetLogger(g_logger);
   g_trader.SetLogger(g_logger);
   g_risk.SetLogger(g_logger);

   if(!g_symbols.Configure(InpSymbols))
     {
      g_logger.Error("No valid symbols configured.");
      return INIT_FAILED;
     }

   g_signals.Configure(InpFastMAPeriod,InpSlowMAPeriod,InpSignalTF);
   g_money.Configure(InpRiskPerTradePct,0.01,50.0);
   g_trader.Configure(InpMagicNumber,InpSlippagePoints);
   g_risk.Configure(InpMaxDailyLossPct,InpMaxDrawdownPct,InpMagicNumber);
   g_risk.OnStart();

   ArrayResize(g_lastSignalBarTimes,g_symbols.Total());
   ArrayInitialize(g_lastSignalBarTimes,0);

   EventSetTimer(1);
   g_logger.Info("BuffaloSpeed initialized successfully.");
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   g_dashboard.Clear();
   g_logger.Info("BuffaloSpeed deinitialized. reason="+IntegerToString(reason));
  }

void OnTick()
  {
  }

void OnTimer()
  {
   if(!g_licenseValid)
      return;

   const bool allowed=g_risk.AllowTrading();
   if(allowed)
     {
      for(int i=0;i<g_symbols.Total();i++)
        {
         const string symbol=g_symbols.Get(i);
         ProcessSymbol(i,symbol);
        }
     }

   g_dashboard.Render(g_licenseState,g_symbols.Total(),allowed,CountOpenPositionsByMagic(InpMagicNumber));
  }
