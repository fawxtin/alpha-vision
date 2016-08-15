//+------------------------------------------------------------------+
//|                                                    Positions.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Positions\LList.mqh>

#ifndef POSITIONS_BASIC
#define POSITIONS_BASIC 1

#define MAGICMA         19851408
#define MAX_POSITIONS   8
#define LOT_SIZE        0.01


/*
 * Positions shall take Trends and decide whenever to open/close or add/reduce size:
 * virtual bool onTrendTrade(Trend object) / true for new open position
 * OR
 * Positions should describe itself _only_, its: 
 *    entry time/target price/stop loss;  
 * automated decisions would be made on another entity (AV Trader!)
 *
 */

struct PositionValue {
   double price;
   double size;
};

// Single Position class
class Position {  
   public:
      int m_ticket;
      datetime m_open;
      double m_size;
      double m_price;
      double m_target;
      double m_stopLoss;
      
      Position() {};
      Position(int ticket, datetime open, double size, double price, double target=0, double stopLoss=0):
         m_ticket(ticket), m_open(open), m_size(size), m_price(price), m_target(target), m_stopLoss(stopLoss) {};
      
      int barOnOpen() {
         return iBarShift(Symbol(), 0, m_open);
      }
      
      void print() {
         PrintFormat("[Position - %d] %.4f / %.2f  -> %.4f, %.4f (Bar %d)",
                     m_ticket, m_price, m_size, m_target, m_stopLoss, barOnOpen());
      }
};

// Multiple Positions class
class Positions {
   /* TODO: deal with an array of positions. */
   protected:
      // # positions attributte
      LList<Position> *m_positions;
      string m_orderType;
      int m_lastBar;

   public:
      Positions(string orderType): m_orderType(orderType), m_lastBar(0) { m_positions = new LList<Position>(); };
      void ~Positions() { delete m_positions; };
      void loadCurrentOrders(bool noMagicMA=false);
      bool add(Position *position);
      bool close(int idx);
      int count() { return m_positions.length(); }
      
      int lastBar() { return m_lastBar; }
      
      bool isLastBarP(int barN) {
         if (barN > m_lastBar) {
            m_lastBar = barN;
            return true;
         }
         return false;
      }
      
      
      PositionValue meanPositionValue(bool printP=false) {
         int ccount = count();
         PositionValue pv = {0, 0};
         for (int i = 0; i < ccount; i++) {
            if (printP) m_positions[i].print();
            Position *p = m_positions[i];
            pv.size += p.m_size;
            pv.price += m_positions[i].m_price * p.m_size;
         }
         if (pv.size > 0) {
            pv.price /= pv.size;
            PrintFormat("[%s Positions] %d positions (MP %.4f / size %.2f)", m_orderType, ccount, pv.price, pv.size);
         }
         
         return pv;
      };
      
      //double getMeanTargetPrice();
      //double getMeanStopLoss();
};

bool Positions::add(Position *position) {
   if (count() < MAX_POSITIONS) {
      m_positions.add(position);
      this.isLastBarP(position.barOnOpen());
      
      return true;
   }
   return false;
}

bool Positions::close(int idx) {
   if ((idx >= MAX_POSITIONS) || (idx > count())) return false;
   // check which position is last after this one is removed
   m_positions.drop(idx);
   return true;
}

void Positions::loadCurrentOrders(bool noMagicMA=false) { // could be LONG / SHORT
   for (int i = 0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;
      
      if ((this.count() < MAX_POSITIONS) && 
          (OrderSymbol() == Symbol()) && 
          (noMagicMA || (OrderMagicNumber() == MAGICMA))) {
         // orders generated by ea in this symbol
         if ((m_orderType == "LONG") && (OrderType() == OP_BUY)) {
            this.add(new Position(OrderTicket(), OrderOpenTime(), OrderLots(), OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss()));
         } else if ((m_orderType == "SHORT") && (OrderType() == OP_SELL)) {
            this.add(new Position(OrderTicket(), OrderOpenTime(), OrderLots(), OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss()));
         }
      }
   }
}

#endif
