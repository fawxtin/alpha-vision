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
      datetime m_lastLong;
      datetime m_lastShort;
      int m_bbBarShort;
      int m_bbBarLong;
      AlphaVisionSignals *m_signals;

   public:
      AlphaVisionTrader(AlphaVisionSignals *signals) {
         m_signals = signals;
         m_bbBarLong = 0;
         m_lastLong = 0;
         m_bbBarShort = 0;
         m_lastShort = 0;
      }
      
      void ~AlphaVisionTrader() { delete m_signals; }
      
      AlphaVisionSignals *getSignals() { return m_signals; }

      // Place positions on BB lines      
      //void goBBLong(BBTrend *bb, string reason, bool useBar=false, double target=0, double stopLoss=0);
      //void goBBShort(BBTrend *bb, string reason, bool useBar=false, double target=0, double stopLoss=0);

      // trader executing signals
      virtual void tradeOnTrends() {}
};


double getTarget(double target, double nDefault) {
   if (target == 0) return nDefault;
   else return target;
}

//// Executing Orders
//void AlphaVisionTrader::goBBLong(BBTrend *bb, string reason, bool useBar=false, double target=0, double stopLoss=0) {
//   if (useBar) {
//      if (m_bbBarLong == Bars) return;
//      else m_bbBarLong = Bars;
//   }
//   if (MathAbs(TimeCurrent() - m_lastLong) < 300) return;
//   else m_lastLong = TimeCurrent();
//
//   if (bb.getTrend() == TREND_POSITIVE || bb.getTrend() == TREND_POSITIVE_BREAKOUT)
//      goLong(bb.m_bbMiddle, getTarget(target, bb.m_bbTop), stopLoss, StringFormat("%s_middle", reason));
//   goLong(bb.m_bbBottom, getTarget(target, bb.m_bbTop), stopLoss, StringFormat("%s_bottom", reason));
//}

//void AlphaVisionTrader::goBBShort(BBTrend *bb, string reason, bool useBar=false, double target=0, double stopLoss=0) {
//   if (useBar) {
//      if (m_bbBarShort == Bars) return;
//      else m_bbBarShort = Bars;
//   }
//   if (MathAbs(TimeCurrent() - m_lastShort) < 300) return;
//   else m_lastShort = TimeCurrent();


//   if (bb.getTrend() == TREND_NEGATIVE || bb.getTrend() == TREND_NEGATIVE_OVERSOLD)
//      goShort(bb.m_bbMiddle, getTarget(target, bb.m_bbBottom), stopLoss, StringFormat("%s_middle", reason));
//   goShort(bb.m_bbTop, getTarget(target, bb.m_bbBottom), stopLoss, StringFormat("%s_top", reason));
//}

#endif
