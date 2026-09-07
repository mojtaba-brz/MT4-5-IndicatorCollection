#property strict
#property version "1.34"
#property description "Correlation-adjusted chart normalized close minus selected companion."
#property description "Closed candles; broker day/session resets; percentage-point histogram."
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots 1
#property indicator_type1 DRAW_COLOR_HISTOGRAM
#property indicator_color1 C'42,64,88',C'25,40,56',C'128,57,58',C'88,37,39'
#property indicator_width1 3
#property indicator_label1 "Correlation-adjusted difference (%)"
#property indicator_level1 0.0
#property indicator_levelcolor clrDimGray
#property indicator_levelstyle STYLE_DOT

#include "../../../Libs/MQLTradingLib/ExchangeTools.mqh"
#include "../Libs/NormalizedCloseDifference.mqh"

// The values below are frozen Pearson correlations of completed H1 log
// returns from the 2024 AssetSessionCorrelation reports. They are reference
// metadata, not a live estimate. The three columns use broker-clock Asia,
// London and New York sessions respectively.
struct NcdH1Correlation
  {
   string first;
   string second;
   double asia;
   double london;
   double new_york;
  };

const NcdH1Correlation NCD_H1_CORRELATIONS[]=
  {
   {"EURUSD","USDJPY",-0.341024044564,-0.342903142677,-0.549560518275},
   {"EURUSD","GBPUSD",0.792614478738,0.758393116607,0.802997357609},
   {"EURUSD","USDCHF",-0.615821682371,-0.626228315287,-0.729073539878},
   {"EURUSD","USDCAD",-0.667895218942,-0.582723914996,-0.573189149709},
   {"EURUSD","AUDUSD",0.617316091684,0.669318500984,0.728937225134},
   {"EURUSD","NZDUSD",0.586822633783,0.694833746060,0.773212523325},
   {"EURUSD","WTI",0.108246079965,0.064877501587,0.023021388997},
   {"EURUSD","GOLD",0.305286411967,0.368992222410,0.370823210308},
   {"EURUSD","SILVER",0.319169651451,0.363051040803,0.352069866359},
   {"EURUSD","DXY",-0.747099651278,-0.910143699872,-0.945425173008},
   {"USDJPY","GBPUSD",-0.272918377184,-0.324545897775,-0.476987790202},
   {"USDJPY","USDCHF",0.597235037696,0.568408397052,0.704550820785},
   {"USDJPY","USDCAD",0.202715162272,0.270064711152,0.326738112713},
   {"USDJPY","AUDUSD",-0.148461901012,-0.361857753320,-0.484115948478},
   {"USDJPY","NZDUSD",-0.219421094141,-0.441606633472,-0.586671896939},
   {"USDJPY","WTI",-0.014912721433,0.058862556398,0.110045009708},
   {"USDJPY","GOLD",-0.155907292524,-0.305796591845,-0.356118025638},
   {"USDJPY","SILVER",-0.097268291229,-0.230560494687,-0.271767750973},
   {"USDJPY","DXY",0.484807682966,0.553354783302,0.681834816046},
   {"GBPUSD","USDCHF",-0.448436882046,-0.495953979775,-0.622282257761},
   {"GBPUSD","USDCAD",-0.658229365679,-0.561425660550,-0.593246121233},
   {"GBPUSD","AUDUSD",0.662524531794,0.682565092198,0.762904829725},
   {"GBPUSD","NZDUSD",0.627783700787,0.694681078987,0.779286707447},
   {"GBPUSD","WTI",0.134142851463,0.060992211484,0.070846336407},
   {"GBPUSD","GOLD",0.327357521950,0.384619519526,0.410434342036},
   {"GBPUSD","SILVER",0.343043574392,0.380027574815,0.390938709542},
   {"GBPUSD","DXY",-0.632547277891,-0.781460515938,-0.832286652412},
   {"USDCHF","USDCAD",0.423669859263,0.407540794004,0.460637946240},
   {"USDCHF","AUDUSD",-0.316640770220,-0.483528890384,-0.581514553092},
   {"USDCHF","NZDUSD",-0.348152743267,-0.547842236283,-0.667667090942},
   {"USDCHF","WTI",-0.083868689909,0.022607966090,0.031643670243},
   {"USDCHF","GOLD",-0.273715325949,-0.336745558508,-0.371756409677},
   {"USDCHF","SILVER",-0.232637385255,-0.282628090764,-0.296008049374},
   {"USDCHF","DXY",0.546793597684,0.688969968699,0.784143244190},
   {"USDCAD","AUDUSD",-0.720360884989,-0.727934676671,-0.717273333945},
   {"USDCAD","NZDUSD",-0.616998307946,-0.689495220900,-0.682690605079},
   {"USDCAD","WTI",-0.257278380109,-0.218147065113,-0.205133038524},
   {"USDCAD","GOLD",-0.317454321493,-0.365184689175,-0.343638369970},
   {"USDCAD","SILVER",-0.369802850195,-0.394738216661,-0.374622107235},
   {"USDCAD","DXY",0.570961672983,0.620593479314,0.625652958069},
   {"AUDUSD","NZDUSD",0.747250222754,0.905494297659,0.927670239912},
   {"AUDUSD","WTI",0.219899416089,0.120450492717,0.100005952261},
   {"AUDUSD","GOLD",0.311528093035,0.448448263909,0.475118952131},
   {"AUDUSD","SILVER",0.367738094255,0.469145592554,0.484997040164},
   {"AUDUSD","DXY",-0.484885280002,-0.706531670406,-0.767936998944},
   {"NZDUSD","WTI",0.132991144420,0.099321138292,0.056656908680},
   {"NZDUSD","GOLD",0.270145573803,0.448923722493,0.462914452611},
   {"NZDUSD","SILVER",0.301245222204,0.444403385150,0.446972428177},
   {"NZDUSD","DXY",-0.478213599286,-0.747465547659,-0.820609898749},
   {"WTI","GOLD",0.327696292839,0.162141415953,0.168595251946},
   {"WTI","SILVER",0.374666106542,0.214711907451,0.226971850735},
   {"WTI","DXY",-0.095266117515,-0.053780847967,-0.018147212978},
   {"GOLD","SILVER",0.776168550664,0.791569064914,0.791313472777},
   {"GOLD","DXY",-0.298591610366,-0.411695458978,-0.420245257623},
   {"SILVER","DXY",-0.312054401367,-0.391522373519,-0.385780264783}
  };

