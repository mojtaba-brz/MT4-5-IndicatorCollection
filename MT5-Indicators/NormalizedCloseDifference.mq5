#property strict
#property version "1.21"
#property description "Chart symbol normalized close minus second symbol normalized close."
#property description "Closed candles; broker day/session resets; percentage-point histogram."
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots 1
#property indicator_type1 DRAW_COLOR_HISTOGRAM
#property indicator_color1 C'42,64,88',C'25,40,56',C'128,57,58',C'88,37,39'
#property indicator_width1 3
#property indicator_label1 "Chart minus second (%)"
#property indicator_level1 0.0
#property indicator_levelcolor clrDimGray
#property indicator_levelstyle STYLE_DOT

#include "../Libs/NormalizedCloseDifference.mqh"

input string InpSecondSymbol="GBPUSD_o";                 // Second symbol (exact broker name)
input ENUM_TIMEFRAMES InpTimeframe=PERIOD_CURRENT;        // Current or higher timeframe
input ENUM_NORMALIZED_RESET InpResetPoint=NORMALIZED_DAY_END; // Reset point
input int InpHistoryDays=14;                              // Calendar days to display (including latest chart day)

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
   datetime          _times[];
   datetime          _cutoff;
   bool              _retry;
   string            _status;

   void Status(const string detail)
     {
      if(detail==_status)
         return;
      _status=detail;
      IndicatorSetString(INDICATOR_SHORTNAME,"Normalized close difference: "+_Symbol+" - "+_second+
                         " ("+IntegerToString(_history_days)+"d) ["+detail+"]");
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
                  const ENUM_NORMALIZED_RESET reset,const int history_days=14)
     {
      _second=second;
      _source_period=(requested==PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : requested);
      _chart_period=(ENUM_TIMEFRAMES)_Period;
      _reset=reset;
      _history_days=history_days;
      Reset();
     }

   void Reset(void)
     {
      _last_chart_open=0;
      _last_count=0;
      _cutoff=0;
      _retry=true;
      _status="";
      ArrayResize(_times,0);
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
      return _calculation.SetParams(_source_period,_reset) && _calculation.Init();
     }

   int Step(const int total,const int previous,const datetime &times[],double &output[],double &colors[])
     {
      if(total<2)
         return 0;
      output[0]=EMPTY_VALUE; // The still-forming chart candle is always blank.
      if(previous>0 && total==_last_count && times[0]==_last_chart_open)
         return total;
      ArrayInitialize(output,EMPTY_VALUE);
      ArrayInitialize(colors,0.0);
      _cutoff=NormalizedHistoryStart(times[0],_history_days);
      int count=1;
      while(count<total && times[count]>=_cutoff)
         ++count;
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
         return true;
        }
      // Cached matched candles can be plotted while synchronization continues;
      // do not hide every value behind a global SERIES_SYNCHRONIZED gate.
      int plotted=_calculation.Project(_times,ArraySize(_times),_chart_period,_cutoff,
                                       chart_rates,second_rates,output);
      ApplyColors(output,colors);
      bool synced=SeriesInfoInteger(_Symbol,_source_period,SERIES_SYNCHRONIZED) &&
                  SeriesInfoInteger(_second,_source_period,SERIES_SYNCHRONIZED);
      _retry=(!synced || plotted==0 || output[1]==EMPTY_VALUE ||
              second_rates[count2-1].time<chart_rates[count1-1].time);
      if(plotted==0)
         Status("no matching closed candles; retrying");
      else if(_second==_Symbol)
         Status("same symbol: difference is zero");
      else
         Status(IntegerToString(plotted)+" bars"+(_retry ? "; awaiting history/close" : ""));
      return true;
     }
  };

CNormalizedDifferenceIndicator Adapter;

int OnInit(void)
  {
   SetIndexBuffer(0,DifferenceBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorIndexBuffer,INDICATOR_COLOR_INDEX);
   ArraySetAsSeries(DifferenceBuffer,true);
   ArraySetAsSeries(ColorIndexBuffer,true);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,4);
   IndicatorSetInteger(INDICATOR_DIGITS,4);
   IndicatorSetString(INDICATOR_SHORTNAME,"Normalized close difference: "+_Symbol+" - "+InpSecondSymbol);
   Adapter.SetParams(InpSecondSymbol,InpTimeframe,InpResetPoint,InpHistoryDays);
   if(!Adapter.Init())
      return INIT_PARAMETERS_INCORRECT;
   if(!EventSetTimer(2))
     {
      Print("NormalizedCloseDifference: cannot start history retry timer: ",GetLastError());
      return INIT_FAILED;
     }
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
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
   return Adapter.Step(rates_total,prev_calculated,time,DifferenceBuffer,ColorIndexBuffer);
  }
