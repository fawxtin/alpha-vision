//+------------------------------------------------------------------+
//|                                            AlphaVisionTrader.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Positions\Trader.mqh>
#include <Signals\AlphaVision.mqh>

#ifndef __TRADER_ALPHAVISION__
#define __TRADER_ALPHAVISION__ 1

class AlphaVisionTrader : public Trader {
   protected:
      AlphaVisionSignals *m_signals;

   public:
      AlphaVisionTrader(AlphaVisionSignals *signals) {
         m_signals = signals;
      }
      
      void ~AlphaVisionTrader() { delete m_signals; }
      
      AlphaVisionSignals *getSignals() { return m_signals; }

      // trader executing signals
      virtual void tradeOnTrends() {}
};


double getTarget(double target, double nDefault) {
   if (target == 0) return nDefault;
   else return target;
}

#endif
