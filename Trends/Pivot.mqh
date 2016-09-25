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
 */

class PivotTrend : public Trend {

};




#endif
