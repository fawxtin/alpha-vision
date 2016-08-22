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


class Trader {
   protected:
      Positions *m_longPositions;
      Positions *m_shortPositions;

   public:
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

void Trader::goLong(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="") {
   if (m_longPositions.lastBar() == Bars || m_longPositions.count() >= MAX_POSITIONS) return; // already traded / full
   //OrderSend
   int vdigits = (int)MarketInfo(Symbol(), MODE_DIGITS);
   double vspread = MarketInfo(Symbol(), MODE_SPREAD) / MathPow(10, vdigits);
   int ticket;
   double price = Ask;
   if (MathAbs(price - signalPrice) < vspread) { // buy market
      PrintFormat("[Trader.goLong/%s] opening At market (%.4f, %.4f => %.4f (%.4f))", reason, price, signalPrice, vspread, MathAbs(signalPrice - price));
      ticket = OrderSend(Symbol(), OP_BUY, LOT_SIZE, price, 3, stopLoss, priceTarget, reason, MAGICMA, 0, clrAliceBlue);
   } else if (signalPrice < price) { // buy limit
      PrintFormat("[Trader.goLong/%s] opening Limit at %f (%.4f)", reason, NormalizeDouble(signalPrice, vdigits), price);
      ticket = OrderSend(Symbol(), OP_BUYLIMIT, LOT_SIZE, NormalizeDouble(signalPrice, vdigits), 3,
                         stopLoss, priceTarget, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
   } else {// buy stop
      PrintFormat("[Trader.goLong/%s] opening Stop at %f (%.4f)", reason, NormalizeDouble(signalPrice, vdigits), price);
      ticket = OrderSend(Symbol(), OP_BUYSTOP, LOT_SIZE, NormalizeDouble(signalPrice, vdigits), 3,
                         stopLoss, priceTarget, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
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

void Trader::goShort(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="") {
   if (m_shortPositions.lastBar() == Bars || m_shortPositions.count() >= MAX_POSITIONS) return; // already traded?
   // short trades
   int vdigits = (int)MarketInfo(Symbol(), MODE_DIGITS);
   double vspread = MarketInfo(Symbol(), MODE_SPREAD) / MathPow(10, vdigits);
   int ticket;
   double price = Bid;
   if (MathAbs(signalPrice - price) < vspread) { // sell market
      PrintFormat("[Trader.goShort/%s] opening At market (%.4f, %.4f => %.4f (%.4f))", reason, price, signalPrice, vspread, MathAbs(signalPrice - price));
      ticket = OrderSend(Symbol(), OP_SELL, LOT_SIZE, price, 3, 0, 0, reason, MAGICMA, 0, clrPink);
   } else if (signalPrice > price) { // sell limit
      PrintFormat("[Trader.goShort/%s] opening Limit at %f (%.4f)", reason, NormalizeDouble(signalPrice, vdigits), price);
      ticket = OrderSend(Symbol(), OP_SELLLIMIT, LOT_SIZE, NormalizeDouble(signalPrice, vdigits), 3,
                         stopLoss, priceTarget, reason, MAGICMA, EXPIRE_NEVER, clrPink);
   } else { // sell stop
      PrintFormat("[Trader.goShort/%s opening Stop at %f (%.4f)", reason, NormalizeDouble(signalPrice, vdigits), price);
      ticket = OrderSend(Symbol(), OP_SELLSTOP, LOT_SIZE, NormalizeDouble(signalPrice, vdigits), 3,
                         stopLoss, priceTarget, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
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

void Trader::closeLongs(string msg="") {
   double price = Bid;
   int oCount = m_longPositions.count();
   PositionValue fullPosition = m_longPositions.meanPositionValue();
   
   if (msg != "") PrintFormat("[Trader.closeLongs] Closing %d longs from: %s", oCount, msg);
   
   // Close pending orders not tracked
   for (int j = 0; j < OrdersTotal(); j++) {
      if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
         if ((OrderSymbol() == Symbol()) && (OrderType() == OP_BUYLIMIT) &&
             (OrderMagicNumber() == MAGICMA)) {
            if (OrderDelete(OrderTicket()))
               PrintFormat("[Trader.closeLongs] Pending long at %.4f closed.", OrderOpenPrice());
            else
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
      } else {
         int check = GetLastError();
         PrintFormat("[Trader.closeLongs.%d/%d] ERROR closing order: %d", i, oCount, check);
      }
   }
   if (oCount > 0) {
      PrintFormat("[Trader.closeLongs] Closed %d orders (size %.2f) / (long MP %.4f -> sell at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, price);
      m_longPositions.clear();
   }
}

void Trader::closeShorts(string msg="") {
   double price = Ask;
   int oCount = m_shortPositions.count();
   PositionValue fullPosition = m_shortPositions.meanPositionValue();
   
   if (msg != "") PrintFormat("[Trader.closeShorts] Closing %d shorts from: %s", oCount, msg);

   // Close pending orders not tracked
   for (int j = 0; j < OrdersTotal(); j++) {
      if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
         if ((OrderSymbol() == Symbol()) && (OrderType() == OP_SELLLIMIT) &&
             (OrderMagicNumber() == MAGICMA)) {
            if (OrderDelete(OrderTicket()))
               PrintFormat("[Trader.closeShorts] Pending short at %.4f closed. (error %d)", OrderOpenPrice(), GetLastError());
         }
      }
   }

   // Close tracked orders
   for (int i = 0; i < oCount; i++) {
      Position *p = m_shortPositions[i];
      if (OrderClose(p.m_ticket, p.m_size, price, 3) == true) {
         PrintFormat("[Trader.closeShorts.%d/%d] Closing order %d (sell price %.4f -> buy price %.4f)", 
                     i, oCount, p.m_ticket, p.m_price, price);
      } else {
         int check = GetLastError();
         PrintFormat("[Trader.closeShorts.%d/%d] ERROR closing order: %d", i, oCount, check);
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