input ENUM_NCD_SECOND_ASSET InpSecondAsset=NCD_AUTO_STRONGEST_H1; // Companion asset
input ENUM_TIMEFRAMES InpTimeframe=PERIOD_CURRENT;        // Current or higher timeframe
input ENUM_NORMALIZED_RESET InpResetPoint=NORMALIZED_EACH_SESSION; // Reset point
input int InpHistoryDays=14;                              // Calendar days to display (including latest chart day)

string NcdAssetName(const ENUM_NCD_SECOND_ASSET asset)
  {
   switch(asset)
     {
      case NCD_EURUSD: return "EURUSD";
      case NCD_USDJPY: return "USDJPY";
      case NCD_GBPUSD: return "GBPUSD";
      case NCD_USDCHF: return "USDCHF";
      case NCD_USDCAD: return "USDCAD";
      case NCD_AUDUSD: return "AUDUSD";
      case NCD_NZDUSD: return "NZDUSD";
      case NCD_WTI: return "WTI";
      case NCD_GOLD: return "GOLD";
      case NCD_SILVER: return "SILVER";
      case NCD_DXY: return "DXY";
      default: return "";
     }
  }

bool NcdH1Reference(const string first,const string second,
                    const ENUM_NORMALIZED_RESET reset,double &correlation,
                    string &reference_session)
  {
   for(int i=0;i<ArraySize(NCD_H1_CORRELATIONS);++i)
     {
      NcdH1Correlation row=NCD_H1_CORRELATIONS[i];
      if(!((row.first==first && row.second==second) ||
           (row.first==second && row.second==first)))
         continue;
      if(reset==NORMALIZED_ASIA_START)
        {
         correlation=row.asia;
         reference_session="Asia";
        }
      else if(reset==NORMALIZED_LONDON_START)
        {
         correlation=row.london;
         reference_session="London";
        }
      else if(reset==NORMALIZED_NEW_YORK_START)
        {
         correlation=row.new_york;
         reference_session="New York";
        }
      else
        {
         correlation=row.asia;
         reference_session="Asia";
         if(MathAbs(row.london)>MathAbs(correlation))
           {
            correlation=row.london;
            reference_session="London";
           }
         if(MathAbs(row.new_york)>MathAbs(correlation))
           {
            correlation=row.new_york;
            reference_session="New York";
           }
        }
      return true;
     }
   correlation=0.0;
   reference_session="unavailable";
   return false;
  }

