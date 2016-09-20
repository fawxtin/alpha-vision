//+------------------------------------------------------------------+
//|                                                StochasticRSI.mq4 |
//|                                                                  |
//| Stochastic RSI                                                   |
//|                                                                  |
//| Algorithm taken from book                                        |
//|     "Cybernetics Analysis for Stock and Futures"                 |
//| by John F. Ehlers                                                |
//|                                                                  |
//|                                              contact@mqlsoft.com |
//|                                          http://www.mqlsoft.com/ |
//+------------------------------------------------------------------+
#property copyright "Coded by Witold Wozniak (www.mqlsoft.com)"
#property link      "http://www.mqlsoft.com"
#property version "2.0"
#property description "The algorithm was taken from the book "
#property description "\"Cybernetics Analysis for Stock and Futures\" "
#property description "by John F. Ehlers"
#property strict

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 clrRed
#property indicator_color2 clrBlue

#property indicator_level1 0
#property indicator_minimum -1
#property indicator_maximum 1

double StocRSI[];
double Trigger[];
double Value3[];

input int RSILength = 8;
input int StocLength = 8;
input int WMALength = 8;
int buffers = 0;
int drawBegin = 8;

int init() {
    drawBegin = MathMax(MathMax(RSILength, StocLength), WMALength);
    IndicatorBuffers(3);
    initBuffer(StocRSI, "Stochastic RSI", DRAW_LINE);
    initBuffer(Trigger, "Trigger", DRAW_LINE);
    initBuffer(Value3);
    IndicatorShortName("Stochastic RSI [" + IntegerToString(RSILength) + ", " + IntegerToString(StocLength) + ", " + IntegerToString(WMALength) + "]");
    return (0);
}

int start() {
    if (Bars <= drawBegin) return (0);
    int countedBars = IndicatorCounted();
    if (countedBars < 0) return (-1);
    if (countedBars > 0) countedBars--;
    int s, limit = MathMin(Bars - countedBars - 1, Bars - drawBegin);
    for (s = limit; s >= 0; s--) {
        double rsi = iRSI(NULL, 0, RSILength, PRICE_CLOSE, s);
        double hh = rsi, ll = rsi;
        for (int i = 0; i < StocLength; i++) {
            double tmp = iRSI(NULL, 0, RSILength, PRICE_CLOSE, s + i);
            hh = MathMax(hh, tmp);
            ll = MathMin(ll, tmp);
        }
        double Value1 = rsi - ll;
        double Value2 = hh - ll;
        Value3[s] = 0.0;
        if (Value2 != 0.0) {
            Value3[s] = Value1 / Value2;
        }        
    }
    for (s = limit - 1; s >= 0; s--) {
        StocRSI[s] = 2.0 * (iMAOnArray(Value3, 0, WMALength, 0, MODE_LWMA, s) - 0.5);
        Trigger[s] = StocRSI[s + 1];
    }
    return (0);   
}

void initBuffer(double& array[], string label = "", int type = DRAW_NONE, int arrow = 0, int style = EMPTY, int width = EMPTY, color clr = CLR_NONE) {
    SetIndexBuffer(buffers, array);
    SetIndexLabel(buffers, label);
    SetIndexEmptyValue(buffers, EMPTY_VALUE);
    SetIndexDrawBegin(buffers, drawBegin);
    SetIndexShift(buffers, 0);
    SetIndexStyle(buffers, type, style, width);
    SetIndexArrow(buffers, arrow);
    buffers++;
}