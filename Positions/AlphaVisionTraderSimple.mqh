//+------------------------------------------------------------------+
//|                                      AlphaVisionTraderSimple.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Positions\AlphaVisionTrader.mqh>

class AlphaVisionTraderSimple : public AlphaVisionTrader {

   public:
      AlphaVisionTraderSimple(Positions *longPs, Positions *shortPs, AlphaVisionSignals *signals): AlphaVisionTrader(longPs, shortPs, signals) {}

      virtual void tradeOnTrends();
      void tradeSimple();
};

void AlphaVisionTraderSimple::tradeOnTrends() {
   /*
    * On Cross signal up, put buy limit orders on BB.
    * On Cross signal down, put sell limit orders on BB.
    *
    * 
    *
    */
   SignalTimeFrames stf = m_signals.getTimeFrames();
   
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *hmaCtMj = avCt.m_hmaMajor;
   HMATrend *hmaCtMn = avCt.m_hmaMinor;
   BBTrend *bbCt = avCt.m_bb;

   SignalChange signalCt;
   string simplifiedMj = hmaCtMj.simplify();
   string simplifiedMn = hmaCtMn.simplify();
   if (simplifiedMj != simplifiedMn) { // Neutral trend
      m_signals.setTrendCt(TREND_NEUTRAL);
      signalCt = m_signals.getTrendCt();
      if (signalCt.changed) {
         if (signalCt.last == TREND_NEGATIVE)
            goBBLong(bbCt, "Neutral-reversal", true);
         else if (signalCt.last == TREND_POSITIVE)
            goBBShort(bbCt, "Neutral-reversal", true);
      }
      tradeSimple();
   } else if (simplifiedMj == "POSITIVE") { // Positive trend
      m_signals.setTrendCt(TREND_POSITIVE);
      signalCt = m_signals.getTrendCt();
      if (signalCt.changed) {
         Alert(StringFormat("[Trader] Current Timeframe trend changed to: %d", signalCt.current));
         closeShorts("Positive-Trend");
         goBBLong(bbCt, "Positive-Reversal", true);
      }
      tradeSimple();
   } else if (simplifiedMj == "NEGATIVE") { // Negative trend
      m_signals.setTrendCt(TREND_NEGATIVE);
      signalCt = m_signals.getTrendCt();
      if (signalCt.changed) {
         Alert(StringFormat("[Trader] Current Timeframe trend changed to: %d", signalCt.current));
         closeLongs("Negative-Trend");
         goBBShort(bbCt, "Negative-Reversal", true);
      }
      tradeSimple();
   }
}

void AlphaVisionTraderSimple::tradeSimple() {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   BBTrend *bbCt = avCt.m_bb;
   BBTrend *bbCt3 = avCt.m_bb3;

   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *hmaFtMj = avFt.m_hmaMajor;
   HMATrend *hmaFtMn = avFt.m_hmaMinor;

   // using fast trend signals and current trend BB positioning
   if (hmaFtMj.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) { // crossing up
      goBBLong(bbCt, "TSimple-bb-hmaFtMj", false, 0, bbCt3.m_bbBottom - m_mkt.vspread);
   } else if (hmaFtMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) { // crossing up
      goBBLong(bbCt, "TSimple-bb-hmaFtMn", false, 0, bbCt3.m_bbBottom - m_mkt.vspread);
   } else if (hmaFtMj.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) { // crossing down
      goBBShort(bbCt, "TSimple-bb-hmaFtMj", false, 0, bbCt3.m_bbTop + m_mkt.vspread);
   } else if (hmaFtMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) { // crossing down
      goBBShort(bbCt, "TSimple-bb-hmaFtMn", false, 0, bbCt3.m_bbTop + m_mkt.vspread);
   }
}