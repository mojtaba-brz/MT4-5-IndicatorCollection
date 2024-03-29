//+------------------------------------------------------------------+
//|                                                  KF Velocity.mq4 |
//|                              Copyright © 2006, iziogas@mail.com. |
//+------------------------------------------------------------------+
#property copyright "iziogas@mail.com"

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1 Turquoise
//---- indicator parameters
//Mode description
// 0: Close
// 1: Open
// 2: High
// 3: Low
// 4: Median   (H+L/2)
// 5: Typical  (H+L+C/3)
// 6: Weighted (H+L+C+C/4)
extern int fake_input = 1;
int Mode=6;
extern double K=1;
extern double Sharpness=1;
extern int    draw_begin=500;

//---- indicator buffers
double Velocity[];

//----
int ExtCountedBars=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- drawing settings
   SetIndexStyle(0,DRAW_LINE);
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS));

   SetIndexDrawBegin(0,draw_begin);

//---- indicator buffers mapping
   SetIndexBuffer(0,Velocity);

//---- initialization done
   return(0);
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iValue(int mode, int shift){
   switch (mode) {
      case 0:
         return (iClose(NULL,0,shift)); 
      case 1:
         return (iOpen(NULL,0,shift)); 
      case 2:
         return (iHigh(NULL,0,shift)); 
      case 3:
         return (iLow(NULL,0,shift)); 
      case 4:
         return ((iHigh(NULL,0,shift)+iLow(NULL,0,shift))/2); 
      case 5:
         return ((iHigh(NULL,0,shift)+iLow(NULL,0,shift)+iClose(NULL,0,shift))/3); 
      case 6:
         return ((iHigh(NULL,0,shift)+iLow(NULL,0,shift)+iClose(NULL,0,shift)+iClose(NULL,0,shift))/4); 
      default:
         return (0); 
      }   
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
   if(Bars<=draw_begin) return(0);


   int i = 0;

   
   double velocity=0;
   double Distance=0;
   double Error=0;
   double value = iValue(Mode,draw_begin+1);
   
   for(i=draw_begin;i>=0;i--) {
   
      Distance = iValue(Mode,i) - value;
      Error = value + Distance * MathSqrt(Sharpness*K/100);
      velocity = velocity + Distance*K/100;
      value = Error+velocity;
      
      Velocity[i] = velocity;      
   }
//---- done
   return(0);
  }

