//+------------------------------------------------------------------+
//|                                                         alma.mq4 |
//|                                              converted by mladen |
//|                                               mladenfx@gmail.com |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""


#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1 DeepSkyBlue  
#property indicator_width1 2

//
//
//
//
//

extern int    AlmaPeriod = 14;
extern double AlmaSigma  = 6.0;
extern double AlmaSample = 0.5;
extern int    AlmaPrice  = PRICE_CLOSE;

//
//
//
//
//

double Alma[];
double coeffs[];


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int init()
{
   SetIndexBuffer(0,Alma);
   
   //
   //
   //
   //
   //
   
      AlmaPeriod = MathMax(AlmaPeriod,1);
      ArrayResize(coeffs,AlmaPeriod);
      
         double m = MathFloor(AlmaSample * (AlmaPeriod - 1.0));
         double s = AlmaPeriod/AlmaSigma;
         for (int i=0; i<AlmaPeriod; i++)
            coeffs[i] = MathExp(-((i-m)*(i-m))/(2.0*s*s));

   //
   //
   //
   //
   //
         
   IndicatorShortName("Alma ("+AlmaPeriod+","+DoubleToStr(AlmaSigma,2)+","+DoubleToStr(AlmaSample,2)+")");
   return(0);
}
 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int start()
{
   int counted_bars = IndicatorCounted();
   int i,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
           limit=MathMin(Bars-counted_bars,Bars-1);

   //
   //
   //
   //
   //
   
	for(i = limit; i >= 0; i--)
   {
      double sum=0;
      double div=0;
      for (int k=0; k<AlmaPeriod && (k+i)<Bars; k++)
      {
         sum += coeffs[k]*iMA(NULL,0,1,0,MODE_SMA,AlmaPrice,i+k);
         div += coeffs[k];
      }
      
      //
      //
      //
      //
      //
      
      if (div!=0)
            Alma[i] = sum/div;
      else  Alma[i] = 0;       
   }
   return(0);
}