bool NcdResolveSecond(const string chart_standard,const ENUM_NCD_SECOND_ASSET requested,
                      const ENUM_NORMALIZED_RESET reset,string &second_standard,
                      string &second_broker,double &correlation,string &reference_session)
  {
   if(requested!=NCD_AUTO_STRONGEST_H1)
     {
      second_standard=NcdAssetName(requested);
      if(second_standard==chart_standard || second_standard=="" ||
         !NcdH1Reference(chart_standard,second_standard,reset,correlation,reference_session))
         return false;
      second_broker=standard_symbol_to_broker_symbol(second_standard);
      return (StringLen(second_broker)>0);
     }
   double strongest=-1.0;
   second_standard="";
   second_broker="";
   correlation=0.0;
   reference_session="unavailable";
   for(int raw=NCD_EURUSD;raw<=NCD_DXY;++raw)
     {
      string candidate=NcdAssetName((ENUM_NCD_SECOND_ASSET)raw);
      if(candidate==chart_standard)
         continue;
      double candidate_correlation=0.0;
      string candidate_session="";
      if(!NcdH1Reference(chart_standard,candidate,reset,candidate_correlation,candidate_session))
         continue;
      string candidate_broker=standard_symbol_to_broker_symbol(candidate);
      if(StringLen(candidate_broker)<=0 ||
         MathAbs(candidate_correlation)<=strongest)
         continue;
      strongest=MathAbs(candidate_correlation);
      second_standard=candidate;
      second_broker=candidate_broker;
      correlation=candidate_correlation;
      reference_session=candidate_session;
     }
   return (second_standard!="");
  }

double DifferenceBuffer[];
double ColorIndexBuffer[];

