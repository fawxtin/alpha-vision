//+------------------------------------------------------------------+
//|                                                          HMA.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>

class HMATrend : public Trend {
   int m_timeframe;
   double m_ma1;
   double m_ma1_i;
   double m_ma2;
   double m_ma2_i;
      
   public:
      // HMATrend(const Trend &ref): m_trend(ref.m_trend), m_value1(ref.m_value1), m_value1_i(ref.m_value1_i),
      //    m_value2(ref.m_value2), m_value2_i(ref.m_value2_i) { };
      HMATrend(): m_timeframe(0) { };
      HMATrend(int timeframe): m_timeframe(timeframe) { };
      virtual void calculate(int Period1, int Period2, bool debug=false);
      
      double getMAPeriod1() { return m_ma1; }
      double getMAPeriod2() { return m_ma2; }
};

void HMATrend::calculate(int Period1, int Period2, bool debug=false) {
   m_trend = TREND_NEUTRAL;
   m_ma1 = iCustom(NULL, m_timeframe, "hma", Period1, 0, MODE_LWMA, PRICE_TYPICAL, 0, 0);
   m_ma1_i = iCustom(NULL, m_timeframe, "hma", Period1, 0, MODE_LWMA, PRICE_TYPICAL, 0, 1);
   m_ma2 = iCustom(NULL, m_timeframe, "hma", Period2, 0, MODE_LWMA, PRICE_TYPICAL, 0, 0);
   m_ma2_i = iCustom(NULL, m_timeframe, "hma", Period2, 0, MODE_LWMA, PRICE_TYPICAL, 0, 1);

   if (debug)
      Print("HMA ", Period1, " (", m_ma1_i, " -> ", m_ma1, ") / MA ", Period2, " (", m_ma2_i, " -> ", m_ma2, ")");
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
