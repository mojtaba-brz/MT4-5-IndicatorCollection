//+------------------------------------------------------------------+
//|                                               FractalTrendID.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_minimum -1.1
#property indicator_maximum 1.1
#property indicator_buffers 3
#property indicator_plots   3
//--- plot UpTrend
#property indicator_label1  "Trend"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDeepSkyBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- indicator buffers
static double         TrendBuffer[];
static double         DownFractalBuffer[];
static double         UpFractalBuffer[];
static double f_up, f_down;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
   SetIndexBuffer(0,TrendBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DownFractalBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,UpFractalBuffer,INDICATOR_CALCULATIONS);

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
      return 0;

   for(int i = MathMax(prev_calculated-1, 0); i<rates_total; i++)
     {
      if(i<5)
        {
         continue;
        }
         if(high[i-2] >= high[i+1-2] && high[i-2] >= high[i+2-2] && high[i-2] >= high[i-1-2] && high[i-2] >= high[i-2-2])
            f_up = high[i-2];
         else
            f_up = EMPTY_VALUE;
         if(low[i-2] <= low[i+1-2] && low[i-2] <= low[i+2-2] && low[i-2] <= low[i-1-2] && low[i-2] <= low[i-2-2])
            f_down = low[i-2];
         else
            f_down = EMPTY_VALUE;


      if(f_up == EMPTY_VALUE)
        {
         if(i > 0)
            UpFractalBuffer[i] = UpFractalBuffer[i-1];
         else
            UpFractalBuffer[i] = EMPTY_VALUE;
        }
      else
         UpFractalBuffer[i] = f_up;

      if(f_down == EMPTY_VALUE)
        {
         if(i > 0)
            DownFractalBuffer[i] = DownFractalBuffer[i-1];
         else
            DownFractalBuffer[i] = EMPTY_VALUE;
        }
      else
         DownFractalBuffer[i] = f_down;

      TrendBuffer[i] = 0.;
      if(UpFractalBuffer[i] != EMPTY_VALUE && UpFractalBuffer[i] < high[i])
         TrendBuffer[i] += 1.;
      if(DownFractalBuffer[i] != EMPTY_VALUE && DownFractalBuffer[i] > low[i])
         TrendBuffer[i] -= 1.;
      if(TrendBuffer[i] == 0. && i>0)
         TrendBuffer[i] = TrendBuffer[i-1];
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
