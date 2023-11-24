//+------------------------------------------------------------------+
//|                                    kase permision stochastic.mq4 |
//+------------------------------------------------------------------+
#property copyright ""
#property link		""
#property indicator_separate_window
#property indicator_buffers  2
#property indicator_color1   LimeGreen
#property indicator_color2   Gold
#property indicator_width1   2
#property indicator_style2   STYLE_DOT
#property indicator_minimum  0
#property indicator_maximum  100
#property indicator_level1   25
#property indicator_level2   75
#property indicator_levelcolor DimGray 

//
//
//
//
//

extern int  pstLength     =   9;
extern int  pstX          =   5;
extern int  pstSmooth     =   3;
extern int  smoothPeriod  =  10;

//
//
//
//
//

extern bool  alertsOn        = false;
extern bool  alertsOnCurrent = true;
extern bool  alertsMessage   = true;
extern bool  alertsSound     = false;
extern bool  alertsEmail     = false;

double pstBuffer[];
double pssBuffer[];
double wrkBuffer[][5];
double trend[];

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
   IndicatorBuffers(3);
   SetIndexBuffer(0,pstBuffer); SetIndexLabel(0,"Stochastic");
   SetIndexBuffer(1,pssBuffer); SetIndexLabel(1,"Signal");
   SetIndexBuffer(2,trend);
   
      pstSmooth    = MathMax(pstSmooth,1);
      smoothPeriod = MathMax(smoothPeriod,1);

   IndicatorShortName("Kase permission stochastic smoothed ("+pstLength+","+pstX+")");   
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

#define TripleK   0
#define TripleDF  1
#define TripleDFs 2
#define TripleDS  3
#define TripleDSs 4

//
//
//
//
//

int start()
{
   double alpha = 2.0/(1.0+pstSmooth);
   int lookBackPeriod = pstLength*pstX;
   int counted_bars   = IndicatorCounted();
   int i,r,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-1);
         if (ArrayRange(wrkBuffer,0) != Bars) ArrayResize(wrkBuffer,Bars);
         
   //
   //
   //
   //
   //

   for(i=limit,r=Bars-i-1; i>=0; i--,r++)
   {
      double min = Low [iLowest (NULL,0,MODE_LOW ,lookBackPeriod,i)];
      double max = High[iHighest(NULL,0,MODE_HIGH,lookBackPeriod,i)]-min;
      if (max>0)
            wrkBuffer[r][TripleK] = 100.0*(Close[i]-min)/max;
      else  wrkBuffer[r][TripleK] =   0.0;
      if (i==(Bars-1))
      {
            wrkBuffer[r][TripleDF] = wrkBuffer[r][TripleK];
            wrkBuffer[r][TripleDS] = wrkBuffer[r][TripleK];
            continue;
      }
      wrkBuffer[r][TripleDF] =  wrkBuffer[r-pstX][TripleDF]+alpha*(wrkBuffer[r][TripleK]-wrkBuffer[r-pstX][TripleDF]);
      wrkBuffer[r][TripleDS] = (wrkBuffer[r-pstX][TripleDS]*2.0+wrkBuffer[r][TripleDF])/3.0;
      
      //
      //
      //
      //
      //
      
      wrkBuffer[r][TripleDSs] = iSma(TripleDS ,3,r);
      pssBuffer[i]            = iSmooth(wrkBuffer[r][TripleDSs],smoothPeriod,i,0);
      wrkBuffer[r][TripleDFs] = iSma(TripleDF ,3,r);
      pstBuffer[i]            = iSmooth(wrkBuffer[r][TripleDFs],smoothPeriod,i,1);
      
      //
      //
      //
      //
      //
      
      trend[i] = trend[i+1];
      if (pstBuffer[i] > pssBuffer[i]) trend[i] =  1;
      if (pstBuffer[i] < pssBuffer[i]) trend[i] = -1;
   }
   
   //
   //
   //
   //
   //
   
   if (alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1;
      if (trend[whichBar] != trend[whichBar+1])
         if (trend[whichBar] == 1)
               doAlert("up");
         else  doAlert("down");
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

double iSma(int forDim, int period, int pos)
{
   double sum = wrkBuffer[pos][forDim];
      for(int i=1; i<period; i++) sum += wrkBuffer[pos-i][forDim];
   return(sum/period);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+  
//
//
//
//
//

void doAlert(string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
      if (previousAlert != doWhat || previousTime != Time[0]) {
          previousAlert  = doWhat;
          previousTime   = Time[0];

          //
          //
          //
          //
          //

          message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," Kase PS trend changed to ",doWhat);
             if (alertsMessage) Alert(message);
             if (alertsEmail)   SendMail(StringConcatenate(Symbol(),"Kase PS "),message);
             if (alertsSound)   PlaySound("alert2.wav");
      }
}


//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

double workSmooth[][10];
double iSmooth(double price,double length,int r, int instanceNo=0)
{
   if (ArrayRange(workSmooth,0)!=Bars) ArrayResize(workSmooth,Bars); instanceNo *= 5; r = Bars-r-1;
 	if(r<=2) { workSmooth[r][instanceNo] = price; workSmooth[r][instanceNo+2] = price; workSmooth[r][instanceNo+4] = price; return(price); }
   
   //
   //
   //
   //
   //
   
	double alpha = 0.45*(length-1.0)/(0.45*(length-1.0)+2.0);
   	  workSmooth[r][instanceNo+0] =  price+alpha*(workSmooth[r-1][instanceNo]-price);
	     workSmooth[r][instanceNo+1] = (price - workSmooth[r][instanceNo])*(1-alpha)+alpha*workSmooth[r-1][instanceNo+1];
	     workSmooth[r][instanceNo+2] =  workSmooth[r][instanceNo+0] + workSmooth[r][instanceNo+1];
	     workSmooth[r][instanceNo+3] = (workSmooth[r][instanceNo+2] - workSmooth[r-1][instanceNo+4])*MathPow(1.0-alpha,2) + MathPow(alpha,2)*workSmooth[r-1][instanceNo+3];
	     workSmooth[r][instanceNo+4] =  workSmooth[r][instanceNo+3] + workSmooth[r-1][instanceNo+4]; 
   return(workSmooth[r][instanceNo+4]);
}

