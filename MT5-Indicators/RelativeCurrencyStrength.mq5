//+------------------------------------------------------------------+
//|                         RelativeCurrencyStrength.mq5              |
//| Tester-safe single-line relative currency strength               |
//|                                                                  |
//| output = S_BASE - S_QUOTE                                        |
//| r(BASE/QUOTE) = S_BASE - S_QUOTE                                 |
//|                                                                  |
//| Important tester behavior:                                       |
//| - explicitly selects all required foreign symbols;                |
//| - explicitly triggers their history loading;                      |
//| - does not publish EMPTY buffers as a completed calculation while |
//|   tester history is still synchronizing;                          |
//| - uses completed context bars only for the actual signal.         |
//+------------------------------------------------------------------+
#property version   "1.20"
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1  "Base-Quote Strength"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1  2

enum ENUM_CS_WEIGHTING
  {
   CS_EQUAL_WEIGHT=0,
   CS_INV_VARIANCE=1
  };

input ENUM_TIMEFRAMES   InpStrengthTimeframe = PERIOD_CURRENT;
input int               InpReturnLookbackBars = 12;
input ENUM_CS_WEIGHTING InpWeighting          = CS_INV_VARIANCE;
input int               InpWeightLookbackBars = 5000;
input bool              InpExcludeChartPair   = true;
input int               InpMaxChartBars       = 1200;
input double            InpRidge              = 1.0e-8;
input bool              InpShowMissingWarning = true;

double StrengthBuffer[];

string CURRENCIES[8] =
  {
   "USD","EUR","GBP","JPY","CHF","CAD","AUD","NZD"
  };

string PAIRS[28] =
  {
   "EURUSD","GBPUSD","AUDUSD","NZDUSD","USDJPY","USDCHF","USDCAD",
   "EURGBP","EURJPY","EURCHF","EURCAD","EURAUD","EURNZD",
   "GBPJPY","GBPCHF","GBPCAD","GBPAUD","GBPNZD",
   "AUDJPY","AUDCHF","AUDCAD","AUDNZD",
   "NZDJPY","NZDCHF","NZDCAD",
   "CADJPY","CADCHF","CHFJPY"
  };

string g_symbols[28];
bool   g_available[28];
int    g_available_count=0;

string g_chart_pair="";
string g_base="";
string g_quote="";
int    g_base_index=-1;
int    g_quote_index=-1;

bool     g_network_ready=false;
datetime g_last_wait_log=0;
string   g_last_wait_symbol="";
int      g_last_wait_bars=-1;

//+------------------------------------------------------------------+
ENUM_TIMEFRAMES EffectiveTimeframe()
  {
   return(InpStrengthTimeframe==PERIOD_CURRENT ?
          (ENUM_TIMEFRAMES)_Period : InpStrengthTimeframe);
  }

//+------------------------------------------------------------------+
int CurrencyIndex(const string ccy)
  {
   for(int i=0;i<8;i++)
      if(CURRENCIES[i]==ccy)
         return(i);

   return(-1);
  }

//+------------------------------------------------------------------+
string DetectConventionalPair(const string broker_symbol)
  {
   for(int i=0;i<28;i++)
      if(StringFind(broker_symbol,PAIRS[i])>=0)
         return(PAIRS[i]);

   return("");
  }

