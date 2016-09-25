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
      AlphaVisionTraderOrchestra(AlphaVisionSignals *signals, double rr): AlphaVisionTrader(signals, rr) {
         setTradeMarket(true);
         m_entries.hPut("BB", new EntryPointsBB(m_signals));
      }
      
      virtual void onTrendSetup(int timeframe);
      virtual void onSignalTrade(int timeframe);

};

///
/// Using RainbowSlow as MAIN Trend
///
void AlphaVisionTraderOrchestra::onTrendSetup(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowSlow = av.m_rainbowSlow;
   StochasticTrend *stoch = av.m_stoch;

   TrendChange rSlow = rainbowSlow.getTrendHst();
   m_cTrend = rSlow.current;
   if (m_cTrend == TREND_NEUTRAL) { // Neutral trend
      ;
   } else if (m_cTrend == TREND_POSITIVE) { // Positive trend
      if (rSlow.changed) {
         Alert(StringFormat("[Trader/%s] %s trend changed to: %s", Symbol(), m_signals.getTimeframeStr(timeframe), 
                            EnumToString((TRENDS) rSlow.current)));
         if (stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) closeShorts(timeframe, StringFormat("Trend-Positive", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      //if (m_sellSetupOk) m_sellSetupOk = false; - safer positioning
   } else if (m_cTrend == TREND_NEGATIVE) { // Negative trend
      if (rSlow.changed) {
         Alert(StringFormat("[Trader/%s] %s trend changed to: %s", Symbol(), m_signals.getTimeframeStr(timeframe),
                            EnumToString((TRENDS) rSlow.current)));
         if (stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) closeLongs(timeframe, StringFormat("Trend-Negative", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      //if (m_buySetupOk) m_buySetupOk = false; - safer positioning
   }

   onTrendValidation(timeframe);
}

void AlphaVisionTraderOrchestra::onSignalTrade(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowFast = av.m_rainbowFast;
   RainbowTrend *rainbowSlow = av.m_rainbowSlow;
   StochasticTrend *stoch = av.m_stoch;
   MACDTrend *macd = av.m_macd;

   if (m_volatility == TREND_VOLATILITY_LOW) setTradeMarket(true);
   else setTradeMarket(false);

   // using fast trend signals and current trend BB positioning
   TrendChange rFast = rainbowFast.getTrendHst();
   if (m_buySetupOk && stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) { // BUY SETUP
      if (rFast.changed == true && rFast.current == TREND_POSITIVE && 
          stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
         onBuySignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
                 stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
         onBuySignal(timeframe, rainbowFast.m_ma3, "macd");
      } else if (rainbowSlow.m_cross_1_2.current == TREND_POSITIVE_FROM_NEGATIVE) {
         onBuySignal(timeframe, rainbowSlow.m_ma2, "hma12");
      } else if (rainbowSlow.m_cross_1_3.current == TREND_POSITIVE_FROM_NEGATIVE) {
         onBuySignal(timeframe, rainbowSlow.m_ma3, "hma13");
      } else if (rainbowSlow.m_cross_2_3.current == TREND_POSITIVE_FROM_NEGATIVE) {
         onBuySignal(timeframe, rainbowSlow.m_ma3, "hma23");
      }
   }
   
   if (m_sellSetupOk && stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) { // SELL SETUP
      if (rFast.changed == true && rFast.current == TREND_NEGATIVE && 
          stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
         onSellSignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
                 stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
         onSellSignal(timeframe, rainbowFast.m_ma3, "macd");
      } else if (rainbowSlow.m_cross_1_2.current == TREND_NEGATIVE_FROM_POSITIVE) {
         onSellSignal(timeframe, rainbowSlow.m_ma2, "hma12");
      } else if (rainbowSlow.m_cross_1_3.current == TREND_NEGATIVE_FROM_POSITIVE) {
         onSellSignal(timeframe, rainbowSlow.m_ma3, "hma13");
      } else if (rainbowSlow.m_cross_2_3.current == TREND_NEGATIVE_FROM_POSITIVE) {
         onSellSignal(timeframe, rainbowSlow.m_ma3, "hma23");
      }
   }
}

