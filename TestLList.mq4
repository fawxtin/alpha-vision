//+------------------------------------------------------------------+
//|                                                    TestLList.mq4 |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

#include <Positions\LList.mqh>

void OnStart() {
   LList<int> *integerList = new LList<int>();
   
   integerList.add(30);
   integerList.add(15);
   integerList.add(90);
   integerList.add(99);
   integerList.add(12);
   integerList.print();
   Print("-----");
   integerList.drop(0);
   integerList.print();
   Print("-----");
   integerList.drop(2);
   integerList.print();
   
   delete integerList;   
}
