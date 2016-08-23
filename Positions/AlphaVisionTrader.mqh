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


class AlphaVisionTrader : public Trader {
   protected:
      int m_bbBarShort;
      int m_bbBarLong;
      AlphaVisionSignals *m_signals;

   public:
      AlphaVisionTrader(Positions *longPs, Positions *shortPs, AlphaVisionSignals *signals): Trader(longPs, shortPs) {
         m_signals = signals;
         m_bbBarLong = 0;
         m_bbBarShort = 0;         
      }
      
      void ~AlphaVisionTrader() { delete m_signals; }
      
      AlphaVisionSignals *getSignals() { return m_signals; }

      // Place positions on BB lines      
      void goBBLong(BBTrend *bb, string reason, bool useBar=false, double target=0);
      void goBBShort(BBTrend *bb, string reason, bool useBar=false, double target=0);

      // trader executing signals
      virtual void tradeOnTrends() {}
};


double getTarget(double target, double nDefault) {
   if (target == 0) return nDefault;
   else return target;
}

//// Executing Orders
void AlphaVisionTrader::goBBLong(BBTrend *bb, string reason, bool useBar=false, double target=0) {
   if (useBar) {
      if (m_bbBarLong == Bars) return;
      else m_bbBarLong = Bars;
   }

   if (bb.getTrend() == TREND_POSITIVE || bb.getTrend() == TREND_POSITIVE_BREAKOUT)
      goLong(bb.m_bbMiddle, getTarget(target, bb.m_bbTop), 0, reason);
   goLong(bb.m_bbBottom, getTarget(target, bb.m_bbTop), 0, reason);
}

void AlphaVisionTrader::goBBShort(BBTrend *bb, string reason, bool useBar=false, double target=0) {
   if (useBar) {
      if (m_bbBarShort == Bars) return;
      else m_bbBarShort = Bars;
   }

   if (bb.getTrend() == TREND_NEGATIVE || bb.getTrend() == TREND_NEGATIVE_OVERSOLD)
      goShort(bb.m_bbMiddle, getTarget(target, bb.m_bbBottom), 0, reason);
   goShort(bb.m_bbTop, getTarget(target, bb.m_bbBottom), 0, reason);
}

