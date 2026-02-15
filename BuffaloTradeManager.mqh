#ifndef __BUFFALO_TRADE_MANAGER_MQH__
#define __BUFFALO_TRADE_MANAGER_MQH__

#include <Trade/Trade.mqh>
#include "BuffaloLogger.mqh"

class BuffaloTradeManager
  {
private:
   CTrade            m_trade;
   long              m_magic;
   int               m_slippagePoints;
   BuffaloLogger    *m_logger;

   bool              ValidateStops(const string symbol,
                                   const ENUM_POSITION_TYPE type,
                                   const double sl,
                                   const double tp)
     {
      const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      const double bid=SymbolInfoDouble(symbol,SYMBOL_BID);
      const double ask=SymbolInfoDouble(symbol,SYMBOL_ASK);
      const int stopLevel=(int)SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
      const double minDistance=MathMax((double)stopLevel,1.0)*point;

      if(point<=0.0 || bid<=0.0 || ask<=0.0)
         return false;

      if(type==POSITION_TYPE_BUY)
         return ((ask-sl)>=minDistance && (tp-ask)>=minDistance);

      return ((sl-bid)>=minDistance && (bid-tp)>=minDistance);
     }

public:
                     BuffaloTradeManager(void)
     {
      m_magic=99001;
      m_slippagePoints=20;
      m_logger=NULL;
     }

   void              SetLogger(BuffaloLogger &logger)
     {
      m_logger=&logger;
     }

   void              Configure(const long magic,const int slippagePoints)
     {
      m_magic=magic;
      m_slippagePoints=slippagePoints;
      m_trade.SetExpertMagicNumber(m_magic);
      m_trade.SetDeviationInPoints(m_slippagePoints);
     }

   bool              HasOpenPosition(const string symbol)
     {
      if(!PositionSelect(symbol))
         return false;

      const long posMagic=(long)PositionGetInteger(POSITION_MAGIC);
      return (posMagic==m_magic);
     }

   bool              OpenBuy(const string symbol,const double volume,const double sl,const double tp)
     {
      if(!ValidateStops(symbol,POSITION_TYPE_BUY,sl,tp))
        {
         if(m_logger!=NULL)
            m_logger.Warn(symbol+": BUY skipped due to invalid stops for broker rules.");
         return false;
        }

      const bool ok=m_trade.Buy(volume,symbol,0.0,sl,tp,"BuffaloSpeed BUY");
      if(!ok && m_logger!=NULL)
         m_logger.Error(symbol+": BUY failed",(int)m_trade.ResultRetcode());
      return ok;
     }

   bool              OpenSell(const string symbol,const double volume,const double sl,const double tp)
     {
      if(!ValidateStops(symbol,POSITION_TYPE_SELL,sl,tp))
        {
         if(m_logger!=NULL)
            m_logger.Warn(symbol+": SELL skipped due to invalid stops for broker rules.");
         return false;
        }

      const bool ok=m_trade.Sell(volume,symbol,0.0,sl,tp,"BuffaloSpeed SELL");
      if(!ok && m_logger!=NULL)
         m_logger.Error(symbol+": SELL failed",(int)m_trade.ResultRetcode());
      return ok;
     }

   void              ManageBreakEvenAndTrailing(const string symbol,const double breakEvenPts,const double trailingPts)
     {
      if(!PositionSelect(symbol))
         return;

      const long posMagic=(long)PositionGetInteger(POSITION_MAGIC);
      if(posMagic!=m_magic)
         return;

      const long type=PositionGetInteger(POSITION_TYPE);
      const double openPrice=PositionGetDouble(POSITION_PRICE_OPEN);
      const double currentSL=PositionGetDouble(POSITION_SL);
      const double currentTP=PositionGetDouble(POSITION_TP);
      const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      const int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
      const double bid=SymbolInfoDouble(symbol,SYMBOL_BID);
      const double ask=SymbolInfoDouble(symbol,SYMBOL_ASK);
      const int stopLevel=(int)SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
      const double minDistance=MathMax((double)stopLevel,1.0)*point;

      if(point<=0.0 || bid<=0.0 || ask<=0.0)
         return;

      double newSL=currentSL;

      if(type==POSITION_TYPE_BUY)
        {
         const double profitPts=(bid-openPrice)/point;
         if(profitPts>=breakEvenPts)
            newSL=MathMax(newSL,openPrice);

         if(profitPts>=trailingPts)
           {
            const double trail=bid-(trailingPts*point);
            newSL=MathMax(newSL,trail);
           }

         if(newSL>0.0 && (bid-newSL)<minDistance)
            newSL=bid-minDistance;
        }
      else if(type==POSITION_TYPE_SELL)
        {
         const double profitPts=(openPrice-ask)/point;
         if(profitPts>=breakEvenPts)
           {
            if(newSL==0.0)
               newSL=openPrice;
            else
               newSL=MathMin(newSL,openPrice);
           }

         if(profitPts>=trailingPts)
           {
            const double trail=ask+(trailingPts*point);
            if(newSL==0.0)
               newSL=trail;
            else
               newSL=MathMin(newSL,trail);
           }

         if(newSL>0.0 && (newSL-ask)<minDistance)
            newSL=ask+minDistance;
        }

      if(newSL!=currentSL && newSL>0.0)
        {
         newSL=NormalizeDouble(newSL,digits);
         if(!m_trade.PositionModify(symbol,newSL,currentTP))
           {
            if(m_logger!=NULL)
               m_logger.Warn(symbol+": failed to modify SL for trailing/breakeven.");
           }
        }
     }
  };

#endif
