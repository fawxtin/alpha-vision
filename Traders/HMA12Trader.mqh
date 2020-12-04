//+------------------------------------------------------------------+
//|                                   AlphaVisionTraderOrchestra.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Traders\AlphaVisionTrader.mqh>


class AlphaVisionTraderHMA12 : public AlphaVisionTrader {
   public:
      AlphaVisionTraderHMA12(AlphaVisionSignals *signals, double rr): AlphaVisionTrader(signals, rr) {
         setTradeMarket(true);
         EntryPoints *entry = m_entries.hGet("BBSM");
         entry.setEnabled(true);
      }
      
      virtual void onTrendSetup(int timeframe);
      virtual void onSignalTrade(int timeframe);

};

///
/// Using RainbowSlow as MAIN Trend
///
void AlphaVisionTraderHMA12::onTrendSetup(int timeframe) {
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

void AlphaVisionTraderHMA12::onSignalTrade(int timeframe) {
   int mjTimeframe = m_signals.getTimeFrameAbove(timeframe);
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   AlphaVision *avMj = m_signals.getAlphaVisionOn(mjTimeframe);
   RainbowTrend *rainbowFast = av.m_rainbowFast;
   RainbowTrend *rainbowSlow = av.m_rainbowSlow;
   StochasticTrend *stoch = av.m_stoch;
   StochasticTrend *stochMj = avMj.m_stoch;
   MACDTrend *macd = av.m_macd;

   if (m_volatility == TREND_VOLATILITY_LOW) setTradeMarket(true);
   else setTradeMarket(false);

   // using fast trend signals and current trend BB positioning
   TrendChange rFast = rainbowFast.getTrendHst();
   if (m_buySetupOk && stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) { // BUY SETUP
      if (rainbowSlow.m_cross_1_2.current == TREND_POSITIVE_FROM_NEGATIVE) {
         onBuySignal(timeframe, rainbowSlow.m_ma2, "hma12");
      }
   }
   
   if (m_sellSetupOk && stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) { // SELL SETUP
      if (rainbowSlow.m_cross_1_2.current == TREND_NEGATIVE_FROM_POSITIVE) {
         onSellSignal(timeframe, rainbowSlow.m_ma2, "hma12");
      }
   }
}

