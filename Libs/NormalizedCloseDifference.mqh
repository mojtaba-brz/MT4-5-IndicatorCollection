#ifndef NORMALIZED_CLOSE_DIFFERENCE_MQH
#define NORMALIZED_CLOSE_DIFFERENCE_MQH

enum ENUM_NORMALIZED_RESET
  {
   NORMALIZED_DAY_END=0,             // End of broker day (00:00)
   NORMALIZED_EACH_SESSION=1,        // Every session start (03:00, 10:00, 15:00)
   NORMALIZED_ASIA_START=2,          // Selected session: Asia (03:00)
   NORMALIZED_LONDON_START=3,        // Selected session: London (10:00)
   NORMALIZED_NEW_YORK_START=4       // Selected session: New York (15:00)
  };

// Stable iCustom input contract shared by the indicator and EA consumers.
enum ENUM_NCD_SECOND_ASSET
  {
   NCD_AUTO_STRONGEST_H1=0,  // Auto: strongest available absolute H1 correlation
   NCD_EURUSD,               // EURUSD
   NCD_USDJPY,               // USDJPY
   NCD_GBPUSD,               // GBPUSD
   NCD_USDCHF,               // USDCHF
   NCD_USDCAD,               // USDCAD
   NCD_AUDUSD,               // AUDUSD
   NCD_NZDUSD,               // NZDUSD
   NCD_WTI,                  // WTI
   NCD_GOLD,                 // GOLD
   NCD_SILVER,               // SILVER
   NCD_DXY                   // DXY
  };

// Broker wall-clock boundaries match the session-correlation research. This
// indicator repository is standalone and does not depend on the parent EA.
datetime NormalizedResetKey(const datetime stamp,const ENUM_NORMALIZED_RESET mode)
  {
   MqlDateTime decoded={};
   if(!TimeToStruct(stamp,decoded))
      return 0;
   int seconds=decoded.hour*3600+decoded.min*60+decoded.sec;
   datetime midnight=stamp-seconds;
   if(mode==NORMALIZED_DAY_END)
      return midnight;
   int start_hour=3;
   if(mode==NORMALIZED_LONDON_START)
      start_hour=10;
   if(mode==NORMALIZED_NEW_YORK_START)
      start_hour=15;
   if(mode==NORMALIZED_EACH_SESSION)
     {
      if(seconds>=15*3600) return midnight+15*3600;
      if(seconds>=10*3600) return midnight+10*3600;
      if(seconds>=3*3600) return midnight+3*3600;
      return midnight-86400+15*3600;
     }
   datetime boundary=midnight+start_hour*3600;
   return (stamp>=boundary ? boundary : boundary-86400);
  }

datetime NormalizedBarEnd(const datetime opened,const ENUM_TIMEFRAMES timeframe)
  {
   if(timeframe!=PERIOD_MN1)
      return opened+PeriodSeconds(timeframe);
   MqlDateTime decoded={};
   if(!TimeToStruct(opened,decoded))
      return 0;
   ++decoded.mon;
   if(decoded.mon==13)
     {
      decoded.mon=1;
      ++decoded.year;
     }
   decoded.day=1;
   return StructToTime(decoded);
  }

// Calendar days including the latest chart day, not workstation wall time.
// This also works on a disconnected/weekend chart showing cached candles.
datetime NormalizedHistoryStart(const datetime latest,const int days)
  {
   if(days<1)
      return latest;
   return (datetime)((long)NormalizedResetKey(latest,NORMALIZED_DAY_END)-
                     (long)(days-1)*86400);
  }

bool NormalizedCandleValid(const MqlRates &bar)
  {
   return MathIsValidNumber(bar.open) && MathIsValidNumber(bar.high) &&
          MathIsValidNumber(bar.low) && MathIsValidNumber(bar.close) &&
          bar.low>0.0 && bar.high>=MathMax(bar.open,bar.close) &&
          bar.low<=MathMin(bar.open,bar.close) && bar.high>=bar.low;
  }

