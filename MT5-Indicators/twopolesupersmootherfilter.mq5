//+------------------------------------------------------------------+
//|                                   TwoPoleSuperSmootherFilter.mq5 |
//|                                                                  |
//| Two-Pole Super Smoother Filter                                   |
//|                                                                  |
//| Algorithm taken from book                                        |
//|     "Cybernetics Analysis for Stock and Futures"                 |
//| by John F. Ehlers                                                |
//|                                                                  |
//|                                              contact@mqlsoft.com |
//|                                          http://www.mqlsoft.com/ |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Coded by Witold Wozniak"
//---- link to the website of the author
#property link      "www.mqlsoft.com"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
//---- one buffer is used for calculation and drawing the indicator
#property indicator_buffers 1
//---- only one plot is used
#property indicator_plots   1
//+----------------------------------------------+
//| Indicator drawing parameters                 |
//+----------------------------------------------+
//---- drawing the indicator as a line
#property indicator_type1   DRAW_LINE
//---- violet color is used for the indicator line
#property indicator_color1  Violet
//---- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1  2
//---- displaying the indicator line label
#property indicator_label1  "Two-Pole Super Smoother Filter"
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int CutoffPeriod=15; // Indicator period
input int Shift=0;         // Horizontal shift of the indicator in bars 
//+----------------------------------------------+
//---- declaration of a dynamic array that
//---- will be used as an indicator buffer
double ExtLineBuffer[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of global variables
double coef1,coef2,coef3,coef4;
//+------------------------------------------------------------------+
//|  Getting the average from the price time series                  |
//+------------------------------------------------------------------+   
double Get_Price(const double  &High[],const double  &Low[],int bar)
  {
//----
   return((High[bar]+Low[bar])/2);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=3;

//---- initialization of variables 
   double tempReal= MathArctan(1.0);
   double rad2Deg = 45.0 / tempReal;
   double deg2Rad = 1.0 / rad2Deg;
   double pi = MathArctan(1.0) * 4.0;
   double a1 = MathExp(-MathSqrt(2.0) * pi / CutoffPeriod);
   double b1 = 2 * a1 * MathCos(deg2Rad * MathSqrt(2.0) * 180 / CutoffPeriod);
   coef2 = b1;
   coef3 = -a1 * a1;
   coef1 = 1.0 - coef2 - coef3;

//---- set ExtLineBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//----  shifting horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"Two-Pole Super Smoother Filter(",CutoffPeriod," ,",Shift,")");
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
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
   if(rates_total<min_rates_total) return(0);

//---- declarations of local variables 
   int first,bar;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
        first=0;                                         // starting index for calculation of all bars
   else first=prev_calculated-1;                         // starting index for calculation of new bars

//---- main indicator calculation loop
   for(bar=first; bar<rates_total; bar++)
     {
      //---- formula for the filter calculation    
      if(bar>min_rates_total) 
           ExtLineBuffer[bar]=coef1 * Get_Price(high,low,bar) + coef2 * ExtLineBuffer[bar-1] + coef3 * ExtLineBuffer[bar-2];
      else ExtLineBuffer[bar]=Get_Price(high,low,bar);
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