//+------------------------------------------------------------------+
//| Resolve broker suffix/prefix, e.g. GBPUSD_o or m.GBPUSD          |
//+------------------------------------------------------------------+
string FindBrokerSymbol(const string pair)
  {
   int total=SymbolsTotal(true);

   for(int i=0;i<total;i++)
     {
      string s=SymbolName(i,true);

      if(s==pair)
         return(s);
     }

   string best="";
   int best_len=1000000;

   for(int i=0;i<total;i++)
     {
      string s=SymbolName(i,true);

      if(StringFind(s,pair)>=0 && StringLen(s)<best_len)
        {
         best=s;
         best_len=StringLen(s);
        }
     }

   if(best!="")
      return(best);

   // In the Strategy Tester, SymbolsTotal(false) exposes the broker's
   // available symbol set. Selecting a resolved symbol explicitly requests it
   // for the testing agent.
   total=SymbolsTotal(false);

   for(int i=0;i<total;i++)
     {
      string s=SymbolName(i,false);

      if(s==pair)
        {
         SymbolSelect(s,true);
         return(s);
        }

      if(StringFind(s,pair)>=0 && StringLen(s)<best_len)
        {
         best=s;
         best_len=StringLen(s);
        }
     }

   if(best!="")
      SymbolSelect(best,true);

   return(best);
  }

//+------------------------------------------------------------------+
//| Trigger tester history loading for all required symbols          |
//+------------------------------------------------------------------+
void RequestNetworkHistory()
  {
   ENUM_TIMEFRAMES tf=EffectiveTimeframe();

   for(int p=0;p<28;p++)
     {
      if(!g_available[p])
         continue;

      if(InpExcludeChartPair && PAIRS[p]==g_chart_pair)
         continue;

      SymbolSelect(g_symbols[p],true);

      // Each of these calls is an explicit foreign-series reference in the
      // tester and therefore triggers synchronization/history transfer.
      Bars(g_symbols[p],tf);
      SeriesInfoInteger(g_symbols[p],tf,SERIES_SYNCHRONIZED);

      // Force the tester to request enough history for WLookback + return
      // horizon. A failed/partial copy is expected during the first attempts.
      int requested=MathMax(32,
                            InpWeightLookbackBars+
                            InpReturnLookbackBars+8);

      datetime probe[];
      ArrayResize(probe,requested);
      ResetLastError();
      CopyTime(g_symbols[p],tf,0,requested,probe);
     }
  }

//+------------------------------------------------------------------+
//| Tester-safe readiness check                                      |
//|                                                                  |
//| Do NOT declare the indicator calculated while required foreign   |
//| histories are still loading. Returning 0 from OnCalculate keeps  |
//| MT5 requesting/recalculating the indicator on following events.  |
//+------------------------------------------------------------------+
bool NetworkHistoryReady()
  {
   if(g_network_ready)
      return(true);

   ENUM_TIMEFRAMES tf=EffectiveTimeframe();

   int required=MathMax(32,
                        InpWeightLookbackBars+
                        InpReturnLookbackBars+8);

   int usable=0;

   for(int p=0;p<28;p++)
     {
      if(!g_available[p])
         continue;

      if(InpExcludeChartPair && PAIRS[p]==g_chart_pair)
         continue;

      string symbol=g_symbols[p];

      SymbolSelect(symbol,true);

      bool synchronized=
         (bool)SeriesInfoInteger(symbol,tf,SERIES_SYNCHRONIZED);

      int bars=Bars(symbol,tf);

      // CopyTime is intentional: it both verifies availability and, when the
      // tester has not supplied enough history yet, requests/builds more.
      datetime probe[];
      ArrayResize(probe,required);

      ResetLastError();
      int copied=CopyTime(symbol,tf,0,required,probe);
      int error=GetLastError();

      if(!synchronized || bars<required || copied<required)
        {
         datetime now=TimeCurrent();

         // Avoid flooding the Journal. Log if the blocked symbol/state changed,
         // or approximately once per simulated minute.
         if(InpShowMissingWarning &&
            (symbol!=g_last_wait_symbol ||
             bars!=g_last_wait_bars ||
             g_last_wait_log==0 ||
             now-g_last_wait_log>=60))
           {
            PrintFormat(
               "[RelativeCurrencyStrength] waiting_history symbol=%s timeframe=%s synchronized=%s bars=%d required=%d copied=%d error=%d",
               symbol,
               EnumToString(tf),
               (synchronized ? "true" : "false"),
               bars,
               required,
               copied,
               error
            );

            g_last_wait_log=now;
            g_last_wait_symbol=symbol;
            g_last_wait_bars=bars;
           }

         return(false);
        }

      usable++;
     }

   int expected=g_available_count-(InpExcludeChartPair ? 1 : 0);

   if(usable<expected || usable<7)
      return(false);

   g_network_ready=true;

   PrintFormat(
      "[RelativeCurrencyStrength] history_ready timeframe=%s symbols=%d required_bars=%d",
      EnumToString(tf),
      usable,
      required
   );

   return(true);
  }

