//+------------------------------------------------------------------+
//|                                                       Trader.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <stdlib.mqh>

#include <Positions\Positions.mqh>


#ifndef __POSITIONS_TRADER__
#define __POSITIONS_TRADER__ true

#define EXPIRE_NEVER D'2018.01.01 23:59:59'   // 60 * 60 * 24 * 7

struct MktT {
   int vdigits;
   double vspread;
};

class Trader {
   protected:
      MktT m_mkt;
      int m_logHandleOpen;
      int m_logHandleClosed;
      Positions *m_longPositions;
      Positions *m_shortPositions;

   public:
      Trader(Positions *longPs, Positions *shortPs) : m_logHandleOpen(0), m_logHandleClosed(0) {
         m_longPositions = longPs;
         m_shortPositions = shortPs;
         m_mkt.vdigits = (int)MarketInfo(Symbol(), MODE_DIGITS);
         m_mkt.vspread = MarketInfo(Symbol(), MODE_SPREAD) / MathPow(10, m_mkt.vdigits);
      }
      
      void ~Trader() {
         delete m_longPositions;
         delete m_shortPositions;
         if (m_logHandleOpen > 0) FileClose(m_logHandleOpen);
         if (m_logHandleClosed > 0) FileClose(m_logHandleClosed);
      }
      
      void enableLogging() {
         m_logHandleOpen = FileOpen(StringFormat("%s_open.csv", Symbol()), FILE_CSV|FILE_WRITE);
         m_logHandleClosed = FileOpen(StringFormat("%s_closed.csv", Symbol()), FILE_CSV|FILE_WRITE);
         if (m_logHandleOpen > 0  && m_logHandleClosed > 0) {
            // header
            FileWrite(m_logHandleOpen, "Position", "OrderType", "Ticket", "Timestamp", "Size",
                                       "SignalPrice", "MarketPrice", "Target", "StopLoss", "RiskRewardRatio", "Reason");
            FileWrite(m_logHandleClosed, "Position", "Ticket", "EntryTS", "ExitTS", "Size",
                                         "EntryPrice", "ExitPrice", "PL", "EntryReason", "ExitReason");
         } else
            PrintFormat("[Trader] error while enabling log: %d", GetLastError());
      }
      
      void logOpenPosition(string posType, string orderType, int ticket, datetime posDate, double size,
                           double signalPrice, double marketPrice, double targetPrice, double stopLoss, string reason) {
         double entry;
         if (orderType == "market") entry = marketPrice;
         else entry = signalPrice;
         
         double riskRewardRatio = 0;
         if (targetPrice > 0 && stopLoss > 0) { // risk & reward ratio wont work on dynamic orders
            riskRewardRatio = MathAbs(targetPrice - entry) / MathAbs(stopLoss - entry);
         }
         if (m_logHandleOpen > 0)
            FileWrite(m_logHandleOpen, posType, orderType, ticket, posDate, size, 
                      signalPrice, marketPrice, targetPrice, stopLoss, riskRewardRatio, reason);
      }
      
      void logClosedPosition(string posType, int ticket, datetime entryDate, datetime exitDate, double size, 
                             double entryPrice, double exitPrice, string entryReason, string exitReason) {
         double profitOrLoss = 0;
         if (posType == "long") profitOrLoss = exitPrice - entryPrice;
         else if (posType == "short") profitOrLoss = entryPrice - exitPrice;
         if (m_logHandleOpen > 0)
            FileWrite(m_logHandleClosed, posType, ticket, entryDate, exitDate, size,
                      entryPrice, exitPrice, profitOrLoss, entryReason, exitReason);
      }
      
      void loadCurrentOrders(bool noMagicMA=false) {
         m_longPositions.loadCurrentOrders(noMagicMA);
         m_shortPositions.loadCurrentOrders(noMagicMA);
      }
            
      // trader executing orders
      void goLong(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="");
      void goShort(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="");
      void closeLongs(string);
      void closeShorts(string);
};


//// Executing Orders
/*
 * Orders shall be executed on timeframe and given a reason.
 * 
 */

