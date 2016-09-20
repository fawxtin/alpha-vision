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
      
      virtual void onTrendSetup(int timeframe);
      virtual void onSignalTrade(int timeframe, int trend);
      virtual void calculateBuyEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="");
      virtual void calculateSellEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="");

};

///
/// Using RainbowSlow as MAIN Trend
///
void AlphaVisionTraderOrchestra::onTrendSetup(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowSlow = av.m_rainbowSlow;
   StochasticTrend *stoch = av.m_stoch;

   TrendChange rSlow = rainbowSlow.getTrendHst();
   if (rSlow.current == TREND_NEUTRAL) { // Neutral trend
      ;
   } else if (rSlow.current == TREND_POSITIVE) { // Positive trend
      if (rSlow.changed) {
         Alert(StringFormat("[Trader/%s] %s trend changed to: %s", Symbol(), m_signals.getTimeframeStr(timeframe), 
                            EnumToString((TRENDS) rSlow.current)));
         if (stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) closeShorts(timeframe, StringFormat("Trend-Positive", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      //if (m_sellSetupOk) m_sellSetupOk = false; - safer positioning
   } else if (rSlow.current == TREND_NEGATIVE) { // Negative trend
      if (rSlow.changed) {
         Alert(StringFormat("[Trader/%s] %s trend changed to: %s", Symbol(), m_signals.getTimeframeStr(timeframe),
                            EnumToString((TRENDS) rSlow.current)));
         if (stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) closeLongs(timeframe, StringFormat("Trend-Negative", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      //if (m_buySetupOk) m_buySetupOk = false; - safer positioning
   }

   onTrendValidation(timeframe, rSlow.current);
}

void AlphaVisionTraderOrchestra::onSignalTrade(int timeframe, int trend) {
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
         onBuySignal(timeframe, trend, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
                 stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
         onBuySignal(timeframe, trend, rainbowFast.m_ma3, "macd");
      } else if (rainbowSlow.m_cross_1_2.current == TREND_POSITIVE_FROM_NEGATIVE) {
         onBuySignal(timeframe, trend, rainbowSlow.m_ma2, "hma12");
      } else if (rainbowSlow.m_cross_1_3.current == TREND_POSITIVE_FROM_NEGATIVE) {
         onBuySignal(timeframe, trend, rainbowSlow.m_ma3, "hma13");
      } else if (rainbowSlow.m_cross_2_3.current == TREND_POSITIVE_FROM_NEGATIVE) {
         onBuySignal(timeframe, trend, rainbowSlow.m_ma3, "hma23");
      }
   }
   
   if (m_sellSetupOk && stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) { // SELL SETUP
      if (rFast.changed == true && rFast.current == TREND_NEGATIVE && 
          stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
         onSellSignal(timeframe, trend, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
                 stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
         onSellSignal(timeframe, trend, rainbowFast.m_ma3, "macd");
      } else if (rainbowSlow.m_cross_1_2.current == TREND_NEGATIVE_FROM_POSITIVE) {
         onSellSignal(timeframe, trend, rainbowSlow.m_ma2, "hma12");
      } else if (rainbowSlow.m_cross_1_3.current == TREND_NEGATIVE_FROM_POSITIVE) {
         onSellSignal(timeframe, trend, rainbowSlow.m_ma3, "hma13");
      } else if (rainbowSlow.m_cross_2_3.current == TREND_NEGATIVE_FROM_POSITIVE) {
         onSellSignal(timeframe, trend, rainbowSlow.m_ma3, "hma23");
      }
   }
}

void AlphaVisionTraderOrchestra::calculateBuyEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="") {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   ee.signal = signalPrice;
   ee.market = Ask;
   ee.limit = bb.m_bbBottom;
   ee.target = bb.m_bbTop;
   ee.stopLoss = bb3.m_bbBottom - m_mkt.vspread * 2;
   ee.algo = StringFormat("ORCH-%s-lmt", signalOrigin);
   
   safeGoLong(timeframe, ee.market, ee.target, ee.stopLoss, m_riskAndRewardRatio, StringFormat("ORCH-%s-mkt", signalOrigin));
}

void AlphaVisionTraderOrchestra::calculateSellEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="") {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   ee.signal = signalPrice;
   ee.market = Bid;
   ee.limit = bb.m_bbTop;
   ee.target = bb.m_bbBottom;
   ee.stopLoss = bb3.m_bbTop + m_mkt.vspread * 2;
   ee.algo = StringFormat("ORCH-%s-lmt", signalOrigin);
   
   safeGoShort(timeframe, ee.market, ee.target, ee.stopLoss, m_riskAndRewardRatio, StringFormat("ORCH-%s-mkt", signalOrigin));
}
