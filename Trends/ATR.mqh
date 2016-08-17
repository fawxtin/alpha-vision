//+------------------------------------------------------------------+
//|                                                          ATR.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

// #include <Trends\trends.mqh>

class ATRdelta {
   public:
      int m_timeframe;
      double m_atr1;
      double m_atr1_i;
      double m_atr2:
      double m_atr2_i;
      
      ATRdelta(int timeframe, int Period1, int Period2) {
         m_timeframe = timeframe;
         m_atr1 = iATR(Symbol(), m_timeframe, Period1, 0);
         m_atr1_i = iATR(Symbol(), m_timeframe, Period1, 1);
         m_atr2 = iATR(Symbol(), m_timeframe, Period2, 0);
         m_atr2_i = iATR(Symbol(), m_timeframe, Period2, 1);
      }
      
      double getStopLossFor(string orderType, double price) {
         double atrMean = (m_atr1 + m_atr1_i) / 2;
         if (orderType == "LONG")
            return price - atrMean;
         else if (orderType == "SHORT")
            return price + atrMean;
      }
      
      double getTargetProfitFor(string orderType, double price) {
         double atrMean = (m_atr2 + m_atr2_i) / 2;
         if (orderType == "LONG")
            return price + atrMean;
         else if (orderType == "SHORT")
            return price - atrMean;
      }
 
}
