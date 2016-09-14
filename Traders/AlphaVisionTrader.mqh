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
      int m_volatility;
      bool m_buySetupOk;
      bool m_sellSetupOk;
      double m_riskAndRewardRatio;

   public:
      AlphaVisionTrader(AlphaVisionSignals *signals, double riskAndRewardRatio=2.0) {
         m_signals = signals;
         m_riskAndRewardRatio = riskAndRewardRatio;
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
