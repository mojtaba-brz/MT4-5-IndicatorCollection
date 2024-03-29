// More information about this indicator can be found at:
// https://fxcodebase.com/code/viewtopic.php?f=38&t=71896

//+------------------------------------------------------------------------------------------------+
//|                                                            Copyright © 2022, Gehtsoft USA LLC  | 
//|                                                                         http://fxcodebase.com  |
//+------------------------------------------------------------------------------------------------+
//|                                                              Support our efforts by donating   | 
//|                                                                 Paypal: https://goo.gl/9Rj74e  |
//+------------------------------------------------------------------------------------------------+
//|                                                                   Developed by : Mario Jemic   |                    
//|                                                                       mario.jemic@gmail.com    |
//|                                                        https://AppliedMachineLearning.systems  |
//|                                                             Patreon :  https://goo.gl/GdXWeN   |  
//+------------------------------------------------------------------------------------------------+

//Your donations will allow the service to continue onward.
//+------------------------------------------------------------------------------------------------+
//|BitCoin                    : 15VCJTLaz12Amr7adHSBtL9v8XomURo9RF                                 |  
//|Ethereum                   : 0x8C110cD61538fb6d7A2B47858F0c0AaBd663068D                         |  
//|SOL Address                : 4tJXw7JfwF3KUPSzrTm1CoVq6Xu4hYd1vLk3VF2mjMYh                       |
//|Cardano/ADA                : addr1v868jza77crzdc87khzpppecmhmrg224qyumud6utqf6f4s99fvqv         |  
//|Dogecoin Address           : DBGXP1Nc18ZusSRNsj49oMEYFQgAvgBVA8                                 |
//|SHIB Address               : 0x1817D9ebb000025609Bf5D61E269C64DC84DA735                         |              
//|Binance(ERC20 & BSC only)  : 0xe84751063de8ade7c5fbff5e73f6502f02af4e2c                         | 
//|BitCoin Cash               : 1BEtS465S3Su438Kc58h2sqvVvHK9Mijtg                                 | 
//|LiteCoin                   : LLU8PSY2vsq7B9kRELLZQcKf5nJQrdeqwD                                 |  
//+------------------------------------------------------------------------------------------------+




#property copyright "Copyright © 2022, Gehtsoft USA LLC"
#property link      "http://fxcodebase.com" 

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 clrDodgerBlue

//---- input parameters
extern int config_param = 14;

extern ENUM_TIMEFRAMES TimeFrame          =  PERIOD_M15;  // Time frame
double          alpha              =  config_param/100.;
extern int             maxbars            =  2000;
extern double          ZoneUp             =  0.005;
extern double          ZoneDown           = -0.005;
extern bool            Interpolate        =  true;            // Interpolate in multi time frame mode?


//---- buffers
double soHPF[],count[];
string indicatorFileName;
string MPrefix="XYZ";
#define _mtfCall(_buff,_y) iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,alpha,maxbars,_buff,_y)

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int init()
{
   SetIndexBuffer(0,soHPF);SetIndexStyle(0,DRAW_LINE);
   
   indicatorFileName = WindowExpertName();
   TimeFrame         = fmax(TimeFrame,_Period);  
   
   IndicatorShortName ("2nd order Gaussian high pass filter");
 return(0);
 }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   ClearObjects(); 
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int start()
{
    int i,counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = fmin(Bars-counted_bars,Bars-1); count[0]=limit;
            if (TimeFrame!=_Period)
            {
               limit = (int)fmax(limit,fmin(Bars-1,_mtfCall(1,0)*TimeFrame/_Period));
               for (i=limit;i>=0 && !_StopFlag; i--)
               {
                  int y = iBarShift(NULL,TimeFrame,Time[i]);
                    soHPF [i] = _mtfCall(0,y);
                 
                     //
                     //
                     //
                     //
                     //
                     
                     if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,Time[i-1]))) continue;
                        #define _interpolate(buff) buff[i+k] = buff[i]+(buff[i+n]-buff[i])*k/n
                        int n,k; datetime time = iTime(NULL,TimeFrame,y);
                           for(n = 1; (i+n)<Bars && Time[i+n] >= time; n++) continue;	
                           for(k = 1; k<n && (i+n)<Bars && (i+k)<Bars; k++) _interpolate(soHPF);    
              }
      for (i = limit; i>=0;i--)
      {
        if(soHPF[i]>ZoneUp)
           {
           DrawTape("001",Time[i],ZoneUp,Time[i],ZoneDown,clrGreen);
           }
        else if(soHPF[i]<ZoneDown)
           {
           DrawTape("001",Time[i],ZoneUp,Time[i],ZoneDown,clrRed);
           }
       }
             
     return(0);
      }

      for (i = limit; i>=0;i--)
      {
	      soHPF[i]=MathPow(1-alpha/2,2)*(Close[i] -2*Close[i+1]+Close[i+2])+2*(1-alpha)*soHPF[i+1]-MathPow(1-alpha,2)*soHPF[i+2];
         
        if(soHPF[i]>ZoneUp)
           {
           DrawTape("001",Time[i],ZoneUp,Time[i],ZoneDown,clrGreen);
           }
        else if(soHPF[i]<ZoneDown)
           {
           DrawTape("001",Time[i],ZoneUp,Time[i],ZoneDown,clrRed);
           }
       }
   return(0);
  }

void DrawTape(string label, double Time1,double Price1,double Time2, double Price2, color clr)
 
{
   string ObjName = MPrefix + label;   
   if (ObjectFind(ObjName) == -1)
      {
      ObjectCreate(ObjName, OBJ_RECTANGLE,ChartWindowFind() ,Time1,Price1,Time2,Price2);
      }
   
   ObjectSet(ObjName, OBJPROP_TIME1, Time1);
   ObjectSet(ObjName, OBJPROP_PRICE1, Price1);
   ObjectSet(ObjName, OBJPROP_TIME2, Time2);
   ObjectSet(ObjName, OBJPROP_PRICE2, Price2);
   ObjectSet(ObjName, OBJPROP_COLOR, clr);
  
}  

//+------------------------------------------------------------------+
//| ClearObjects function                                            |
//+------------------------------------------------------------------+
void ClearObjects() 
{ 
  for(int i=0;i<ObjectsTotal();i++) 
  if(StringFind(ObjectName(i),MPrefix)==0) { ObjectDelete(ObjectName(i)); i--; } 
}
