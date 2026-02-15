#ifndef __BUFFALO_MONEY_MANAGER_MQH__
#define __BUFFALO_MONEY_MANAGER_MQH__

#include "BuffaloLogger.mqh"

class BuffaloMoneyManager
  {
private:
   double            m_riskPerTradePct;
   double            m_minLot;
   double            m_maxLot;
   BuffaloLogger    *m_logger;

   int               VolumeDigits(const double step) const
     {
      if(step<=0.0)
         return 2;

      int digits=0;
      double value=step;
      while(digits<8 && MathRound(value)!=value)
        {
         value*=10.0;
         digits++;
        }
      return digits;
     }

public:
                     BuffaloMoneyManager(void)
     {
      m_riskPerTradePct=1.0;
      m_minLot=0.01;
      m_maxLot=10.0;
      m_logger=NULL;
     }

   void              SetLogger(BuffaloLogger &logger)
     {
      m_logger=&logger;
     }

   void              Configure(const double riskPct,const double minLot,const double maxLot)
     {
      m_riskPerTradePct=MathMax(0.1,riskPct);
      m_minLot=MathMax(0.01,minLot);
      m_maxLot=MathMax(m_minLot,maxLot);
     }

   double            ComputeLotSize(const string symbol,const double stopLossPoints)
     {
      if(stopLossPoints<=0.0 || symbol=="")
         return m_minLot;

      const double balance=AccountInfoDouble(ACCOUNT_BALANCE);
      const double riskMoney=balance*(m_riskPerTradePct/100.0);

      double tickValue=0.0;
      double tickSize=0.0;
      if(!SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE,tickValue))
         tickValue=0.0;
      if(!SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE,tickSize))
         tickSize=0.0;

      if(tickValue<=0.0 || tickSize<=0.0)
         return m_minLot;

      const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      if(point<=0.0)
         return m_minLot;

      const double stopDistancePrice=stopLossPoints*point;
      const double lossPerLot=(stopDistancePrice/tickSize)*tickValue;
      if(lossPerLot<=0.0)
         return m_minLot;

      double volume=riskMoney/lossPerLot;

      double step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
      if(step<=0.0)
         step=0.01;
      double minVol=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
      double maxVol=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
      if(minVol<=0.0)
         minVol=m_minLot;
      if(maxVol<=0.0)
         maxVol=m_maxLot;

      volume=MathFloor(volume/step)*step;
      volume=MathMax(volume,MathMax(m_minLot,minVol));
      volume=MathMin(volume,MathMin(m_maxLot,maxVol));

      const int volDigits=VolumeDigits(step);
      volume=NormalizeDouble(volume,volDigits);

      if(m_logger!=NULL)
         m_logger.Debug(symbol+": computed lot size="+DoubleToString(volume,volDigits));

      return volume;
     }
  };

#endif
