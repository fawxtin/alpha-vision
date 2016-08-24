//+------------------------------------------------------------------+
//|                                                    Positions.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Arrays\LList.mqh>

#ifndef __POSITIONS_BASIC__
#define __POSITIONS_BASIC__ 1

#define MAGICMA         19851408
#define MAX_POSITIONS   16
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
      string m_entryType;
      datetime m_open;
      double m_size;
      double m_price;
      double m_marketPrice; // when opening the position (for limit/stop orders)
      double m_signalPrice; // the signal price when it occurred the opening position
      double m_target;
      double m_stopLoss;
      string m_reason;
      datetime m_closeTS;
      double m_closePrice;
      int m_orderType;
      
      Position() {};
      Position(int ticket, string entryType, double marketPrice, double signalPrice): m_ticket(ticket), m_entryType(entryType), 
         m_marketPrice(marketPrice), m_signalPrice(signalPrice) {
         load();
      };

      void load() {
         if (OrderSelect(m_ticket, SELECT_BY_TICKET)) {
            m_open = OrderOpenTime();
            m_size = OrderLots();
            m_price = OrderOpenPrice();
            m_target = OrderTakeProfit();
            m_stopLoss = OrderStopLoss();
            m_reason = OrderComment();
            m_closeTS = OrderCloseTime();
            m_closePrice = OrderClosePrice();
            m_orderType = OrderType(); //EnumToString((ENUM_ORDER_TYPE) OrderType());
         }
      }
            
      int barOnOpen() { return iBarShift(Symbol(), 0, m_open); }
      
      bool isPending() {
         load();
         if (m_orderType >= 2) return true;
         else return false;
      }
      
      void close(double price) {
         if (isPending()) {
            PrintFormat("[Position] Deleting pending position %d", m_ticket);
            if (!OrderDelete(m_ticket))
               PrintFormat("[Position] Error deleting position %d: %d", m_ticket, GetLastError());
            else {
               m_closeTS = TimeCurrent();
               m_closePrice = m_price;
            }
         } else {
            PrintFormat("[Position] Closing position %d", m_ticket);
            if (!OrderClose(m_ticket, m_size, price, 3))
               PrintFormat("[Position] Error closing position %d: %d", m_ticket, GetLastError());
            else
               load();
         }
      }
      
      void print() {
         PrintFormat("[Position - %d] %.4f / %.2f  -> %.4f, %.4f (Bar %d)",
                     m_ticket, m_price, m_size, m_target, m_stopLoss, barOnOpen());
      }
      
};

// Multiple Positions class
class Positions {
   /* TODO: deal with an array of positions. */
   private:
      int m_logHandleOpen;
      int m_logHandleClosed;

   protected:
      // # positions attributte
      LList<Position> *m_positions;
      string m_positionType;
      int m_lastBar;

   public:
      Positions(string positionType, bool logging=false): m_positionType(positionType), m_lastBar(0), m_logHandleOpen(0), m_logHandleClosed(0) {
         m_positions = new LList<Position>();
         if (logging) enableLogging();
      };
      void ~Positions() {
         delete m_positions;
         if (m_logHandleOpen > 0) FileClose(m_logHandleOpen);
         if (m_logHandleClosed > 0) FileClose(m_logHandleClosed);
      };
      
      void loadCurrentOrders(bool noMagicMA=false);
      void cleanClosedOrders(bool noMagicMA=false);
      bool add(Position *position);
      bool close(int idx, double price=0, string reason="");
      void cleanOrders();
      int count() { return m_positions.length(); }
      string positionType() { return m_positionType; }
      
      int lastBar() { return m_lastBar; }
      void setLastBar(int bar) { m_lastBar = bar; }
      
      bool isLastBarP(int barN) {
         if (barN > m_lastBar) {
            m_lastBar = barN;
            return true;
         }
         return false;
      }
      
      Position *operator[](int index) {
         if (index < 0 || index >= m_positions.length())
            return NULL;
      
         return m_positions[index];
      }
      
      
      PositionValue meanPositionValue(bool printP=false) {
         int ccount = count();
         PositionValue pv = {0, 0};
         for (int i = 0; i < ccount; i++) {
            Position *p = m_positions[i];
            if (printP) p.print();
            if (p.isPending()) break;
            pv.size += p.m_size;
            pv.price += m_positions[i].m_price * p.m_size;
         }
         if (pv.size > 0) {
            pv.price /= pv.size;
            PrintFormat("[%s Positions] %d positions (MP %.4f / size %.2f)", m_positionType, ccount, pv.price, pv.size);
         }
         
         return pv;
      };
      
