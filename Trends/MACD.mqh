//+------------------------------------------------------------------+
//|                                                   Stochastic.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>

#ifndef __TRENDS_MACD__
#define __TRENDS_MACD__ 1


class MACDTrend : public Trend {
   /*
    * fast 12; slow 26; sma 9
    *
    */
   public:
      int m_timeframe;
      int m_pFast;
      int m_pSlow;
      int m_pSma;
      double m_main;
      double m_main_i;
      double m_signal;
      double m_signal_i;
      
      MACDTrend(int timeframe, int fast=12, int slow=26, int sma=9) : m_pFast(fast), m_pSlow(slow), m_pSma(sma) {
         m_trendType = "MACD";
         m_timeframe = timeframe; 
      };
      
      void calculate();
};

void MACDTrend::calculate(void) {
   m_main = iMACD(NULL, m_timeframe, m_pFast, m_pSlow, m_pSma, PRICE_CLOSE, MODE_MAIN, 0);
   m_main_i = iMACD(NULL, m_timeframe, m_pFast, m_pSlow, m_pSma, PRICE_CLOSE, MODE_MAIN, 0);
   m_signal = iMACD(NULL, m_timeframe, m_pFast, m_pSlow, m_pSma, PRICE_CLOSE, MODE_MAIN, 0);
   m_signal_i = iMACD(NULL, m_timeframe, m_pFast, m_pSlow, m_pSma, PRICE_CLOSE, MODE_MAIN, 0);
   
   // TODO: read more about macd and the better way to deal with its signals
   if (m_signal >= m_main) { // positive region
      if (m_signal_i < m_main_i) { // crossing up
         m_trend = TREND_POSITIVE_FROM_NEGATIVE;
      } else {
         m_trend = TREND_POSITIVE;
      }
   } else {
      if (m_signal_i > m_main_i) { // crossing down
         m_trend = TREND_NEGATIVE_FROM_POSITIVE;
      } else {
         m_trend = TREND_NEGATIVE;
      }
   }
}

#endif
