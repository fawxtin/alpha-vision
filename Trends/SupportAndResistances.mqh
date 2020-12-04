//+------------------------------------------------------------------+
//|                                                        Supportandresistance.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>

#ifndef __TRENDS_SUPPORTANDRESISTANCE__
#define __TRENDS_SUPPORTANDRESISTANCE__ 1

/*
 * Considering support and resistances using PERIOD_W1 - 1
 *
 *
 *
 */
 
class SupportAndResistanceTrend : public Trend {
   private:
      int m_smoothness;

   public:
      double m_resistance;
      double m_support;
      
      SupportAndResistanceTrend(int timeframe, int smoothness=12) {
         m_timeframe = timeframe;
         m_trendType = "SupportAndResistance";
         m_smoothness = smoothness;
      };
   
      void calculate();
      void calcTrend();
      
      double getRelativePosition();
};

void SupportAndResistanceTrend::calculate(void) {
   int barHigh = iHighest(Symbol(), PERIOD_W1, MODE_HIGH, m_smoothness, 2);
   int barLow = iLowest(Symbol(), PERIOD_W1, MODE_LOW, m_smoothness, 2);

   m_resistance = iHigh(Symbol(), PERIOD_W1, barHigh);
   m_support = iLow(Symbol(), PERIOD_W1, barLow);

   calcTrend();
}

void SupportAndResistanceTrend::calcTrend(void) {
   double relativePosition = getRelativePosition();

   if (relativePosition > 1) {
      setTrendHst(TREND_POSITIVE_BREAKOUT);
   } else if (relativePosition > -1) {
      setTrendHst(TREND_NEUTRAL);
   } else {
      setTrendHst(TREND_NEGATIVE_BREAKOUT);
   }
}

double SupportAndResistanceTrend::getRelativePosition() {
   double price = (Ask + Bid) / 2;
   double range = m_resistance - m_support;
   double middle = (m_resistance + m_support) / 2;
   double relative = 0;
   
   if (range > 0) relative = (price - middle) / range;

   return relative;
}

#endif