void Trader::goLong(double signalPrice, double targetPrice=0, double stopLoss=0, string reason="") {
   if (m_longPositions.lastBar() == Bars || m_longPositions.count() >= MAX_POSITIONS) return; // already traded / full
   //OrderSend
   int ticket;
   double marketPrice = Ask;
   if (MathAbs(marketPrice - signalPrice) < m_mkt.vspread) { // buy market
      PrintFormat("[Trader.goLong/%s] opening At market (%.4f, %.4f)", reason, signalPrice, marketPrice);
      ticket = OrderSend(Symbol(), OP_BUY, LOT_SIZE, marketPrice, 3, stopLoss, targetPrice, reason, MAGICMA, 0, clrAliceBlue);
      logOpenPosition("long", "market", ticket, TimeCurrent(), LOT_SIZE, signalPrice, marketPrice, targetPrice, stopLoss, reason);
   } else if (signalPrice < marketPrice) { // buy limit
      PrintFormat("[Trader.goLong/%s] opening Limit at %.4f", reason, signalPrice);
      ticket = OrderSend(Symbol(), OP_BUYLIMIT, LOT_SIZE, NormalizeDouble(signalPrice, m_mkt.vdigits), 3,
                         stopLoss, targetPrice, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
      logOpenPosition("long", "limit", ticket, TimeCurrent(), LOT_SIZE, signalPrice, marketPrice, targetPrice, stopLoss, reason);
   } else {// buy stop
      PrintFormat("[Trader.goLong/%s] opening Stop at %.4f", reason, signalPrice);
      ticket = OrderSend(Symbol(), OP_BUYSTOP, LOT_SIZE, NormalizeDouble(signalPrice, m_mkt.vdigits), 3,
                         stopLoss, targetPrice, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
      logOpenPosition("long", "stop", ticket, TimeCurrent(), LOT_SIZE, signalPrice, marketPrice, targetPrice, stopLoss, reason);
   }
   
   if (ticket == -1) {
      int check = GetLastError();
      PrintFormat("[Trader.goLong] ERROR opening order: %d / %s", check, ErrorDescription(check));
   } else if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
      m_longPositions.add(new Position(ticket, OrderOpenTime(), OrderLots(),
                                       OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss()));
      m_longPositions.setLastBar(Bars);
   } 
}

void Trader::goShort(double signalPrice, double targetPrice=0, double stopLoss=0, string reason="") {
   if (m_shortPositions.lastBar() == Bars || m_shortPositions.count() >= MAX_POSITIONS) return; // already traded?
   // short trades
   int ticket;
   double marketPrice = Bid;
   if (MathAbs(signalPrice - marketPrice) < m_mkt.vspread) { // sell market
      PrintFormat("[Trader.goShort/%s] opening At market (%.4f, %.4f)", reason, signalPrice, marketPrice);
      ticket = OrderSend(Symbol(), OP_SELL, LOT_SIZE, marketPrice, 3, stopLoss, targetPrice, reason, MAGICMA, 0, clrPink);
      logOpenPosition("short", "market", ticket, TimeCurrent(), LOT_SIZE, signalPrice, marketPrice, targetPrice, stopLoss, reason);
   } else if (signalPrice > marketPrice) { // sell limit
      PrintFormat("[Trader.goShort/%s] opening Limit at %.4f", reason, signalPrice);
      ticket = OrderSend(Symbol(), OP_SELLLIMIT, LOT_SIZE, NormalizeDouble(signalPrice, m_mkt.vdigits), 3,
                         stopLoss, targetPrice, reason, MAGICMA, EXPIRE_NEVER, clrPink);
      logOpenPosition("short", "limit", ticket, TimeCurrent(), LOT_SIZE, signalPrice, marketPrice, targetPrice, stopLoss, reason);
   } else { // sell stop
      PrintFormat("[Trader.goShort/%s opening Stop at %.4f", reason, signalPrice);
      ticket = OrderSend(Symbol(), OP_SELLSTOP, LOT_SIZE, NormalizeDouble(signalPrice, m_mkt.vdigits), 3,
                         stopLoss, targetPrice, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
      logOpenPosition("short", "stop", ticket, TimeCurrent(), LOT_SIZE, signalPrice, marketPrice, targetPrice, stopLoss, reason);
   }
   
   if (ticket == -1) {
      int check = GetLastError();
      PrintFormat("[Trader.goShort] ERROR opening order: %d / %s", check, ErrorDescription(check));
   } else if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
      m_shortPositions.add(new Position(ticket, OrderOpenTime(), OrderLots(),
                                        OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss()));
      m_shortPositions.setLastBar(Bars);
   }
}

void Trader::closeLongs(string reason="") {
   double price = Bid;
   int oCount = m_longPositions.count();
   PositionValue fullPosition = m_longPositions.meanPositionValue();
   
   if (reason != "") PrintFormat("[Trader.closeLongs] Closing %d longs: %s", oCount, reason);
   
   // Close pending orders not tracked
   for (int j = 0; j < OrdersTotal(); j++) {
      if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
         if ((OrderSymbol() == Symbol()) && (OrderType() == OP_BUYLIMIT) &&
             (OrderMagicNumber() == MAGICMA)) {
            if (OrderDelete(OrderTicket())) {
               PrintFormat("[Trader.closeLongs] Pending long at %.4f closed.", OrderOpenPrice());
               logClosedPosition("long", OrderTicket(), OrderOpenTime(), TimeCurrent(), 
                                 OrderLots(), OrderOpenPrice(), OrderOpenPrice(), OrderComment(), StringFormat("%s-pending", reason));
            } else
               PrintFormat("[Trader.closeLongs] Error closing pending long at %.4f closed. (error %d)", OrderOpenPrice(), GetLastError());
         }
      }
   }

   // Close tracked orders
   for (int i = 0; i < oCount; i++) {
      Position *p = m_longPositions[i];

      if (OrderClose(p.m_ticket, p.m_size, price, 3) == true) {
         PrintFormat("[Trader.closeLongs.%d/%d] Closing order %d (buy price %.4f -> sell price %.4f)", 
                     i, oCount, p.m_ticket, p.m_price, price);
      } else
         PrintFormat("[Trader.closeLongs.%d/%d] Order already closed", i, oCount);
      
      if (OrderSelect(p.m_ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
         logClosedPosition("long", p.m_ticket, OrderOpenTime(), OrderCloseTime(), 
                           OrderLots(), OrderOpenPrice(), OrderClosePrice(), OrderComment(), reason);
      }
   }
   
   if (oCount > 0) {
      PrintFormat("[Trader.closeLongs] Closed %d orders (size %.2f) / (long MP %.4f -> sell at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, price);
      m_longPositions.clear();
   }
}

void Trader::closeShorts(string reason="") {
   double price = Ask;
   int oCount = m_shortPositions.count();
   PositionValue fullPosition = m_shortPositions.meanPositionValue();
   
   if (reason != "") PrintFormat("[Trader.closeShorts] Closing %d shorts: %s", oCount, reason);

   // Close pending orders not tracked
   for (int j = 0; j < OrdersTotal(); j++) {
      if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
         if ((OrderSymbol() == Symbol()) && (OrderType() == OP_SELLLIMIT) &&
             (OrderMagicNumber() == MAGICMA)) {
            if (OrderDelete(OrderTicket())) {
               PrintFormat("[Trader.closeShorts] Pending short at %.4f closed. (error %d)", OrderOpenPrice(), GetLastError());
               logClosedPosition("short", OrderTicket(), OrderOpenTime(), TimeCurrent(), 
                                 OrderLots(), OrderOpenPrice(), OrderOpenPrice(), OrderComment(), StringFormat("%s-pending", reason));
            } else
               PrintFormat("[Trader.closeShorts] Error closing pending short at %.4f closed. (error %d)", OrderOpenPrice(), GetLastError());
         }
      }
   }

   // Close tracked orders
   for (int i = 0; i < oCount; i++) {
      Position *p = m_shortPositions[i];

      if (OrderClose(p.m_ticket, p.m_size, price, 3) == true) {
         PrintFormat("[Trader.closeShorts.%d/%d] Closing order %d (sell price %.4f -> buy price %.4f)", 
                     i, oCount, p.m_ticket, p.m_price, price);
      } else
         PrintFormat("[Trader.closeLongs.%d/%d] Order already closed", i, oCount);

      if (OrderSelect(p.m_ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
         logClosedPosition("short", p.m_ticket, OrderOpenTime(), OrderCloseTime(), 
                           OrderLots(), OrderOpenPrice(), OrderClosePrice(), OrderComment(), reason);
      }
   }

   if (oCount > 0) {
      PrintFormat("[Trader.closeShorts] Closed %d orders (size %.2f) / (sell MP %.4f -> cover at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, price);
      m_shortPositions.clear();
   }
}

//void debugPrintSignal() {
//   if (iDebug) {
//      PrintFormat("[AV.CT.HMA] Major Signal (%d -> %s) / Minor signal (%d -> %s) / [last bar %d/current bar %d]",
//                  major.getTrend(), major.simplify(), minor.getTrend(), minor.simplify(), positions.lastBar(), Bars);
//   }
//}



#endif
