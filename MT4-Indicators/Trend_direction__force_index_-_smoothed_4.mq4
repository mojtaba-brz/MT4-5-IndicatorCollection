//------------------------------------------------------------------
#property copyright   "copyright© mladen"
#property description "Trend direction & force index - smoothed"
#property description "made by mladen"
#property description "for more visit www.forex-station.com"
#property link        "www.forex-station.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers  7
#property indicator_color1   DarkGray
#property indicator_color2   DarkGray
#property indicator_color3   DarkGray
#property indicator_color4   LimeGreen
#property indicator_color5   LimeGreen
#property indicator_color6   Orange
#property indicator_color7   Orange
#property indicator_width3   2
#property indicator_width4   2
#property indicator_width5   2
#property indicator_width6   2
#property indicator_width7   2
#property indicator_maximum  1
#property indicator_minimum -1
#property strict

//
//
//
//
//

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased   // Heiken ashi trend biased price
};
enum enMaTypes
{
   ma_sma,     // Simple moving average - SMA
   ma_ema,     // Exponential moving average - EMA
   ma_mcg,     // McGinley Dynamic
   ma_dsema,   // double smoothed exponential moving average - DSEMA
   ma_dema,    // Double exponential moving average - DEMA
   ma_tema,    // Tripple exponential moving average - TEMA
   ma_smma,    // Smoothed moving average - SMMA
   ma_lwma,    // Linear weighted moving average - LWMA
   ma_pwma,    // Parabolic weighted moving average - PWMA
   ma_alxma,   // Alexander moving average - ALXMA
   ma_vwma,    // Volume weighted moving average - VWMA
   ma_hull,    // Hull moving average
   ma_tma,     // Triangular moving average (TMA)
   ma_b2p,     // Two pole Ehlers Butterworth
   ma_b3p,     // Three pole Ehlers Butterworth
   ma_s2p,     // Two pole Ehlers smoother
   ma_s3p,     // Three pole Ehlers smoother
   ma_sine,    // Sine weighted moving average
   ma_linr,    // Linear regression value
   ma_ilinr,   // Integral of linear regression slope
   ma_ie2,     // IE/2
   ma_nlma,    // Non lag moving average
   ma_zlma,    // Zero lag moving average
   ma_lead,    // Leader exponential moving average
   ma_ssm,     // Super smoother
   ma_smoo     // Smoother
};
enum enTimeFrames
{
   tf_cu  = 0,              // Current time frame
   tf_m1  = PERIOD_M1,      // 1 minute
   tf_m5  = PERIOD_M5,      // 5 minutes
   tf_m15 = PERIOD_M15,     // 15 minutes
   tf_m30 = PERIOD_M30,     // 30 minutes
   tf_h1  = PERIOD_H1,      // 1 hour
   tf_h4  = PERIOD_H4,      // 4 hours
   tf_d1  = PERIOD_D1,      // Daily
   tf_w1  = PERIOD_W1,      // Weekly
   tf_mb1 = PERIOD_MN1      // Monthly
};
enum enInterpolation
{
   int_noint, // No interpolation
   int_line,  // Linear interpolation
   int_quad   // Quadratic interpolation
};

extern int          trendPeriod      = 20;       // Period of calculation

extern enTimeFrames TimeFrame        = tf_cu;    // Time frame to use
extern enMaTypes    trendMethod      = ma_ema;   // Averaging type
extern enPrices     Price            = pr_close; // Price to use
extern double TriggerUp              =  0.05;    // Trigger up level
extern double TriggerDown            = -0.05;    // Trigger dow level
extern double SmoothLength           = 5;        // Smoothing length
extern double SmoothPhase            = 0;        // Smoothing phase
extern bool   ColorChangeOnZeroCross = false;    // Change the color on zero line cross?
extern bool   alertsOn               = False;    // Turn alerts on?
extern bool   alertsOnCurrentBar     = true;     // Alerts on current (stil opened) bar?
extern bool   alertsMessage          = true;     // Alerts should show popup message?
extern bool   alertsSound            = false;    // Alerts should play alert sound?
extern bool   alertsEmail            = false;    // Alerts shouls send email?
extern bool   alertsPush             = false;    // Alerts shouls send push notification?
extern enInterpolation Interpolate   = int_line; // Interpolating method when using multi time frame mode

//
//
//
//
//

double   TrendBuffer[];
double   TrendBufferUa[];
double   TrendBufferUb[];
double   TrendBufferDa[];
double   TrendBufferDb[];
double   TriggBuffera[];
double   TriggBufferb[];
double   trend[];

//
//
//
//
//

string indicatorFileName;
bool   returnBars;

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
   IndicatorBuffers(8);
   SetIndexBuffer(0,TriggBuffera);  SetIndexLabel(0,NULL);
   SetIndexBuffer(1,TriggBufferb);  SetIndexLabel(1,NULL);
   SetIndexBuffer(2,TrendBuffer);   SetIndexLabel(2,"Trend direction & force");
   SetIndexBuffer(3,TrendBufferUa);
   SetIndexBuffer(4,TrendBufferUb);
   SetIndexBuffer(5,TrendBufferDa);
   SetIndexBuffer(6,TrendBufferDb);
   SetIndexBuffer(7,trend);

   //
   //
   //
   //
   //

      indicatorFileName = WindowExpertName();
      returnBars        = (TimeFrame==-99);
      TimeFrame         = MathMax(TimeFrame,_Period);
   IndicatorShortName(timeFrameToString(TimeFrame)+" forex-station trend direction & force ("+(string)trendPeriod+")");
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

double workTrend[][3];
#define _MMA   0
#define _SMMA  1
#define _TDF   2

//
//
//
//
//