//+------------------------------------------------------------------+
bool LoadCloseWindow(const string symbol,
                     const ENUM_TIMEFRAMES tf,
                     const int start_shift,
                     const int count,
                     double &closes[])
  {
   ArrayResize(closes,count);

   ResetLastError();

   int copied=
      CopyClose(symbol,tf,start_shift,count,closes);

   if(copied!=count)
      return(false);

   for(int i=0;i<count;i++)
      if(!MathIsValidNumber(closes[i]) || closes[i]<=0.0)
         return(false);

   return(true);
  }

//+------------------------------------------------------------------+
bool SolveLinear(double &A[][9],
                 double &b[],
                 double &x[],
                 const int n)
  {
   double M[9][10];

   for(int r=0;r<n;r++)
     {
      for(int c=0;c<n;c++)
         M[r][c]=A[r][c];

      M[r][n]=b[r];
     }

   for(int col=0;col<n;col++)
     {
      int pivot=col;
      double best=MathAbs(M[col][col]);

      for(int r=col+1;r<n;r++)
        {
         double v=MathAbs(M[r][col]);

         if(v>best)
           {
            best=v;
            pivot=r;
           }
        }

      if(best<1.0e-14 || !MathIsValidNumber(best))
         return(false);

      if(pivot!=col)
        {
         for(int c=col;c<=n;c++)
           {
            double tmp=M[col][c];
            M[col][c]=M[pivot][c];
            M[pivot][c]=tmp;
           }
        }

      double div=M[col][col];

      for(int c=col;c<=n;c++)
         M[col][c]/=div;

      for(int r=0;r<n;r++)
        {
         if(r==col)
            continue;

         double factor=M[r][col];

         if(MathAbs(factor)<1.0e-20)
            continue;

         for(int c=col;c<=n;c++)
            M[r][c]-=factor*M[col][c];
        }
     }

   ArrayResize(x,n);

   for(int i=0;i<n;i++)
     {
      x[i]=M[i][n];

      if(!MathIsValidNumber(x[i]))
         return(false);
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| Compute the eight latent strengths at chart_time                 |
//|                                                                  |
//| The +1 shift is deliberate: the context bar containing           |
//| chart_time is never used. Only the latest completed context bar  |
//| and older bars contribute to the signal.                         |
//+------------------------------------------------------------------+
bool ComputeCurrencyStrengths(const datetime chart_time,
                              double &strength[])
  {
   ENUM_TIMEFRAMES tf=EffectiveTimeframe();

   double returns[28];
   double weights[28];

   int bases[28];
   int quotes[28];

   bool usable[28];

   ArrayInitialize(returns,0.0);
   ArrayInitialize(weights,0.0);

   int n_equations=0;
   double weight_sum=0.0;

   int horizon=MathMax(1,InpReturnLookbackBars);
   int wlook=MathMax(10,InpWeightLookbackBars);

   for(int p=0;p<28;p++)
     {
      usable[p]=false;

      if(!g_available[p])
         continue;

      if(InpExcludeChartPair && PAIRS[p]==g_chart_pair)
         continue;

      string pair=PAIRS[p];

      int ibase=
         CurrencyIndex(StringSubstr(pair,0,3));

      int iquote=
         CurrencyIndex(StringSubstr(pair,3,3));

      if(ibase<0 || iquote<0)
         continue;

      int containing_shift=
         iBarShift(g_symbols[p],tf,chart_time,false);

      if(containing_shift<0)
         continue;

      // Strictly completed context data.
      int start_shift=containing_shift+1;

      int count=
         (InpWeighting==CS_INV_VARIANCE ?
          wlook+horizon :
          horizon+1);

      double closes[];

      if(!LoadCloseWindow(g_symbols[p],
                          tf,
                          start_shift,
                          count,
                          closes))
         continue;

      int newest=count-1;
      int older=newest-horizon;

      if(older<0)
         continue;

      double ret=
         MathLog(closes[newest]/closes[older]);

      if(!MathIsValidNumber(ret))
         continue;

      double w=1.0;

      if(InpWeighting==CS_INV_VARIANCE)
        {
         double sum=0.0;
         double sumsq=0.0;

         int nret=0;

         for(int k=0;k<wlook;k++)
           {
            int i0=newest-k;
            int i1=i0-horizon;

            if(i1<0)
               break;

            double rk=
               MathLog(closes[i0]/closes[i1]);

            if(!MathIsValidNumber(rk))
               continue;

            sum+=rk;
            sumsq+=rk*rk;
            nret++;
           }

         if(nret<10)
            continue;

         double mean=sum/nret;
         double var=sumsq/nret-mean*mean;

         var=MathMax(var,1.0e-10);

         w=1.0/var;
        }

      returns[p]=ret;
      weights[p]=w;
      bases[p]=ibase;
      quotes[p]=iquote;
      usable[p]=true;

      n_equations++;
      weight_sum+=w;
     }

   if(n_equations<7 || weight_sum<=0.0)
      return(false);

   double mean_weight=
      weight_sum/n_equations;

   double M[9][9];
   double rhs[];

   ArrayResize(rhs,9);

   for(int r=0;r<9;r++)
     {
      rhs[r]=0.0;

      for(int c=0;c<9;c++)
         M[r][c]=0.0;
     }

   for(int p=0;p<28;p++)
     {
      if(!usable[p])
         continue;

      int b=bases[p];
      int q=quotes[p];

      double w=
         weights[p]/mean_weight;

      double ret=
         returns[p];

      M[b][b]+=w;
      M[q][q]+=w;
      M[b][q]-=w;
      M[q][b]-=w;

      rhs[b]+=w*ret;
      rhs[q]-=w*ret;
     }

   double ridge=
      MathMax(0.0,InpRidge);

   for(int i=0;i<8;i++)
     {
      M[i][i]+=ridge;

      // sum(S)=0 constraint
      M[i][8]=1.0;
      M[8][i]=1.0;
     }

   rhs[8]=0.0;

   double solution[];

   if(!SolveLinear(M,rhs,solution,9))
      return(false);

   ArrayResize(strength,8);

   for(int i=0;i<8;i++)
      strength[i]=100.0*solution[i];

   return(true);
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpReturnLookbackBars<1)
      return(INIT_PARAMETERS_INCORRECT);

   if(InpWeighting==CS_INV_VARIANCE &&
      InpWeightLookbackBars<10)
      return(INIT_PARAMETERS_INCORRECT);

   if(InpMaxChartBars<2)
      return(INIT_PARAMETERS_INCORRECT);

   SetIndexBuffer(
      0,
      StrengthBuffer,
      INDICATOR_DATA
   );

   ArraySetAsSeries(
      StrengthBuffer,
      true
   );

   g_chart_pair=
      DetectConventionalPair(_Symbol);

   if(g_chart_pair=="")
     {
      Print(
         "[RelativeCurrencyStrength] unsupported chart symbol: ",
         _Symbol
      );

      return(INIT_FAILED);
     }

   g_base=
      StringSubstr(g_chart_pair,0,3);

   g_quote=
      StringSubstr(g_chart_pair,3,3);

   g_base_index=
      CurrencyIndex(g_base);

   g_quote_index=
      CurrencyIndex(g_quote);

   for(int p=0;p<28;p++)
     {
      g_symbols[p]=
         FindBrokerSymbol(PAIRS[p]);

      g_available[p]=
         (g_symbols[p]!="");

      if(g_available[p])
        {
         SymbolSelect(
            g_symbols[p],
            true
         );

         g_available_count++;
        }
     }

   int expected=
      28;

   if(g_available_count<expected)
     {
      string missing="";

      for(int p=0;p<28;p++)
         if(!g_available[p])
            missing+=
               (missing=="" ? "" : ", ")+
               PAIRS[p];

      PrintFormat(
         "[RelativeCurrencyStrength] symbol_resolution_failed found=%d expected=%d missing=%s",
         g_available_count,
         expected,
         missing
      );

      // The intended indicator is the full 28-cross network.
      return(INIT_FAILED);
     }

   PlotIndexSetString(
      0,
      PLOT_LABEL,
      g_base+"-"+g_quote+" Strength"
   );

   IndicatorSetString(
      INDICATOR_SHORTNAME,
      StringFormat(
         "%s-%s Relative Strength [%s, R%d, W%d]",
         g_base,
         g_quote,
         EnumToString(EffectiveTimeframe()),
         InpReturnLookbackBars,
         InpWeightLookbackBars
      )
   );

   IndicatorSetInteger(
      INDICATOR_DIGITS,
      5
   );

   IndicatorSetInteger(
      INDICATOR_LEVELS,
      1
   );

   IndicatorSetDouble(
      INDICATOR_LEVELVALUE,
      0,
      0.0
   );

   IndicatorSetInteger(
      INDICATOR_LEVELCOLOR,
      0,
      clrDimGray
   );

   IndicatorSetInteger(
      INDICATOR_LEVELSTYLE,
      0,
      STYLE_DOT
   );

   // Explicit tester preload.
   RequestNetworkHistory();

   PrintFormat(
      "[RelativeCurrencyStrength] initialized symbol=%s pair=%s timeframe=%s return_lookback=%d weight_lookback=%d exclude_pair=%s",
      _Symbol,
      g_chart_pair,
      EnumToString(EffectiveTimeframe()),
      InpReturnLookbackBars,
      InpWeightLookbackBars,
      (InpExcludeChartPair ? "true" : "false")
   );

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total<=0)
      return(0);

   ArraySetAsSeries(
      time,
      true
   );

   // Critical tester behavior:
   // do not tell MT5 this indicator has been successfully calculated until all
   // foreign histories required by WLookback are actually available.
   if(!NetworkHistoryReady())
     {
      RequestNetworkHistory();

      for(int i=0;i<MathMin(rates_total,InpMaxChartBars);i++)
         StrengthBuffer[i]=EMPTY_VALUE;

      return(0);
     }

   int limit;

   if(prev_calculated<=0)
      limit=
         MathMin(
            rates_total,
            InpMaxChartBars
         );
   else
     {
      int newly_added=
         rates_total-prev_calculated;

      limit=
         MathMin(
            rates_total,
            MathMax(2,newly_added+2)
         );

      limit=
         MathMin(
            limit,
            InpMaxChartBars
         );
     }

   int successful=0;

   for(int i=limit-1;i>=0;i--)
     {
      double s[];

      if(ComputeCurrencyStrengths(
            time[i],
            s))
        {
         StrengthBuffer[i]=
            s[g_base_index]-
            s[g_quote_index];

         successful++;
        }
      else
         StrengthBuffer[i]=EMPTY_VALUE;
     }

   if(successful==0)
     {
      // If synchronization was reported ready but no network point can be
      // solved, force another readiness pass on the next event and surface it.
      g_network_ready=false;

      if(InpShowMissingWarning)
         PrintFormat(
            "[RelativeCurrencyStrength] calculation_wait symbol=%s timeframe=%s no_solved_points=%d",
            _Symbol,
            EnumToString(EffectiveTimeframe()),
            limit
         );

      return(0);
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
