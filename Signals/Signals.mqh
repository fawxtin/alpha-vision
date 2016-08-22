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
      //SignalChange m_trendMj;
      //SignalChange m_trendFt;
      SignalChange m_trendCt;
      //SignalChange m_trendSp;
      
      Signals() {
         //m_trendMj = TREND_EMPTY;
         //m_trendFt = TREND_EMPTY;
         m_trendCt.last = TREND_EMPTY;
         m_trendCt.current = TREND_EMPTY;
         m_trendCt.changed = false;
         //m_trendSp = TREND_EMPTY;
      }
      
      //SignalChange getTrendMj() { return m_trendMj; }
      
      //void setTrendMj(int trend) {
      //   if (m_trendMj.current != trend) {
      //      m_trendMj.last = m_trendMj.current;
      //      m_trendMj.current = trend;
      //      m_trendMj.changed = true
      //      Alert(StringFormat("[Trader] Major timeframe trend changed to: %d", trend));
      //   } else if (m_trendMj.changed) m_trendMj.changed = false;
      //}

      //SignalChange getTrendFt() { return m_trendFt; }
      
      //void setTrendFt(int trend) {
      //   if (m_trendFt.current != trend) {
      //      m_trendFt.last = m_trendFt.current;
      //      m_trendFt.current = trend;
      //      m_trendFt.changed = true
      //      Alert(StringFormat("[Trader] Fast Timeframe trend changed to: %d", trend));
      //   } else if (m_trendFt.changed) m_trendFt.changed = false;
      //}
      
      SignalChange getTrendCt() { return m_trendCt; }
      
      void setTrendCt(int trend) {
         if (m_trendCt.current != trend) {
            m_trendCt.last = m_trendCt.current;
            m_trendCt.current = trend;
            m_trendCt.changed = true;
         } else if (m_trendCt.changed) m_trendCt.changed = false;
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
 
 