int start()
{
   int i,r,limit,counted_bars=IndicatorCounted();
   if(counted_bars < 0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-2); // if(!checkName()) return(0);
         if (returnBars) { TriggBuffera[0] = limit+1; return(0); }
       
   //
   //
   //
   //
   //
   
   if (TimeFrame == Period())
   {
      if (ArrayRange(workTrend,0)!=Bars) ArrayResize(workTrend,Bars);
      if (trend[limit]== 1) CleanPoint(limit,TrendBufferUa,TrendBufferUb);
      if (trend[limit]==-1) CleanPoint(limit,TrendBufferDa,TrendBufferDb);
      
      //
      //
      //
      //
      //
      
      double alpha = 2.0 /(trendPeriod+1.0); 
      for (i=limit, r=Bars-i-1; i>=0; i--, r++)
      {
               workTrend[r][_MMA]  = iCustomMa(trendMethod,getPrice(Price,Open,Close,High,Low,i),trendPeriod,i);
               workTrend[r][_SMMA] = workTrend[r-1][_SMMA]+alpha*(workTrend[r][_MMA]-workTrend[r-1][_SMMA]);
                     double impetmma  = workTrend[r][_MMA]  - workTrend[r-1][_MMA];
                     double impetsmma = workTrend[r][_SMMA] - workTrend[r-1][_SMMA];
                     double divma     = MathAbs(workTrend[r][_MMA]-workTrend[r][_SMMA])/Point;
                     double averimpet = (impetmma+impetsmma)/(2*Point);
               workTrend[r][_TDF]  = divma*MathPow(averimpet,3);

               //
               //
               //
               //
               //
               
               double absValue = absHighest(workTrend,_TDF,trendPeriod*3,r);
               if (absValue > 0)
                     TrendBuffer[i]  = iSmooth(workTrend[r][_TDF]/absValue,SmoothLength,SmoothPhase,i);
               else  TrendBuffer[i]  = iSmooth(                       0.00,SmoothLength,SmoothPhase,i);
                     TriggBuffera[i] = TriggerUp;
                     TriggBufferb[i] = TriggerDown;

               //
               //
               //
               //
               //
               
               TrendBufferUa[i] = EMPTY_VALUE;
               TrendBufferUb[i] = EMPTY_VALUE;
               TrendBufferDa[i] = EMPTY_VALUE;
               TrendBufferDb[i] = EMPTY_VALUE;
                  trend[i] = trend[i+1];
                  if (ColorChangeOnZeroCross)
                  {
                     if (TrendBuffer[i]>0) trend[i] =  1;
                     if (TrendBuffer[i]<0) trend[i] = -1;
                  }
                  else
                  {
                     if (TrendBuffer[i]>TriggBuffera[i])                                   trend[i] =  1;
                     if (TrendBuffer[i]<TriggBufferb[i])                                   trend[i] = -1;
                     if (TrendBuffer[i]>TriggBufferb[i] && TrendBuffer[i]<TriggBuffera[i]) trend[i] =  0;
                  }                     
                  if (trend[i] ==  1) PlotPoint(i,TrendBufferUa,TrendBufferUb,TrendBuffer);
                  if (trend[i] == -1) PlotPoint(i,TrendBufferDa,TrendBufferDb,TrendBuffer);
      }
      manageAlerts();
      return(0);         
   }
      
   //
   //
   //
   //
   //

   limit = (int)MathMax(limit,MathMin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/Period()));
   for(i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,TimeFrame,Time[i]);
        TrendBuffer[i]   = iCustom(NULL,TimeFrame,indicatorFileName,tf_cu,trendPeriod,trendMethod,Price,TriggerUp,TriggerDown,SmoothLength,SmoothPhase,ColorChangeOnZeroCross,alertsOn,alertsOnCurrentBar,alertsMessage,alertsSound,alertsEmail,alertsPush,2,y);
        trend[i]         = iCustom(NULL,TimeFrame,indicatorFileName,tf_cu,trendPeriod,trendMethod,Price,TriggerUp,TriggerDown,SmoothLength,SmoothPhase,ColorChangeOnZeroCross,alertsOn,alertsOnCurrentBar,alertsMessage,alertsSound,alertsEmail,alertsPush,7,y);
        TrendBufferUa[i] = EMPTY_VALUE;
        TrendBufferUb[i] = EMPTY_VALUE;
        TrendBufferDa[i] = EMPTY_VALUE;
        TrendBufferDb[i] = EMPTY_VALUE;
        TriggBuffera[i]  = TriggerUp;
        TriggBufferb[i]  = TriggerDown;

         //
         //
         //
         //
         //
      
         if (Interpolate==int_noint || (i>0 && y==iBarShift(NULL,TimeFrame,Time[i-1]))) continue;
             interpolate(TrendBuffer,TimeFrame,i,Interpolate);
   }
   for(i=limit; i>=0; i--)
   {
      if (trend[i] ==  1) PlotPoint(i,TrendBufferUa,TrendBufferUb,TrendBuffer);
      if (trend[i] == -1) PlotPoint(i,TrendBufferDa,TrendBufferDb,TrendBuffer);
   }
   return(0);
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
//
//
//
//
//

