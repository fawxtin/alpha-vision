//+------------------------------------------------------------------+
//|                                                      Rainbow.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>

/*
 * Rainbow uses a 5 - 8 - 13 Hull MA to track positive/negative trending,
 * to be used in fast scalper algorithms.
 *
 * debug real low volatility for multiple crossing
 */

#ifndef __TRENDS_RAINBOW__
#define __TRENDS_RAINBOW__ 1

class RainbowTrend : public Trend {
   private:
      int m_timeframe;
      int m_period1;
      int m_period2;
      int m_period3;
      
   public:
      double m_ma1;
      double m_ma2;
      double m_ma3;
      
      RainbowTrend(int timeframe, int period1=5, int period2=8, int period3=13) : m_period1(period1), 
               m_period2(period2), m_period3(period3) {
         m_trendType = "RAINBOW";
         m_period1 = 5;
         m_period2 = 8;
         m_period3 = 13;
         m_timeframe = timeframe;
      }
      
      virtual void calculate(void);
};

void RainbowTrend::calculate(void) {
   m_ma1 = iCustom(NULL, m_timeframe, "hma", m_period1, 0, MODE_LWMA, PRICE_TYPICAL, 0, 0);
   //m_ma1_i = iCustom(NULL, m_timeframe, "hma", m_period1, 0, MODE_LWMA, PRICE_TYPICAL, 0, 1);
   m_ma2 = iCustom(NULL, m_timeframe, "hma", m_period2, 0, MODE_LWMA, PRICE_TYPICAL, 0, 0);
   //m_ma2_i = iCustom(NULL, m_timeframe, "hma", m_period2, 0, MODE_LWMA, PRICE_TYPICAL, 0, 1);
   m_ma3 = iCustom(NULL, m_timeframe, "hma", m_period3, 0, MODE_LWMA, PRICE_TYPICAL, 0, 0);
   //m_ma3_i = iCustom(NULL, m_timeframe, "hma", m_period3, 0, MODE_LWMA, PRICE_TYPICAL, 0, 1);
   
   if (m_ma1 > m_ma2 && m_ma2 > m_ma3) {
      setTrendHst(TREND_POSITIVE);
   } else if (m_ma1 < m_ma2 && m_ma2 < m_ma3) {
      setTrendHst(TREND_NEGATIVE);
   } else {
      setTrendHst(TREND_NEUTRAL);
   }
}

#endif
