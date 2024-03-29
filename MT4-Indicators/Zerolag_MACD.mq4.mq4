//+------------------------------------------------------------------+
//|                                                 ZeroLag MACD.mq4 |
//|                                                               RD |
//|                                                 marynarz15@wp.pl |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""

#property indicator_separate_window
#property  indicator_buffers 2
#property indicator_color1 Magenta
#property indicator_color2 Orange
//---- input parameters
input int config_param = 10;
int       FastEMA=(int)MathRound(12 * config_param/10);
int       SlowEMA=(int)MathRound(24 * config_param/10);
int       SignalEMA=(int)MathRound(9 * config_param/10);
//---- buffers
double MACDBuffer[];
double SignalBuffer[];
double FastEMABuffer[];
double SlowEMABuffer[];
double SignalEMABuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   IndicatorBuffers(5);
   SetIndexBuffer(0,MACDBuffer);
   SetIndexBuffer(1,SignalBuffer);
   SetIndexBuffer(2,FastEMABuffer);
   SetIndexBuffer(3,SlowEMABuffer);
   SetIndexBuffer(4,SignalEMABuffer);
   SetIndexStyle(0,DRAW_HISTOGRAM,EMPTY,2);
   SetIndexStyle(1,DRAW_LINE,EMPTY,2);
   SetIndexDrawBegin(0,SlowEMA);
   SetIndexDrawBegin(1,SlowEMA);
   IndicatorShortName("ZeroLag MACD("+FastEMA+","+SlowEMA+","+SignalEMA+")");
   SetIndexLabel(0,"MACD");
   SetIndexLabel(1,"Signal");
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int limit;
   int counted_bars=IndicatorCounted();
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
   double EMA,ZeroLagEMAp,ZeroLagEMAq;
   for(int i=0; i<limit; i++)
      {
         FastEMABuffer[i]=iMA(NULL,0,FastEMA,0,MODE_EMA,PRICE_CLOSE,i);
         SlowEMABuffer[i]=iMA(NULL,0,SlowEMA,0,MODE_EMA,PRICE_CLOSE,i);
      }
   for(i=0; i<limit; i++)
      {
         EMA=iMAOnArray(FastEMABuffer,Bars,FastEMA,0,MODE_EMA,i);
         ZeroLagEMAp=FastEMABuffer[i]+FastEMABuffer[i]-EMA;
         EMA=iMAOnArray(SlowEMABuffer,Bars,SlowEMA,0,MODE_EMA,i);
         ZeroLagEMAq=SlowEMABuffer[i]+SlowEMABuffer[i]-EMA;
         MACDBuffer[i]=ZeroLagEMAp - ZeroLagEMAq;
      }
   for(i=0; i<limit; i++)
         SignalEMABuffer[i]=iMAOnArray(MACDBuffer,Bars,SignalEMA,0,MODE_EMA,i);
   for(i=0; i<limit; i++)
      {
         EMA=iMAOnArray(SignalEMABuffer,Bars,SignalEMA,0,MODE_EMA,i);
         SignalBuffer[i]=SignalEMABuffer[i]+SignalEMABuffer[i]-EMA;
      }
   return(0);
  }
//+------------------------------------------------------------------+