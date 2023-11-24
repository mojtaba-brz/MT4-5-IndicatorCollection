//+------------------------------------------------------------------+
//|                                      ATR_Based_EMA_variant_1.mq4 |
//|                                             nielsindicatorcoding |
//|                                   nielsindicatorcoding@gmail.com |
//+------------------------------------------------------------------+
#property copyright "nielsindicatorcoding"
#property link      "mailto:nielsindicatorcoding@gmail.com"
#property version   "1.00"
#property description "ATR based EMA variant 1"
#property description "Based on te actual ATR% value an EMA equivalent value is calculated for each candle close"
#property description "Higher ATR means slower EMA"

#property strict
#property indicator_chart_window
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Yellow
#property indicator_label1  "EMA_ATR_var1"
#property indicator_label2  "EMA_Equivalent"


double SIGNAL[];
double EMA_Equivalent[];
input double     EMA_Fastest=14.0;
input double     multiplier = 300.0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {

   SetIndexStyle(0, DRAW_LINE,STYLE_SOLID,5);
   SetIndexBuffer(0, SIGNAL);
   SetIndexBuffer(1, EMA_Equivalent);
      
   return(0);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int i;
   double ema_multiplier;
   double int_atr;
   double int_signal;
   int_atr = High[Bars-1]/Low[Bars-1];
   int_signal = Close[Bars-1];
     
   for(i=Bars-1; i>=0; i--)
   {
      int_atr = int_atr*13/14+(High[i]/Low[i])/14;
      EMA_Equivalent[i] =(((int_atr-1)*multiplier+1)*EMA_Fastest);
      ema_multiplier = 2/(EMA_Equivalent[i]+1);
      int_signal = int_signal*(1-ema_multiplier)+Close[i]*ema_multiplier;
      SIGNAL[i] = int_signal;
   }

   return(0);
  }
  