// Color indexes for the separate-window histogram. The sign determines the
// hue; movement toward zero is deliberately darker, because the advantage is
// weakening even though the output has not crossed zero yet.
int NormalizedDifferenceColorIndex(const double value,const double previous_value,
                                   const bool has_previous)
  {
   if(value>=0.0)
      return (has_previous && value<previous_value ? 1 : 0); // blue, dark blue
   return (has_previous && value>previous_value ? 3 : 2);    // red, dark red
  }

// Publish a recalculated series atomically. An asynchronous CopyRates refresh
// can temporarily produce no latest closed value; in that case the caller's
// last valid buffers must remain untouched instead of blinking blank.
bool NormalizedPublishProjection(const double &candidate[],const double &candidate_colors[],
                                 const int plotted,double &output[],double &colors[])
  {
   int count=ArraySize(candidate);
   if(plotted<=0 || count<2 || candidate[1]==EMPTY_VALUE ||
      ArraySize(candidate_colors)!=count || ArraySize(output)<count ||
      ArraySize(colors)<count)
      return false;
   for(int i=0;i<count;++i)
     {
      output[i]=candidate[i];
      colors[i]=candidate_colors[i];
     }
   return true;
  }

// Restore an owned snapshot by timestamp after MT5 reallocates/clears indicator
// buffers while extending chart history. All time arrays are newest-first.
int NormalizedRestoreSnapshot(const datetime &snapshot_times[],
                              const double &snapshot_values[],
                              const double &snapshot_colors[],
                              const datetime &current_times[],const int current_total,
                              double &output[],double &colors[])
  {
   ArrayInitialize(output,EMPTY_VALUE);
   ArrayInitialize(colors,0.0);
   int saved=ArraySize(snapshot_times);
   if(saved<=0 || ArraySize(snapshot_values)!=saved ||
      ArraySize(snapshot_colors)!=saved || current_total<=0)
      return 0;
   int current=0,snapshot=0,restored=0;
   while(current<current_total && snapshot<saved)
     {
      if(current_times[current]==snapshot_times[snapshot])
        {
         output[current]=snapshot_values[snapshot];
         colors[current]=snapshot_colors[snapshot];
         ++current;
         ++snapshot;
         ++restored;
        }
      else if(current_times[current]>snapshot_times[snapshot])
         ++current;
      else
         ++snapshot;
     }
   if(current_total>0)
      output[0]=EMPTY_VALUE;
   return restored;
  }