void interpolate(double& target[], int ptimeFrame, int i, int interpolateType)
{
   int bar = iBarShift(NULL,ptimeFrame,Time[i]); double x0 = 0, x1 = 1, x2 = 2, y0 =0, y1 = 0, y2 = 0;
   if (interpolateType==int_quad)
   {
      y0 = target[i];                                                
      y1 = target[(int)MathMin(iBarShift(NULL,0,iTime(NULL,ptimeFrame,bar+0))+1,Bars-1)]; 
      y2 = target[(int)MathMin(iBarShift(NULL,0,iTime(NULL,ptimeFrame,bar+1))+1,Bars-1)]; 
   }      

      //
      //
      //
      //
      //

      datetime time = iTime(NULL,ptimeFrame,bar);
      int n,k;
         for(n = 1; (i+n)<Bars && Time[i+n] >= time; n++) continue;
         for(k = 1; (i+n)<Bars && (i+k)<Bars && k<n; k++)
         if (interpolateType==int_quad)
         {
            double x3 = (double)k/n;
               target[i+k]  = y0*(x3-x1)*(x3-x2)/(-x1*(-x2))+
                              y1*(x3-x0)*(x3-x2)/( x1*(-x1))+
		                        y2*(x3-x0)*(x3-x1)/( x2*( x1));         
         }
         else target[i+k] = target[i] + (target[i+n] - target[i])*k/n;
}


//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//


//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

string methodNames[] = {"SMA","EMA","McGinley Dynamic","Double smoothed EMA","Double EMA","Tripple EMA","Smoothed MA","Linear weighted MA","Parabolic weighted MA","Alexander MA","Volume weghted MA","Hull MA","Triangular MA","Two pole Ehlers Buterworth","Three pole Ehlers Buterworth","Two pole Ehlers smoother","Three pole Ehlers smoother","Sine weighted MA","Linear regression","Intergral of linear regression slope","IE/2","NonLag MA","Zero lag EMA","Leader EMA","Super smoother","Smoothed"};
string getAverageName(int method)
{
   int max = ArraySize(methodNames)-1;
      method=MathMax(MathMin(method,max),0); return(methodNames[method]);
}

//
//
//
//
//

#define _maWorkBufferx1 1
#define _maWorkBufferx2 2
#define _maWorkBufferx3 3
#define _maWorkBufferx5 5

double iCustomMa(int mode, double price, double length, int i, int instanceNo=0)
{
   if (length<=1) return(price);
   int r = Bars-i-1;
   switch (mode)
   {
      case ma_sma   : return(iSma(price,(int)length,r,instanceNo));
      case ma_ema   : return(iEma(price,length,r,instanceNo));
      case ma_dsema : return(iDsema(price,length,r,instanceNo));
      case ma_dema  : return(iDema(price,length,r,instanceNo));
      case ma_tema  : return(iTema(price,length,r,instanceNo));
      case ma_smma  : return(iSmma(price,length,r,instanceNo));
      case ma_lwma  : return(iLwma(price,length,r,instanceNo));
      case ma_pwma  : return(iLwmp(price,length,r,instanceNo));
      case ma_alxma : return(iAlex(price,length,r,instanceNo));
      case ma_vwma  : return(iWwma(price,length,r,instanceNo));
      case ma_hull  : return(iHull(price,length,r,instanceNo));
      case ma_tma   : return(iTma(price,length,r,instanceNo));
      case ma_b2p   : return(iB2po(price,(int)length,r,instanceNo));
      case ma_b3p   : return(iB3po(price,(int)length,r,instanceNo));
      case ma_s2p   : return(iS2po(price,(int)length,r,instanceNo));
      case ma_s3p   : return(iS3po(price,(int)length,r,instanceNo));
      case ma_mcg   : return(iMcGinley(price,length,r,instanceNo));
      case ma_sine  : return(iSineWMA(price,(int)length,r,instanceNo));
      case ma_linr  : return(iLinr(price,length,r,instanceNo));
      case ma_ilinr : return(iIlrs(price,(int)length,r,instanceNo));
      case ma_ie2   : return(iIe2(price,length,r,instanceNo));
      case ma_nlma  : return(iNonLagMa(price,length,r,instanceNo));
      case ma_zlma  : return(iZeroLag(price,length,r,instanceNo));
      case ma_lead  : return(iLeader(price,length,r,instanceNo));
      case ma_ssm   : return(iSsm(price,length,r,instanceNo));
      case ma_smoo  : return(iSmooth(price,(int)length,r,instanceNo));
      default : return(0);
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

double workSma[][_maWorkBufferx2];
double iSma(double price, int period, int r, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= Bars) ArrayResize(workSma,Bars); instanceNo *= 2; int k;

   //
   //
   //
   //
   //
      
   workSma[r][instanceNo] = price;
   if (r>=period)
          workSma[r][instanceNo+1] = workSma[r-1][instanceNo+1]+(workSma[r][instanceNo]-workSma[r-period][instanceNo])/period;
   else { workSma[r][instanceNo+1] = 0; for(k=0; k<period && (r-k)>=0; k++) workSma[r][instanceNo+1] += workSma[r-k][instanceNo];  
          workSma[r][instanceNo+1] /= k; }
   return(workSma[r][instanceNo+1]);
}

//
//
//
//
//

double workEma[][_maWorkBufferx1];
double iEma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= Bars) ArrayResize(workEma,Bars);

   //
   //
   //
   //
   //
      
   workEma[r][instanceNo] = price;
   double alpha = 2.0 / (1.0+period);
   if (r>0)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//
//
//
//
//

double workDsema[][_maWorkBufferx2];
#define _ema1 0
#define _ema2 1

double iDsema(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workDsema,0)!= Bars) ArrayResize(workDsema,Bars); instanceNo*=2;

   //
   //
   //
   //
   //
   
   workDsema[r][_ema1+instanceNo] = price;
   workDsema[r][_ema2+instanceNo] = price;
   double alpha = 2.0 /(1.0+MathSqrt(period));
   if (r>0)
   {
          workDsema[r][_ema1+instanceNo] = workDsema[r-1][_ema1+instanceNo]+alpha*(price                         -workDsema[r-1][_ema1+instanceNo]);
          workDsema[r][_ema2+instanceNo] = workDsema[r-1][_ema2+instanceNo]+alpha*(workDsema[r][_ema1+instanceNo]-workDsema[r-1][_ema2+instanceNo]); }
   return(workDsema[r][_ema2+instanceNo]);
}