// Adapter state belongs to one indicator instance. No function-local static
// remembers a different chart, symbol or timeframe.
class CNormalizedDifferenceIndicator
  {
private:
   string            _second;
   ENUM_TIMEFRAMES    _source_period;
   ENUM_TIMEFRAMES    _chart_period;
   ENUM_NORMALIZED_RESET _reset;
   CNormalizedCloseDifference _calculation;
   datetime          _last_chart_open;
   int               _last_count;
   int               _history_days;
   double            _correlation;
   string            _reference_session;
   datetime          _times[];
   datetime          _cutoff;
   bool              _retry;
   bool              _has_snapshot;
   datetime          _snapshot_times[];
   double            _snapshot_values[];
   double            _snapshot_colors[];
   string            _status;

   void CaptureSnapshot(const double &values[],const double &colors[])
     {
      int count=ArraySize(_times);
      ArrayResize(_snapshot_times,count);
      ArrayResize(_snapshot_values,count);
      ArrayResize(_snapshot_colors,count);
      for(int i=0;i<count;++i)
        {
         _snapshot_times[i]=_times[i];
         _snapshot_values[i]=values[i];
         _snapshot_colors[i]=colors[i];
        }
      _has_snapshot=(count>1 && _snapshot_values[1]!=EMPTY_VALUE);
     }

   void RestoreSnapshot(const datetime &times[],const int total,
                        double &output[],double &colors[])
     {
      if(!_has_snapshot)
        {
         ArrayInitialize(output,EMPTY_VALUE);
         ArrayInitialize(colors,0.0);
         return;
        }
      NormalizedRestoreSnapshot(_snapshot_times,_snapshot_values,_snapshot_colors,
                                times,total,output,colors);
     }

   void Status(const string detail)
     {
      if(detail==_status)
         return;
      _status=detail;
      IndicatorSetString(INDICATOR_SHORTNAME,"NCD r="+DoubleToString(_correlation,3)+": "+
                         _Symbol+"-"+_second+" ["+detail+"]");
     }

   void ApplyColors(const double &output[],double &colors[])
     {
      ArrayInitialize(colors,0.0);
      int index=_last_count-1;
      if(index>=ArraySize(output))
         index=ArraySize(output)-1;
      bool has_previous=false;
      double previous_value=0.0;
      // Series arrays run newest -> oldest, so walk in the opposite direction
      // to compare each confirmed value with its immediately preceding value.
      for(;index>=1;--index)
        {
         double value=output[index];
         if(value==EMPTY_VALUE)
           {
            has_previous=false;
            continue;
           }
         colors[index]=(double)NormalizedDifferenceColorIndex(value,previous_value,has_previous);
         previous_value=value;
         has_previous=true;
        }
     }

public:
   void SetParams(const string second,const ENUM_TIMEFRAMES requested,
                  const ENUM_NORMALIZED_RESET reset,const double correlation,
                  const string reference_session,const int history_days=14)
     {
      _second=second;
      _source_period=(requested==PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : requested);
      _chart_period=(ENUM_TIMEFRAMES)_Period;
      _reset=reset;
      _correlation=correlation;
      _reference_session=reference_session;
      _history_days=history_days;
      Reset();
     }

   void Reset(void)
     {
      _last_chart_open=0;
      _last_count=0;
      _cutoff=0;
      _retry=true;
      _has_snapshot=false;
      _status="";
      ArrayResize(_times,0);
      ArrayResize(_snapshot_times,0);
      ArrayResize(_snapshot_values,0);
      ArrayResize(_snapshot_colors,0);
      _calculation.Reset();
     }

   bool Init(void)
     {
      Reset();
      if(_second=="" || _history_days<1 || PeriodSeconds(_source_period)<PeriodSeconds(_chart_period))
        {
         Print("NormalizedCloseDifference: select the current or a higher timeframe, a valid second symbol and HistoryDays >= 1.");
         return false;
        }
      if(_second==_Symbol)
        {
         Print("NormalizedCloseDifference: Second symbol must differ from the chart symbol. ",
               "A self-comparison is exactly zero and has no visible histogram bars.");
         Status("invalid: same as chart symbol");
         return false;
        }
      if(!SymbolSelect(_second,true))
        {
         Print("NormalizedCloseDifference: cannot select second symbol ",_second,
               ". Use its exact broker name, including any suffix.");
         return false;
        }
      Status("loading history");
      return _calculation.SetParams(_source_period,_reset,_correlation) && _calculation.Init();
     }

   int Step(const int total,const int previous,const datetime &times[],double &output[],double &colors[])
     {
      if(total<2)
         return 0;
      output[0]=EMPTY_VALUE; // The still-forming chart candle is always blank.
      _cutoff=NormalizedHistoryStart(times[0],_history_days);
      int count=1;
      while(count<total && times[count]>=_cutoff)
         ++count;
      // Scrolling can load thousands of older chart bars and increase
      // rates_total without changing the bounded timeline used here. Do not
      // restart cross-symbol history acquisition for irrelevant old bars.
      bool same_window=(_has_snapshot && times[0]==_last_chart_open &&
                        count==ArraySize(_times) && count>0 &&
                        times[count-1]==_times[count-1]);
      if(same_window)
        {
         // History expansion can reset the platform-owned buffers even though
         // the bounded timeline and its correct values have not changed.
         RestoreSnapshot(times,total,output,colors);
         _last_count=total;
         return total;
        }
      RestoreSnapshot(times,total,output,colors);
      ArrayResize(_times,count);
      ArraySetAsSeries(_times,true);
      for(int i=0;i<count;++i)
         _times[i]=times[i];
      _last_chart_open=times[0];
      _last_count=total;
      _retry=true;
      Refresh(output,colors);
      // Even while loading, register the buffer size with MT5. OnTimer can
      // then publish downloaded history without waiting for a market tick.
      return total;
     }

   bool Refresh(double &output[],double &colors[])
     {
      if(!_retry || ArraySize(_times)<2)
         return false;
      // MT5 allocates indicator buffers asynchronously. Do not clear a valid
      // snapshot merely because a timer fired before allocation completes.
      if(ArraySize(output)<ArraySize(_times) || ArraySize(colors)<ArraySize(_times))
        {
         Status("waiting for indicator buffer");
         return false;
        }
      // The OnCalculate snapshot is the authoritative chart timeline.
      // SERIES_LASTBAR_DATE can lag it while a chart refreshes; rejecting it
      // here caused a permanently blank buffer after attachment. A subsequent
      // OnCalculate replaces this snapshot when the chart advances.
      datetime first_reset=NormalizedResetKey(_times[ArraySize(_times)-1],_reset);
      // Bounded display window plus the reset and two source bars of context.
      datetime from=first_reset-2*PeriodSeconds(_source_period);
      MqlRates chart_rates[],second_rates[];
      ArraySetAsSeries(chart_rates,false);
      ArraySetAsSeries(second_rates,false);
      ResetLastError();
      int count1=CopyRates(_Symbol,_source_period,from,_last_chart_open,chart_rates);
      int error1=(count1<=0 ? GetLastError() : 0);
      ResetLastError();
      int count2=CopyRates(_second,_source_period,from,_last_chart_open,second_rates);
      int error2=(count2<=0 ? GetLastError() : 0);
      if(count1<=0 || count2<=0)
        {
         Status(StringFormat("waiting for history; errors %d/%d",error1,error2));
         return false;
        }
      // Cached matched candles can be plotted while synchronization continues;
      // do not hide every value behind a global SERIES_SYNCHRONIZED gate.
      double candidate[],candidate_colors[];
      ArrayResize(candidate,ArraySize(output));
      ArrayResize(candidate_colors,ArraySize(colors));
      ArraySetAsSeries(candidate,true);
      ArraySetAsSeries(candidate_colors,true);
      int plotted=_calculation.Project(_times,ArraySize(_times),_chart_period,_cutoff,
                                       chart_rates,second_rates,candidate);
      ApplyColors(candidate,candidate_colors);
      bool synced=SeriesInfoInteger(_Symbol,_source_period,SERIES_SYNCHRONIZED) &&
                  SeriesInfoInteger(_second,_source_period,SERIES_SYNCHRONIZED);
      // Once a valid snapshot exists, do not replace it with one of the
      // progressively longer responses returned while either series reloads.
      bool may_publish=(!_has_snapshot || synced);
      bool published=(may_publish &&
                      NormalizedPublishProjection(candidate,candidate_colors,plotted,output,colors));
      if(published)
         CaptureSnapshot(candidate,candidate_colors);
      _retry=(!synced || !published);
      if(!published)
         Status(_has_snapshot ? "waiting; retained" : "no matching closed candles; retrying");
      else if(_second==_Symbol)
         Status("same symbol: difference is zero");
      else
         Status(IntegerToString(plotted)+" bars"+(_retry ? "; awaiting history/close" : ""));
      return published;
     }
  };