      // Logging
      void enableLogging();
      double calculateRiskRewardRatio(Position *p);
      void logOpenPosition(Position *p);
      void logClosedPosition(Position *p, string exitReason);
      
      //double getMeanTargetPrice();
      //double getMeanStopLoss();
};


////
//// Handling the list of positions
////

bool Positions::add(Position *position) {
   if (count() < MAX_POSITIONS) {
      Print("[Positions.add]");
      position.print();
      m_positions.add(position);
      this.isLastBarP(position.barOnOpen());
      if (m_logHandleOpen > 0) logOpenPosition(position);

      return true;
   }
   return false;
}

bool Positions::close(int idx, double price=0, string reason="") {
   if ((idx >= MAX_POSITIONS) || (idx > count())) return false;
   // check which position is last after this one is removed
   Position *p = m_positions[idx];
   p.close(price);
   if (m_logHandleClosed > 0) logClosedPosition(p, reason);
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
         if ((m_positionType == "LONG") && 
             (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)) {
            this.add(new Position(OrderTicket(), "loaded", OrderOpenPrice(), OrderOpenPrice()));
         } else if ((m_positionType == "SHORT") && 
                    (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP)) {
            this.add(new Position(OrderTicket(), "loaded", OrderOpenPrice(), OrderOpenPrice()));
         }
      }
   }
}

void Positions::cleanOrders() { // could be LONG / SHORT
   int i = 0;
   while (i < m_positions.length()) {
      Position *p = m_positions[i];
      
      if (!OrderSelect(p.m_ticket, SELECT_BY_TICKET)) close(i); // order deleted
      else {
         if (OrderCloseTime() > 0) // already closed
            close(i);
         else // keep searching
            i++;
      }
   }
}

////
//// Logging part
////

void Positions::enableLogging(void) {
   m_logHandleOpen = FileOpen(StringFormat("%s_%s_open.csv", Symbol(), m_positionType), FILE_CSV|FILE_WRITE);
   m_logHandleClosed = FileOpen(StringFormat("%s_%s_closed.csv", Symbol(), m_positionType), FILE_CSV|FILE_WRITE);
   if (m_logHandleOpen > 0  && m_logHandleClosed > 0) {
      // header
      FileWrite(m_logHandleOpen, "Position", "EntryType", "Ticket", "Timestamp", "Size",
                "SignalPrice", "MarketPrice", "Target", "StopLoss", "RiskRewardRatio", "Reason");
      FileWrite(m_logHandleClosed, "Position", "EntryType", "OutType", "Ticket", "EntryTS", "ExitTS", "Size",
                "EntryPrice", "ExitPrice", "Target", "StopLoss", "RiskRewardRatio", "PL", "EntryReason", "ExitReason");
   } else
      PrintFormat("[Trader] error while enabling log: %d", GetLastError());
}

double Positions::calculateRiskRewardRatio(Position *p) {
   double riskRewardRatio = 0;
   if (p.m_target > 0 && p.m_stopLoss > 0) { // risk & reward ratio wont work on dynamic orders
      riskRewardRatio = MathAbs(p.m_target - p.m_price) / MathAbs(p.m_stopLoss - p.m_price);
   }
   
   return riskRewardRatio;
}

void Positions::logOpenPosition(Position *p) {
   double riskRewardRatio = calculateRiskRewardRatio(p);
   if (m_logHandleOpen > 0)
      FileWrite(m_logHandleOpen, m_positionType, p.m_entryType, p.m_ticket, p.m_open, p.m_size, 
                p.m_signalPrice, p.m_marketPrice, p.m_target, p.m_stopLoss, riskRewardRatio, p.m_reason);
}

void Positions::logClosedPosition(Position *p, string exitReason) {
   double riskRewardRatio = calculateRiskRewardRatio(p);
   double profitOrLoss = 0;
   if (m_positionType == "LONG") profitOrLoss = p.m_closePrice - p.m_price;
   else if (m_positionType == "SHORT") profitOrLoss = p.m_price - p.m_closePrice;
   if (m_logHandleClosed > 0) {
      string orderType = StringSubstr(EnumToString((ENUM_ORDER_TYPE) p.m_orderType), 11);
      FileWrite(m_logHandleClosed, m_positionType, p.m_entryType, orderType, p.m_ticket, 
                p.m_open, p.m_closeTS, p.m_size, p.m_price, p.m_closePrice, p.m_target, p.m_stopLoss, 
                riskRewardRatio, profitOrLoss, p.m_reason, exitReason);
   }
}


#endif
