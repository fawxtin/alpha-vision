//+------------------------------------------------------------------+
//|                                     AlphaVisionTraderScalper.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <Traders\AlphaVisionTrader.mqh>

#define STOCH_OVERSOLD_THRESHOLD 35
#define STOCH_OVERBOUGHT_THRESHOLD 65
#define MIN_RISK_AND_REWARD_RATIO 2

class AlphaVisionTraderSwing : public AlphaVisionTrader {
   public:
      AlphaVisionTraderSwing(AlphaVisionSignals *signals): AlphaVisionTrader(signals) { }
      
      virtual void onTrendSetup(int timeframe);
      virtual void onSignalTrade(int timeframe);
      virtual void onSignalValidation(int timeframe);
      virtual void checkVolatility(int timeframe);
      virtual void onScalpTrade(int timeframe);
      virtual void onBreakoutTrade(int timeframe) {}
      void swingBuy(int timeframe, double signalPrice, string signalOrigin="");
      void swingSell(int timeframe, double signalPrice, string signalOrigin="");

};

void AlphaVisionTraderSwing::onTrendSetup(int timeframe) {
   int higherTF = m_signals.getTimeFrameAbove(timeframe);
   AlphaVision *avHi = m_signals.getAlphaVisionOn(higherTF);
   StochasticTrend *stochHi = avHi.m_stoch;
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   ATRdelta *atr = av.m_atr;

   if (stochHi.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
      m_buySetupOk = false;
      m_sellSetupOk = true;
   } else if (stochHi.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
      m_buySetupOk = true;
      m_sellSetupOk = false;
   } else if (m_buySetupOk == false || m_sellSetupOk == false) {
      m_buySetupOk = true;
      m_sellSetupOk = true;
   }

   onSignalValidation(timeframe);
}

void AlphaVisionTraderSwing::onSignalValidation(int timeframe) {
   int higherTF = m_signals.getTimeFrameAbove(timeframe);
   AlphaVision *avHi = m_signals.getAlphaVisionOn(higherTF);
   RainbowTrend *rainbowHiFast = avHi.m_rainbowFast;
   StochasticTrend *stochHi = avHi.m_stoch;

   TrendChange rHiFast = rainbowHiFast.getTrendHst();
   if (rHiFast.current == TREND_NEUTRAL) { // Neutral trend
      onSignalTrade(timeframe);
   } else if (rHiFast.current == TREND_POSITIVE) { // Positive trend
      if (rHiFast.changed) {
         Alert(StringFormat("[SWNGTrader/%s] %s RainbowFast changed to: %s", Symbol(), m_signals.getTimeframeStr(higherTF), 
                            EnumToString((TRENDS) rHiFast.current)));
         if (stochHi.m_signal > STOCH_OVERSOLD_THRESHOLD) closeShorts(timeframe, StringFormat("Trend-Positive", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      onSignalTrade(timeframe);
   } else if (rHiFast.current == TREND_POSITIVE) { // Negative trend
      if (rHiFast.changed) {
         Alert(StringFormat("[SWNGTrader/%s] %s RainbowFast changed to: %s", Symbol(), m_signals.getTimeframeStr(higherTF),
                            EnumToString((TRENDS) rHiFast.current)));
         if (stochHi.m_signal < STOCH_OVERBOUGHT_THRESHOLD) closeLongs(timeframe, StringFormat("Trend-Negative", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      onSignalTrade(timeframe);
   }
}


void AlphaVisionTraderSwing::onSignalTrade(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbow = av.m_rainbowFast;
   StochasticTrend *stoch = av.m_stoch;
   ATRdelta *atr = av.m_atr;
   BBTrend *bb = av.m_bb;

   TrendChange tc = rainbow.getTrendHst();
   // using fast trend signals and current trend BB positioning
   if (tc.changed == false) return;
   if (m_buySetupOk == true && tc.current == TREND_POSITIVE &&
       stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up on oversold territory
      swingBuy(timeframe, rainbow.m_ma3, "rainbow");
   } else if (m_sellSetupOk == true && tc.current == TREND_NEGATIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down on overbought territory
      swingSell(timeframe, rainbow.m_ma3, "rainbow");
   }
}

void AlphaVisionTraderSwing::swingBuy(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("long", timeframe)) return;
   else markBarTraded("long", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   double marketPrice = Ask;
   double limitPrice;
   double target;
   double stopLoss;
   
   if (bb.simplify() == "POSITIVE") {
      limitPrice = (bb.m_bbMiddle + bb.m_bbBottom) / 2;
      target = bb.m_bbTop;
      stopLoss = bb.m_bbBottom - (m_mkt.vspread * 2);
   } else { // Negative
      limitPrice = bb.m_bbBottom;
      target = (bb.m_bbMiddle + bb.m_bbTop) / 2;
      stopLoss = bb3.m_bbBottom - (m_mkt.vspread * 2);      
   }
   
   safeGoLong(timeframe, marketPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("SWNG-%s-mkt", signalOrigin));
   safeGoLong(timeframe, signalPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("SWNG-%s-sgn", signalOrigin));
   safeGoLong(timeframe, limitPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("SWNG-%s-lmt", signalOrigin));
}

void AlphaVisionTraderSwing::swingSell(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("short", timeframe)) return;
   else markBarTraded("short", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   double marketPrice = Bid;
   double limitPrice = bb.m_bbTop;
   double target = bb.m_bbBottom;
   double stopLoss = bb3.m_bbTop + m_mkt.vspread;

   if (bb.simplify() == "POSITIVE") {
      limitPrice = bb.m_bbTop;
      target = (bb.m_bbMiddle + bb.m_bbBottom) / 2;
      stopLoss = bb3.m_bbTop + (m_mkt.vspread * 2);      
   } else if (bb.simplify() == "NEGATIVE") {
      limitPrice = (bb.m_bbMiddle + bb.m_bbTop) / 2;
      target = bb.m_bbBottom;
      stopLoss = bb.m_bbTop + (m_mkt.vspread * 2);
   }

   
   safeGoShort(timeframe, marketPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("SWNG-%s-mkt", signalOrigin));
   safeGoShort(timeframe, signalPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("SWNG-%s-sgn", signalOrigin));
   safeGoShort(timeframe, limitPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("SWNG-%s-lmt", signalOrigin));
}