CNormalizedDifferenceIndicator Adapter;
string ResolvedSecondSymbol="";
double ResolvedH1Correlation=0.0;
string ResolvedH1Session="";
bool RetryTimerActive=false;
string ResetObjectPrefix="";

color NcdResetColor(const datetime boundary)
  {
   MqlDateTime decoded={};
   if(!TimeToStruct(boundary,decoded))
      return C'82,99,122';
   if(decoded.hour==3)
      return C'88,103,122';
   if(decoded.hour==10)
      return C'69,112,102';
   if(decoded.hour==15)
      return C'118,91,119';
   return C'82,99,122';
  }

void DrawResetPoints(const int total,const datetime &times[])
  {
   // iCustom calculation instances have no visible indicator window. Avoid
   // chart-object work there; only an attached indicator owns reset markers.
   if(total<3 || ResetObjectPrefix=="" || ChartWindowFind()<0)
      return;
   datetime cutoff=NormalizedHistoryStart(times[0],InpHistoryDays);
   for(int object_index=ObjectsTotal(0)-1;object_index>=0;--object_index)
     {
      string object_name=ObjectName(0,object_index);
      if(StringFind(object_name,ResetObjectPrefix)==0 &&
         (datetime)ObjectGetInteger(0,object_name,OBJPROP_TIME)<cutoff)
         ObjectDelete(0,object_name);
     }
   int count=1;
   while(count<total && times[count]>=cutoff)
      ++count;
   datetime previous_key=0;
   for(int i=count-1;i>=1;--i)
     {
      datetime decision=NormalizedBarEnd(times[i],_Period);
      datetime key=NormalizedResetKey(decision-1,InpResetPoint);
      if(key<=0 || key==previous_key)
         continue;
      previous_key=key;
      string name=ResetObjectPrefix+IntegerToString((int)key);
      if(ObjectFind(0,name)>=0 || !ObjectCreate(0,name,OBJ_VLINE,0,key,0.0))
         continue;
      ObjectSetInteger(0,name,OBJPROP_COLOR,NcdResetColor(key));
      ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DOT);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,name,OBJPROP_BACK,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetString(0,name,OBJPROP_TOOLTIP,
                      "NCD normalization reset: "+
                      TimeToString(key,TIME_DATE|TIME_MINUTES));
     }
  }

