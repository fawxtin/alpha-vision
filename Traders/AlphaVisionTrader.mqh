//+------------------------------------------------------------------+
//|                                            AlphaVisionTrader.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Traders\Trader.mqh>
#include <Signals\AlphaVision.mqh>

#ifndef __TRADER_ALPHAVISION__
#define __TRADER_ALPHAVISION__ 1

class AlphaVisionTrader : public Trader {
   protected:
      AlphaVisionSignals *m_signals;
      bool m_buySetupOk;
      bool m_sellSetupOk;

   public:
      AlphaVisionTrader(AlphaVisionSignals *signals) {
         m_signals = signals;
         m_buySetupOk = false;
         m_sellSetupOk = false;
      }
      
      void ~AlphaVisionTrader() { delete m_signals; }
      
      AlphaVisionSignals *getSignals() { return m_signals; }

      // trader executing signals
      virtual void onTrendSetup(int timeframe) {}
      virtual void onSignalTrade(int timeframe) {}
      virtual void onSignalValidation(int timeframe) {}
      virtual void checkVolatility(int timeframe) {}
      virtual void onScalpTrade(int timeframe) {}
      virtual void onBreakoutTrade(int timeframe) {}
};


#endif
