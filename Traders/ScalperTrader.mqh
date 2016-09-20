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
      
      virtual void onSignalTrade(int timeframe, int trend);
      void scalperBuy(int timeframe, double signalPrice, string signalOrigin="");
      void scalperSell(int timeframe, double signalPrice, string signalOrigin="");

};

void AlphaVisionTraderScalper::onSignalTrade(int timeframe, int trend) {
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
         scalperBuy(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         scalperBuy(timeframe, rainbowFast.m_ma3, "macd");
      }   
   }
   
   if (m_sellSetupOk == true && stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) { // SELL SETUP
      if (tc.changed == true && tc.current == TREND_NEGATIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         scalperSell(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         scalperSell(timeframe, rainbowFast.m_ma3, "macd");
      }
   }
}

void AlphaVisionTraderScalper::scalperBuy(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("long", timeframe)) return;
   else markBarTraded("long", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb4 = av.m_bb4;

   string bbType;
   double bbRelativePosition = bb.getRelativePosition();
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
      stopLoss = bb4.m_bbBottom - (m_mkt.vspread * 2);      
   } else { // Lower low
      bbType = "ll";
      limitPrice = bb.m_bbBottom;
      target = bb.m_bbMiddle;
      stopLoss = bb4.m_bbBottom - (m_mkt.vspread * 2);      
   }
   
   safeGoLong(timeframe, limitPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("SCLP-%s-%s", signalOrigin, bbType));
}

void AlphaVisionTraderScalper::scalperSell(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("short", timeframe)) return;
   else markBarTraded("short", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb4 = av.m_bb4;

   string bbType;
   double bbRelativePosition = bb.getRelativePosition();
   double limitPrice;
   double target;
   double stopLoss;

   if (bbRelativePosition > 1) { // Higher top
      bbType = "ht";
      limitPrice = bb.m_bbTop;
      target = bb.m_bbMiddle;
      stopLoss = bb4.m_bbTop + (m_mkt.vspread * 2);      
   } else if (bbRelativePosition > 0) { // Higher low
      bbType = "hl";
      limitPrice = (bb.m_bbMiddle + bb.m_bbTop) / 2;
      target = bb.m_bbMiddle;
      stopLoss = bb4.m_bbTop + (m_mkt.vspread * 2);   
   } else if (bbRelativePosition > -1) { // Lower top
      bbType = "lt";
      limitPrice = bb.m_bbMiddle;
      target = bb.m_bbBottom;
      stopLoss = bb.m_bbTop + (m_mkt.vspread * 2);      
   } else { // Lower low
      bbType = "ll";
      limitPrice = (bb.m_bbMiddle + bb.m_bbBottom) / 2;
      target = bb.m_bbBottom;
      stopLoss = bb.m_bbTop + (m_mkt.vspread * 2);      
   }
   
   safeGoShort(timeframe, limitPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("SCLP-%s-%s", signalOrigin, bbType));
}
