//+------------------------------------------------------------------+
//|                                     AlphaVisionTraderScalper.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <Traders\AlphaVisionTrader.mqh>

/*
 * TODO: trade breakouts;
 * + set pivot trend signal
 * 
 */

class AlphaVisionTraderPivot : public AlphaVisionTrader {      
   public:
      AlphaVisionTraderPivot(AlphaVisionSignals *signals, double rr): AlphaVisionTrader(signals) {
         m_riskAndRewardRatio = rr;
         m_entries.hPut("PVT", new EntryPointsPivot(m_signals));
      }

      virtual void onTrendSetup(int timeframe);
      virtual void onSignalTrade(int timeframe);
};

///
/// Using above timeframe Pivot as Trend Setup
///
void AlphaVisionTraderPivot::onTrendSetup(int timeframe) {
   int mjTimeframe = m_signals.getTimeFrameAbove(timeframe);
   AlphaVision *avMj = m_signals.getAlphaVisionOn(mjTimeframe);
   PivotTrend *pivot = avMj.m_pivot;

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   StochasticTrend *stoch = av.m_stoch;

   TrendChange pTrend = pivot.getTrendHst();
   m_cTrend = pTrend.current;
   if (m_cTrend == TREND_NEUTRAL || m_cTrend == TREND_POSITIVE || m_cTrend == TREND_NEGATIVE) { // Neutral trend
      ;
   } else if (m_cTrend == TREND_POSITIVE_BREAKOUT) { // Positive trend
      if (pTrend.changed) {
         Alert(StringFormat("[Trader/%s] %s trend changed to: %s", Symbol(), m_signals.getTimeframeStr(timeframe), 
                            EnumToString((TRENDS) m_cTrend)));
         if (stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) closeShorts(timeframe, StringFormat("Trend-Positive", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      //if (m_sellSetupOk) m_sellSetupOk = false; - safer positioning
   } else if (m_cTrend == TREND_NEGATIVE_BREAKOUT) { // Negative trend
      if (pTrend.changed) {
         Alert(StringFormat("[Trader/%s] %s trend changed to: %s", Symbol(), m_signals.getTimeframeStr(timeframe),
                            EnumToString((TRENDS) m_cTrend)));
         if (stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) closeLongs(timeframe, StringFormat("Trend-Negative", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      //if (m_buySetupOk) m_buySetupOk = false; - safer positioning
   }

   onTrendValidation(timeframe);
}


void AlphaVisionTraderPivot::onSignalTrade(int timeframe) {
   //if (m_volatility != TREND_VOLATILITY_LOW); // trade breakouts
   
   int mjTimeframe = m_signals.getTimeFrameAbove(timeframe);
   AlphaVision *avMj = m_signals.getAlphaVisionOn(mjTimeframe);
   PivotTrend *pivot = avMj.m_pivot;

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowFast = av.m_rainbowFast;
   StochasticTrend *stoch = av.m_stoch;
   ATRdelta *atr = av.m_atr;
   BBTrend *bb = av.m_bb;
   MACDTrend *macd = av.m_macd;

   TrendChange rainbowTC = rainbowFast.getTrendHst();
   TrendChange pivotTC = rainbowFast.getTrendHst();
   // using fast trend signals and current trend BB positioning
   if (m_buySetupOk == true && stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) { // BUY SETUP
      if (rainbowTC.changed == true && rainbowTC.current == TREND_POSITIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         onBuySignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         onBuySignal(timeframe, rainbowFast.m_ma3, "macd");
      } else if (pivotTC.changed == true && pivotTC.current == TREND_POSITIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         onBuySignal(timeframe, rainbowFast.m_ma3, "pvt");
      } else if (pivotTC.changed == true && pivotTC.current == TREND_POSITIVE_BREAKOUT && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         onBuySignal(timeframe, rainbowFast.m_ma3, "pvtBrk");
      }
   }
   
   if (m_sellSetupOk == true && stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) { // SELL SETUP
      if (rainbowTC.changed == true && rainbowTC.current == TREND_NEGATIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         onSellSignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         onSellSignal(timeframe, rainbowFast.m_ma3, "macd");
      } else if (pivotTC.changed == true && pivotTC.current == TREND_NEGATIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         onSellSignal(timeframe, rainbowFast.m_ma3, "pvt");
      } else if (pivotTC.changed == true && pivotTC.current == TREND_NEGATIVE_BREAKOUT && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         onSellSignal(timeframe, rainbowFast.m_ma3, "pvtBrk");
      }
   }
}