// One instance owns both anchor closes and the sequential stream. Step accepts
// completed, timestamp-matched OHLC candles; only their closes enter the
// explicitly close-only formula. It is always sym1 minus sym2 (the chart
// symbol's normalized close minus the second symbol's normalized close).
// Normalized units are percentage points.
class CNormalizedCloseDifference
  {
private:
   ENUM_TIMEFRAMES    _timeframe;
   ENUM_NORMALIZED_RESET _mode;
   bool              _initialized;
   bool              _anchored;
   datetime          _last_open;
   datetime          _last_end;
   datetime          _reset_key;
   double            _chart_anchor;
   double            _second_anchor;
   double            _correlation_sign;
   double            _value;

public:
                     CNormalizedCloseDifference(void)
     {
      _initialized=false;
      _timeframe=PERIOD_CURRENT;
      _mode=NORMALIZED_DAY_END;
      _correlation_sign=1.0;
      Reset();
     }

   bool SetParams(const ENUM_TIMEFRAMES timeframe,const ENUM_NORMALIZED_RESET mode,
                  const double correlation=1.0)
     {
      _initialized=false;
      Reset();
      if(timeframe==PERIOD_CURRENT || PeriodSeconds(timeframe)<=0 ||
         mode<NORMALIZED_DAY_END || mode>NORMALIZED_NEW_YORK_START ||
         !MathIsValidNumber(correlation))
         return false;
      _timeframe=timeframe;
      _mode=mode;
      // A negative reference correlation denotes an inverse companion. Keep
      // the displayed meaning consistent: positive still means the chart
      // symbol is stronger than its correlation-adjusted companion.
      _correlation_sign=(correlation<0.0 ? -1.0 : 1.0);
      return true;
     }

   bool Init(void)
     {
      Reset();
      _initialized=(_timeframe!=PERIOD_CURRENT && PeriodSeconds(_timeframe)>0);
      return _initialized;
     }

   void Reset(void)
     {
      _anchored=false;
      _last_open=0;
      _last_end=0;
      _reset_key=0;
      _chart_anchor=0.0;
      _second_anchor=0.0;
      _value=EMPTY_VALUE;
     }

   double Step(const MqlRates &chart_bar,const MqlRates &second_bar,
               const datetime available_at)
     {
      if(!_initialized)
         return EMPTY_VALUE;
      datetime closed=NormalizedBarEnd(chart_bar.time,_timeframe);
      if(chart_bar.time!=second_bar.time || closed>available_at ||
         !NormalizedCandleValid(chart_bar) || !NormalizedCandleValid(second_bar))
        {
         Reset();
         return EMPTY_VALUE;
        }
      if(_anchored && chart_bar.time==_last_open)
         return _value;
      // A close exactly at a boundary ends the preceding period. Its next
      // candle belongs to the new period; no old-period value is carried in.
      datetime key=NormalizedResetKey(closed-1,_mode);
      if(!_anchored || chart_bar.time!=_last_end || key!=_reset_key)
        {
         _chart_anchor=chart_bar.close;
         _second_anchor=second_bar.close;
         _reset_key=key;
         _anchored=true;
        }
      _last_open=chart_bar.time;
      _last_end=closed;
      _value=_correlation_sign*100.0*(chart_bar.close/_chart_anchor-
                                       second_bar.close/_second_anchor);
      return _value;
     }

   double Value(void) const { return _value; }

   // Deterministic projection shared by the live adapter and regression tests.
   // times/output are series arrays; OHLC arrays are chronological. Source
   // context before cutoff is consumed for anchoring but is never displayed.
   int Project(const datetime &times[],const int total,const ENUM_TIMEFRAMES chart_period,
               const datetime cutoff,const MqlRates &first[],const MqlRates &second[],
               double &output[])
     {
      Reset();
      ArrayInitialize(output,EMPTY_VALUE);
      int source_index=0,second_index=0,plotted=0;
      double latest=EMPTY_VALUE;
      datetime latest_end=0,latest_key=0;
      for(int chart_index=total-1;chart_index>=1;--chart_index)
        {
         datetime decision=NormalizedBarEnd(times[chart_index],chart_period);
         while(source_index<ArraySize(first) &&
               NormalizedBarEnd(first[source_index].time,_timeframe)<=decision)
           {
            datetime target=first[source_index].time;
            while(second_index<ArraySize(second) && second[second_index].time<target)
               ++second_index;
            latest=EMPTY_VALUE;
            latest_end=NormalizedBarEnd(target,_timeframe);
            if(second_index<ArraySize(second) && second[second_index].time==target)
              {
               latest=Step(first[source_index],second[second_index],decision);
               latest_key=ResetKey();
              }
            else
               Reset();
            ++source_index;
           }
         if(times[chart_index]<cutoff)
            continue; // Source context was consumed, but is not displayed.
         datetime key=NormalizedResetKey(decision-1,_mode);
         datetime next_due=NormalizedBarEnd(latest_end,_timeframe);
         if(latest!=EMPTY_VALUE && latest_key==key && decision<next_due)
           {
            output[chart_index]=latest;
            ++plotted;
           }
        }
      if(total>0)
         output[0]=EMPTY_VALUE;
      return plotted;
     }

   datetime ResetKey(void) const { return _reset_key; }
   datetime LastEnd(void) const { return _last_end; }
   double ChartAnchor(void) const { return _chart_anchor; }
   double SecondAnchor(void) const { return _second_anchor; }
   double CorrelationSign(void) const { return _correlation_sign; }
  };
#endif
