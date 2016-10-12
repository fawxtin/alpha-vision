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
      void calcTrend();
      
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
   calcTrend();
}

void PivotTrend::calcTrend(void) {
   double relativePosition = getRelativePosition();

   if (relativePosition > 2) {
      setTrendHst(TREND_POSITIVE_BREAKOUT);
   } else if (relativePosition > 1) {
      setTrendHst(TREND_POSITIVE);
   } else if (relativePosition > -1) {
      setTrendHst(TREND_NEUTRAL);
   } else if (relativePosition > -2) {
      setTrendHst(TREND_NEGATIVE);
   } else {
      setTrendHst(TREND_NEGATIVE_BREAKOUT);
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
   int barHigh = iHighest(Symbol(), m_timeframe, MODE_HIGH, m_smoothness, 1);
   int barLow = iLowest(Symbol(), m_timeframe, MODE_LOW, m_smoothness, 1);

   if ((barHigh >= 0) && (barLow >= 0))
      calcFivePoint(High[barHigh], Low[barLow], iClose(Symbol(), m_timeframe, 1));
}

double PivotTrend::getRelativePosition() {
   double price = (Ask + Bid) / 2;
   double range1 = m_R1 - m_S1;
   double range2 = m_R2 - m_S2;
   m_ppDiff = MathAbs(price - m_typical);
   double relative = 0;
   
   if (range1 > 0) relative = (price - m_typical) / range1;

   string algoType = EnumToString((PivotSystem) m_pivotType);
   string tfStr = EnumToString((ENUM_TIMEFRAMES) m_timeframe);
   //PrintFormat("[PivotTrend/%s/%s] %.4f - %.4f * %.4f * %.4f - %.4f / %.4f (%.2f)", algoType, tfStr,
   //            m_S2, m_S1, m_typical, m_R1, m_R2, price, relative);

   return relative;
}

#endif
