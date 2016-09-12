//+------------------------------------------------------------------+
//|                                   AlphaVisionTraderOrchestra.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Traders\AlphaVisionTrader.mqh>

#define STOCH_OVERSOLD_THRESHOLD 35
#define STOCH_OVERBOUGHT_THRESHOLD 65
#define MIN_RISK_AND_REWARD_RATIO 2

class AlphaVisionTraderOrchestra : public AlphaVisionTrader {
   public:
      AlphaVisionTraderOrchestra(AlphaVisionSignals *signals): AlphaVisionTrader(signals) { }
      
      virtual void onTrendSetup(int timeframe);
      virtual void onSignalValidation(int timeframe);
      virtual void onSignalTrade(int timeframe);
      void orchestraBuy(int timeframe, double signalPrice, string signalOrigin="");
      void orchestraSell(int timeframe, double signalPrice, string signalOrigin="");

};

void AlphaVisionTraderOrchestra::onTrendSetup(int timeframe) {
   int higherTF = m_signals.getTimeFrameAbove(timeframe);
   AlphaVision *avHi = m_signals.getAlphaVisionOn(higherTF);
   StochasticTrend *stochHi = avHi.m_stoch;
   RainbowTrend *rainbowHiSlow = avHi.m_rainbowSlow;

   // XXX considering using higher timeframe rainbowSlow as another trend check
   if (stochHi.m_signal >= STOCH_OVERBOUGHT_THRESHOLD || rainbowHiSlow.getTrend() == TREND_NEGATIVE) {
      m_buySetupOk = false;
      m_sellSetupOk = true;
   } else if (stochHi.m_signal <= STOCH_OVERSOLD_THRESHOLD || rainbowHiSlow.getTrend() == TREND_POSITIVE) {
      m_buySetupOk = true;
      m_sellSetupOk = false;
   } else if (m_buySetupOk == false || m_sellSetupOk == false) {
      m_buySetupOk = true;
      m_sellSetupOk = true;
   }
   
   onSignalValidation(timeframe);
}

void AlphaVisionTraderOrchestra::onSignalValidation(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowSlow = av.m_rainbowSlow;
   StochasticTrend *stoch = av.m_stoch;

   TrendChange rSlow = rainbowSlow.getTrendHst();
   if (rSlow.current == TREND_NEUTRAL) { // Neutral trend
      onSignalTrade(timeframe);
   } else if (rSlow.current == TREND_POSITIVE) { // Positive trend
      if (rSlow.changed) {
         Alert(StringFormat("[Trader/%s] %s trend changed to: %s", Symbol(), m_signals.getTimeframeStr(timeframe), 
                            EnumToString((TRENDS) rSlow.current)));
         if (stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) closeShorts(timeframe, StringFormat("Trend-Positive", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      //if (m_sellSetupOk) m_sellSetupOk = false; - safer positioning
      onSignalTrade(timeframe);
   } else if (rSlow.current == TREND_NEGATIVE) { // Negative trend
      if (rSlow.changed) {
         Alert(StringFormat("[Trader/%s] %s trend changed to: %s", Symbol(), m_signals.getTimeframeStr(timeframe),
                            EnumToString((TRENDS) rSlow.current)));
         if (stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) closeLongs(timeframe, StringFormat("Trend-Negative", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      //if (m_buySetupOk) m_buySetupOk = false; - safer positioning
      onSignalTrade(timeframe);
   }
}

void AlphaVisionTraderOrchestra::onSignalTrade(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowFast = av.m_rainbowFast;
   StochasticTrend *stoch = av.m_stoch;
   MACDTrend *macd = av.m_macd;

   // using fast trend signals and current trend BB positioning
   TrendChange rFast = rainbowFast.getTrendHst();
   
   if (rFast.changed == true && m_buySetupOk && rFast.current == TREND_POSITIVE && 
       stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
      orchestraBuy(timeframe, rainbowFast.m_ma3, "rainbow");
   } else if (m_buySetupOk && macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
              stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
      orchestraBuy(timeframe, rainbowFast.m_ma3, "macd");
   } else if (rFast.changed == true && m_sellSetupOk && rFast.current == TREND_NEGATIVE && 
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
      orchestraSell(timeframe, rainbowFast.m_ma3, "rainbow");
   } else if (m_sellSetupOk && macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
      orchestraSell(timeframe, rainbowFast.m_ma3, "macd");
   }
}

void AlphaVisionTraderOrchestra::orchestraBuy(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("long", timeframe)) return;
   else markBarTraded("long", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   double marketPrice = Ask;
   double limitPrice = bb.m_bbBottom;
   double target = bb.m_bbTop;
   double stopLoss = bb3.m_bbBottom - m_mkt.vspread;
   
   safeGoLong(timeframe, marketPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("ORCH-%s-mkt", signalOrigin));
   safeGoLong(timeframe, limitPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("ORCH-%s-lmt", signalOrigin));
}

void AlphaVisionTraderOrchestra::orchestraSell(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("short", timeframe)) return;
   else markBarTraded("short", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   double marketPrice = Bid;
   double limitPrice = bb.m_bbTop;
   double target = bb.m_bbBottom;
   double stopLoss = bb3.m_bbTop + m_mkt.vspread;
   
   safeGoShort(timeframe, marketPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("ORCH-%s-mkt", signalOrigin));
   safeGoShort(timeframe, limitPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("ORCH-%s-lmt", signalOrigin));
}
