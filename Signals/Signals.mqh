//+------------------------------------------------------------------+
//|                                                      Signals.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

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

struct SignalChange {
   int last;
   int current;
   bool changed;
};

class Signals {
   public:
      SignalChange m_signalMj;
      //SignalChange m_trendFt;
      SignalChange m_signalCt;
      //SignalChange m_trendSp;
      
      Signals() {
         m_signalMj.last = TREND_EMPTY;
         m_signalMj.current = TREND_EMPTY;
         m_signalMj.changed = false;
         //m_trendFt = TREND_EMPTY;
         m_signalCt.last = TREND_EMPTY;
         m_signalCt.current = TREND_EMPTY;
         m_signalCt.changed = false;
         //m_trendSp = TREND_EMPTY;
      }
      
      SignalChange getSignalMj() { return m_signalMj; }
      
      void setSignalMj(int signal) {
         if (m_signalMj.current != signal) {
            m_signalMj.last = m_signalMj.current;
            m_signalMj.current = signal;
            m_signalMj.changed = true;
         } else if (m_signalMj.changed) m_signalMj.changed = false;
      }

      //SignalChange getTrendFt() { return m_trendFt; }
      
      //void setTrendFt(int trend) {
      //   if (m_trendFt.current != trend) {
      //      m_trendFt.last = m_trendFt.current;
      //      m_trendFt.current = trend;
      //      m_trendFt.changed = true
      //      Alert(StringFormat("[Trader] Fast Timeframe trend changed to: %d", trend));
      //   } else if (m_trendFt.changed) m_trendFt.changed = false;
      //}
      
      SignalChange getSignalCt() { return m_signalCt; }
      
      void setSignalCt(int signal) {
         if (m_signalCt.current != signal) {
            m_signalCt.last = m_signalCt.current;
            m_signalCt.current = signal;
            m_signalCt.changed = true;
         } else if (m_signalCt.changed) m_signalCt.changed = false;
      }
      
      //SignalChange getTrendSp() { return m_trendSp; }
      
      //void setTrendSp(int trend) {
      //   if (m_trendSp.current != trend) {
      //      m_trendSp.last = m_trendSp.current;
      //      m_trendSp.current = trend;
      //      m_trendSp.changed = true
      //      Alert(StringFormat("[Trader] Super Timeframe trend changed to: %d", trend));
      //   } else if (m_trendSp.changed) m_trendSp.changed = false;
      //}

};
 
 