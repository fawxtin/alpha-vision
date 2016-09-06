//+------------------------------------------------------------------+
//|                                                          ATR.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>

#ifndef __TRENDS_ATR__
#define __TRENDS_ATR__

#define VOLATILITY_DELAY 35 // percentage of normal different between fast / slow
/*
 * when ratio difference between fast and slow is bellow 35%,
 * we are under low volatility period.
 *
 * when difference from fast to slow is 35% higher, we enter higher volatility rate
 * when difference from fast to slow is 35% lower, we enter lower volatility rate
 */

class ATRdelta : public Trend {
   public:
      int m_timeframe;
      int m_period1;
      int m_period2;
      double m_atr1;
      double m_atr1_i;
      double m_atr2;
      double m_atr2_i;
      
      ATRdelta(int timeframe, int period1, int period2) {
         //m_trendType = "ATR"; 
         m_timeframe = timeframe;
         m_period1 = period1;
         m_period2 = period2;
         m_trend = TREND_VOLATILITY_EMPTY;
      }

      void calculate(void) {
         m_atr1 = iATR(Symbol(), m_timeframe, m_period1, 0);
         m_atr1_i = iATR(Symbol(), m_timeframe, m_period1, 1);
         m_atr2 = iATR(Symbol(), m_timeframe, m_period2, 0);
         m_atr2_i = iATR(Symbol(), m_timeframe, m_period2, 1);
         
         // set volatility states: 
         // TREND_VOLATILITY_LOW; TREND_VOLATILITY_HIGH; TREND_VOLATILITY_LOW_TO_HIGH
         if (m_atr2 == 0 || m_atr2_i == 0) {
            PrintFormat("[atr.debug] zeroed atr2: (%.4f, %.4f)", m_atr2, m_atr2_i);
            return;
         }
         
         if (m_atr1 <= m_atr2) { // low volatility
            setTrendHst(TREND_VOLATILITY_LOW);
         } else {
            double atrDiff = (m_atr1 - m_atr2) / m_atr2;
            if (atrDiff * 100 > VOLATILITY_DELAY) {
               double atrDiff_i = (m_atr1_i - m_atr2_i) / m_atr2_i;
               if (atrDiff_i * 100 <= VOLATILITY_DELAY) m_trend = TREND_VOLATILITY_LOW_TO_HIGH;
               else setTrendHst(TREND_VOLATILITY_HIGH);
            } else
               setTrendHst(TREND_VOLATILITY_LOW);
         }
      }
            
      double getStopLossFor(string orderType, double price) {
         double atrMean = (m_atr1 + m_atr1_i) / 2;
         if (orderType == "LONG")
            return price - atrMean;
         else if (orderType == "SHORT")
            return price + atrMean;
         else
            return 0;
      }
      
      double getTargetProfitFor(string orderType, double price) {
         double atrMean = (m_atr2 + m_atr2_i) / 2;
         if (orderType == "LONG")
            return price + atrMean;
         else if (orderType == "SHORT")
            return price - atrMean;
         else
            return 0;
      }
 
};

#endif
