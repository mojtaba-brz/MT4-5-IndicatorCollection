// More information about this indicator can be found at:
// https://fxcodebase.com/code/viewtopic.php?f=38&t=73153


//+------------------------------------------------------------------------------------------------+
//|                                                            Copyright © 2023, Gehtsoft USA LLC  | 
//|                                                                         http://fxcodebase.com  |
//+------------------------------------------------------------------------------------------------+
//|                                                                   Developed by : Mario Jemic   |                    
//|                                                                       mario.jemic@gmail.com    |
//|                                                        https://AppliedMachineLearning.systems  |
//|                                                                       https://mario-jemic.com/ |
//+------------------------------------------------------------------------------------------------+

//+------------------------------------------------------------------------------------------------+
//|                                           Our work would not be possible without your support. |
//+------------------------------------------------------------------------------------------------+
//|                                                               Paypal: https://goo.gl/9Rj74e    |
//|                                                             Patreon :  https://goo.gl/GdXWeN   |  
//+------------------------------------------------------------------------------------------------+


#property copyright "Copyright © 2023, Gehtsoft USA LLC"
#property link      "http://fxcodebase.com"
#property version "1.0"
 

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 Yellow
//---- indicator parameters
extern int period = 14;

extern bool histogram_mode = true;
//---- indicator buffers
double ma[];
double temp[];
//----

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   IndicatorBuffers(4);
   if(histogram_mode)
      SetIndexStyle(0, DRAW_HISTOGRAM);
   else
      SetIndexStyle(0, DRAW_LINE);
   SetIndexBuffer(0, ma);
   SetIndexStyle(1, DRAW_NONE);
   SetIndexBuffer(1, ema1);
   SetIndexStyle(2, DRAW_NONE);
   SetIndexBuffer(2, ema2); //---- initialization done
   SetIndexStyle(3, DRAW_NONE);
   SetIndexBuffer(3, temp);
   SetLevelStyle(STYLE_DOT, 1);
   SetLevelValue(0, 0);
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double prevhigh;
double prevlow;
double ema1[];
double ema2[];
int start()
  {
   int limit = Bars - IndicatorCounted() - 1;
//----
   for(int i = limit; i >= 0; i--)
     {
      //Detrended Ehlers Leading Indicator
      //by AlexF
      /*
      //period=14
      if high>high[1] then
      prevhigh=high
      endif
      if low<low[1] then
      prevlow=low
      endif
      price=(prevhigh+prevlow)/2

      if barindex>2 then
      alpha=2/(period+1)
      else
      alpha=.67
      endif
      alpha2=alpha/2

      ema1=(alpha*price)+((1-alpha)*Ema1)
      ema2=((alpha2)*price)+((1-alpha2)*Ema2)
      dsp=ema1-ema2
      temp=(alpha*dsp)+((1-alpha)*temp)
      deli=dsp-temp

      return deli as "DELI",  0 as "ZERO"
      */
      //Detrended Ehlers Leading Indicator
      //by AlexF
      //
      if(iHigh(NULL, 0, i) > iHigh(NULL, 0, i + 1))
         prevhigh = iHigh(NULL, 0, i);
      if(iLow(NULL, 0, i) < iLow(NULL, 0, i + 1))
         prevlow = iLow(NULL, 0, i);
      double price = (prevhigh + prevlow) / 2.0;
      double alpha;
      //if (i > 2)
      alpha = 2.0 / double(period + 1);
      /*else
       alpha=.67;*/
      double alpha2 = alpha / 2.0;
      ema1[i] = (alpha * price) + ((1 - alpha) * ema1[i + 1]);
      ema2[i] = ((alpha2) * price) + ((1 - alpha2) * ema2[i + 1]);
      double dsp = ema1[i] - ema2[i];
      temp[i] = (alpha * dsp) + ((1 - alpha) * temp[i + 1]);
      ma[i] = dsp - temp[i];
     }
   return 0;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------------------------------------+
//|                                                                    We appreciate your support. | 
//+------------------------------------------------------------------------------------------------+
//|                                                               Paypal: https://goo.gl/9Rj74e    |
//|                                                             Patreon :  https://goo.gl/GdXWeN   |  
//+------------------------------------------------------------------------------------------------+
//|                                                                   Developed by : Mario Jemic   |                    
//|                                                                       mario.jemic@gmail.com    |
//|                                                        https://AppliedMachineLearning.systems  |
//|                                                                       https://mario-jemic.com/ |
//+------------------------------------------------------------------------------------------------+

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

