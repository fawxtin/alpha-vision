//+------------------------------------------------------------------+
//|                                                   Stochastic.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>

#ifndef __TRENDS_MACD__
#define __TRENDS_MACD__ 1



class MACDTrend : public Trend {
   /*
    * fast 12; slow 26; sma 9
    *
    */
   private:
      int m_crossBarUp;
      int m_crossBarDown;
    
   public:
      int m_timeframe;
      int m_pFast;
      int m_pSlow;
      int m_pSma;
      double m_main;
      double m_main_i;
      double m_signal;
      double m_signal_i;
      
      MACDTrend(int timeframe, int fast=12, int slow=26, int sma=9) : m_pFast(fast), m_pSlow(slow), m_pSma(sma) {
         m_trendType = "MACD";
         m_timeframe = timeframe; 
         m_crossBarUp = 0;
         m_crossBarDown = 0;
         
         m_trendHst.last = TREND_EMPTY;
         m_trendHst.current = TREND_EMPTY;
         m_trendHst.changed = false;
      };
      
      void calculate();
};

void MACDTrend::calculate(void) {
   m_main = iMACD(NULL, m_timeframe, m_pFast, m_pSlow, m_pSma, PRICE_CLOSE, MODE_MAIN, 0);
   m_main_i = iMACD(NULL, m_timeframe, m_pFast, m_pSlow, m_pSma, PRICE_CLOSE, MODE_MAIN, 0);
   m_signal = iMACD(NULL, m_timeframe, m_pFast, m_pSlow, m_pSma, PRICE_CLOSE, MODE_SIGNAL, 0);
   m_signal_i = iMACD(NULL, m_timeframe, m_pFast, m_pSlow, m_pSma, PRICE_CLOSE, MODE_SIGNAL, 0);
   
   // TODO: read more about macd and the better way to deal with its signals
   if (m_main >= m_signal) { // positive region
      if (m_main_i < m_signal_i) { // crossing up
         setTrendHst(TREND_POSITIVE_FROM_NEGATIVE);
         if (m_crossBarUp != Bars) {
            PrintFormat("[trend.macd] Crossed UP at %.4f!", m_signal);
            m_crossBarUp = Bars;
         }
      } else {
         setTrendHst(TREND_POSITIVE);
         if (m_trendHst.changed == true && 
             m_trendHst.last == TREND_NEGATIVE &&
             m_crossBarUp != Bars) {
            m_trend = TREND_POSITIVE_FROM_NEGATIVE;
            PrintFormat("[trend.macd] (Forced) Crossed UP at %.4f!", m_signal);
            m_crossBarUp = Bars;
         }
      }
   } else {
      if (m_main_i > m_signal_i) { // crossing down
         setTrendHst(TREND_NEGATIVE_FROM_POSITIVE);
         if (m_crossBarDown != Bars) {
            PrintFormat("[trend.macd] Crossed DOWN at %.4f!", m_signal);
            m_crossBarDown = Bars;
         }
      } else {
         setTrendHst(TREND_NEGATIVE);
         if (m_trendHst.changed == true && 
             m_trendHst.last == TREND_POSITIVE &&
             m_crossBarDown != Bars) {
            m_trend = TREND_NEGATIVE_FROM_POSITIVE;
            PrintFormat("[trend.macd] (Forced) Crossed DOWN at %.4f!", m_signal);
            m_crossBarDown = Bars;
         }
      }
   }
}

#endif
