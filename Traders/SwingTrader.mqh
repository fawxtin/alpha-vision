//+------------------------------------------------------------------+
//|                                     AlphaVisionTraderScalper.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

/*
 * Swing Trader shall accumulate positions and do scale in and scale out
 * according to current trend.
 *
 */

#include <Traders\AlphaVisionTrader.mqh>


class AlphaVisionTraderSwing : public AlphaVisionTrader {
   public:
      AlphaVisionTraderSwing(AlphaVisionSignals *signals, double lotSize): AlphaVisionTrader(signals) {
         m_lotSize = lotSize;
      }
      
      virtual void onSignalTrade(int timeframe, int trend);
      virtual void calculateBuyEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="");
      virtual void calculateSellEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="");

};


void AlphaVisionTraderSwing::onSignalTrade(int timeframe, int trend) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowFast = av.m_rainbowFast;
   StochasticTrend *stoch = av.m_stoch;
   ATRdelta *atr = av.m_atr;
   BBTrend *bb = av.m_bb;
   MACDTrend *macd = av.m_macd;

   TrendChange tc = rainbowFast.getTrendHst();
   
   if (m_buySetupOk == true && stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) { // BUY SETUP
      if (tc.changed == true && tc.current == TREND_POSITIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up on oversold territory
         onBuySignal(timeframe, trend, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
         onBuySignal(timeframe, trend, rainbowFast.m_ma3, "macd");
      }   
   }
   
   if (m_sellSetupOk == true && stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) { // SELL SETUP
      if (tc.changed == true && tc.current == TREND_NEGATIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down on overbought territory
         onSellSignal(timeframe, trend, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
         onSellSignal(timeframe, trend, rainbowFast.m_ma3, "macd");
      }
   }
}

void AlphaVisionTraderSwing::calculateBuyEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="") {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;
   
   string bbType;
   double bbRelativePosition = bb.getRelativePosition();

   ee.market = Ask;   
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
      ee.stopLoss = bb3.m_bbBottom - (m_mkt.vspread * 2);      
   } else { // Lower low
      bbType = "ll";
      ee.limit = bb.m_bbBottom;
      ee.target = bb.m_bbMiddle;
      ee.stopLoss = bb3.m_bbBottom - (m_mkt.vspread * 2);      
   }
   ee.algo = StringFormat("SWNG-%s-%s", signalOrigin, bbType);
}

void AlphaVisionTraderSwing::calculateSellEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="") {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   string bbType;
   double bbRelativePosition = bb.getRelativePosition();
   ee.market = Bid;
   ee.limit = bb.m_bbTop;
   ee.target = bb.m_bbBottom;
   ee.stopLoss = bb3.m_bbTop + m_mkt.vspread;

   if (bbRelativePosition > 1) { // Higher top
      bbType = "ht";
      ee.limit = bb.m_bbTop;
      ee.target = bb.m_bbMiddle;
      ee.stopLoss = bb3.m_bbTop + (m_mkt.vspread * 2);      
   } else if (bbRelativePosition > 0) { // Higher low
      bbType = "hl";
      ee.limit = (bb.m_bbMiddle + bb.m_bbTop) / 2;
      ee.target = (bb.m_bbMiddle + bb.m_bbBottom) / 2;
      ee.stopLoss = bb3.m_bbTop + (m_mkt.vspread * 2);   
   } else if (bbRelativePosition > -1) { // Lower top
      bbType = "lt";
      ee.limit = bb.m_bbMiddle;
      ee.target = bb.m_bbBottom;
      ee.stopLoss = bb.m_bbTop + (m_mkt.vspread * 2);      
   } else { // Lower low
      bbType = "ll";
      ee.limit = bb.m_bbMiddle;
      ee.target = bb.m_bbBottom;
      ee.stopLoss = bb.m_bbTop + (m_mkt.vspread * 2);      
   }
   ee.algo = StringFormat("SWNG-%s-%s", signalOrigin, bbType);
}
