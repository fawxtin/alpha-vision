//+------------------------------------------------------------------+
//|                                                      Hull MA.mq4 |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property version   "hma.001"
#property strict

#include <Trends\trends.mqh>
#include <Trends\HMA.mqh>


input int MAPeriod1 = 20;
input int MAPeriod2 = 50;
input int MAPeriod3 = 200;

string gMajorTrend;
string gMinorTrend;
double gBasePrice;

// Support and Resistence levels
int counter = 0;
double gTopPrice1;
double gTopPrice2;
double gBottomPrice1;
double gBottomPrice2;

int OnInit() {
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   //EventKillTimer();
   Alert("Bye Bye!");
}

void OnTick() {
   /*
    * Calculate current trend and support/resistence levels
    */
   if ((counter % 10) == 0){
      if (Bars < 100) {
         Alert("Too few bars.");
         return;
      }
      int majorTrend = CalculateHMATrend(MAPeriod2, MAPeriod3);
      int minorTrend = CalculateHMATrend(MAPeriod1, MAPeriod2);
   
      setupTrend(gMajorTrend, majorTrend, "Major");
      setupTrend(gMinorTrend, minorTrend, "Minor");
   }
   counter++;
}