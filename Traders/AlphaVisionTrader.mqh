//+------------------------------------------------------------------+
//|                                            AlphaVisionTrader.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Traders\Trader.mqh>
#include <Signals\AlphaVision.mqh>

#ifndef __TRADER_ALPHAVISION__
#define __TRADER_ALPHAVISION__ 1

#define STOCH_OVERSOLD_THRESHOLD 35
#define STOCH_OVERBOUGHT_THRESHOLD 65
#define STOCH_OVERREGION 10


struct EntryExitSpot {
   double target;
   double limit;
   double market;
   double stopLoss;
   double signal;
   string algo;
};


class AlphaVisionTrader : public Trader {
   protected:
      AlphaVisionSignals *m_signals;
      int m_volatility;
      //int m_trend; -- trading trend?
      bool m_buySetupOk;
      bool m_sellSetupOk;
      double m_riskAndRewardRatio;

   public:
      AlphaVisionTrader(AlphaVisionSignals *signals, double riskAndRewardRatio=2.0) {
         m_signals = signals;
         m_riskAndRewardRatio = riskAndRewardRatio;
         m_buySetupOk = false;
         m_sellSetupOk = false;
      }
      
      void ~AlphaVisionTrader() { delete m_signals; }
      
      AlphaVisionSignals *getSignals() { return m_signals; }

      // trader executing signals
      virtual void onTrendSetup(int timeframe);
      virtual void onTrendValidation(int timeframe, int trend);
      virtual void checkVolatility(int timeframe);
      virtual void onSignalTrade(int timeframe, int trend) {}
      virtual void onBuySignal(int timeframe, int trend, double signalPrice, string signalStr="");
      virtual void onSellSignal(int timeframe, int trend, double signalPrice, string signalStr="");

      virtual void calculateBuyEntry(EntryExitSpot &ee, int timeframe, int trend, double signalPrice, string signalOrigin) {}
      virtual void calculateSellEntry(EntryExitSpot &ee, int timeframe, int trend, double signalPrice, string signalOrigin) {}
      
      virtual void onScalpTrade(int timeframe) {}
      virtual void onBreakoutTrade(int timeframe) {}
};

///
/// Uses Higher Timeframe RainbowFast as MAIN Trend
///
void AlphaVisionTrader::onTrendSetup(int timeframe) {
   int higherTF = m_signals.getTimeFrameAbove(timeframe);
   AlphaVision *avHi = m_signals.getAlphaVisionOn(higherTF);
   RainbowTrend *rainbowHiFast = avHi.m_rainbowFast;
   StochasticTrend *stochHi = avHi.m_stoch;

   TrendChange rHiFast = rainbowHiFast.getTrendHst();
   if (rHiFast.current == TREND_NEUTRAL) { // Neutral trend
      ;   
   } else if (rHiFast.current == TREND_POSITIVE) { // Positive trend
      if (rHiFast.changed) {
         Alert(StringFormat("[Trader/%s] %s RainbowFast changed to: %s", Symbol(), m_signals.getTimeframeStr(higherTF), 
                            EnumToString((TRENDS) rHiFast.current)));
         if (stochHi.m_signal < STOCH_OVERBOUGHT_THRESHOLD) closeShorts(timeframe, StringFormat("Trend-Positive", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
   } else if (rHiFast.current == TREND_NEGATIVE) { // Negative trend
      if (rHiFast.changed) {
         Alert(StringFormat("[Trader/%s] %s RainbowFast changed to: %s", Symbol(), m_signals.getTimeframeStr(higherTF),
                            EnumToString((TRENDS) rHiFast.current)));
         if (stochHi.m_signal > STOCH_OVERSOLD_THRESHOLD) closeLongs(timeframe, StringFormat("Trend-Negative", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
   }
   
   onTrendValidation(timeframe, rHiFast.current);
}

void AlphaVisionTrader::onTrendValidation(int timeframe, int trend) {
   int higherTF = m_signals.getTimeFrameAbove(timeframe);
   AlphaVision *avHi = m_signals.getAlphaVisionOn(higherTF);
   StochasticTrend *stochHi = avHi.m_stoch;
   RainbowTrend *rainbowHiSlow = avHi.m_rainbowSlow;
   
   m_buySetupOk = true;
   m_sellSetupOk = true;
   
   // RainbowSlow trending
   if (rainbowHiSlow.getTrend() == TREND_NEGATIVE) m_buySetupOk = false;
   if (rainbowHiSlow.getTrend() == TREND_POSITIVE) m_sellSetupOk = false;
   
   /// Strength
   // Overbought regions
   if (stochHi.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) m_buySetupOk = false;
   if (stochHi.m_signal >= (STOCH_OVERBOUGHT_THRESHOLD + STOCH_OVERREGION)) m_sellSetupOk = true;
   // Oversold regions
   if (stochHi.m_signal <= STOCH_OVERSOLD_THRESHOLD) m_sellSetupOk = false;
   if (stochHi.m_signal <= (STOCH_OVERSOLD_THRESHOLD - STOCH_OVERREGION)) m_buySetupOk = true;
   
   checkVolatility(timeframe);

   onSignalTrade(timeframe, trend);
}

void AlphaVisionTrader::checkVolatility(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   ATRdelta *atr = av.m_atr;

   m_volatility = atr.getTrend();
}

void AlphaVisionTrader::onBuySignal(int timeframe, int trend, double signalPrice, string signalOrig="") {
   if (isBarMarked("long", timeframe)) return;
   else markBarTraded("long", timeframe);

   EntryExitSpot ee;
   calculateBuyEntry(ee, timeframe, trend, signalPrice, signalOrig);
   safeGoLong(timeframe, ee.limit, ee.target, ee.stopLoss, m_riskAndRewardRatio, ee.algo);
}

void AlphaVisionTrader::onSellSignal(int timeframe, int trend, double signalPrice, string signalOrig="") {
   if (isBarMarked("short", timeframe)) return;
   else markBarTraded("short", timeframe);

   EntryExitSpot ee;
   calculateSellEntry(ee, timeframe, trend, signalPrice, signalOrig);
   safeGoShort(timeframe, ee.limit, ee.target, ee.stopLoss, m_riskAndRewardRatio, ee.algo);
}

#endif
