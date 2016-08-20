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

class StochasticTrend : public Trend {
   /*
    * SMI 6 / 15
    * SMI 18 / 40
    *
    */
   public:
      int m_period1;
      int m_period2;
      
      StochasticTrend() {};
      
};

#endif