//
//
//
//
//

double workDema[][_maWorkBufferx2];
#define _dema1 0
#define _dema2 1

double iDema(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workDema,0)!= Bars) ArrayResize(workDema,Bars); instanceNo*=2;

   //
   //
   //
   //
   //
      
   workDema[r][_dema1+instanceNo] = price;
   workDema[r][_dema2+instanceNo] = price;
   double alpha = 2.0 / (1.0+period);
   if (r>0)
   {
          workDema[r][_dema1+instanceNo] = workDema[r-1][_dema1+instanceNo]+alpha*(price                         -workDema[r-1][_dema1+instanceNo]);
          workDema[r][_dema2+instanceNo] = workDema[r-1][_dema2+instanceNo]+alpha*(workDema[r][_dema1+instanceNo]-workDema[r-1][_dema2+instanceNo]); }
   return(workDema[r][_dema1+instanceNo]*2.0-workDema[r][_dema2+instanceNo]);
}

//
//
//
//
//

double workTema[][_maWorkBufferx3];
#define _tema1 0
#define _tema2 1
#define _tema3 2

double iTema(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workTema,0)!= Bars) ArrayResize(workTema,Bars); instanceNo*=3;

   //
   //
   //
   //
   //
      
   workTema[r][_tema1+instanceNo] = price;
   workTema[r][_tema2+instanceNo] = price;
   workTema[r][_tema3+instanceNo] = price;
   double alpha = 2.0 / (1.0+period);
   if (r>0)
   {
          workTema[r][_tema1+instanceNo] = workTema[r-1][_tema1+instanceNo]+alpha*(price                         -workTema[r-1][_tema1+instanceNo]);
          workTema[r][_tema2+instanceNo] = workTema[r-1][_tema2+instanceNo]+alpha*(workTema[r][_tema1+instanceNo]-workTema[r-1][_tema2+instanceNo]);
          workTema[r][_tema3+instanceNo] = workTema[r-1][_tema3+instanceNo]+alpha*(workTema[r][_tema2+instanceNo]-workTema[r-1][_tema3+instanceNo]); }
   return(workTema[r][_tema3+instanceNo]+3.0*(workTema[r][_tema1+instanceNo]-workTema[r][_tema2+instanceNo]));
}

//
//
//
//
//

double workSmma[][_maWorkBufferx1];
double iSmma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workSmma,0)!= Bars) ArrayResize(workSmma,Bars);

   //
   //
   //
   //
   //

   if (r<period)
         workSmma[r][instanceNo] = price;
   else  workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}

//
//
//
//
//

double workLwma[][_maWorkBufferx1];
double iLwma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLwma,0)!= Bars) ArrayResize(workLwma,Bars);
   
   //
   //
   //
   //
   //
   
   workLwma[r][instanceNo] = price;
      double sumw = period;
      double sum  = period*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k;
                sumw  += weight;
                sum   += weight*workLwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workLwmp[][_maWorkBufferx1];
double iLwmp(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLwmp,0)!= Bars) ArrayResize(workLwmp,Bars);
   
   //
   //
   //
   //
   //
   
   workLwmp[r][instanceNo] = price;
      double sumw = period*period;
      double sum  = sumw*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = (period-k)*(period-k);
                sumw  += weight;
                sum   += weight*workLwmp[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workAlex[][_maWorkBufferx1];
double iAlex(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workAlex,0)!= Bars) ArrayResize(workAlex,Bars);
   if (period<4) return(price);
   
   //
   //
   //
   //
   //

   workAlex[r][instanceNo] = price;
      double sumw = period-2;
      double sum  = sumw*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k-2;
                sumw  += weight;
                sum   += weight*workAlex[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workTma[][_maWorkBufferx1];
double iTma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workTma,0)!= Bars) ArrayResize(workTma,Bars);
   
   //
   //
   //
   //
   //
   
   workTma[r][instanceNo] = price;

      double half = (period+1.0)/2.0;
      double sum  = price;
      double sumw = 1;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = k+1; if (weight > half) weight = period-k;
                sumw  += weight;
                sum   += weight*workTma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workSineWMA[][_maWorkBufferx1];
#define Pi 3.14159265358979323846264338327950288

double iSineWMA(double price, int period, int r, int instanceNo=0)
{
   if (period<1) return(price);
   if (ArrayRange(workSineWMA,0)!= Bars) ArrayResize(workSineWMA,Bars);
   
   //
   //
   //
   //
   //
   
   workSineWMA[r][instanceNo] = price;
      double sum  = 0;
      double sumw = 0;
  
      for(int k=0; k<period && (r-k)>=0; k++)
      { 
         double weight = MathSin(Pi*(k+1.0)/(period+1.0));
                sumw  += weight;
                sum   += weight*workSineWMA[r-k][instanceNo]; 
      }
      return(sum/sumw);
}

//
//
//
//
//

double workWwma[][_maWorkBufferx1];
double iWwma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workWwma,0)!= Bars) ArrayResize(workWwma,Bars);
   
   //
   //
   //
   //
   //
   
   workWwma[r][instanceNo] = price;
      int    i    = Bars-r-1;
      double sumw = (double)Volume[i];
      double sum  = sumw*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = (double)Volume[i+k];
                sumw  += weight;
                sum   += weight*workWwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workHull[][_maWorkBufferx2];