int OnInit(void)
  {
   SetIndexBuffer(0,DifferenceBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorIndexBuffer,INDICATOR_COLOR_INDEX);
   ArraySetAsSeries(DifferenceBuffer,true);
   ArraySetAsSeries(ColorIndexBuffer,true);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,4);
   IndicatorSetInteger(INDICATOR_DIGITS,4);
   string chart_standard=broker_symbol_to_standard_symbol(_Symbol);
   string resolved_second_asset="";
   if(!NcdResolveSecond(chart_standard,InpSecondAsset,InpResetPoint,resolved_second_asset,
                        ResolvedSecondSymbol,ResolvedH1Correlation,ResolvedH1Session))
     {
      Print("NormalizedCloseDifference: no selected/automatic H1-reference companion is available for ",
            chart_standard,". Add the supported broker symbols to Market Watch.");
      return INIT_PARAMETERS_INCORRECT;
     }
   IndicatorSetString(INDICATOR_SHORTNAME,"NCD r="+DoubleToString(ResolvedH1Correlation,3)+": "+
                      _Symbol+"-"+ResolvedSecondSymbol);
   ResetObjectPrefix="NCD_RESET_"+IntegerToString((int)InpResetPoint)+"_"+
                     ResolvedSecondSymbol+"_";
   Adapter.SetParams(ResolvedSecondSymbol,InpTimeframe,InpResetPoint,ResolvedH1Correlation,
                     ResolvedH1Session,InpHistoryDays);
   if(!Adapter.Init())
      return INIT_PARAMETERS_INCORRECT;
   // In the tester, CopyBuffer requests already drive indicator calculation,
   // so the standalone chart-history retry timer is redundant.
   if(!MQLInfoInteger(MQL_TESTER) && !EventSetTimer(2))
     {
      Print("NormalizedCloseDifference: cannot start history retry timer: ",GetLastError());
      return INIT_FAILED;
     }
   RetryTimerActive=!MQLInfoInteger(MQL_TESTER);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(RetryTimerActive)
      EventKillTimer();
   RetryTimerActive=false;
   if(ResetObjectPrefix!="")
      ObjectsDeleteAll(0,ResetObjectPrefix);
   ResetObjectPrefix="";
   Adapter.Reset();
  }

void OnTimer(void)
  {
   if(Adapter.Refresh(DifferenceBuffer,ColorIndexBuffer))
      ChartRedraw();
  }

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],const double &high[],const double &low[],const double &close[],
                const long &tick_volume[],const long &volume[],const int &spread[])
  {
   ArraySetAsSeries(time,true);
   int result=Adapter.Step(rates_total,prev_calculated,time,DifferenceBuffer,ColorIndexBuffer);
   DrawResetPoints(rates_total,time);
   return result;
  }
