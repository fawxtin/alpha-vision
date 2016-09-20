//+------------------------------------------------------------------+
//|                                   AlphaVisionTraderOrchestra.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Traders\AlphaVisionTrader.mqh>


class AlphaVisionTraderOrchestra : public AlphaVisionTrader {
   public:
      AlphaVisionTraderOrchestra(AlphaVisionSignals *signals, double rr): AlphaVisionTrader(signals, rr) { }
      
      virtual void onTrendValidation(int timeframe);
      virtual void onSignalTrade(int timeframe);
      void orchestraBuy(int timeframe, double signalPrice, string signalOrigin="");
      void orchestraSell(int timeframe, double signalPrice, string signalOrigin="");

};

/// Using RainbowSlow as MAIN Trend
void AlphaVisionTraderOrchestra::onTrendValidation(int timeframe) {
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
   RainbowTrend *rainbowSlow = av.m_rainbowSlow;
   StochasticTrend *stoch = av.m_stoch;
   MACDTrend *macd = av.m_macd;

   // using fast trend signals and current trend BB positioning
   TrendChange rFast = rainbowFast.getTrendHst();
   
   if (m_buySetupOk && stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) { // BUY SETUP
      if (rFast.changed == true && rFast.current == TREND_POSITIVE && 
          stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
         orchestraBuy(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
                 stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
         orchestraBuy(timeframe, rainbowFast.m_ma3, "macd");
      } else if (rainbowSlow.m_cross_1_2.current == TREND_POSITIVE_FROM_NEGATIVE) {
         orchestraBuy(timeframe, rainbowSlow.m_ma2, "hma12");
      } else if (rainbowSlow.m_cross_1_3.current == TREND_POSITIVE_FROM_NEGATIVE) {
         orchestraBuy(timeframe, rainbowSlow.m_ma3, "hma13");
      } else if (rainbowSlow.m_cross_2_3.current == TREND_POSITIVE_FROM_NEGATIVE) {
         orchestraBuy(timeframe, rainbowSlow.m_ma3, "hma23");
      }
   }
   
   if (m_sellSetupOk && stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) { // SELL SETUP
      if (rFast.changed == true && rFast.current == TREND_NEGATIVE && 
          stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
         orchestraSell(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
                 stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
         orchestraSell(timeframe, rainbowFast.m_ma3, "macd");
      } else if (rainbowSlow.m_cross_1_2.current == TREND_NEGATIVE_FROM_POSITIVE) {
         orchestraSell(timeframe, rainbowSlow.m_ma2, "hma12");
      } else if (rainbowSlow.m_cross_1_3.current == TREND_NEGATIVE_FROM_POSITIVE) {
         orchestraSell(timeframe, rainbowSlow.m_ma3, "hma13");
      } else if (rainbowSlow.m_cross_2_3.current == TREND_NEGATIVE_FROM_POSITIVE) {
         orchestraSell(timeframe, rainbowSlow.m_ma3, "hma23");
      }
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
   double stopLoss = bb3.m_bbBottom - m_mkt.vspread * 2;
   
   safeGoLong(timeframe, marketPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("ORCH-%s-mkt", signalOrigin));
   safeGoLong(timeframe, limitPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("ORCH-%s-lmt", signalOrigin));
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
   double stopLoss = bb3.m_bbTop + m_mkt.vspread * 2;
   
   safeGoShort(timeframe, marketPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("ORCH-%s-mkt", signalOrigin));
   safeGoShort(timeframe, limitPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("ORCH-%s-lmt", signalOrigin));
}
