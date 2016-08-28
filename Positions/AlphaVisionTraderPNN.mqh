//+------------------------------------------------------------------+
//|                                         AlphaVisionTraderPNN.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict


#include <Positions\AlphaVisionTrader.mqh>

class AlphaVisionTraderPNN : public AlphaVisionTrader {
   public:
      AlphaVisionTraderPNN(Positions *longPs, Positions *shortPs, AlphaVisionSignals *signals): AlphaVisionTrader(longPs, shortPs, signals) {}

      virtual void tradeOnTrends();
      
      void tradeNeutralTrend();
      void tradeNegativeTrend();
      void tradePositiveTrend();
};

void AlphaVisionTraderPNN::tradeOnTrends() {
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
      m_signals.setSignalMj(TREND_NEUTRAL);
      tradeNeutralTrend();
   } else if (simplifiedMj == "POSITIVE") { // Positive trend
      m_signals.setSignalMj(TREND_POSITIVE);
      signalMj = m_signals.getSignalMj();
      if (signalMj.changed) {
         Alert(StringFormat("[Trader] Current Timeframe trend changed to: %d", signalMj.current));
         closeShorts();
      }
      tradePositiveTrend();
   } else if (simplifiedMj == "NEGATIVE") { // Negative trend
      m_signals.setSignalMj(TREND_NEGATIVE);
      signalMj = m_signals.getSignalMj();
      if (signalMj.changed) {
         Alert(StringFormat("[Trader] Current Timeframe trend changed to: %d", signalMj.current));
         closeLongs();
      }
      tradeNegativeTrend();
   }
}

void AlphaVisionTraderPNN::tradeNeutralTrend() {
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

   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *hmaFtMj = avFt.m_hmaMajor;
   HMATrend *hmaFtMn = avFt.m_hmaMinor;
   BBTrend *bbFt = avFt.m_bb;


   // using current trend
   if (hmaCtMj.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) { // crossing up
      //goLong(Ask, bbFt.m_bbTop, 0, "Neutral-market");
      goBBLong(bbFt, "TNeutral-bb");
      goLong(hmaCtMj.getMAPeriod2(), bbCt.m_bbTop, 0, "Neutral-hmaMj");
   } else if (hmaCtMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) { // crossing up
      //goLong(Ask, bbFt.m_bbTop, 0, "Neutral-market");
      goBBLong(bbFt, "TNeutral-bb");
      goLong(hmaCtMn.getMAPeriod2(), bbCt.m_bbTop, 0, "Neutral-hmaMn");
   } else if (hmaCtMj.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) { // crossing down
      //PrintFormat("[AVT.neutral.short.Mj] hma %.4f / bb %.4f", hmaFtMj.getMAPeriod1(), bbFt.m_bbTop);
      //goShort(Bid, bbFt.m_bbBottom, 0, "Neutral-market");
      goBBShort(bbFt, "TNeutral-bb");
      goShort(hmaCtMj.getMAPeriod2(), bbCt.m_bbBottom, 0, "Neutral-hmaMj");
   } else if (hmaCtMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) { // crossing down
      //PrintFormat("[AVT.neutral.short.Mn] hma %.4f / bb %.4f", hmaFtMn.getMAPeriod1(), bbFt.m_bbTop);
      //goShort(Bid, bbFt.m_bbBottom, 0, "Neutral-market");
      goBBShort(bbFt, "TNeutral-bb");
      goShort(hmaCtMn.getMAPeriod2(), bbCt.m_bbBottom, 0, "Neutral-hmaMn");
   }
}

void AlphaVisionTraderPNN::tradePositiveTrend() {
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

   //if (hmaMtMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
   //   closeLongs("Positive Trend"); // close longs
   //   goBBShort(bbCt, "TPositive-Reversal", true);
   //   return;
   //}
   
   if (hmaFtMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goBBLong(bbFt, "TPositive-bb", false, bbCt.m_bbTop);
      goBBLong(bbCt, "TPositive-bb", false, bbCt.m_bbTop);
      goLong(hmaFtMn.getMAPeriod2(), bbCt.m_bbTop, 0, "TPositive-hmaMn");
   } else if (hmaFtMj.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goBBLong(bbFt, "TPositive-bb", false, bbCt.m_bbTop);
      goBBLong(bbCt, "TPositive-bb", false, bbCt.m_bbTop);
      goLong(hmaFtMj.getMAPeriod2(), bbCt.m_bbTop, 0, "TPositive-hmaMj");
   }
}

void AlphaVisionTraderPNN::tradeNegativeTrend() {
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

   //if (hmaMtMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
   //   closeShorts("Negative Trend"); // cover shorts
   //   goBBLong(bbCt, "TNegative-Reversal", true);
   //   return;
   //}

   if (hmaFtMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goBBShort(bbFt, "TNegative-bb", false, bbCt.m_bbBottom);
      goBBShort(bbCt, "TNegative-bb", false, bbCt.m_bbBottom);
      goShort(hmaFtMn.getMAPeriod2(), bbCt.m_bbBottom, 0, "TPositive-hmaMn");
   } else if (hmaFtMj.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goBBShort(bbFt, "TNegative-bb", false, bbCt.m_bbBottom);
      goBBShort(bbCt, "TNegative-bb", false, bbCt.m_bbBottom);
      goShort(hmaFtMj.getMAPeriod2(), bbCt.m_bbBottom, 0, "TPositive-hmaMj");
   }
}
