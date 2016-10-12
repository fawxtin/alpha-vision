//+------------------------------------------------------------------+
//|                                                        Pivot.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>

#ifndef __TRENDS_PIVOT__
#define __TRENDS_PIVOT__ 1

/*
 * R2 = P + (H - L) = P + (R1 - S1)
 * R1 = (P * 2) - L
 * P = (H + L + C) / 3
 * S1 = (P * 2) - H
 * S2 = P - (H - L) = P - (R1 - S1)
 *
 * R3 = H + 2 * (PP - L)
 * S3 = L - 2 * (H - PP)
 */
 
 enum PivotSystem {
   PIVOT_5POINT,
   PIVOT_5POINT_SMOOTH,
   PIVOT_7POINT,
   PIVOT_7POINT_SMOOTH
 };

class PivotTrend : public Trend {
   private:
      int m_pivotType;
      int m_smoothness;
      void calcFivePoint(double high, double low, double close);

   public:
      double m_typical;
      double m_ppDiff;
      double m_R1;
      double m_R2;
      double m_R3;
      double m_S1;
      double m_S2;
      double m_S3;
      
      PivotTrend(int timeframe, int pivotType=PIVOT_5POINT, int smoothness=1) {
         m_timeframe = timeframe;
         m_trendType = "Pivot";
         m_pivotType = pivotType;
         m_smoothness = smoothness;
      };
   
      void calculate();
      void methodFivePoint();
      void methodFivePointSmooth();
      
      double getRelativePosition();
};

void PivotTrend::calculate(void) {
   switch (m_pivotType) {
      case PIVOT_5POINT:
         this.methodFivePoint();
         break;
      case PIVOT_5POINT_SMOOTH:
         this.methodFivePointSmooth();
         break;
   }
}

void PivotTrend::calcFivePoint(double high,double low,double close) {
   m_typical = (high + low + close)/3;
   m_R1 = (m_typical * 2) - low;
   m_S1 = (m_typical * 2) - high;
   m_R2 = m_typical + (m_R1 - m_S1);
   m_S2 = m_typical - (m_R1 - m_S1);
   m_R3 = high + 2 * (m_typical - low);
   m_S3 = low - 2 * (high - m_typical);
}

void PivotTrend::methodFivePoint(void) {
   calcFivePoint(iHigh(Symbol(), m_timeframe, 1), 
                 iLow(Symbol(), m_timeframe, 1),
                 iClose(Symbol(), m_timeframe, 1));
}

void PivotTrend::methodFivePointSmooth(void) {
   calcFivePoint(iHighest(Symbol(), m_timeframe, MODE_HIGH, m_smoothness, 1),
                 iLowest(Symbol(), m_timeframe, MODE_LOW, m_smoothness, 1),
                 iClose(Symbol(), m_timeframe, 1));
}

double PivotTrend::getRelativePosition(void) {
   double price = (Ask - Bid) / 2;
   double range1 = m_R1 - m_S1;
   double range2 = m_R2 - m_S2;
   m_ppDiff = MathAbs(price - m_typical);
   
   PrintFormat("[PivotTrend] Typical %.4f, Range1 %.2f, Range2 %.2f", m_typical, range1, range2);
   return (price - m_typical) / range1;
}

#endif
