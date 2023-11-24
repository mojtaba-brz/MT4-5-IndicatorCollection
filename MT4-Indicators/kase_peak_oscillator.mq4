//+------------------------------------------------------------------+
//|                                                    kase peak.mq4 |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"

#property indicator_separate_window
#property indicator_buffers  5
#property indicator_color1   DimGray
#property indicator_color2   DimGray
#property indicator_color3   Magenta
#property indicator_color4   DeepSkyBlue
#property indicator_color5   Magenta
#property indicator_width3   2
#property indicator_width4   2
#property indicator_width5   2
#property indicator_level1   0
#property indicator_levelcolor DimGray 

//
//
//
//
//

extern double kpoDeviations  = 2.0;
extern int    kpoShortCycle  = 8;
extern int    kpoLongCycle   = 65;
extern double kpoSensitivity = 40; 
extern bool   allPeaksMode   = false;

//
//
//
//
//

double kphBuffer[];
double kpoBuffer[];
double kpdBuffer[];
double kpmBuffer[];
double kppBuffer[];
double wrkBuffer[][6];

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
   SetIndexBuffer(0,kphBuffer); SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(1,kpoBuffer); SetIndexLabel(1,NULL);
   SetIndexBuffer(2,kpdBuffer);
   SetIndexBuffer(3,kpmBuffer);
   SetIndexBuffer(4,kppBuffer); SetIndexStyle(4,DRAW_HISTOGRAM);
   
   IndicatorShortName("Kase peak oscillator ("+DoubleToStr(kpoDeviations,2)+","+kpoShortCycle+","+kpoLongCycle+","+DoubleToStr(kpoSensitivity,2)+")");   
   return(0);
}
int deinit() { return(0); }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

#define ccLog 0
#define ccDev 1
#define x1    2
#define xs    3
#define xp    4
#define xpAbs 5

//
//
//
//
//

int start()
{
   int counted_bars=IndicatorCounted();
   int i,r,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-kpoLongCycle);
         if (ArrayRange(wrkBuffer,0) != Bars) ArrayResize(wrkBuffer,Bars);
         
   //
   //
   //
   //
   //

   for(i=limit,r=Bars-i-1; i>=0; i--,r++)
   {
      wrkBuffer[r][x1]    = wrkBuffer[r-1][x1];
      wrkBuffer[r][xs]    = wrkBuffer[r-1][xs];
      wrkBuffer[r][ccLog] = MathLog(Close[i]/Close[i+1]);
      wrkBuffer[r][ccDev] = iDeviation(ccLog,9,r);

      //
      //
      //
      //
      //
      
      double avg = iSma(ccDev,30,r);
         if (avg>0)
         {
            double max1 = 0;
            double maxs = 0;
               for (int k=kpoShortCycle; k<kpoLongCycle; k++)
               {
                  max1 = MathMax(MathLog(High[i]/Low[i+k])/MathSqrt(k),max1);
                  maxs = MathMax(MathLog(High[i+k]/Low[i])/MathSqrt(k),maxs);
               }                  
            wrkBuffer[r][x1] = max1/avg;
            wrkBuffer[r][xs] = maxs/avg;
         }
         wrkBuffer[r][xp]    = kpoSensitivity*(iSma(x1,3,r)-iSma(xs,3,r));
         wrkBuffer[r][xpAbs] = MathAbs(wrkBuffer[r][xp]);

         //
         //
         //
         //
         //

         kppBuffer[i+1] = EMPTY_VALUE;      
         kpoBuffer[i]   = wrkBuffer[r][xp];
         kphBuffer[i]   = wrkBuffer[r][xp];

            double tmpVal = iSma(xpAbs,50,r)+kpoDeviations*(iDeviation(xpAbs,50,r));
            double maxVal = MathMax(90.0,tmpVal);
            double minVal = MathMin(90.0,tmpVal);
      
         if (kpoBuffer[i] > 0) { kpdBuffer[i] =  maxVal; kpmBuffer[i] =  minVal; }
         else                  { kpdBuffer[i] = -maxVal; kpmBuffer[i] = -minVal; }
      
      //
      //
      //
      //
      //

      if (!allPeaksMode)
      {         
         if (kpoBuffer[i+1]>0 && kpoBuffer[i+1]>kpoBuffer[i] && kpoBuffer[i+1]>=kpoBuffer[i+2] && kpoBuffer[i+1]>= maxVal) kppBuffer[i+1] = kpoBuffer[i+1];
         if (kpoBuffer[i+1]<0 && kpoBuffer[i+1]<kpoBuffer[i] && kpoBuffer[i+1]<=kpoBuffer[i+2] && kpoBuffer[i+1]<=-maxVal) kppBuffer[i+1] = kpoBuffer[i+1];
      }
      else
      {
         if (kpoBuffer[i+1]>0 && kpoBuffer[i+1]>kpoBuffer[i] && kpoBuffer[i+1]>=kpoBuffer[i+2]) kppBuffer[i+1] = kpoBuffer[i+1];
         if (kpoBuffer[i+1]<0 && kpoBuffer[i+1]<kpoBuffer[i] && kpoBuffer[i+1]<=kpoBuffer[i+2]) kppBuffer[i+1] = kpoBuffer[i+1];
      }         
   }
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

double iDeviation(int forDim, int period, int pos)
{
   double dMA  = iSma(forDim,period,pos);
   double dSum = 0;
      for(int i=0; i<period; i++,pos--) dSum += (wrkBuffer[pos][forDim]-dMA)*(wrkBuffer[pos][forDim]-dMA);
   return(MathSqrt(dSum/period));
}

//
//
//
//
//

double iSma(int forDim, int period, int pos)
{
   double sum = wrkBuffer[pos][forDim];
      for(int i=1; i<period; i++) sum += wrkBuffer[pos-i][forDim];
   return(sum/period);
}