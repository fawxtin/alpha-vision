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
      void swingBuy(int timeframe, double signalPrice, string signalOrigin="");
      void swingSell(int timeframe, double signalPrice, string signalOrigin="");

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
         swingBuy(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
         swingBuy(timeframe, rainbowFast.m_ma3, "macd");
      }   
   }
   
   if (m_sellSetupOk == true && stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) { // SELL SETUP
      if (tc.changed == true && tc.current == TREND_NEGATIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down on overbought territory
         swingSell(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
         swingSell(timeframe, rainbowFast.m_ma3, "macd");
      }
   }
}

void AlphaVisionTraderSwing::swingBuy(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("long", timeframe)) return;
   else markBarTraded("long", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;
   
   string bbType;
   double bbRelativePosition = bb.getRelativePosition();
   double marketPrice = Ask;
   double limitPrice;
   double target;
   double stopLoss;
   
   if (bbRelativePosition > 1) { // Higher top
      bbType = "ht";
      limitPrice = bb.m_bbMiddle;
      target = bb.m_bbTop;
      stopLoss = bb.m_bbBottom - (m_mkt.vspread * 2);
   } else if (bbRelativePosition > 0) { // Higher low
      bbType = "hl";
      limitPrice = (bb.m_bbMiddle + bb.m_bbBottom) / 2;
      target = bb.m_bbTop;
      stopLoss = bb.m_bbBottom - (m_mkt.vspread * 2);   
   } else if (bbRelativePosition > -1) { // Lower top
      bbType = "lt";
      limitPrice = bb.m_bbBottom;
      target = (bb.m_bbMiddle + bb.m_bbTop) / 2;
      stopLoss = bb3.m_bbBottom - (m_mkt.vspread * 2);      
   } else { // Lower low
      bbType = "ll";
      limitPrice = bb.m_bbBottom;
      target = bb.m_bbMiddle;
      stopLoss = bb3.m_bbBottom - (m_mkt.vspread * 2);      
   }
   
   safeGoLong(timeframe, limitPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("SWNG-%s-%s", signalOrigin, bbType));
}

void AlphaVisionTraderSwing::swingSell(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("short", timeframe)) return;
   else markBarTraded("short", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   string bbType;
   double bbRelativePosition = bb.getRelativePosition();
   double marketPrice = Bid;
   double limitPrice = bb.m_bbTop;
   double target = bb.m_bbBottom;
   double stopLoss = bb3.m_bbTop + m_mkt.vspread;

   if (bbRelativePosition > 1) { // Higher top
      bbType = "ht";
      limitPrice = bb.m_bbTop;
      target = bb.m_bbMiddle;
      stopLoss = bb3.m_bbTop + (m_mkt.vspread * 2);      
   } else if (bbRelativePosition > 0) { // Higher low
      bbType = "hl";
      limitPrice = (bb.m_bbMiddle + bb.m_bbTop) / 2;
      target = (bb.m_bbMiddle + bb.m_bbBottom) / 2;
      stopLoss = bb3.m_bbTop + (m_mkt.vspread * 2);   
   } else if (bbRelativePosition > -1) { // Lower top
      bbType = "lt";
      limitPrice = bb.m_bbMiddle;
      target = bb.m_bbBottom;
      stopLoss = bb.m_bbTop + (m_mkt.vspread * 2);      
   } else { // Lower low
      bbType = "ll";
      limitPrice = bb.m_bbMiddle;
      target = bb.m_bbBottom;
      stopLoss = bb3.m_bbTop + (m_mkt.vspread * 2);      
   }
   
   safeGoShort(timeframe, limitPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("SWNG-%s-%s", signalOrigin, bbType));
}