double iHull(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workHull,0)!= Bars) ArrayResize(workHull,Bars);

   //
   //
   //
   //
   //

      int HmaPeriod  = (int)MathMax(period,2);
      int HalfPeriod = (int)MathFloor(HmaPeriod/2);
      int HullPeriod = (int)MathFloor(MathSqrt(HmaPeriod));
      double hma,hmw,weight; instanceNo *= 2;

         workHull[r][instanceNo] = price;

         //
         //
         //
         //
         //
               
         hmw = HalfPeriod; hma = hmw*price; 
            for(int k=1; k<HalfPeriod && (r-k)>=0; k++)
            {
               weight = HalfPeriod-k;
               hmw   += weight;
               hma   += weight*workHull[r-k][instanceNo];  
            }             
            workHull[r][instanceNo+1] = 2.0*hma/hmw;

         hmw = HmaPeriod; hma = hmw*price; 
            for(int k=1; k<period && (r-k)>=0; k++)
            {
               weight = HmaPeriod-k;
               hmw   += weight;
               hma   += weight*workHull[r-k][instanceNo];
            }             
            workHull[r][instanceNo+1] -= hma/hmw;

         //
         //
         //
         //
         //
         
         hmw = HullPeriod; hma = hmw*workHull[r][instanceNo+1];
            for(int k=1; k<HullPeriod && (r-k)>=0; k++)
            {
               weight = HullPeriod-k;
               hmw   += weight;
               hma   += weight*workHull[r-k][1+instanceNo];  
            }
   return(hma/hmw);
}

//
//
//
//
//

double workLinr[][_maWorkBufferx1];
double iLinr(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLinr,0)!= Bars) ArrayResize(workLinr,Bars);

   //
   //
   //
   //
   //
   
      period = MathMax(period,1);
      workLinr[r][instanceNo] = price;
         double lwmw = period; double lwma = lwmw*price;
         double sma  = price;
         for(int k=1; k<period && (r-k)>=0; k++)
         {
            double weight = period-k;
                   lwmw  += weight;
                   lwma  += weight*workLinr[r-k][instanceNo];  
                   sma   +=        workLinr[r-k][instanceNo];
         }             
   
   return(3.0*lwma/lwmw-2.0*sma/period);
}

//
//
//
//
//

double workIe2[][_maWorkBufferx1];
double iIe2(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workIe2,0)!= Bars) ArrayResize(workIe2,Bars); if (r==0) return(price);

   //
   //
   //
   //
   //
   
      period = MathMax(period,1);
      workIe2[r][instanceNo] = price;
         double sumx=0, sumxx=0, sumxy=0, sumy=0;
         for (int k=0; k<period && (r-k)>=0; k++)
         {
            price = workIe2[r-k][instanceNo];
                   sumx  += k;
                   sumxx += k*k;
                   sumxy += k*price;
                   sumy  +=   price;
         }
         double tslope  = (period*sumxy - sumx*sumy)/(sumx*sumx-period*sumxx);
         double average = sumy/period;
   return(((average+tslope)+(sumy+tslope*sumx)/period)/2.0);
}
//
//
//
//
//

double workIlrs[][_maWorkBufferx2];
double iIlrs(double price, int period, int r, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workIlrs,0)!= Bars) ArrayResize(workIlrs,Bars); if (r==0) return(price); instanceNo *= 2; int k;

   //
   //
   //
   //
   //
   
   workIlrs[r][instanceNo] = price;
      
      double sum  =  period*(period-1.0)/2.0;
      double sum2 = (period-1.0)*period*(2.0*period-1.0)/6.0; 
      double sum1 = 0, sumy = 0;
         for (k=0; k<period && (r-k)>=0; k++)
         {
             sum1  += workIlrs[r-k][instanceNo]*k;
             sumy  += workIlrs[r-k][instanceNo];
         }
      double num1  = sum1*period-sum*sumy;
      double num2  = sum*sum-sum2*period;
      double slope = 0;
      if (num2!=0) slope=num1/num2;
         if (r>=period)
                workIlrs[r][instanceNo+1] = workIlrs[r-1][instanceNo+1]+(workIlrs[r][instanceNo]-workIlrs[r-period][instanceNo])/period;
         else { workIlrs[r][instanceNo+1] = 0; for(k=0; k<period && (r-k)>=0; k++) workIlrs[r][instanceNo+1] += workIlrs[r-k][instanceNo]; workIlrs[r][instanceNo+1] /= k; }

   return(workIlrs[r][instanceNo+1]+slope);
}

//
//
//
//
//

double workLeader[][_maWorkBufferx2];
double iLeader(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLeader,0)!= Bars) ArrayResize(workLeader,Bars); instanceNo*=2;

   //
   //
   //
   //
   //
   
      workLeader[r][instanceNo+0] = price;
      workLeader[r][instanceNo+1] = price;
      double alpha = 2.0/(period+1.0);
      if (r>0)
      {
         workLeader[r][instanceNo  ] = workLeader[r-1][instanceNo  ]+alpha*(price                          -workLeader[r-1][instanceNo  ]);
         workLeader[r][instanceNo+1] = workLeader[r-1][instanceNo+1]+alpha*(price-workLeader[r][instanceNo]-workLeader[r-1][instanceNo+1]); }
   return(workLeader[r][instanceNo]+workLeader[r][instanceNo+1]);
}

//
//
//
//
//

