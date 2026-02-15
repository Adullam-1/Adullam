#ifndef __BUFFALO_DASHBOARD_MQH__
#define __BUFFALO_DASHBOARD_MQH__

class BuffaloDashboard
  {
private:
   string            m_name;

public:
                     BuffaloDashboard(void)
     {
      m_name="BuffaloSpeedDashboard";
     }

   void              Render(const string licenseState,
                            const int symbols,
                            const bool riskAllowed,
                            const int positions)
     {
      string text="BuffaloSpeed EA\n";
      text+="License: "+licenseState+"\n";
      text+="Symbols: "+IntegerToString(symbols)+"\n";
      text+="Risk Check: "+string(riskAllowed?"OK":"BLOCKED")+"\n";
      text+="Open Positions: "+IntegerToString(positions)+"\n";
      text+="Balance: "+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+"\n";
      text+="Equity: "+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2);
      Comment(text);
     }

   void              Clear(void)
     {
      Comment("");
     }
  };

#endif
