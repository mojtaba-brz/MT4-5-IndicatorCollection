//+------------------------------------------------------------------
#property copyright   "© mladen, 2018"
#property link        "mladenfx@gmail.com"
#property version     "1.00"
#property description "Trend direction and force"
//+------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   1
#property indicator_label1  "Trend direction and force"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrSandyBrown,clrDeepSkyBlue
#property indicator_width1  2

//
//--- input parameters
//

input int    inpTrendPeriod  = 20;      // Trend period

input double inpSmooth       = 3;       // Smoothing period
input double    dead_zone    =  0.05;   // Dead-zone

//
//--- buffers and global variables declarations
//

double val[],valc[],levup[],levdn[],mma[],smma[],tdf[],tdfa[],val1[],val_abs[], ª_alpha,ª_alpha2;
int ª_maxPeriod;

//------------------------------------------------------------------
//  Custom indicator initialization function
//------------------------------------------------------------------

int OnInit()
{
   //
   //--- indicator buffers mapping
   //
         SetIndexBuffer(0,val_abs  ,INDICATOR_DATA);
         SetIndexBuffer(1,valc ,INDICATOR_COLOR_INDEX);
         SetIndexBuffer(2,mma  ,INDICATOR_CALCULATIONS);
         SetIndexBuffer(3,smma ,INDICATOR_CALCULATIONS);
         SetIndexBuffer(4,tdf  ,INDICATOR_CALCULATIONS);
         SetIndexBuffer(5,tdfa ,INDICATOR_CALCULATIONS);
         SetIndexBuffer(6,val1 ,INDICATOR_CALCULATIONS);
         SetIndexBuffer(7,val  ,INDICATOR_DATA);
         
         ª_alpha     = 2.0/(1.0+inpTrendPeriod);
         ª_alpha2    = 2.0/(1.0+MathSqrt(inpSmooth>1?inpSmooth:1));
         ª_maxPeriod = 3*inpTrendPeriod;
         
            IndicatorSetInteger(INDICATOR_LEVELS,0);
   //
   //---
   //
   IndicatorSetString(INDICATOR_SHORTNAME,"Trend direction and force ("+(string)inpTrendPeriod+","+(string)(inpSmooth>1?inpSmooth:1)+")");
   return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason) { }

//------------------------------------------------------------------
// Custom indicator iteration function
//------------------------------------------------------------------
//
//---
//

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
   int i = (prev_calculated>0 ? prev_calculated-1 : 0); for (; i<rates_total && !_StopFlag; i++)
   {
         mma[i]  = (i>0) ? mma [i-1]+ª_alpha*(close[i]-mma [i-1]) : close[i];
         smma[i] = (i>0) ? smma[i-1]+ª_alpha*(mma[i]  -smma[i-1]) : mma[i];
            double impetmma  = (i>0) ? mma[i]  - mma[i-1]  : 0;
            double impetsmma = (i>0) ? smma[i] - smma[i-1] : 0;
            double divma     = (mma[i]-smma[i]); if (divma<0) divma = -divma;
            double averimpet = (impetmma+impetsmma)/2.0;
         tdf[i]  = divma*averimpet*averimpet*averimpet;
         tdfa[i] = tdf[i]>0 ? tdf[i] : -tdf[i];

         //
         //---
         //

         int    _start    = i-ª_maxPeriod+1; if (_start<0) _start=0;
         double _absValue = tdfa[ArrayMaximum(tdfa,_start,ª_maxPeriod)];
         double _val1     = (_absValue>0) ? tdf[i]/_absValue : 0;
         val1[i]  = (i>0) ? val1[i-1]+ª_alpha2*(_val1  -val1[i-1]) : 0;
         val[i]   = (i>0) ? val[i-1] +ª_alpha2*(val1[i]-val [i-1]) : 0;
         valc[i]  = (val[i] >dead_zone) ? 2 : (val[i] <-dead_zone) ? 1 : 0;
         val_abs[i] = MathAbs(val[i]) - dead_zone;
   }
   return (i);
}
//+------------------------------------------------------------------+