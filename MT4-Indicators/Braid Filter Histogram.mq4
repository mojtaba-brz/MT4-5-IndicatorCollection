//+----------------------------------------------------------------------------+
//|                                                           Braid_Filter.mq4 |
//| Braid Filter indicator of Robert Hill stocks and commodities magazine 2006 |
//| MT4 code by Max Michael 2021                                               |
//+----------------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers   4
#property indicator_color1    clrGreen
#property indicator_width1    4 
#property indicator_color2    clrRed
#property indicator_width2    4
#property indicator_color3    clrGray
#property indicator_width3    4
#property indicator_color4    clrDodgerBlue
#property indicator_width4    2
#property strict

//
//
//
input int config_param = 10;
int                MaPeriod1         = (int)MathRound(3 * config_param/10);
int                MaPeriod2         = (int)MathRound(7 * config_param/10);
int                MaPeriod3         = (int)MathRound(14 * config_param/10);

input int                AtrPeriod         = 14;
input double             PipsMinSepPercent = 40;
input ENUM_MA_METHOD     ModeMA            = MODE_SMMA;

double UpH[],DnH[],NuH[],trend[],fil[];

//
//
//

int OnInit()
{
   IndicatorBuffers(5);
   SetIndexBuffer(0,UpH,INDICATOR_DATA); SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(1,DnH,INDICATOR_DATA); SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexBuffer(2,NuH,INDICATOR_DATA); SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexBuffer(3,fil,INDICATOR_DATA); SetIndexStyle(3,DRAW_LINE);
   SetIndexBuffer(4,trend);
return(INIT_SUCCEEDED);
}

int  OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int i=rates_total-prev_calculated+1; if (i>=rates_total) i=rates_total-1;
   
   //
   //
   //
   
   for (; i>=0 && !_StopFlag; i--)
   {
      double ma1 = iMA(NULL,0,MaPeriod1,0,ModeMA,PRICE_CLOSE,i);
      double ma2 = iMA(NULL,0,MaPeriod2,0,ModeMA,PRICE_OPEN, i);
      double ma3 = iMA(NULL,0,MaPeriod3,0,ModeMA,PRICE_CLOSE,i);
      double max = fmax(fmax(ma1,ma2),ma3);
      double min = fmin(fmin(ma1,ma2),ma3);
      double dif = max - min;
      double atr = iATR(NULL,0,AtrPeriod*2-1,i+1); //period*2-1 = wilders smoothing
      fil[i]   = atr * PipsMinSepPercent/100;
      trend[i] = (i<rates_total-1) ? (ma1>ma2 && dif>fil[i]) ? 1 : (ma2>ma1 && dif>fil[i]) ? -1 : (dif<fil[i]) ? 0 : trend[i+1] : 0;  
      UpH[i]  = (trend[i] == 1) ? dif : EMPTY_VALUE;
      DnH[i]  = (trend[i] ==-1) ? dif : EMPTY_VALUE;   
      NuH[i]  = (trend[i] == 0) ? dif : EMPTY_VALUE;   
   }
return(rates_total);
}
