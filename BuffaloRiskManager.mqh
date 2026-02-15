#ifndef __BUFFALO_RISK_MANAGER_MQH__
#define __BUFFALO_RISK_MANAGER_MQH__

#include "BuffaloLogger.mqh"

class BuffaloRiskManager
  {
private:
   double            m_maxDailyLossPct;
   double            m_maxDrawdownPct;
   double            m_initialBalance;
   long              m_magic;
   BuffaloLogger    *m_logger;

public:
                     BuffaloRiskManager(void)
     {
      m_maxDailyLossPct=5.0;
      m_maxDrawdownPct=20.0;
      m_initialBalance=0.0;
      m_magic=0;
      m_logger=NULL;
     }

   void              SetLogger(BuffaloLogger &logger)
     {
      m_logger=&logger;
     }

   void              Configure(const double maxDailyLossPct,const double maxDrawdownPct,const long magic)
     {
      m_maxDailyLossPct=MathMax(0.1,maxDailyLossPct);
      m_maxDrawdownPct=MathMax(1.0,maxDrawdownPct);
      m_magic=magic;
     }

   void              OnStart(void)
     {
      m_initialBalance=AccountInfoDouble(ACCOUNT_BALANCE);
     }

   bool              AllowTrading(void)
     {
      const double balance=AccountInfoDouble(ACCOUNT_BALANCE);
      const double equity=AccountInfoDouble(ACCOUNT_EQUITY);

      if(m_initialBalance<=0.0)
         m_initialBalance=balance;

      const double drawdownPct=((m_initialBalance-equity)/m_initialBalance)*100.0;
      if(drawdownPct>=m_maxDrawdownPct)
        {
         if(m_logger!=NULL)
            m_logger.Error("Max drawdown breached. Trading paused.");
         return false;
        }

      datetime dayStart=(datetime)(TimeCurrent()-(TimeCurrent()%86400));
      if(!HistorySelect(dayStart,TimeCurrent()))
         return true;

      double dayPnL=0.0;
      const int deals=(int)HistoryDealsTotal();
      for(int i=0;i<deals;i++)
        {
         const ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0)
            continue;

         const long dealMagic=HistoryDealGetInteger(ticket,DEAL_MAGIC);
         if(m_magic!=0 && dealMagic!=m_magic)
            continue;

         const long dealType=HistoryDealGetInteger(ticket,DEAL_TYPE);
         if(dealType!=DEAL_TYPE_BUY && dealType!=DEAL_TYPE_SELL)
            continue;

         dayPnL+=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         dayPnL+=HistoryDealGetDouble(ticket,DEAL_SWAP);
         dayPnL+=HistoryDealGetDouble(ticket,DEAL_COMMISSION);
        }

      const double dailyLossPct=(dayPnL<0.0)?((-dayPnL)/m_initialBalance)*100.0:0.0;
      if(dailyLossPct>=m_maxDailyLossPct)
        {
         if(m_logger!=NULL)
            m_logger.Error("Max daily loss breached. Trading paused.");
         return false;
        }

      return true;
     }
  };

#endif
