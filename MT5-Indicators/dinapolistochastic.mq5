//+------------------------------------------------------------------+ 
//|                                           DiNapoliStochastic.mq5 | 
//|                                      Copyright � 2010, LenIFCHIK |
//|                                                                  |
//+------------------------------------------------------------------+
//---- copyright
#property copyright "Copyright � 2010, LenIFCHIK"
#property link      ""
//---- version
#property version   "1.00"
//---- plot indicator in separate window
#property indicator_separate_window
//---- two buffers
#property indicator_buffers 2
//---- two plots
#property indicator_plots   2
//+----------------------------------------------+
//| Stochastic plot settings                     |
//+----------------------------------------------+
//---- draw as a line
#property indicator_type1   DRAW_LINE
//---- draw color 
#property indicator_color1  clrDarkOrange
//---- line style
#property indicator_style1  STYLE_SOLID
//---- line width
#property indicator_width1  1
//---- label
#property indicator_label1  "Stochastic"
//+----------------------------------------------+
//| Signal plot settings                         |
//+----------------------------------------------+
//---- draw as line
#property indicator_type2   DRAW_LINE
//---- draw color
#property indicator_color2  clrBlueViolet
//---- line style
#property indicator_style2  STYLE_SOLID
//---- line width
#property indicator_width2  1
//---- label
#property indicator_label2  "Signal"
//+----------------------------------------------+
//| Horizontal levels                            |
//+----------------------------------------------+
#property indicator_level3 70.0
#property indicator_level2 50.0
#property indicator_level1 30.0
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//|  constants                                   |
//+----------------------------------------------+
#define RESET 0       // reset
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint FastK=8;    // Period of fast %K line

input uint SlowK=3;    // Period of slow %K line
input uint SlowD=3;    // Period of slow %D line
input int Shift=0;     // Shift (in bars)
//+----------------------------------------------+
//---- declaration of dynamic arrays, which will be used
//---- as indicator buffers
double StoBuffer[];
double SigBuffer[];
//---- declaration of integer type variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- set min rates
   min_rates_total=int(FastK);

//---- set StoBuffer[] as indicator buffer
   SetIndexBuffer(0,StoBuffer,INDICATOR_DATA);
//---- set shift (Shift)
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- set plot draw begin (min_rates_total)
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- set empty values
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- set indexing as timeseries
   ArraySetAsSeries(StoBuffer,true);

//---- set SignalBuffer[] as indicator buffer
   SetIndexBuffer(1,SigBuffer,INDICATOR_DATA);
//---- set shift (Shift)
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- set plot draw begin (min_rates_total)
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- set empty values
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- set indexing as timeseries
   ArraySetAsSeries(SigBuffer,true);

//---- prepare indicator short name
   string shortname;
   StringConcatenate(shortname,"DiNapoliStochastic(",FastK,", ",SlowK,", ",SlowD,", ",Shift,")");
//---- set indicator short name
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- set precision
   IndicatorSetInteger(INDICATOR_DIGITS,2);

   return(0);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // total rates
                const int prev_calculated,// bars, calculated at last tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // high values
                const double& low[],      // low values
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- check amount of bars
   if(rates_total<min_rates_total) return(RESET);

//---- double variables
   double HH,LL,Range,Res;
//---- integer variables
   int limit;

//---- calculation of limit (starting bar index)
   if(prev_calculated>rates_total || prev_calculated<=0)// first start checking
     {
      limit=rates_total-min_rates_total-1; // starting index for all bars
      StoBuffer[limit+1]=50.0;
      SigBuffer[limit+1]=50.0;
     }
   else limit=rates_total-prev_calculated;  // starting index for new bars

//---- set indexing as timeseries
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//---- main caluclation loop
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      HH=high[ArrayMaximum(high,bar,FastK)];
      LL=low [ArrayMinimum(low, bar,FastK)];
      Range=MathMax(HH-LL,1*_Point);
      Res=100*(close[bar]-LL)/Range;
      StoBuffer[bar]=StoBuffer[bar+1]+(Res-StoBuffer[bar+1])/SlowK;            //stochastic line
      SigBuffer[bar]=SigBuffer[bar+1]+(StoBuffer[bar]-SigBuffer[bar+1])/SlowD; //signal line
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
