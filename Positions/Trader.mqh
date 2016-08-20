//+------------------------------------------------------------------+
//|                                                       Trader.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Positions\Positions.mqh>


#ifndef __POSITIONS_TRADER__
#define __POSITIONS_TRADER__ true

class Trader {
   public:
      Positions *m_longPositions;
      Positions *m_shortPositions;
      
      Trader(Positions *longPs, Positions *shortPs) {
         m_longPositions = longPs;
         m_shortPositions = shortPs;
         
      }
      
      void ~Trader() {
         delete m_longPositions;
         delete m_shortPositions;
      }
      
      void loadCurrentOrders(bool noMagicMA=false) {
         m_longPositions.loadCurrentOrders(noMagicMA);
         m_shortPositions.loadCurrentOrders(noMagicMA);
      }

      Positions *getLongPositions() { return m_longPositions; }
      Positions *getShortPositions() { return m_shortPositions; }
      
};



#endif
