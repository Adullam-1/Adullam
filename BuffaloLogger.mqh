#ifndef __BUFFALO_LOGGER_MQH__
#define __BUFFALO_LOGGER_MQH__

class BuffaloLogger
  {
private:
   string            m_prefix;
   bool              m_debug;

public:
                     BuffaloLogger(void)
     {
      m_prefix="[BuffaloSpeed]";
      m_debug=true;
     }

   void              SetPrefix(const string prefix)
     {
      m_prefix=prefix;
     }

   void              EnableDebug(const bool enabled)
     {
      m_debug=enabled;
     }

   void              Info(const string message)
     {
      Print(m_prefix+" [INFO] "+message);
     }

   void              Warn(const string message)
     {
      Print(m_prefix+" [WARN] "+message);
     }

   void              Error(const string message,const int code=0)
     {
      if(code!=0)
         Print(m_prefix+" [ERROR] "+message+" | code="+IntegerToString(code));
      else
         Print(m_prefix+" [ERROR] "+message);
     }

   void              Debug(const string message)
     {
      if(m_debug)
         Print(m_prefix+" [DEBUG] "+message);
     }
  };

#endif
