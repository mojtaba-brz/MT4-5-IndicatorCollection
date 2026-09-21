//+------------------------------------------------------------------+
//| WLS_CurrencyStrength.mq5                                         |
//| 8-currency FX strength from all 28 conventional crosses.         |
//| r(BASE/QUOTE) = S_BASE - S_QUOTE, solved by weighted least       |
//| squares with sum(S)=0. Uses only completed context bars.         |
//+------------------------------------------------------------------+
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   8

#property indicator_label1  "USD"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1  2
#property indicator_label2  "EUR"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRoyalBlue
#property indicator_width2  2
#property indicator_label3  "GBP"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMediumPurple
#property indicator_width3  2
#property indicator_label4  "JPY"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrTomato
#property indicator_width4  2
#property indicator_label5  "CHF"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrDarkOrange
#property indicator_width5  2
#property indicator_label6  "CAD"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrFireBrick
#property indicator_width6  2
#property indicator_label7  "AUD"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrSeaGreen
#property indicator_width7  2
#property indicator_label8  "NZD"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrLimeGreen
#property indicator_width8  2

enum ENUM_CS_WEIGHTING
  {
   CS_EQUAL_WEIGHT=0,
   CS_INV_VARIANCE=1
  };

input ENUM_TIMEFRAMES   InpStrengthTimeframe = PERIOD_H1;
input int               InpReturnLookbackBars = 1;
input ENUM_CS_WEIGHTING InpWeighting          = CS_INV_VARIANCE;
input int               InpWeightLookbackBars = 120;
input bool              InpExcludeChartPair   = false;
input int               InpMaxChartBars       = 1200;
input double            InpRidge               = 1.0e-8;
input bool              InpShowMissingWarning = true;

double BufUSD[],BufEUR[],BufGBP[],BufJPY[],BufCHF[],BufCAD[],BufAUD[],BufNZD[];

string CURRENCIES[8]={"USD","EUR","GBP","JPY","CHF","CAD","AUD","NZD"};
string PAIRS[28]=
  {
   "EURUSD","GBPUSD","AUDUSD","NZDUSD","USDJPY","USDCHF","USDCAD",
   "EURGBP","EURJPY","EURCHF","EURCAD","EURAUD","EURNZD",
   "GBPJPY","GBPCHF","GBPCAD","GBPAUD","GBPNZD",
   "AUDJPY","AUDCHF","AUDCAD","AUDNZD",
   "NZDJPY","NZDCHF","NZDCAD","CADJPY","CADCHF","CHFJPY"
  };

string g_symbols[28];
bool   g_available[28];
int    g_available_count=0;
string g_chart_pair="";

ENUM_TIMEFRAMES EffectiveTimeframe()
  {
   if(InpStrengthTimeframe==PERIOD_CURRENT) return((ENUM_TIMEFRAMES)_Period);
   return(InpStrengthTimeframe);
  }

int CurrencyIndex(const string ccy)
  {
   for(int i=0;i<8;i++) if(CURRENCIES[i]==ccy) return(i);
   return(-1);
  }

string DetectConventionalPair(const string broker_symbol)
  {
   for(int i=0;i<28;i++) if(StringFind(broker_symbol,PAIRS[i])>=0) return(PAIRS[i]);
   return("");
  }

string FindBrokerSymbol(const string pair)
  {
   int total=SymbolsTotal(true);
   for(int i=0;i<total;i++)
     {
      string s=SymbolName(i,true);
      if(s==pair) return(s);
     }

   string best=""; int best_len=1000000;
   for(int i=0;i<total;i++)
     {
      string s=SymbolName(i,true);
      if(StringFind(s,pair)>=0 && StringLen(s)<best_len)
        { best=s; best_len=StringLen(s); }
     }
   if(best!="") return(best);

   total=SymbolsTotal(false); best=""; best_len=1000000;
   for(int i=0;i<total;i++)
     {
      string s=SymbolName(i,false);
      if(s==pair) { SymbolSelect(s,true); return(s); }
      if(StringFind(s,pair)>=0 && StringLen(s)<best_len)
        { best=s; best_len=StringLen(s); }
     }
   if(best!="") { SymbolSelect(best,true); return(best); }
   return("");
  }

bool LoadCloseWindow(const string symbol,const ENUM_TIMEFRAMES tf,const int start_shift,const int count,double &closes[])
  {
   ArrayResize(closes,count);
   ResetLastError();
   int copied=CopyClose(symbol,tf,start_shift,count,closes);
   if(copied!=count) return(false);
   for(int i=0;i<count;i++)
      if(!MathIsValidNumber(closes[i]) || closes[i]<=0.0) return(false);
   return(true);
  }

