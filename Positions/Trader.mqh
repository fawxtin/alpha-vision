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
      Positions *m_longPositions;
      Positions *m_shortPositions;

   public:
      Trader(Positions *longPs, Positions *shortPs) {
         m_longPositions = longPs;
         m_shortPositions = shortPs;
         m_mkt.vdigits = (int)MarketInfo(Symbol(), MODE_DIGITS);
         m_mkt.vspread = MarketInfo(Symbol(), MODE_SPREAD) / MathPow(10, m_mkt.vdigits);
      }
      
      void ~Trader() {
         delete m_longPositions;
         delete m_shortPositions;
      }
      
      void loadCurrentOrders(bool noMagicMA=false) {
         m_longPositions.loadCurrentOrders(noMagicMA);
         m_shortPositions.loadCurrentOrders(noMagicMA);
      }
      
      void cleanOrders(bool noMagicMA=false) {
         m_longPositions.cleanOrders();
         m_shortPositions.cleanOrders();
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
   signalPrice = NormalizeDouble(signalPrice, m_mkt.vdigits);
   
   string orderType = "market";
   if (MathAbs(marketPrice - signalPrice) < m_mkt.vspread) { // buy market
      PrintFormat("[Trader.goLong/%s] opening At market (%.4f, %.4f)", reason, signalPrice, marketPrice);
      ticket = OrderSend(Symbol(), OP_BUY, LOT_SIZE, marketPrice, 3, stopLoss, targetPrice, reason, MAGICMA, 0, clrAliceBlue);
   } else if (signalPrice < marketPrice) { // buy limit
      PrintFormat("[Trader.goLong/%s] opening Limit at %.4f", reason, signalPrice);
      ticket = OrderSend(Symbol(), OP_BUYLIMIT, LOT_SIZE, signalPrice, 3,
                         stopLoss, targetPrice, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
      orderType = "limit";
   } else {// buy stop
      PrintFormat("[Trader.goLong/%s] opening Stop at %.4f", reason, signalPrice);
      ticket = OrderSend(Symbol(), OP_BUYSTOP, LOT_SIZE, signalPrice, 3,
                         stopLoss, targetPrice, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
      orderType = "stop";
   }
   
   if (ticket == -1) {
      int check = GetLastError();
      Alert(StringFormat("[Trader.goLong] ERROR opening order: %d / %s", check, ErrorDescription(check)));
   } else {
      m_longPositions.add(new Position(ticket, orderType, marketPrice, signalPrice));
      m_longPositions.setLastBar(Bars);
   } 
}

void Trader::goShort(double signalPrice, double targetPrice=0, double stopLoss=0, string reason="") {
   if (m_shortPositions.lastBar() == Bars || m_shortPositions.count() >= MAX_POSITIONS) return; // already traded?
   // short trades
   int ticket;
   double marketPrice = Bid;
   signalPrice = NormalizeDouble(signalPrice, m_mkt.vdigits);
   
   string orderType = "market";
   if (MathAbs(signalPrice - marketPrice) < m_mkt.vspread) { // sell market
      PrintFormat("[Trader.goShort/%s] opening At market (%.4f, %.4f)", reason, signalPrice, marketPrice);
      ticket = OrderSend(Symbol(), OP_SELL, LOT_SIZE, marketPrice, 3, stopLoss, targetPrice, reason, MAGICMA, 0, clrPink);
   } else if (signalPrice > marketPrice) { // sell limit
      PrintFormat("[Trader.goShort/%s] opening Limit at %.4f", reason, signalPrice);
      orderType = "limit";
      ticket = OrderSend(Symbol(), OP_SELLLIMIT, LOT_SIZE, signalPrice, 3,
                         stopLoss, targetPrice, reason, MAGICMA, EXPIRE_NEVER, clrPink);
   } else { // sell stop
      PrintFormat("[Trader.goShort/%s opening Stop at %.4f", reason, signalPrice);
      orderType = "stop";
      ticket = OrderSend(Symbol(), OP_SELLSTOP, LOT_SIZE, signalPrice, 3,
                         stopLoss, targetPrice, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
   }
   
   if (ticket == -1) {
      int check = GetLastError();
      Alert(StringFormat("[Trader.goShort] ERROR opening order: %d / %s", check, ErrorDescription(check)));
   } else {
      m_shortPositions.add(new Position(ticket, orderType, marketPrice, signalPrice));
      m_shortPositions.setLastBar(Bars);
   }
}

void Trader::closeLongs(string reason="") {
   double closePrice = Bid;
   int oCount = m_longPositions.count();
   PositionValue fullPosition = m_longPositions.meanPositionValue();
   
   // Close pending orders not tracked
   //for (int j = 0; j < OrdersTotal(); j++) {
   //   if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
   //      if ((OrderSymbol() == Symbol()) && (OrderType() == OP_BUYLIMIT) &&
   //          (OrderMagicNumber() == MAGICMA)) {
   //         if (OrderDelete(OrderTicket())) {
   //            PrintFormat("[Trader.closeLongs] Pending long at %.4f closed.", OrderOpenPrice());
   //            logClosedPosition("long", OrderTicket(), OrderOpenTime(), TimeCurrent(), 
   //                              OrderLots(), OrderOpenPrice(), OrderOpenPrice(), OrderComment(), StringFormat("%s-pending", reason));
   //         } else
   //            PrintFormat("[Trader.closeLongs] Error closing pending long at %.4f closed. (error %d)", OrderOpenPrice(), GetLastError());
   //      }
   //   }
   //}

   /// Close tracked orders
   if (reason != "") PrintFormat("[Trader.closeLongs] Closing %d longs: %s", oCount, reason);
   if (oCount > 0) 
      PrintFormat("[Trader.closeLongs] Closing %d orders (size %.2f) / (long MP %.4f -> sell at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, closePrice);

   while (m_longPositions.count() > 0) {
      m_longPositions.close(0, closePrice, reason);
   }   
}

void Trader::closeShorts(string reason="") {
   double closePrice = Ask;
   int oCount = m_shortPositions.count();
   PositionValue fullPosition = m_shortPositions.meanPositionValue();
   
   // Close pending orders not tracked
   //for (int j = 0; j < OrdersTotal(); j++) {
   //   if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
   //      if ((OrderSymbol() == Symbol()) && (OrderType() == OP_SELLLIMIT) &&
   //          (OrderMagicNumber() == MAGICMA)) {
   //         if (OrderDelete(OrderTicket())) {
   //            PrintFormat("[Trader.closeShorts] Pending short at %.4f closed. (error %d)", OrderOpenPrice(), GetLastError());
   //            logClosedPosition("short", OrderTicket(), OrderOpenTime(), TimeCurrent(), 
   //                              OrderLots(), OrderOpenPrice(), OrderOpenPrice(), OrderComment(), StringFormat("%s-pending", reason));
   //         } else
   //            PrintFormat("[Trader.closeShorts] Error closing pending short at %.4f closed. (error %d)", OrderOpenPrice(), GetLastError());
   //      }
   //   }
   //}

   if (reason != "") PrintFormat("[Trader.closeShorts] Closing %d shorts: %s", oCount, reason);
   if (oCount > 0)
      PrintFormat("[Trader.closeShorts] Closed %d orders (size %.2f) / (sell MP %.4f -> cover at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, closePrice);
   
   while (m_shortPositions.count() > 0) {
      m_shortPositions.close(0, closePrice, reason);
   }
}

//void debugPrintSignal() {
//   if (iDebug) {
//      PrintFormat("[AV.CT.HMA] Major Signal (%d -> %s) / Minor signal (%d -> %s) / [last bar %d/current bar %d]",
//                  major.getTrend(), major.simplify(), minor.getTrend(), minor.simplify(), positions.lastBar(), Bars);
//   }
//}



#endif
