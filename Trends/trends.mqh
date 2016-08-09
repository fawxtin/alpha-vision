//+------------------------------------------------------------------+
//|                                                       trends.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#ifndef __TRENDS__
#define TRENDS "TRENDS"

#define TREND_POSITIVE_FROM_NEGATIVE  2
#define TREND_POSITIVE                1
#define TREND_NEGATIVE               -1
#define TREND_NEGATIVE_FROM_POSITIVE -2
#define TREND_NEUTRAL                 0


void setupTrend(string &refTrend, int trend, string signalMsg="Trend", bool alertP=true) {
   switch (trend) {
      case TREND_NEGATIVE:
         refTrend = "NEGATIVE";
         break;
      case TREND_POSITIVE:
         refTrend = "POSITIVE";
         break;
      case TREND_NEGATIVE_FROM_POSITIVE:
         refTrend = "NEGATIVE";
         break;
      case TREND_POSITIVE_FROM_NEGATIVE:
         refTrend = "POSITIVE";
         break;
      case TREND_NEUTRAL:
         refTrend = "NEGATIVE";
         break;
      default:
         break;
   }
   if (alertP) {
      if (refTrend != NULL)
         Alert(signalMsg, " Signal (", trend, "): ", refTrend);
      else
         Alert(signalMsg, " Signal NULL");
   }
}
















#endif 