bool SolveLinear(double &A[][9],double &b[],double &x[],const int n)
  {
   double M[9][10];
   for(int r=0;r<n;r++)
     {
      for(int c=0;c<n;c++) M[r][c]=A[r][c];
      M[r][n]=b[r];
     }

   for(int col=0;col<n;col++)
     {
      int pivot=col; double best=MathAbs(M[col][col]);
      for(int r=col+1;r<n;r++)
        {
         double v=MathAbs(M[r][col]);
         if(v>best) { best=v; pivot=r; }
        }
      if(best<1.0e-14 || !MathIsValidNumber(best)) return(false);

      if(pivot!=col)
        {
         for(int c=col;c<=n;c++)
           {
            double tmp=M[col][c]; M[col][c]=M[pivot][c]; M[pivot][c]=tmp;
           }
        }

      double div=M[col][col];
      for(int c=col;c<=n;c++) M[col][c]/=div;

      for(int r=0;r<n;r++)
        {
         if(r==col) continue;
         double factor=M[r][col];
         if(MathAbs(factor)<1.0e-20) continue;
         for(int c=col;c<=n;c++) M[r][c]-=factor*M[col][c];
        }
     }

   ArrayResize(x,n);
   for(int i=0;i<n;i++)
     {
      x[i]=M[i][n];
      if(!MathIsValidNumber(x[i])) return(false);
     }
   return(true);
  }

bool ComputeStrength(const datetime chart_time,double &strength[])
  {
   ENUM_TIMEFRAMES tf=EffectiveTimeframe();
   double returns[28],weights[28];
   int bases[28],quotes[28];
   bool usable[28];
   ArrayInitialize(returns,0.0); ArrayInitialize(weights,0.0);

   int n_equations=0; double weight_sum=0.0;
   int horizon=MathMax(1,InpReturnLookbackBars);
   int wlook=MathMax(10,InpWeightLookbackBars);

   for(int p=0;p<28;p++)
     {
      usable[p]=false;
      if(!g_available[p]) continue;
      if(InpExcludeChartPair && g_chart_pair!="" && PAIRS[p]==g_chart_pair) continue;

      int ibase=CurrencyIndex(StringSubstr(PAIRS[p],0,3));
      int iquote=CurrencyIndex(StringSubstr(PAIRS[p],3,3));
      if(ibase<0 || iquote<0) continue;

      int containing_shift=iBarShift(g_symbols[p],tf,chart_time,false);
      if(containing_shift<0) continue;

      // Strictly use the previous completed context bar.
      int start_shift=containing_shift+1;
      int count=(InpWeighting==CS_INV_VARIANCE ? wlook+horizon : horizon+1);
      double closes[];
      if(!LoadCloseWindow(g_symbols[p],tf,start_shift,count,closes)) continue;

      int newest=count-1;
      int old_index=newest-horizon;
      if(old_index<0) continue;

      double r=MathLog(closes[newest]/closes[old_index]);
      if(!MathIsValidNumber(r)) continue;

      double w=1.0;
      if(InpWeighting==CS_INV_VARIANCE)
        {
         double sum=0.0,sumsq=0.0; int nret=0;
         for(int k=0;k<wlook;k++)
           {
            int i0=newest-k, i1=i0-horizon;
            if(i1<0) break;
            double rk=MathLog(closes[i0]/closes[i1]);
            if(!MathIsValidNumber(rk)) continue;
            sum+=rk; sumsq+=rk*rk; nret++;
           }
         if(nret<10) continue;
         double mean=sum/nret;
         double var=(sumsq/nret)-mean*mean;
         var=MathMax(var,1.0e-10);
         w=1.0/var;
        }

      returns[p]=r; weights[p]=w; bases[p]=ibase; quotes[p]=iquote; usable[p]=true;
      n_equations++; weight_sum+=w;
     }

   if(n_equations<7 || weight_sum<=0.0) return(false);
   double mean_weight=weight_sum/n_equations;

   double M[9][9]; double rhs[]; ArrayResize(rhs,9);
   for(int r=0;r<9;r++)
     {
      rhs[r]=0.0;
      for(int c=0;c<9;c++) M[r][c]=0.0;
     }

   for(int p=0;p<28;p++)
     {
      if(!usable[p]) continue;
      int b=bases[p], q=quotes[p];
      double w=weights[p]/mean_weight, ret=returns[p];
      M[b][b]+=w; M[q][q]+=w; M[b][q]-=w; M[q][b]-=w;
      rhs[b]+=w*ret; rhs[q]-=w*ret;
     }

   double ridge=MathMax(0.0,InpRidge);
   for(int i=0;i<8;i++)
     {
      M[i][i]+=ridge;
      M[i][8]=1.0;
      M[8][i]=1.0;
     }
   rhs[8]=0.0;

   double solution[];
   if(!SolveLinear(M,rhs,solution,9)) return(false);

   ArrayResize(strength,8);
   for(int i=0;i<8;i++) strength[i]=100.0*solution[i];
   return(true);
  }

