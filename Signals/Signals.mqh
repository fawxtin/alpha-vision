//+------------------------------------------------------------------+
//|                                                      Signals.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Arrays\Hash.mqh>
#include <Trends\trends.mqh>

/*
 * Signals keep track of different timeframe signals
 *
 *
 */
 
enum SSIGNALS {
   SSIGNAL_EMPTY,
   SSIGNAL_NEUTRAL,
   SSIGNAL_POSITIVE,
   SSIGNAL_NEGATIVE
};

struct SignalTimeFrames {
   int super;
   int major;
   int current;
   int fast;
};

class SignalChange : public HashValue {
   public:
      int last;
      int current;
      bool changed;
      
      SignalChange(int currentSgn): last(currentSgn), current(currentSgn), changed(false) {} 
};

class Signals {
   public:
      Hash *m_signalHst;
      SignalTimeFrames m_timeframes;
      
      Signals(SignalTimeFrames &tfs) {
         m_signalHst = new Hash(193, true);
         m_timeframes = tfs;
      }
      void ~Signals() {
         delete m_signalHst;
      }
      
      string getTimeframeStr(int timeframe) { return EnumToString((ENUM_TIMEFRAMES) timeframe); }
      
      SignalTimeFrames getTimeFrames() { return m_timeframes; }
      
      SignalChange *getSignal(int timeframe) { return m_signalHst.hGet(getTimeframeStr(timeframe)); }
      
      void setSignal(int timeframe, int signal) {
         SignalChange *sc = getSignal(timeframe);
         if (sc == NULL) {
            sc = new SignalChange(signal);
            m_signalHst.hPut(getTimeframeStr(timeframe), sc);
         } else if (sc.current != signal) {
            sc.last = sc.current;
            sc.current = signal;
            sc.changed = true;
         } else if (sc.changed) sc.changed = false;
      }

};
 
 