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

#define TREND_POSITIVE_BREAKOUT       4
#define TREND_POSITIVE_OVERBOUGHT     3
#define TREND_POSITIVE_FROM_NEGATIVE  2
#define TREND_POSITIVE                1
#define TREND_NEGATIVE               -1
#define TREND_NEGATIVE_FROM_POSITIVE -2
#define TREND_NEGATIVE_OVERSOLD      -3
#define TREND_NEGATIVE_BREAKOUT      -4
#define TREND_NEUTRAL                 0
#define TREND_STABLE                  0


// TODO: create a class that keeps trend values

class Trend {
   protected:
      int m_trend;
      
   public:
      Trend() {};
      int getTrend() { return m_trend; };
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