void SetEmpty(const int i)
  {
   BufUSD[i]=EMPTY_VALUE; BufEUR[i]=EMPTY_VALUE; BufGBP[i]=EMPTY_VALUE; BufJPY[i]=EMPTY_VALUE;
   BufCHF[i]=EMPTY_VALUE; BufCAD[i]=EMPTY_VALUE; BufAUD[i]=EMPTY_VALUE; BufNZD[i]=EMPTY_VALUE;
  }

void SetStrength(const int i,const double &s[])
  {
   BufUSD[i]=s[0]; BufEUR[i]=s[1]; BufGBP[i]=s[2]; BufJPY[i]=s[3];
   BufCHF[i]=s[4]; BufCAD[i]=s[5]; BufAUD[i]=s[6]; BufNZD[i]=s[7];
  }

int OnInit()
  {
   if(InpReturnLookbackBars<1 || InpMaxChartBars<10) return(INIT_PARAMETERS_INCORRECT);
   if(InpWeighting==CS_INV_VARIANCE && InpWeightLookbackBars<10) return(INIT_PARAMETERS_INCORRECT);

   SetIndexBuffer(0,BufUSD,INDICATOR_DATA); SetIndexBuffer(1,BufEUR,INDICATOR_DATA);
   SetIndexBuffer(2,BufGBP,INDICATOR_DATA); SetIndexBuffer(3,BufJPY,INDICATOR_DATA);
   SetIndexBuffer(4,BufCHF,INDICATOR_DATA); SetIndexBuffer(5,BufCAD,INDICATOR_DATA);
   SetIndexBuffer(6,BufAUD,INDICATOR_DATA); SetIndexBuffer(7,BufNZD,INDICATOR_DATA);

   ArraySetAsSeries(BufUSD,true); ArraySetAsSeries(BufEUR,true); ArraySetAsSeries(BufGBP,true); ArraySetAsSeries(BufJPY,true);
   ArraySetAsSeries(BufCHF,true); ArraySetAsSeries(BufCAD,true); ArraySetAsSeries(BufAUD,true); ArraySetAsSeries(BufNZD,true);

   for(int p=0;p<28;p++)
     {
      g_symbols[p]=FindBrokerSymbol(PAIRS[p]);
      g_available[p]=(g_symbols[p]!="");
      if(g_available[p]) { SymbolSelect(g_symbols[p],true); g_available_count++; }
     }

   g_chart_pair=DetectConventionalPair(_Symbol);
   IndicatorSetString(INDICATOR_SHORTNAME,StringFormat("WLS Currency Strength [%s, %d-bar]",EnumToString(EffectiveTimeframe()),InpReturnLookbackBars));
   IndicatorSetInteger(INDICATOR_DIGITS,4);
   IndicatorSetInteger(INDICATOR_LEVELS,1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,0.0);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrDimGray);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_DOT);

   PrintFormat("WLS Currency Strength: found %d/28 FX pairs. Chart pair=%s",g_available_count,g_chart_pair);

   if(InpShowMissingWarning && g_available_count<28)
     {
      string missing="";
      for(int p=0;p<28;p++) if(!g_available[p]) missing+=(missing=="" ? "" : ", ")+PAIRS[p];
      Print("Missing FX symbols: ",missing);
     }

   if(g_available_count<7) return(INIT_FAILED);
   return(INIT_SUCCEEDED);
  }

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
  {
   if(rates_total<=0) return(0);
   ArraySetAsSeries(time,true);

   int limit;
   if(prev_calculated<=0) limit=MathMin(rates_total,InpMaxChartBars);
   else
     {
      int newly_added=rates_total-prev_calculated;
      limit=MathMin(rates_total,MathMax(3,newly_added+3));
      limit=MathMin(limit,InpMaxChartBars);
     }

   for(int i=limit-1;i>=0;i--)
     {
      double s[];
      if(ComputeStrength(time[i],s)) SetStrength(i,s);
      else SetEmpty(i);
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
