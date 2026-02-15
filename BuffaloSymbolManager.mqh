#ifndef __BUFFALO_SYMBOL_MANAGER_MQH__
#define __BUFFALO_SYMBOL_MANAGER_MQH__

#include "BuffaloLogger.mqh"

class BuffaloSymbolManager
  {
private:
   string            m_symbols[];
   int               m_total;
   BuffaloLogger    *m_logger;

public:
                     BuffaloSymbolManager(void)
     {
      m_total=0;
      m_logger=NULL;
      ArrayResize(m_symbols,0);
     }

   void              SetLogger(BuffaloLogger &logger)
     {
      m_logger=&logger;
     }

   bool              Configure(const string csvSymbols)
     {
      string raw[];
      const int parts=StringSplit(csvSymbols,',',raw);
      if(parts<=0)
         return false;

      ArrayResize(m_symbols,0);
      m_total=0;

      for(int i=0;i<parts;i++)
        {
         string symbol=raw[i];
         StringTrimLeft(symbol);
         StringTrimRight(symbol);

         if(symbol=="")
            continue;

         if(!SymbolSelect(symbol,true))
           {
            if(m_logger!=NULL)
               m_logger.Error("Failed to select symbol: "+symbol,GetLastError());
            continue;
           }

         const int newIndex=m_total;
         ArrayResize(m_symbols,newIndex+1);
         m_symbols[newIndex]=symbol;
         m_total++;
        }

      if(m_total==0)
         return false;

      if(m_logger!=NULL)
         m_logger.Info("Configured "+IntegerToString(m_total)+" symbols.");

      return true;
     }

   int               Total(void) const
     {
      return m_total;
     }

   string            Get(const int index) const
     {
      if(index<0 || index>=m_total)
         return "";
      return m_symbols[index];
     }
  };

#endif
