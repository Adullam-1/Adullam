#ifndef __BUFFALO_SIGNAL_ENGINE_MQH__
#define __BUFFALO_SIGNAL_ENGINE_MQH__

#include "BuffaloLogger.mqh"

enum BuffaloSignal
  {
   SIGNAL_NONE=0,
   SIGNAL_BUY=1,
   SIGNAL_SELL=-1
  };

class BuffaloSignalEngine
  {
private:
   int               m_fastPeriod;
   int               m_slowPeriod;
   ENUM_TIMEFRAMES   m_tf;
   BuffaloLogger    *m_logger;

   bool              ReadEMA(const string symbol,
                             const int period,
                             double &current,
                             double &previous)
     {
      const int handle=iMA(symbol,m_tf,period,0,MODE_EMA,PRICE_CLOSE);
      if(handle==INVALID_HANDLE)
         return false;

      double values[];
      ArraySetAsSeries(values,true);
      const int copied=CopyBuffer(handle,0,1,2,values);
      IndicatorRelease(handle);

      if(copied<2)
         return false;

      current=values[0];
      previous=values[1];
      return true;
     }

public:
                     BuffaloSignalEngine(void)
     {
      m_fastPeriod=20;
      m_slowPeriod=50;
      m_tf=PERIOD_M15;
      m_logger=NULL;
     }

   void              SetLogger(BuffaloLogger &logger)
     {
      m_logger=&logger;
     }

   void              Configure(const int fast,const int slow,const ENUM_TIMEFRAMES tf)
     {
      m_fastPeriod=MathMax(2,fast);
      m_slowPeriod=MathMax(m_fastPeriod+1,slow);
      m_tf=tf;
     }

   BuffaloSignal     Evaluate(const string symbol)
     {
      if(symbol=="")
         return SIGNAL_NONE;

      const int bars=iBars(symbol,m_tf);
      if(bars<m_slowPeriod+3)
         return SIGNAL_NONE;

      double fastCurr=0.0;
      double fastPrev=0.0;
      double slowCurr=0.0;
      double slowPrev=0.0;

      if(!ReadEMA(symbol,m_fastPeriod,fastCurr,fastPrev))
         return SIGNAL_NONE;

      if(!ReadEMA(symbol,m_slowPeriod,slowCurr,slowPrev))
         return SIGNAL_NONE;

      if(fastPrev<=slowPrev && fastCurr>slowCurr)
        {
         if(m_logger!=NULL)
            m_logger.Debug(symbol+": BUY crossover detected.");
         return SIGNAL_BUY;
        }

      if(fastPrev>=slowPrev && fastCurr<slowCurr)
        {
         if(m_logger!=NULL)
            m_logger.Debug(symbol+": SELL crossover detected.");
         return SIGNAL_SELL;
        }

      return SIGNAL_NONE;
     }
  };

#endif
