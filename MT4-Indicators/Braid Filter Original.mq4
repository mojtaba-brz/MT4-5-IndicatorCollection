//compile//
//+------------------------------------------------------------------+
//|                                       EMA_58_Crossover_Alert.mq4 |
//|                         Copyright © 2006, Robert Hill            |
//|                                                                  |
//| Written Robert Hill for use with AIME for the EMA 5/8 cross to   |
//| draw arrows and popup alert or send email                        |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2006, Robert Hill"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 Aqua
#property indicator_color2 Red
#property indicator_color3 Yellow
#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1

input int config_param = 10;
int                Period1         = (int)MathRound(5 * config_param/10);
int                Period2         = (int)MathRound(8 * config_param/10);
int                Period3         = (int)MathRound(20 * config_param/10);

extern int PipsMinSepPercent = 50;
extern int MaType = MODE_EMA;

double CrossUp[];
double CrossDown[];
double Filter[];
double Ema5[];
double Ema8[];
double Ema20[];

double   myPoint;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   IndicatorBuffers(6);
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID);
   SetIndexBuffer(0, CrossUp);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID);
   SetIndexBuffer(1, CrossDown);
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID);
   SetIndexBuffer(2, Filter);
   SetIndexBuffer(3, Ema5);
   SetIndexBuffer(4, Ema8);
   SetIndexBuffer(5, Ema20);
   myPoint = SetPoint(Symbol());
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
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
int start() {
   int limit, i;
   double fastMAnow, slowMAnow;
   
   int counted_bars=IndicatorCounted();
//---- check for possible errors
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;

   limit=Bars-counted_bars;
   
   ArraySetAsSeries(Ema5, true);
   ArraySetAsSeries(Ema8, true);
   ArraySetAsSeries(Ema20, true);
   
   for(i = 0; i <= limit; i++) {
   
     if (MaType < 4)
     {
      fastMAnow = iMA(NULL, 0, Period1, 0, MaType, PRICE_CLOSE, i);
      slowMAnow = iMA(NULL, 0, Period2, 0, MaType, PRICE_OPEN, i);
      Ema20[i] = iMA(NULL, 0, Period3, 0, MaType, PRICE_CLOSE, i);
      }
      else
      {
      fastMAnow = iLsma(Period1, PRICE_CLOSE, i);
      slowMAnow = iLsma(Period2, PRICE_OPEN, i);
      Ema20[i] = iLsma(Period3, PRICE_CLOSE, i);
      }
      
      Ema5[i] = fastMAnow;
      Ema8[i] = slowMAnow;
      CrossUp[i] = 0;
      CrossDown[i] = 0;
      Filter[i] = iATR(NULL, 0, 14, i)*PipsMinSepPercent/100.0;
      
      if ((fastMAnow > slowMAnow))
      {
        CrossUp[i] = GetDif(i);
      }
      else if ((fastMAnow < slowMAnow))
      {
        CrossDown[i] = GetDif(i);
      }
   }
   return(0);
}

double iLsma(int LSMAPeriod,double myPrice, int shift)
{
   double wt;
   
   double ma1=iMA(NULL,0,LSMAPeriod,0,MODE_SMA ,myPrice,shift);
   double ma2=iMA(NULL,0,LSMAPeriod,0,MODE_LWMA,myPrice,shift);
   wt = MathFloor((3.0*ma2-2.0*ma1)/myPoint)*myPoint;
   return(wt);
}  


double GetDif(int pos)
{

  double ma5 = Ema5[pos];
  double ma8 = Ema8[pos];
  double ma20 = Ema20[pos];
  double max, min;
  
  double dif;
  
  max = MathMax(ma5, ma8);
  max = MathMax(max, ma20);
  min = MathMin(ma5, ma8);
  min = MathMin( min, ma20);
  
  dif = max - min;
  return(dif);
}

double SetPoint(string mySymbol)
{
   double mPoint, myDigits;
   
   myDigits = MarketInfo (mySymbol, MODE_DIGITS);
   if (myDigits < 4)
      mPoint = 0.01;
   else
      mPoint = 0.0001;
   
   return(mPoint);
}
