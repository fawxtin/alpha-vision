//+------------------------------------------------------------------+
//|                                                           BB.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>

#ifndef __TRENDS_BB__
#define __TRENDS_BB__ 1

class BBTrend : public Trend {
   public:
      int m_timeframe;
      double m_stdDev;
      double m_bbMiddle;
      double m_bbBottom;
      double m_bbTop;
      //double m_bbVolatility;
      bool __debug;
      
      BBTrend(void): m_timeframe(0), m_stdDev(2.0), __debug(false) { m_trendType = "BB"; };
      BBTrend(int timeframe): m_timeframe(timeframe), m_stdDev(2.0), __debug(false) { m_trendType = "BB"; };
      BBTrend(int timeframe, double stdDeviation): m_timeframe(timeframe), m_stdDev(stdDeviation), __debug(false) { m_trendType = "BB"; };
      
      void setDebug(bool debug) { __debug = debug; };
      void calculate(int period=20);
      double getRelativePosition();
      double getVolatility();
};

void BBTrend::calculate(int period=20) {
   /*
    * BB shall provide info on whether the trend is positive or negative
    * Also, it shall consider Buy/Sell opportunities when volatility is low.
    */
   m_trend = TREND_NEUTRAL;
   m_bbMiddle = iBands(Symbol(), m_timeframe, period, m_stdDev, 0, PRICE_CLOSE, MODE_MAIN, 0);
   m_bbBottom = iBands(Symbol(), m_timeframe, period, m_stdDev, 0, PRICE_CLOSE, MODE_LOWER, 0);
   m_bbTop = iBands(Symbol(), m_timeframe, period, m_stdDev, 0, PRICE_CLOSE, MODE_UPPER, 0);
   
   if (__debug)
      PrintFormat("[BB %.1f/%d/%d] (%.4f <-> %.4f <-> %.4f)",
                  m_stdDev, period, m_timeframe, m_bbBottom, m_bbMiddle, m_bbTop);
   
   if (Bid >= m_bbMiddle) { // Positive Tunnel
      if (Bid <= m_bbTop) { // Inside Positive Tunnel
         setTrendHst(TREND_POSITIVE);   
      } else { // Breakout Over Positive Tunnel
         setTrendHst(TREND_POSITIVE_OVERBOUGHT);   
      }
   } else { // Negative Tunnel
      if (Bid >= m_bbBottom) { // Inside Negative Tunnel
         setTrendHst(TREND_NEGATIVE);
      } else { // Breakout Negative Tunnel
         setTrendHst(TREND_NEGATIVE_OVERSOLD);
      }
   }
}

double BBTrend::getRelativePosition(void) {
   if (m_bbBottom == 0 || m_bbMiddle == 0 || m_bbTop == 0) return 0;
   
   double price = (Ask - Bid) / 2;
   double range = m_bbTop - m_bbBottom;
   
   return (price - m_bbMiddle) * m_stdDev / range;
}

#endif
