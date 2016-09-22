//+------------------------------------------------------------------+
//|                                     AlphaVisionTraderScalper.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <Traders\AlphaVisionTrader.mqh>


class AlphaVisionTraderScalper : public AlphaVisionTrader {      
   public:
      AlphaVisionTraderScalper(AlphaVisionSignals *signals, double rr): AlphaVisionTrader(signals) {
         m_riskAndRewardRatio = rr;
      }
      
      virtual void onSignalTrade(int timeframe);
      virtual void calculateBuyEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin);
      virtual void calculateSellEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin);

};

void AlphaVisionTraderScalper::onSignalTrade(int timeframe) {
   // wont trade on high volatility
   if (m_volatility != TREND_VOLATILITY_LOW) return;
   
   int higherTF = m_signals.getTimeFrameAbove(timeframe);
   AlphaVision *avHi = m_signals.getAlphaVisionOn(higherTF);
   StochasticTrend *stochHi = avHi.m_stoch;

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowFast = av.m_rainbowFast;
   StochasticTrend *stoch = av.m_stoch;
   ATRdelta *atr = av.m_atr;
   BBTrend *bb = av.m_bb;
   MACDTrend *macd = av.m_macd;

   TrendChange tc = rainbowFast.getTrendHst();
   // using fast trend signals and current trend BB positioning
   if (m_buySetupOk == true && stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) { // BUY SETUP
      if (tc.changed == true && tc.current == TREND_POSITIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         onBuySignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         onBuySignal(timeframe, rainbowFast.m_ma3, "macd");
      }   
   }
   
   if (m_sellSetupOk == true && stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) { // SELL SETUP
      if (tc.changed == true && tc.current == TREND_NEGATIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         onSellSignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         onSellSignal(timeframe, rainbowFast.m_ma3, "macd");
      }
   }
}

void AlphaVisionTraderScalper::calculateBuyEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="") {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb4 = av.m_bb4;

   string bbType;
   double bbRelativePosition = bb.getRelativePosition();
   
   if (bbRelativePosition > 1) { // Higher top
      bbType = "ht";
      ee.limit = bb.m_bbMiddle;
      ee.target = bb.m_bbTop;
      ee.stopLoss = bb.m_bbBottom - (m_mkt.vspread * 2);
   } else if (bbRelativePosition > 0) { // Higher low
      bbType = "hl";
      ee.limit = (bb.m_bbMiddle + bb.m_bbBottom) / 2;
      ee.target = bb.m_bbTop;
      ee.stopLoss = bb.m_bbBottom - (m_mkt.vspread * 2);   
   } else if (bbRelativePosition > -1) { // Lower top
      bbType = "lt";
      ee.limit = bb.m_bbBottom;
      ee.target = (bb.m_bbMiddle + bb.m_bbTop) / 2;
      ee.stopLoss = bb4.m_bbBottom - (m_mkt.vspread * 2);      
   } else { // Lower low
      bbType = "ll";
      ee.limit = bb.m_bbBottom;
      ee.target = bb.m_bbMiddle;
      ee.stopLoss = bb4.m_bbBottom - (m_mkt.vspread * 2);      
   }
   ee.algo = StringFormat("SCLP-%s-%s", signalOrigin, bbType);
}

void AlphaVisionTraderScalper::calculateSellEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="") {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb4 = av.m_bb4;

   string bbType;
   double bbRelativePosition = bb.getRelativePosition();

   if (bbRelativePosition > 1) { // Higher top
      bbType = "ht";
      ee.limit = bb.m_bbTop;
      ee.target = bb.m_bbMiddle;
      ee.stopLoss = bb4.m_bbTop + (m_mkt.vspread * 2);      
   } else if (bbRelativePosition > 0) { // Higher low
      bbType = "hl";
      ee.limit = (bb.m_bbMiddle + bb.m_bbTop) / 2;
      ee.target = bb.m_bbMiddle;
      ee.stopLoss = bb4.m_bbTop + (m_mkt.vspread * 2);   
   } else if (bbRelativePosition > -1) { // Lower top
      bbType = "lt";
      ee.limit = bb.m_bbMiddle;
      ee.target = bb.m_bbBottom;
      ee.stopLoss = bb.m_bbTop + (m_mkt.vspread * 2);      
   } else { // Lower low
      bbType = "ll";
      ee.limit = (bb.m_bbMiddle + bb.m_bbBottom) / 2;
      ee.target = bb.m_bbBottom;
      ee.stopLoss = bb.m_bbTop + (m_mkt.vspread * 2);      
   }
   ee.algo = StringFormat("SCLP-%s-%s", signalOrigin, bbType);
}
