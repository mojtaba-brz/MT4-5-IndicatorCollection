//+------------------------------------------------------------------+
//|                                               ForceOfCandles.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_minimum -1
#property indicator_maximum 1
#property indicator_buffers 4
#property indicator_plots   3
//--- plot Force
#property indicator_label1  "upForce"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "downForce"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#property indicator_label3  "Power"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrWheat
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- indicator buffers
static double         UpForceBuffer[], DownForceBuffer[], Power[];
static double  power_of_sellers, power_of_buyers,
       total_range, Force[],
       alpha;
static int atr_handle;
double get_indicator_value_by_handle(int indicator_handle, int shift = 1, int line_index = 0)
  {
   double temp_buffer[];
   ArraySetAsSeries(temp_buffer, true);
   CopyBuffer(indicator_handle, line_index, shift, 1, temp_buffer);

   return temp_buffer[0];
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   alpha = 0.8;
   SetIndexBuffer(0,UpForceBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DownForceBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,Power,INDICATOR_DATA);
   SetIndexBuffer(3,Force,INDICATOR_CALCULATIONS);
   
   atr_handle = iATR(Symbol(), PERIOD_CURRENT, 14);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(rates_total <= 0)
     {
      return 0;
     }

   for(int i = MathMax(prev_calculated-1, 0); i<rates_total; i++)
     {
      if(i == 0)
        {
         Force[i] = 0.;
         Power[i] = 0;
         continue;
        }
      total_range = get_indicator_value_by_handle(atr_handle);//MathMax(high[i] - low[i], 0.00000000000001);
      power_of_buyers = MathMin(open[i], close[i]) - low[i];
      power_of_sellers = high[i] - MathMax(open[i], close[i]);
      Power[i] = (power_of_buyers - power_of_sellers)/total_range;
      Force[i] = alpha*Force[i-1] + (1-alpha)*(Power[i] - Force[i-1]);
      Force[i] = MathMax(-1, MathMin(1, Force[i]));
      if(Force[i] < 0.)
        {
         DownForceBuffer[i] = Force[i];
         UpForceBuffer[i] = 0.;
        }
      else
        {
         UpForceBuffer[i] = Force[i];
         DownForceBuffer[i] = 0.;
        }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
