//+------------------------------------------------------------------+
//|                         RelativeCurrencyStrength.mq5              |
//|  Single-line relative currency strength for the current FX chart |
//|                                                                  |
//|  Example on GBPUSD:                                              |
//|       output = S_GBP - S_USD                                     |
//|                                                                  |
//|  The 8 currency strengths are estimated internally from the      |
//|  28-cross FX network using weighted least squares, but only the   |
//|  base-minus-quote strength is plotted.                            |
//+------------------------------------------------------------------+
#property version   "1.00"
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

input ENUM_TIMEFRAMES   InpStrengthTimeframe = PERIOD_H1;
input int               InpReturnLookbackBars = 1;
input ENUM_CS_WEIGHTING InpWeighting          = CS_INV_VARIANCE;
input int               InpWeightLookbackBars = 120;

// If true, the current chart pair is removed from the WLS network.
// For GBPUSD this means GBP and USD are estimated from the other 27 pairs.
// Recommended for an independent strength estimate.
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

//+------------------------------------------------------------------+
ENUM_TIMEFRAMES EffectiveTimeframe()
  {
   if(InpStrengthTimeframe==PERIOD_CURRENT)
      return((ENUM_TIMEFRAMES)_Period);
   return(InpStrengthTimeframe);
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
//| Detect the conventional six-letter FX pair inside broker symbol  |
//| e.g. GBPUSD_o -> GBPUSD, m.EURJPY -> EURJPY                      |
//+------------------------------------------------------------------+
string DetectConventionalPair(const string broker_symbol)
  {
   for(int i=0;i<28;i++)
      if(StringFind(broker_symbol,PAIRS[i])>=0)
         return(PAIRS[i]);

   return("");
  }

//+------------------------------------------------------------------+
string FindBrokerSymbol(const string pair)
  {
   int total=SymbolsTotal(true);

   // Exact match first
   for(int i=0;i<total;i++)
     {
      string s=SymbolName(i,true);
      if(s==pair)
         return(s);
     }

   // Then shortest Market Watch symbol containing pair name
   string best="";
   int best_len=1000000;

   for(int i=0;i<total;i++)
     {
      string s=SymbolName(i,true);

      if(StringFind(s,pair)>=0)
        {
         int n=StringLen(s);

         if(n<best_len)
           {
            best=s;
            best_len=n;
           }
        }
     }

   if(best!="")
      return(best);

   // Finally inspect all broker symbols
   total=SymbolsTotal(false);
   best="";
   best_len=1000000;

   for(int i=0;i<total;i++)
     {
      string s=SymbolName(i,false);

      if(s==pair)
        {
         SymbolSelect(s,true);
         return(s);
        }

      if(StringFind(s,pair)>=0)
        {
         int n=StringLen(s);

         if(n<best_len)
           {
            best=s;
            best_len=n;
           }
        }
     }

   if(best!="")
     {
      SymbolSelect(best,true);
      return(best);
     }

   return("");
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
   int copied=CopyClose(symbol,tf,start_shift,count,closes);

   if(copied!=count)
      return(false);

   for(int i=0;i<count;i++)
      if(!MathIsValidNumber(closes[i]) || closes[i]<=0.0)
         return(false);

   return(true);
  }

//+------------------------------------------------------------------+
//| Gaussian elimination                                             |
//+------------------------------------------------------------------+
bool SolveLinear(double &A[][9],double &b[],double &x[],const int n)
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
//| Estimate all 8 strengths internally                              |
//+------------------------------------------------------------------+
bool ComputeCurrencyStrengths(const datetime chart_time,double &strength[])
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

      // Avoid direct leakage from the current pair if requested.
      if(InpExcludeChartPair && g_chart_pair!="" && PAIRS[p]==g_chart_pair)
         continue;

      string pair=PAIRS[p];

      int ibase=CurrencyIndex(StringSubstr(pair,0,3));
      int iquote=CurrencyIndex(StringSubstr(pair,3,3));

      if(ibase<0 || iquote<0)
         continue;

      int containing_shift=iBarShift(g_symbols[p],tf,chart_time,false);

      if(containing_shift<0)
         continue;

      // IMPORTANT:
      // iBarShift points to the TF bar containing chart_time.
      // +1 means we use the previous completed TF bar only.
      int start_shift=containing_shift+1;

      int count=(InpWeighting==CS_INV_VARIANCE)
                ? wlook+horizon
                : horizon+1;

      double closes[];

      if(!LoadCloseWindow(g_symbols[p],tf,start_shift,count,closes))
         continue;

      int newest=count-1;
      int older=newest-horizon;

      if(older<0)
         continue;

      double ret=MathLog(closes[newest]/closes[older]);

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

            double rk=MathLog(closes[i0]/closes[i1]);

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

   // Normalize weights for numerical conditioning
   double mean_weight=weight_sum/n_equations;

   // Solve
   //
   //   r_pair = S_base - S_quote
   //
   // using constrained WLS:
   //
   //   sum(S_currency) = 0
   //
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

      double w=weights[p]/mean_weight;
      double ret=returns[p];

      M[b][b]+=w;
      M[q][q]+=w;
      M[b][q]-=w;
      M[q][b]-=w;

      rhs[b]+=w*ret;
      rhs[q]-=w*ret;
     }

   double ridge=MathMax(0.0,InpRidge);

   for(int i=0;i<8;i++)
     {
      M[i][i]+=ridge;

      // zero-sum constraint row/column
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

   if(InpWeighting==CS_INV_VARIANCE && InpWeightLookbackBars<10)
      return(INIT_PARAMETERS_INCORRECT);

   if(InpMaxChartBars<10)
      return(INIT_PARAMETERS_INCORRECT);

   SetIndexBuffer(0,StrengthBuffer,INDICATOR_DATA);
   ArraySetAsSeries(StrengthBuffer,true);

   g_chart_pair=DetectConventionalPair(_Symbol);

   if(g_chart_pair=="")
     {
      Print("RelativeCurrencyStrength must be attached to a supported FX pair. Symbol=",
            _Symbol);
      return(INIT_FAILED);
     }

   g_base=StringSubstr(g_chart_pair,0,3);
   g_quote=StringSubstr(g_chart_pair,3,3);

   g_base_index=CurrencyIndex(g_base);
   g_quote_index=CurrencyIndex(g_quote);

   if(g_base_index<0 || g_quote_index<0)
      return(INIT_FAILED);

   for(int p=0;p<28;p++)
     {
      g_symbols[p]=FindBrokerSymbol(PAIRS[p]);
      g_available[p]=(g_symbols[p]!="");

      if(g_available[p])
        {
         SymbolSelect(g_symbols[p],true);
         g_available_count++;
        }
     }

   PlotIndexSetString(0,PLOT_LABEL,g_base+"-"+g_quote+" Strength");

   IndicatorSetString(
      INDICATOR_SHORTNAME,
      StringFormat("%s-%s Relative Strength [%s, %d]",
                   g_base,
                   g_quote,
                   EnumToString(EffectiveTimeframe()),
                   InpReturnLookbackBars)
   );

   IndicatorSetInteger(INDICATOR_DIGITS,4);

   IndicatorSetInteger(INDICATOR_LEVELS,1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,0.0);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrDimGray);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_DOT);

   PrintFormat(
      "RelativeCurrencyStrength: %s = S_%s - S_%s; found %d/28 FX pairs; exclude chart pair=%s",
      g_chart_pair,
      g_base,
      g_quote,
      g_available_count,
      (InpExcludeChartPair ? "true" : "false")
   );

   if(InpShowMissingWarning && g_available_count<28)
     {
      string missing="";

      for(int p=0;p<28;p++)
         if(!g_available[p])
            missing+=(missing=="" ? "" : ", ")+PAIRS[p];

      Print("Missing FX symbols: ",missing);
     }

   // If chart pair is excluded, 27 remaining edges should normally be available.
   // At minimum we need enough edges to identify all 8 currencies.
   if(g_available_count<7)
      return(INIT_FAILED);

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

   ArraySetAsSeries(time,true);

   int limit;

   if(prev_calculated<=0)
      limit=MathMin(rates_total,InpMaxChartBars);
   else
     {
      int added=rates_total-prev_calculated;
      limit=MathMin(rates_total,MathMax(3,added+3));
      limit=MathMin(limit,InpMaxChartBars);
     }

   for(int i=limit-1;i>=0;i--)
     {
      double s[];

      if(ComputeCurrencyStrengths(time[i],s))
         StrengthBuffer[i]=s[g_base_index]-s[g_quote_index];
      else
         StrengthBuffer[i]=EMPTY_VALUE;
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
