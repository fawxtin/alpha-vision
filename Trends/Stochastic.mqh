//+------------------------------------------------------------------+
//|                                                   Stochastic.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>

#ifndef __TRENDS_STOCHASTIC__
#define __TRENDS_STOCHASTIC__ 1

#define STOCHASTIC_REGION_OVERBOUGHT 75
#define STOCHASTIC_REGION_OVERSOLD   25

class StochasticTrend : public Trend {
   /*
    * SMI 6 (or 8) / 15
    * SMI 18 / 40
    * (default) 21 / 45
    */
   public:
      int m_timeframe;
      int m_KPeriod;
      int m_DPeriod;
      double m_main;
      double m_main_i;
      double m_signal;
      double m_signal_i;
      
      StochasticTrend(int timeframe, int Kperiod=21, int Dperiod=45) : m_KPeriod(Kperiod), m_DPeriod(Dperiod) {
         m_trendType = "STOCHASTIC";
         m_timeframe = timeframe; 
      };
      
      void calculate();
};

void StochasticTrend::calculate(void) {
   m_main = iStochastic(NULL, m_timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   m_main_i = iStochastic(NULL, m_timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   m_signal = iStochastic(NULL, m_timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   m_signal_i = iStochastic(NULL, m_timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   
   // TODO: read more about stochastic and the better way to deal with its signals
   if (m_main >= STOCHASTIC_REGION_OVERBOUGHT) { // overbought region
      if (m_signal_i > m_main && m_main > m_signal) { // crossing
         m_trend = TREND_NEGATIVE_FROM_POSITIVE;
      } else if (m_signal > m_main) {
         m_trend = TREND_POSITIVE_OVERBOUGHT;
      } else {
         m_trend = TREND_NEGATIVE;
      }
   } else if (m_main >= STOCHASTIC_REGION_OVERBOUGHT) { // oversold region
      if (m_signal_i < m_main && m_main < m_signal) { // crossing
         m_trend = TREND_POSITIVE_FROM_NEGATIVE;
      } else if (m_signal < m_main) {
         m_trend = TREND_NEGATIVE_OVERSOLD;
      } else {
         m_trend = TREND_POSITIVE;
      }   
   } else { // middle, neutral region
      if (m_signal > m_main) {
         m_trend = TREND_POSITIVE;
      } else {
         m_trend = TREND_NEGATIVE;
      }
   }
}

#endif
