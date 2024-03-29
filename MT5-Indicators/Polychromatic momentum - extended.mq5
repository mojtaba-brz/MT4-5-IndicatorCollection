//+------------------------------------------------------------------
#property copyright   "mladen"
#property link        "mladenfx@gmail.com"
#property description "Polychromatic momentum - extended"
//+------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_label1  "Polychromatic momentum"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrSkyBlue,clrDodgerBlue
#property indicator_width1  2
//--- input parameters
input int                inpMomPeriod     = 20;           // Polychromatic momentum period

input int                inpSmoothPeriod  = 5;            // Smoothing period
input ENUM_APPLIED_PRICE inpPrice         =  PRICE_CLOSE; // Price
//--- buffers and global variables declarations
double val[],valc[],prices[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,val,INDICATOR_DATA);
   SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,prices,INDICATOR_CALCULATIONS);
//---
   IndicatorSetString(INDICATOR_SHORTNAME,"Polychromatic momentum - extended ("+(string)inpMomPeriod+","+(string)inpSmoothPeriod+")");
   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator de-initialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
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
   if(Bars(_Symbol,_Period)<rates_total) return(prev_calculated);
   int i=(int)MathMax(prev_calculated-1,1); for(; i<rates_total && !_StopFlag; i++)
     {
      prices[i]=iDsema(getPrice(inpPrice,open,close,high,low,i,rates_total),inpSmoothPeriod,i,rates_total);
      double sumMom = 0;
      double sumWgh = 0;
      for(int k=0; k<inpMomPeriod && (i-k-1)>=0; k++)
        {
         double weight=MathSqrt(k+1);
         sumMom += (prices[i]-prices[i-k-1])/weight;
         sumWgh += weight;
        }
      val[i]  = (sumWgh != 0) ? sumMom/sumWgh : 0;
      valc[i] = (i>0) ?(val[i]>val[i-1]) ? 1 :(val[i]<val[i-1]) ? 2 : valc[i-1]: 0;
     }
   return (i);
  }
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
double workDsema[][2];
#define _ema1 0
#define _ema2 1
//
//---
//
double iDsema(double price,double period,int r,int bars,int instanceNo=0)
  {
   if(period<=1) return(price);
   if(ArrayRange(workDsema,0)!=bars) ArrayResize(workDsema,bars); instanceNo*=2;

//
//
//
//
//

   workDsema[r][_ema1+instanceNo] = price;
   workDsema[r][_ema2+instanceNo] = price;
   double alpha=2.0/(1.0+MathSqrt(period));
   if(r>0)
     {
      workDsema[r][_ema1+instanceNo]=workDsema[r-1][_ema1+instanceNo]+alpha*(price                         -workDsema[r-1][_ema1+instanceNo]);
      workDsema[r][_ema2+instanceNo]=workDsema[r-1][_ema2+instanceNo]+alpha*(workDsema[r][_ema1+instanceNo]-workDsema[r-1][_ema2+instanceNo]); 
     }
   return(workDsema[r][_ema2+instanceNo]);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getPrice(ENUM_APPLIED_PRICE tprice,const double &open[],const double &close[],const double &high[],const double &low[],int i,int _bars)
  {
   switch(tprice)
     {
      case PRICE_CLOSE:     return(close[i]);
      case PRICE_OPEN:      return(open[i]);
      case PRICE_HIGH:      return(high[i]);
      case PRICE_LOW:       return(low[i]);
      case PRICE_MEDIAN:    return((high[i]+low[i])/2.0);
      case PRICE_TYPICAL:   return((high[i]+low[i]+close[i])/3.0);
      case PRICE_WEIGHTED:  return((high[i]+low[i]+close[i]+close[i])/4.0);
     }
   return(0);
  }
//+------------------------------------------------------------------+