double workb2po[][_maWorkBufferx2];
double iB2po(double price, int period, int r, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workb2po,0)!= Bars) ArrayResize(workb2po,Bars); instanceNo*=2; workb2po[r][instanceNo+0] = price;

   //
   //
   //
   //
   //
      
      double a     = MathExp(-1.414*Pi/period);
      double b     = 2*a*MathCos(1.414*Pi/period);
      double coef2 = b;
      double coef3 = -a*a;
      double coef1 = (1-b+a*a)/4;

   if(r>=2) 
          workb2po[r][instanceNo+1] = coef1*(workb2po[r][instanceNo+0] + 2*workb2po[r-1][instanceNo+0] + workb2po[r-2][instanceNo+0]) + coef2*workb2po[r-1][instanceNo+1] + coef3*workb2po[r-2][instanceNo+1];
   else   workb2po[r][instanceNo+1] = workb2po[r][instanceNo+0];
   return(workb2po[r][instanceNo+1]);
}

//
//
//
//
//
//

double workb3po[][_maWorkBufferx2];
double iB3po(double price, int period, int r, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workb3po,0)!= Bars) ArrayResize(workb3po,Bars); instanceNo*=2; workb3po[r][instanceNo+0] = price;

   //
   //
   //
   //
   //

   double a     = MathExp(-Pi/period);
   double b     = 2*a*MathCos(1.738*Pi/period);
   double c     =  a*a;
   double coef2 = b+c;
   double coef3 = -(c+b*c);
   double coef4 = c*c;
   double coef1 = (1-b+c)*(1-c)/8;
   
   if(r>=3) 
          workb3po[r][instanceNo+1] = coef1*(workb3po[r][instanceNo+0] + 3*workb3po[r-1][instanceNo+0] + 3*workb3po[r-2][instanceNo+0]+ workb3po[r-3][instanceNo+0]) + coef2*workb3po[r-1][instanceNo+1] + coef3*workb3po[r-2][instanceNo+1] + coef4*workb3po[r-3][instanceNo+1];
   else   workb3po[r][instanceNo+1] = workb3po[r][instanceNo+0];
   return(workb3po[r][instanceNo+1]);
}
//
//
//
//
//

double works2po[][_maWorkBufferx2];
double iS2po(double price, int period, int r, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(works2po,0)!= Bars) ArrayResize(works2po,Bars); instanceNo*=2; works2po[r][instanceNo+0] = price;

   //
   //
   //
   //
   //
      
      double a     = MathExp(-1.414*Pi/period);
      double b     = 2*a*MathCos(1.414*Pi/period);
      double coef2 = b;
      double coef3 = -a*a;
      double coef1 = 1-coef2-coef3;
   
   if(r>=2) 
          works2po[r][instanceNo+1] = coef1*works2po[r][instanceNo+0] + coef2*works2po[r-1][instanceNo+1] + coef3*works2po[r-2][instanceNo+1];
   else   works2po[r][instanceNo+1] = works2po[r][instanceNo+0];
   return(works2po[r][instanceNo+1]);
}

//
//
//
//
//
//

double works3po[][_maWorkBufferx2];
double iS3po(double price, int period, int r, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(works3po,0)!= Bars) ArrayResize(works3po,Bars); instanceNo*=2; works3po[r][instanceNo+0] = price;

   //
   //
   //
   //
   //

      double a = MathExp(-Pi/period);
      double b = 2*a*MathCos(1.738*Pi/period);
      double c = a*a;
      double coef2 = b+c;
      double coef3 = -(c+b*c);
      double coef4 = c*c;
      double coef1 = 1-coef2-coef3-coef4;
   
   if(r>=3) 
          works3po[r][instanceNo+1] = coef1*works3po[r][instanceNo+0] + coef2*works3po[r-1][instanceNo+1] + coef3*works3po[r-2][instanceNo+1] + coef4*works3po[r-3][instanceNo+1];
   else   works3po[r][instanceNo+1] = works3po[r][instanceNo+0];
   return(works3po[r][instanceNo+1]);
}

//
//
//
//
//

double workbMg[][_maWorkBufferx1];
double iMcGinley(double price, double period, int r, int instanceNo)
{
   if (period<=1) return(price);
   if (ArrayRange(workbMg,0)!= Bars) ArrayResize(workbMg,Bars);
   
   if(r<1 || (r<0 && workbMg[r-1][instanceNo]==0))
          workbMg[r][instanceNo] = price;
   else   workbMg[r][instanceNo] = workbMg[r-1][instanceNo] + (price - workbMg[r-1][instanceNo])/(period*MathPow(price/workbMg[r-1][instanceNo],4)/2.0); 
   return(workbMg[r][instanceNo]);
}

//
//
//
//
//

double workZl[][_maWorkBufferx2];
#define _zprice 0
#define _zlema  1

double iZeroLag(double price, double length, int r, int instanceNo=0)
{
   if (ArrayRange(workZl,0)!=Bars) ArrayResize(workZl,Bars); instanceNo *= 2; workZl[r][_zprice+instanceNo] = price;

   //
   //
   //
   //
   //

   double median = 0;
   double alpha  = 2.0/(1.0+length); 
   int    per    = (int)((length-1.0)/2.0);
   if (r<(per+1))
          workZl[r][_zlema+instanceNo] = price;
   else   
      {
         if ((int)length%2==0)
               median = (workZl[r-per][_zprice+instanceNo]+workZl[r-per-1][_zprice+instanceNo])/2.0;
         else  median =  workZl[r-per][_zprice+instanceNo];
         workZl[r][_zlema+instanceNo] = workZl[r-1][_zlema+instanceNo]+alpha*(2.0*price-median-workZl[r-1][_zlema+instanceNo]);
      }            
   return(workZl[r][_zlema+instanceNo]);
}

//
//
//
//
//

