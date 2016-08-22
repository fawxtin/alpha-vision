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
      
      // trader executing signals
      void tradeOnTrends();
      void tradeNeutralTrend();
      void tradeNegativeTrend();
      void tradePositiveTrend();
      void goBBLong(BBTrend *bb, string reason, bool useBar=false, double target=0);
      void goBBShort(BBTrend *bb, string reason, bool useBar=false, double target=0);

};

void AlphaVisionTrader::tradeOnTrends() {
   /*
    * Create an Alpha Vision class handling the trends and positions
    * New Approach: Crossing signals means points of support and resistence,
    *    depending on the major timeframe trend will take different actions
    *    on these lines (moving pivot?)
    *
    * Problems to solve:
    *    a) Trading rules:
    *       Consider MajorTimeFrame to set which trade schema we will use
    *       When Mt is Positive, we only search for buy entries
    *       When Mt is Neutral, we scalp
    *       When Mt is Negative, we only search for sell entries
    *       Use Ct to set Entry / Target / Stoploss
    *       Use Ft to scalp and enter trends positions
    *
    */
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avMt = m_signals.getAlphaVisionOn(stf.major);
   HMATrend *hmaMtMj = avMt.m_hmaMajor;
   HMATrend *hmaMtMn = avMt.m_hmaMinor;
   
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *hmaCtMj = avCt.m_hmaMajor;

   SignalChange signalMj;
   string simplifiedMj = hmaMtMj.simplify();
   string simplifiedMn = hmaMtMn.simplify();
   if (simplifiedMj != simplifiedMn) { // Neutral trend
      m_signals.setTrendMj(TREND_NEUTRAL);
      tradeNeutralTrend();
   } else if (simplifiedMj == "POSITIVE") { // Positive trend
      m_signals.setTrendMj(TREND_POSITIVE);
      signalMj = m_signals.getTrendMj();
      if (signalMj.changed) {
         Alert(StringFormat("[Trader] Current Timeframe trend changed to: %d", signalMj.current));
         closeShorts();
      }
      tradePositiveTrend();
   } else if (simplifiedMj == "NEGATIVE") { // Negative trend
      m_signals.setTrendMj(TREND_NEGATIVE);
      signalMj = m_signals.getTrendMj();
      if (signalMj.changed) {
         Alert(StringFormat("[Trader] Current Timeframe trend changed to: %d", signalMj.current));
         closeLongs();
      }
      tradeNegativeTrend();
   }
}

void AlphaVisionTrader::tradeNeutralTrend() {
   /* neutral territory, scalp setup
    * 1) major != minor
    *    open and close positions on crossing
    * 2) major == minor
    *    only close positions on major crossing?
    *
    */
   
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *hmaCtMj = avCt.m_hmaMajor;
   HMATrend *hmaCtMn = avCt.m_hmaMinor;
   BBTrend *bbCt = avCt.m_bb;

   //AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   //HMATrend *hmaFtMj = avFt.m_hmaMajor;
   //HMATrend *hmaFtMn = avFt.m_hmaMinor;
   //BBTrend *bbFt = avFt.m_bb;


   // using current trend
   if (hmaCtMj.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) { // crossing up
      //goLong(Ask, bbFt.m_bbTop, 0, "Neutral-market");
      goLong(hmaCtMj.getMAPeriod2(), bbCt.m_bbTop, 0, "Neutral-hmaMj");
      goBBLong(bbCt, "TNeutral-bb");
   } else if (hmaCtMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) { // crossing up
      //goLong(Ask, bbFt.m_bbTop, 0, "Neutral-market");
      goLong(hmaCtMn.getMAPeriod2(), bbCt.m_bbTop, 0, "Neutral-hmaMn");
      goBBLong(bbCt, "TNeutral-bb");
   } else if (hmaCtMj.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) { // crossing down
      //PrintFormat("[AVT.neutral.short.Mj] hma %.4f / bb %.4f", hmaFtMj.getMAPeriod1(), bbFt.m_bbTop);
      //goShort(Bid, bbFt.m_bbBottom, 0, "Neutral-market");
      goShort(hmaCtMj.getMAPeriod2(), bbCt.m_bbBottom, 0, "Neutral-hmaMj");
      goBBShort(bbCt, "TNeutral-bb");
   } else if (hmaCtMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) { // crossing down
      //PrintFormat("[AVT.neutral.short.Mn] hma %.4f / bb %.4f", hmaFtMn.getMAPeriod1(), bbFt.m_bbTop);
      //goShort(Bid, bbFt.m_bbBottom, 0, "Neutral-market");
      goShort(hmaCtMn.getMAPeriod2(), bbCt.m_bbBottom, 0, "Neutral-hmaMn");
      goBBShort(bbCt, "TNeutral-bb");
   }
}

void AlphaVisionTrader::tradePositiveTrend() {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avMt = m_signals.getAlphaVisionOn(stf.major);
   HMATrend *hmaMtMn = avMt.m_hmaMinor;
   BBTrend *bbMt = avMt.m_bb;

   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *hmaCtMn = avCt.m_hmaMinor;
   BBTrend *bbCt = avCt.m_bb;
  
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *hmaFtMj = avFt.m_hmaMajor;
   HMATrend *hmaFtMn = avFt.m_hmaMinor;
   BBTrend *bbFt = avFt.m_bb;

   if (hmaMtMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      closeLongs("Positive Trend"); // close longs
      goBBShort(bbCt, "TPositive-Reversal", true);
      return;
   }
   
   if (hmaFtMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goLong(hmaFtMn.getMAPeriod2(), bbCt.m_bbTop, 0, "TPositive-hmaMn");
      goBBLong(bbFt, "TPositive-bb", false, bbCt.m_bbTop);
   } else if (hmaFtMj.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goLong(hmaFtMj.getMAPeriod2(), bbCt.m_bbTop, 0, "TPositive-hmaMj");
      goBBLong(bbFt, "TPositive-bb", false, bbCt.m_bbTop);
   }
}

void AlphaVisionTrader::tradeNegativeTrend() {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avMt = m_signals.getAlphaVisionOn(stf.major);
   HMATrend *hmaMtMn = avMt.m_hmaMinor;
   BBTrend *bbMt = avMt.m_bb;

   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *hmaCtMn = avCt.m_hmaMinor;
   BBTrend *bbCt = avCt.m_bb;
  
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *hmaFtMj = avFt.m_hmaMajor;
   HMATrend *hmaFtMn = avFt.m_hmaMinor;
   BBTrend *bbFt = avFt.m_bb;

   if (hmaMtMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      closeShorts("Negative Trend"); // cover shorts
      goBBLong(bbCt, "TNegative-Reversal", true);
      return;
   }

   if (hmaFtMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goShort(hmaFtMn.getMAPeriod2(), bbCt.m_bbBottom, 0, "TPositive-hmaMn");
      goBBShort(bbFt, "TNegative-bb", false, bbCt.m_bbBottom);
   } else if (hmaFtMj.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goShort(hmaFtMj.getMAPeriod2(), bbCt.m_bbBottom, 0, "TPositive-hmaMj");
      goBBShort(bbFt, "TNegative-bb", false, bbCt.m_bbBottom);
   }
}

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

