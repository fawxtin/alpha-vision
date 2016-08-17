//+------------------------------------------------------------------+
//|                                                           BB.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>

class BBTrend : public Trend {
   public:
      int m_timeframe;
      double m_stdDev;
      double m_bbMiddle;
      double m_bbBottom;
      double m_bbTop;
      
      BBTrend(): m_timeframe(0), m_stdDev(2.0) {};
      BBTrend(int timeframe): m_timeframe(timeframe), m_stdDev(2.0) {};
      BBTrend(int timeframe, double stdDeviation): m_timeframe(timeframe), m_stdDev(stdDeviation) {};
      
      virtual void calculate(int period, bool debug);
}

void BBTrend::calculate(int period, bool debug=false) {
   /*
    * BB shall provide info on whether the trend is positive or negative
    * Also, it shall consider Buy/Sell opportunities when volatility is low.
    */
   m_trend = TREND_NEUTRAL;
   m_bbMiddle = iBands(Symbol(), m_timeframe, period, m_stdDev, 0, PRICE_CLOSE, MODE_MAIN, 0);
   m_bbBottom = iBands(Symbol(), m_timeframe, period, m_stdDev, 0, PRICE_CLOSE, MODE_LOWER, 0);
   m_bbTop = iBands(Symbol(), m_timeframe, period, m_stdDev, 0, PRICE_CLOSE, MODE_UPPER, 0);
   
   if (debug)
      PrintFormat("[BB %.1f/%d/%d] (%.4f <-> %.4f <-> %.4f)",
                  m_stdDev, period, m_timeframe, m_bbBottom, m_bbMiddle, m_bbTop);
   
   if (Bid >= bb2_middle) { // Positive Tunnel
      if (Bid <= bb2_top) { // Inside Positive Tunnel
         m_trend = TREND_POSITIVE;   
      } else { // Breakout Over Positive Tunnel
         m_trend = TREND_POSITIVE_OVERBOUGHT;   
      }
   } else { // Negative Tunnel
      if (Bid >= bb2_bottom) { // Inside Negative Tunnel
         m_trend = TREND_NEGATIVE;
      } else { // Breakout Negative Tunnel
         m_trend = TREND_NEGATIVE_OVERSOLD;
      }
   }
}