double workSmooth[][_maWorkBufferx5];
double iSmooth(double price,int length,int r, int instanceNo=0)
{
   if (ArrayRange(workSmooth,0)!=Bars) ArrayResize(workSmooth,Bars); instanceNo *= 5;
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

//
//
//
//
//

double workSsm[][_maWorkBufferx2];
#define _tprice  0
#define _ssm     1

double workSsmCoeffs[][4];
#define _speriod 0
#define _sc1    1
#define _sc2    2
#define _sc3    3

double iSsm(double price, double period, int i, int instanceNo)
{
   if (ArrayRange(workSsm,0) !=Bars)                 ArrayResize(workSsm,Bars);
   if (ArrayRange(workSsmCoeffs,0) < (instanceNo+1)) ArrayResize(workSsmCoeffs,instanceNo+1);
   if (workSsmCoeffs[instanceNo][_speriod] != period)
   {
      workSsmCoeffs[instanceNo][_speriod] = period;
      double a1 = MathExp(-1.414*Pi/period);
      double b1 = 2.0*a1*MathCos(1.414*Pi/period);
         workSsmCoeffs[instanceNo][_sc2] = b1;
         workSsmCoeffs[instanceNo][_sc3] = -a1*a1;
         workSsmCoeffs[instanceNo][_sc1] = 1.0 - workSsmCoeffs[instanceNo][_sc2] - workSsmCoeffs[instanceNo][_sc3];
   }

   //
   //
   //
   //
   //

      int s = instanceNo*2; 
      workSsm[i][s+_ssm]    = price;
      workSsm[i][s+_tprice] = price;
      if (i>1)
      {  
          workSsm[i][s+_ssm] = workSsmCoeffs[instanceNo][_sc1]*(workSsm[i][s+_tprice]+workSsm[i-1][s+_tprice])/2.0 + 
                               workSsmCoeffs[instanceNo][_sc2]*workSsm[i-1][s+_ssm]                                + 
                               workSsmCoeffs[instanceNo][_sc3]*workSsm[i-2][s+_ssm]; }
   return(workSsm[i][s+_ssm]);
}

//
//
//
//
//

#define _length  0
#define _len     1
#define _weight  2

double  nlmvalues[_maWorkBufferx1][3];
double  nlmprices[ ][_maWorkBufferx1];
double  nlmalphas[ ][_maWorkBufferx1];

//
//
//
//
//

double iNonLagMa(double price, double length, int r, int instanceNo=0)
{
   if (ArrayRange(nlmprices,0) != Bars)         ArrayResize(nlmprices,Bars);
   if (ArrayRange(nlmvalues,0) <  instanceNo+1) ArrayResize(nlmvalues,instanceNo+1);
                               nlmprices[r][instanceNo]=price;
   if (length<3 || r<3) return(nlmprices[r][instanceNo]);
   
   //
   //
   //
   //
   //
   
   if (nlmvalues[instanceNo][_length] != length  || ArraySize(nlmalphas)==0)
   {
      double Cycle = 4.0;
      double Coeff = 3.0*Pi;
      int    Phase = (int)(length-1);
      
         nlmvalues[instanceNo][_length] = length;
         nlmvalues[instanceNo][_len   ] = length*4 + Phase;  
         nlmvalues[instanceNo][_weight] = 0;

         if (ArrayRange(nlmalphas,0) < nlmvalues[instanceNo][_len]) ArrayResize(nlmalphas,(int)nlmvalues[instanceNo][_len]);
         for (int k=0; k<nlmvalues[instanceNo][_len]; k++)
         {
            double t;
            if (k<=Phase-1) 
                  t = 1.0 * k/(Phase-1);
            else  t = 1.0 + (k-Phase+1)*(2.0*Cycle-1.0)/(Cycle*length-1.0); 
            double beta = MathCos(Pi*t);
            double g = 1.0/(Coeff*t+1); if (t <= 0.5 ) g = 1;
      
            nlmalphas[k][instanceNo]        = g * beta;
            nlmvalues[instanceNo][_weight] += nlmalphas[k][instanceNo];
         }
   }
   
   //
   //
   //
   //
   //
   
   if (nlmvalues[instanceNo][_weight]>0)
   {
      double sum = 0;
           for (int k=0; k < nlmvalues[instanceNo][_len] && (r-k)>=0; k++) sum += nlmalphas[k][instanceNo]*nlmprices[r-k][instanceNo];
           return( sum / nlmvalues[instanceNo][_weight]);
   }
   else return(0);           
}

//
//
//
//
//

void manageAlerts()
{
   if (alertsOn)
   {
      int whichBar = 1; if (alertsOnCurrentBar) whichBar = 0;
      
      //
      //
      //
      //
      //
      
      if (ColorChangeOnZeroCross)
      {
         if (trend[whichBar] != trend[whichBar+1])
         {
            if (trend[whichBar] == 1) doAlert(whichBar," crossed zero line up");
            if (trend[whichBar] ==-1) doAlert(whichBar," crossed zero line down");
         }
      }         
      else
      {
         if (trend[whichBar] != trend[whichBar+1])
         {
            if (trend[whichBar]   == 1                        ) doAlert(whichBar," crossed "+DoubleToStr(TriggerUp  ,2)+" line up");
            if (trend[whichBar]   ==-1                        ) doAlert(whichBar," crossed "+DoubleToStr(TriggerDown,2)+" line down");
            if (trend[whichBar+1] == 1 && trend[whichBar] == 0) doAlert(whichBar," crossed "+DoubleToStr(TriggerUp  ,2)+" line down");
            if (trend[whichBar+1] ==-1 && trend[whichBar] ==-0) doAlert(whichBar," crossed "+DoubleToStr(TriggerDown,2)+" line up");
         }         
      }         
   }
}   

//
//
//
//
//

void doAlert(int forBar, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
      if (previousAlert != doWhat || previousTime != Time[forBar]) {
          previousAlert  = doWhat;
          previousTime   = Time[forBar];

          //
          //
          //
          //
          //

          message =  timeFrameToString(Period())+" "+Symbol()+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+doWhat;
             if (alertsMessage) Alert(message);
             if (alertsEmail)   SendMail(StringConcatenate(Symbol()," trend dirrection & strength "),message);
             if (alertsPush)    SendNotification(message);
             if (alertsSound)   PlaySound("alert2.wav");
      }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

double absHighest(double& array[][], int index, int length, int shift)
{
   double result = 0.00;
   
   for (int i = length-1; i>=0 && (shift-i)>=0; i--)
      if (result < MathAbs(array[shift-i][index]))
          result = MathAbs(array[shift-i][index]);
   return(result);          
}

//-------------------------------------------------------------------
//                                                                  
//-------------------------------------------------------------------
//
//
//
//
//

void CleanPoint(int i,double& first[],double& second[])
{
   if (i>=Bars-3) return;
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i+1] = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}

void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (i>=Bars-2) return;
   if (first[i+1] == EMPTY_VALUE)
      if (first[i+2] == EMPTY_VALUE) 
            { first[i]  = from[i];  first[i+1]  = from[i+1]; second[i] = EMPTY_VALUE; }
      else  { second[i] =  from[i]; second[i+1] = from[i+1]; first[i]  = EMPTY_VALUE; }
   else     { first[i]  = from[i];                           second[i] = EMPTY_VALUE; }
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
//
//
//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

double wrk[][10];

#define bsmax  5
#define bsmin  6
#define volty  7
#define vsum   8
#define avolty 9


//
//
//
//
//

double iSmooth(double price, double length, double phase, int i, int s=0)
{
   if (length <=1) return(price);
   if (ArrayRange(wrk,0) != Bars) ArrayResize(wrk,Bars);
   
   int k,r = Bars-i-1; 
      if (r==0) { for(k=0; k<7; k++) wrk[r][k+s]=price; for(; k<10; k++) wrk[r][k+s]=0; return(price); }

   //
   //
   //
   //
   //
   
      double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
      double pow1   = MathMax(len1-2.0,0.5);
      double del1   = price - wrk[r-1][bsmax+s];
      double del2   = price - wrk[r-1][bsmin+s];
      double div    = 1.0/(10.0+10.0*(MathMin(MathMax(length-10,0),100))/100);
      int    forBar = MathMin(r,10);
	
         wrk[r][volty+s] = 0;
               if(MathAbs(del1) > MathAbs(del2)) wrk[r][volty+s] = MathAbs(del1); 
               if(MathAbs(del1) < MathAbs(del2)) wrk[r][volty+s] = MathAbs(del2); 
         wrk[r][vsum+s] =	wrk[r-1][vsum+s] + (wrk[r][volty+s]-wrk[r-forBar][volty+s])*div;
         
         //
         //
         //
         //
         //
   
         wrk[r][avolty+s] = wrk[r-1][avolty+s]+(2.0/(MathMax(4.0*length,30)+1.0))*(wrk[r][vsum+s]-wrk[r-1][avolty+s]);
            double dVolty = 0;
            if (wrk[r][avolty+s] > 0) dVolty = wrk[r][volty+s]/wrk[r][avolty+s];
	               if (dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
                  if (dVolty < 1)                      dVolty = 1.0;

      //
      //
      //
      //
      //
	        
   	double pow2 = MathPow(dVolty, pow1);
      double len2 = MathSqrt(0.5*(length-1))*len1;
      double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

         if (del1 > 0) wrk[r][bsmax+s] = price; else wrk[r][bsmax+s] = price - Kv*del1;
         if (del2 < 0) wrk[r][bsmin+s] = price; else wrk[r][bsmin+s] = price - Kv*del2;
	
   //
   //
   //
   //
   //
      
      double R     = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
      double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
      double alpha = MathPow(beta,pow2);

         wrk[r][0+s] = price + alpha*(wrk[r-1][0+s]-price);
         wrk[r][1+s] = (price - wrk[r][0+s])*(1-beta) + beta*wrk[r-1][1+s];
         wrk[r][2+s] = (wrk[r][0+s] + R*wrk[r][1+s]);
         wrk[r][3+s] = (wrk[r][2+s] - wrk[r-1][4+s])*MathPow((1-alpha),2) + MathPow(alpha,2)*wrk[r-1][3+s];
         wrk[r][4+s] = (wrk[r-1][4+s] + wrk[r][3+s]); 

   //
   //
   //
   //
   //

   return(wrk[r][4+s]);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//
//

double workHa[][4];
double getPrice(int price, const double& open[], const double& close[], const double& high[], const double& low[], int i, int instanceNo=0)
{
  if (price>=pr_haclose && price<=pr_hatbiased)
   {
      if (ArrayRange(workHa,0)!= Bars) ArrayResize(workHa,Bars);
         int r = Bars-i-1;
         
         //
         //
         //
         //
         //
         
         double haOpen;
         if (r>0)
                haOpen  = (workHa[r-1][instanceNo+2] + workHa[r-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[r][instanceNo+0] = haLow;  workHa[r][instanceNo+1] = haHigh; } 
         else                 { workHa[r][instanceNo+0] = haHigh; workHa[r][instanceNo+1] = haLow;  } 
                                workHa[r][instanceNo+2] = haOpen;
                                workHa[r][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (price)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (price)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:   
               if (close[i]>open[i])
                     return((high[i]+close[i])/2.0);
               else  return((low[i]+close[i])/2.0);        
   }
   return(0);
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
//
//
//
//
//

bool checkName()
{
   string en = WindowExpertName(); StringToLower(en);
   if (en!= "trend direction & force index - smoothed 4")
   {
      Alert("contact Forex-TSD");
      Alert("You are trying to use renamed indicator");
         return(false);
   }
   return(true);
}