//+------------------------------------------------------------------+
//|                                                       trends.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#ifndef __TRENDS__
#define __TRENDS__ "TRENDS"

enum TRENDS {
   TREND_EMPTY,
   TREND_NEUTRAL,
   TREND_POSITIVE_BREAKOUT,
   TREND_POSITIVE,
   TREND_NEGATIVE,
   TREND_POSITIVE_OVERBOUGHT,
   TREND_POSITIVE_FROM_NEGATIVE,
   TREND_NEGATIVE_FROM_POSITIVE,
   TREND_NEGATIVE_OVERSOLD,
   TREND_NEGATIVE_BREAKOUT,
   TREND_VOLATILITY_EMPTY,
   TREND_VOLATILITY_LOW,
   TREND_VOLATILITY_LOW_TO_HIGH,
   TREND_VOLATILITY_HIGH
};

struct TrendChange {
   int last;
   int current;
   bool changed;
};

// TODO: create a class that keeps trend values

class Trend {
   protected:
      //int m_lastTrend;
      int m_trend;
      string m_trendType;
      TrendChange m_trendHst;
      
   public:
      Trend() { m_trend = TREND_EMPTY; };
      int getTrend() { return m_trend; };
      
      TrendChange getTrendHst() { return m_trendHst; }
      
      void setTrendHst(int trend) {
         m_trend = trend;
         if (m_trendHst.current == TREND_EMPTY) {
            m_trendHst.current = trend;
            m_trendHst.last = trend;
         } else if (m_trendHst.current != trend) {
            m_trendHst.last = m_trendHst.current;
            m_trendHst.current = trend;
            m_trendHst.changed = true;
         } else if (m_trendHst.changed) m_trendHst.changed = false;
      }

      //bool setTrend(int 
      string simplify();
      virtual void calculate() { m_trend = TREND_NEUTRAL; };
      virtual void alert();
};

string Trend::simplify() {
   string refTrend = "NEUTRAL";
   switch (m_trend) {
      case TREND_NEGATIVE:
         refTrend = "NEGATIVE";
         break;
      case TREND_NEGATIVE_FROM_POSITIVE:
         refTrend = "POSITIVE";
         break;
      case TREND_NEGATIVE_OVERSOLD:
         refTrend = "NEGATIVE";
         break;
      case TREND_POSITIVE:
         refTrend = "POSITIVE";
         break;
      case TREND_POSITIVE_FROM_NEGATIVE:
         refTrend = "NEGATIVE";
         break;
      case TREND_POSITIVE_OVERBOUGHT:
         refTrend = "POSITIVE";
         break;
      case TREND_NEUTRAL:
      default:
         break;
   }
   
   return refTrend;
}



#endif 

