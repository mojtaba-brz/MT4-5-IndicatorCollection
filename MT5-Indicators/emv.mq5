//+---------------------------------------------------------------------+
//|                                          Ease of Movement Value.mq5 |
//|                                Copyright © 2011,   Nikolay Kositsin | 
//|                                 Khabarovsk,   farria@mail.redcom.ru | 
//+---------------------------------------------------------------------+
//| For the indicator to work, place the file SmoothAlgorithms.mqh      |
//| in the directory: terminal_data_folder\MQL5\Include                 |
//+---------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2011, Nikolay Kositsin"
//---- link to the website of the author
#property link "farria@mail.redcom.ru"
#property description "Ease of Movement Value"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window
//---- one buffer is used for the indicator calculation and drawing
#property indicator_buffers 1
//---- one plot is used
#property indicator_plots   1
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//---- drawing the indicator 1 as a line
#property indicator_type1   DRAW_LINE
//---- medium slate blue color is used as the color of the bullish line of the indicator
#property indicator_color1  MediumSlateBlue
//---- line of the indicator 1 is a continuous line
#property indicator_style1  STYLE_SOLID
//---- thickness of the indicator 1 line is equal to 1
#property indicator_width1  1
//---- bullish indicator label display
#property indicator_label1  "Ease of Movement Value"
//+-----------------------------------+
//|  CXMA class description           | 
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//---- declaration of the CXMA class variables from the SmoothAlgorithms.mqh file
CXMA XMA1;
//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
enum Applied_price_      // Type of constant
  {
   PRICE_CLOSE_ = 1,     // Close
   PRICE_OPEN_,          // Open
   PRICE_HIGH_,          // High
   PRICE_LOW_,           // Low
   PRICE_MEDIAN_,        // Median Price (HL/2)
   PRICE_TYPICAL_,       // Typical Price (HLC/3)
   PRICE_WEIGHTED_,      // Weighted Close (HLCC/4)
   PRICE_SIMPLE_,        // Simple Price (OC/2)
   PRICE_QUARTER_,       // Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  // TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_   // TrendFollow_2 Price 
  };
/*enum Smooth_Method - enumeration is declared in the SmoothAlgorithms.mqh file
  {
   MODE_SMA_,  // SMA
   MODE_EMA_,  // EMA
   MODE_SMMA_, // SMMA
   MODE_LWMA_, // LWMA
   MODE_JJMA,  // JJMA
   MODE_JurX,  // JurX
   MODE_ParMA, // ParMA
   MODE_T3,    // T3
   MODE_VIDYA, // VIDYA
   MODE_AMA,   // AMA
  }; */
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input Smooth_Method MA_SMethod=MODE_SMA;           // Smoothing method
input int SmLength=14;                             // Smoothing depth                    
input int SmPhase=15;                              // Smoothing parameter
input Applied_price_ IPC=PRICE_QUARTER_;           // Price constant
input ENUM_APPLIED_VOLUME VolumeType=VOLUME_TICK;  // Volume
input int Shift=0;                                 // Horizontal shift of the indicator in bars 
//+----------------------------------------------+
//---- declaration of dynamic arrays that further 
//---- will be used as indicator buffers
double EMVBuffer[];
//---- declaration of the integer variables for the start of data calculation
int StartBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   StartBars=XMA1.GetStartBars(MA_SMethod,SmLength,SmPhase)+1;
//---- setting up alerts for invalid values of external variables
   XMA1.XMALengthCheck("Length", SmLength);
   XMA1.XMAPhaseCheck("Phase", SmPhase, MA_SMethod);
//---- initialization of the vertical shift
//---- set EMVBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,EMVBuffer,INDICATOR_DATA);
//---- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing shift of the beginning of counting of drawing the indicator 1 by StartBars
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"Ease of Movement Value");
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<StartBars) return(0);
//---- declarations of local variables 
   int first,bar;
   double price0,price1,EMV;
   long Volume;
//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      first=1;                                           // starting index for calculation of all bars
     }

   else first=prev_calculated-1;                         // starting index for calculation of new bars
//---- main indicator calculation loop
   for(bar=first; bar<rates_total; bar++)
     {
      //---- call of the PriceSeries function to get the input price 'price_'
      price0=PriceSeries(PRICE_MEDIAN,bar,  open,low,high,close);
      price1=PriceSeries(PRICE_MEDIAN,bar-1,open,low,high,close);

      if(VolumeType==VOLUME_TICK) Volume=long(tick_volume[bar]);
      else                        Volume=long(volume[bar]);
 
      if(Volume!=0) EMV=(price0-price1)*price0/(2*Volume); 
      else          EMV=0; 

      EMVBuffer[bar]= XMA1.XMASeries(1, prev_calculated, rates_total, MA_SMethod, SmPhase, SmLength, EMV, bar, false);
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
