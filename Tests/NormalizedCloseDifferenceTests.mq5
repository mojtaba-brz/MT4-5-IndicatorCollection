#property strict
#include "../Libs/NormalizedCloseDifference.mqh"

int Failures=0;

void Expect(const string name,const bool condition)
  {
   if(!condition) { ++Failures; Print("FAIL: ",name); }
  }

MqlRates Candle(const string opened,const double price)
  {
   MqlRates bar={};
   bar.time=StringToTime(opened);
   bar.open=price;
   bar.high=price+1.0;
   bar.low=price-1.0;
   bar.close=price;
   return bar;
  }

double Feed(CNormalizedCloseDifference &state,const string opened,
            const double chart_price,const double second_price)
  {
   MqlRates first=Candle(opened,chart_price);
   MqlRates second=Candle(opened,second_price);
   return state.Step(first,second,first.time+3600);
  }

void OnStart(void)
  {
   Expect("14 calendar days include latest day",
          NormalizedHistoryStart(D'2026.09.04 23:55',14)==D'2026.08.22 00:00');
   Expect("one day starts at latest chart midnight",
          NormalizedHistoryStart(D'2026.09.04 23:55',1)==D'2026.09.04 00:00');
   CNormalizedCloseDifference state;
   Expect("params",state.SetParams(PERIOD_H1,NORMALIZED_DAY_END));
   Expect("init",state.Init());
   Expect("first common close zero",Feed(state,"2026.09.04 00:00",100.0,200.0)==0.0);
   Expect("sym1 minus sym2 percentage points",
          MathAbs(Feed(state,"2026.09.04 01:00",101.0,204.0)+1.0)<1e-10);
   Expect("positive relative movement",
          MathAbs(Feed(state,"2026.09.04 02:00",103.0,202.0)-2.0)<1e-10);
   Expect("positive rising is matte blue",NormalizedDifferenceColorIndex(1.0,0.0,true)==0);
   Expect("positive falling is dark blue",NormalizedDifferenceColorIndex(1.0,2.0,true)==1);
   Expect("negative falling is matte red",NormalizedDifferenceColorIndex(-2.0,-1.0,true)==2);
   Expect("negative rising is dark red",NormalizedDifferenceColorIndex(-1.0,-2.0,true)==3);
   Expect("zero is matte blue",NormalizedDifferenceColorIndex(0.0,1.0,true)==0);
   Expect("first value uses matte sign color",NormalizedDifferenceColorIndex(-1.0,0.0,false)==2);
   Expect("gap reanchors",Feed(state,"2026.09.04 04:00",105.0,220.0)==0.0);
   Expect("new day reanchors",Feed(state,"2026.09.05 00:00",110.0,240.0)==0.0);

   state.SetParams(PERIOD_H1,NORMALIZED_EACH_SESSION);
   state.Init();
   Feed(state,"2026.09.04 08:00",100.0,200.0);
   Expect("close at session boundary finishes old session",
          MathAbs(Feed(state,"2026.09.04 09:00",101.0,204.0)-1.0)<1e-10);
   Expect("first London close reanchors",Feed(state,"2026.09.04 10:00",102.0,205.0)==0.0);
   Expect("London continued",MathAbs(Feed(state,"2026.09.04 11:00",102.0,207.05)-1.0)<1e-10);
   Expect("overnight retains latest session key",
          NormalizedResetKey(StringToTime("2026.09.05 02:00"),NORMALIZED_EACH_SESSION)==
          StringToTime("2026.09.04 15:00"));
   Expect("selected London prior-day key",
          NormalizedResetKey(StringToTime("2026.09.05 09:00"),NORMALIZED_LONDON_START)==
          StringToTime("2026.09.04 10:00"));
   Expect("calendar month close",
          NormalizedBarEnd(StringToTime("2024.02.01"),PERIOD_MN1)==StringToTime("2024.03.01"));

   MqlRates first=Candle("2026.09.04 12:00",102.0);
   MqlRates second=Candle("2026.09.04 12:00",200.0);
   Expect("forming candle rejected",state.Step(first,second,first.time+3599)==EMPTY_VALUE);
   second.time+=60;
   Expect("mismatched timestamp rejected",state.Step(first,second,first.time+3600)==EMPTY_VALUE);
   second=first;
   second.high=1.0;
   Expect("invalid OHLC rejected",state.Step(first,second,first.time+3600)==EMPTY_VALUE);
   state.Reset();
   Expect("explicit reset clears value",state.Value()==EMPTY_VALUE);
   Expect("explicit reset reanchors",Feed(state,"2026.09.04 13:00",100.0,200.0)==0.0);

   MqlRates chart[],other[];
   datetime times[];
   double output[];
   ArrayResize(chart,3);
   ArrayResize(other,3);
   ArrayResize(times,8);
   ArrayResize(output,8);
   ArraySetAsSeries(times,true);
   ArraySetAsSeries(output,true);
   for(int i=0;i<3;++i)
     {
      chart[i]=Candle("2026.09.04 00:00",100.0+i);
      chart[i].time+=i*3600;
      other[i]=Candle("2026.09.04 00:00",200.0+4*i);
      other[i].time=chart[i].time;
     }
   for(int i=0;i<8;++i)
      times[i]=D'2026.09.04 03:30'-i*1800;
   state.SetParams(PERIOD_H1,NORMALIZED_DAY_END);
   state.Init();
   int plotted=state.Project(times,8,PERIOD_M30,D'2026.09.04 00:00',chart,other,output);
   Expect("HTF projects six completed values",plotted==6);
   Expect("forming chart bar blank",output[0]==EMPTY_VALUE);
   Expect("before first HTF close blank",output[7]==EMPTY_VALUE);
   Expect("first HTF close zero",output[6]==0.0);
   Expect("HTF close not backpainted",output[5]==0.0);
   Expect("second HTF close is nonzero",MathAbs(output[4]+1.0)<1e-10);
   Expect("HTF value held causally",MathAbs(output[3]+1.0)<1e-10);

   state.Project(times,8,PERIOD_M30,D'2026.09.04 02:00',chart,other,output);
   Expect("before display cutoff blank",output[4]==EMPTY_VALUE);
   Expect("display cutoff preserves earlier anchor",MathAbs(output[3]+1.0)<1e-10);
   Expect("last completed value",MathAbs(output[1]+2.0)<1e-10);

   // An asynchronous first request has no candles. The same snapshot can be
   // replayed after history arrives, without any new chart tick/bar.
   ArrayResize(other,0);
   Expect("unavailable second history produces no values",
          state.Project(times,8,PERIOD_M30,D'2026.09.04',chart,other,output)==0);
   ArrayResize(other,3);
   for(int i=0;i<3;++i)
     {
      other[i]=chart[i];
      other[i].close=200.0+4*i;
      other[i].open=other[i].close;
      other[i].low=other[i].close-1;
      other[i].high=other[i].close+1;
     }
   Expect("same snapshot recovers after history arrival",
          state.Project(times,8,PERIOD_M30,D'2026.09.04',chart,other,output)==6);
   Expect("recovered value nonzero",MathAbs(output[4]+1.0)<1e-10);
   // Remove the middle second-symbol candle. Do not hold the older source
   // value past its next due close or bridge the missing candle with returns.
   other[1]=other[2];
   ArrayResize(other,2);
   state.Project(times,8,PERIOD_M30,D'2026.09.04',chart,other,output);
   Expect("missing pair blank",output[4]==EMPTY_VALUE);
   Expect("missing pair not forward filled",output[3]==EMPTY_VALUE);
   Expect("first matched candle after gap reanchors",output[2]==0.0);
   PrintFormat("NormalizedCloseDifferenceTests: %d failures",Failures);
  }
