//+------------------------------------------------------------------+
//|                                                          HMA.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>

#ifndef __TRENDS_HMA__
#define __TRENDS_HMA__ 1

class HMATrend : public Trend {
   int m_timeframe;
   int m_period1;
   int m_period2;
   double m_ma1;
   double m_ma1_i;
   double m_ma2;
   double m_ma2_i;
   bool __debug;
      
   public:
      // HMATrend(const Trend &ref): m_trend(ref.m_trend), m_value1(ref.m_value1), m_value1_i(ref.m_value1_i),
      //    m_value2(ref.m_value2), m_value2_i(ref.m_value2_i) { };
      HMATrend(int timeframe, int period1, int period2): m_timeframe(timeframe), m_period1(period1), m_period2(period2) { };
      void setDebug(bool debug) { __debug = debug; }
      virtual void calculate();
      
      double getMAPeriod1() { return m_ma1; }
      double getMAPeriod2() { return m_ma2; }
};

void HMATrend::calculate() {
   m_trend = TREND_NEUTRAL;
   m_ma1 = iCustom(NULL, m_timeframe, "hma", m_period1, 0, MODE_LWMA, PRICE_TYPICAL, 0, 0);
   m_ma1_i = iCustom(NULL, m_timeframe, "hma", m_period1, 0, MODE_LWMA, PRICE_TYPICAL, 0, 1);
   m_ma2 = iCustom(NULL, m_timeframe, "hma", m_period2, 0, MODE_LWMA, PRICE_TYPICAL, 0, 0);
   m_ma2_i = iCustom(NULL, m_timeframe, "hma", m_period2, 0, MODE_LWMA, PRICE_TYPICAL, 0, 1);

   if (__debug)
      Print("HMA ", m_period1, " (", m_ma1_i, " -> ", m_ma1, ") / MA ", m_period2, " (", m_ma2_i, " -> ", m_ma2, ")");
   if (m_ma1_i >= m_ma2_i) { // came from a bull context
      if (m_ma1 > m_ma2) {
         m_trend = TREND_POSITIVE;
      } else { // switching to bear!
         m_trend = TREND_NEGATIVE_FROM_POSITIVE;
      }
   } else { // came from a bear context
      if (m_ma1 >= m_ma2) {
         m_trend = TREND_POSITIVE_FROM_NEGATIVE;
      } else {
         m_trend = TREND_NEGATIVE;
      }
   }
}

#endif
