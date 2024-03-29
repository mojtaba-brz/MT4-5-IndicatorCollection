//---------------------------------------------------------------------------------------------------------------------
#property copyright   "© mladen, 2022"
#property link        "mladenfx@gmail.com"
//---------------------------------------------------------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "SmoothStep"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrDodgerBlue,clrCoral
#property indicator_width1  2
#property indicator_level1  0.2
#property indicator_level2  0.8
#property strict

//
//
//

input int             inpPeriod  = 32;        // Period

   enum enPrices
         {
            pr_close,      // Close
            pr_open,       // Open
            pr_high,       // High
            pr_low,        // Low
            pr_median,     // Median
            pr_typical,    // Typical
            pr_weighted,   // Weighted
            pr_lowhigh,    // Low/High/Close
         };
input enPrices         inpPrice   = pr_close; // Price         

//
//
//

double val[],valc[];
struct sGlobalStruct
{
   int period;
};
sGlobalStruct global;

//---------------------------------------------------------------------------------------------------------------------
//                                                                  
//---------------------------------------------------------------------------------------------------------------------
//
//
//

int OnInit()
{
   SetIndexBuffer(0,val ,INDICATOR_DATA);
   SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);
   
      //
      //
      //

      global.period  = MathMax(inpPeriod,1);
   IndicatorSetString(INDICATOR_SHORTNAME,StringFormat("Smooth step (%i)",global.period));
   return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason) { return;}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//

int OnCalculate (const int       rates_total,
                 const int       prev_calculated,
                 const datetime& time[],
                 const double&   open[],
                 const double&   high[],
                 const double&   low[],
                 const double&   close[],
                 const long&     tick_volume[],
                 const long&     volume[],
                 const int&      spread[] )
{
   int limit = (prev_calculated>0) ? prev_calculated-1 : 0;
      
   //
   //
   //

         static double m_lows[];  
         static int    m_lowsSize  = -1; 
                   if (m_lowsSize <rates_total) m_lowsSize = ArrayResize(m_lows ,rates_total+500,2000);
         static double m_highs[]; 
         static int    m_highsSize = -1; 
                   if (m_highsSize<rates_total) m_highsSize = ArrayResize(m_highs,rates_total+500,2000);
         struct sWorkStruct   
            {
                  int    prevBar;
                  double prevmin;
                  double prevmax;
            };
         static sWorkStruct m_work[];
         static int         m_workSize= -1;
                        if (m_workSize<=rates_total) m_workSize = ArrayResize(m_work,rates_total+500,2000);  
      
      //
      //
      //
      
      for(int i=limit; i<rates_total; i++)
         {
            double _price  = close[i];
            double _priceh = close[i];
            double _pricel = close[i];
            
            //
            //
            //
            
               switch (inpPrice)
                  {
                     case pr_close    : _price  = _priceh = _pricel = close[i]; break;
                     case pr_open     : _price  = _priceh = _pricel = open[i];  break;
                     case pr_high     : _price  = _priceh = _pricel = high[i];  break;
                     case pr_low      : _price  = _priceh = _pricel = low[i];   break;
                     case pr_median   : _price  = _priceh = _pricel = (high[i]+low[i])/2.0; break;
                     case pr_typical  : _price  = _priceh = _pricel = (high[i]+low[i]+close[i])/3.0; break;
                     case pr_weighted : _price  = _priceh = _pricel = (high[i]+low[i]+close[i]*2.0)/4.0; ; break;
                     case pr_lowhigh  : _price  = close[i]; 
                                        _priceh = high[i]; 
                                        _pricel = low[i]; 
                                        break;
                  }
                  m_lows[i]  = _pricel;      
                  m_highs[i] = _priceh;      

                  //
                  //
                  //
      
                  if (m_work[i].prevBar!=i)
                     {
                        m_work[i  ].prevBar = i;
                        m_work[i+1].prevBar =-1;
      
                        if (i>0 && global.period>1)
                              {
                                 int _minMaxPeriod = global.period-1; 
                                 int _start        = i-global.period+1; if(_start<0) { _start = 0; _minMaxPeriod = i+1; }
                                          m_work[i].prevmin = m_lows [ArrayMinimum(m_lows ,_start,_minMaxPeriod)];
                                          m_work[i].prevmax = m_highs[ArrayMaximum(m_highs,_start,_minMaxPeriod)];
                              }
                        else
                              {
                                          m_work[i].prevmin = m_lows[i];
                                          m_work[i].prevmax = m_highs[i];
                              }
                     }
         
                  double min = (m_work[i].prevmin < _pricel) ? m_work[i].prevmin : _pricel;
                  double max = (m_work[i].prevmax > _priceh) ? m_work[i].prevmax : _priceh;
                  double raw = (max!=min) ? (_price - min)/(max- min) : 0;
            //
            //
            //
            
            val[i]  = raw * raw * (3.0 - 2.0 * raw);
            valc[i] = (i>0) ? (val[i]>val[i-1]) ? 1 : (val[i]<val[i-1]) ? 2 : valc[i-1] : 0;
         }
   
   //
   //
   //
   
   return (rates_total);
}