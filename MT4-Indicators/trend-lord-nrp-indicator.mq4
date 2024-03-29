//+------------------------------------------------------------------+
//|                                                   Trend_Lord.mq4 |
//|                               Copyright © 2015, Gehtsoft USA LLC |
//|                                            http://fxcodebase.com |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
//------
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1  clrCornflowerBlue  //Green
#property indicator_color2  clrSalmon  //Red
//------
#property indicator_width1  2
#property indicator_width2  2
//------
#property indicator_style1  STYLE_DOT
#property indicator_style2  STYLE_DOT
//------
extern int                Length  =  12;  //45;  //50;

extern ENUM_MA_METHOD       Mode  =  MODE_SMMA;  //MODE_LWMA;
extern ENUM_APPLIED_PRICE  Price  =  PRICE_CLOSE;    // Applied price
extern bool          ShowHighLow  =  false;
extern int             SIGNALBAR  =  1;   //На каком баре сигналить....
extern bool        AlertsMessage  =  true,   //false,    
                     AlertsSound  =  true,   //false,
                     AlertsEmail  =  false,
                    AlertsMobile  =  false;                       
extern string          SoundFile  =  "alert2.wav";   //"news.wav";   //"expert.wav";  //   //"stops.wav"   //"alert2.wav"   //
                       
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
double BUYY[], SELL[];   datetime TimeBar=0;  
double Array1[], MA[];   int SqLength;
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
int init()
{
   Length = fmax(Length,1);   
   SqLength=MathSqrt(Length);
   IndicatorShortName("Trend Lord TT ["+(string)Length+">"+(string)SqLength+"]");
   SetIndexLabel(0,stringMTF(_Period)+":  BUY   "+StringSubstr(EnumToString(Mode),5)+" ["+(string)Length+">"+(string)SqLength+"]");
   SetIndexLabel(1,stringMTF(_Period)+":  SELL  "+StringSubstr(EnumToString(Mode),5)+" ["+(string)Length+">"+(string)SqLength+"]");
  	IndicatorBuffers(4);   IndicatorDigits(Digits);   //if (Digits==3 || Digits==5) IndicatorDigits(Digits-1);
   SetIndexBuffer(0,BUYY);  SetIndexDrawBegin(0,Length+SqLength);
   SetIndexBuffer(1,SELL);  SetIndexDrawBegin(1,Length+SqLength);
   SetIndexBuffer(2,Array1);
   SetIndexBuffer(3,MA);
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexStyle(2,DRAW_NONE);
   SetIndexStyle(3,DRAW_NONE);
//------
return(0);
}
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
int deinit() { return(0); }
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
int start()
{
   int i, CountedBars=IndicatorCounted();   
   if (CountedBars<0) return(-1);       //Стандарт+Tankk-Вариант!!!
   if (CountedBars>0) CountedBars--;
   int limit=fmin(Bars-CountedBars,Bars-2);  //+MAX*10*TFK
   //---
   for (i=limit; i>=0; i--)  MA[i]=iMA(NULL, 0, Length, 0, Mode, Price, i);
   //---
   for (i=limit; i>=0; i--)
    {
     Array1[i]=iMAOnArray(MA, Bars, SqLength, 0, Mode, i);
     //---
     double slotLL = (ShowHighLow) ? Low[i] : MA[i];    ///можно сделать и fmax(Array1[i],Low[i])....
     double slotHH = (ShowHighLow) ? High[i] : MA[i];
     //---
     if (Array1[i] > Array1[i+1]) { BUYY[i]=slotLL;  SELL[i]=Array1[i]; }
     if (Array1[i] < Array1[i+1]) { BUYY[i]=slotHH;  SELL[i]=Array1[i]; }
    } 
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   if (AlertsMessage || AlertsEmail || AlertsMobile || AlertsSound) 
    {  ///CCI w Haos [MK]  —  
     string messageUP = WindowExpertName()+":  "+_Symbol+", "+stringMTF(_Period)+"  >> Trend changed to BUY";   ///Arrow UP >> BUY";   ///+"  >>  Fast above Slow  >>  BUY";
     string messageDN = WindowExpertName()+":  "+_Symbol+", "+stringMTF(_Period)+"  << Trend changed to SELL";   ///Arrow DN << SELL";   ///+"  <<  Fast below Slow  <<  SELL";
   //------
     if (TimeBar!=Time[0] &&  (Array1[SIGNALBAR] > Array1[1+SIGNALBAR] && Array1[1+SIGNALBAR] <= Array1[2+SIGNALBAR])) {    ////(MAIN[SGB] > FINSIG[SGB] && MAIN[SGB+1] <= FINSIG[SGB+1])) {   
         if (AlertsMessage) Alert(messageUP);  
         if (AlertsEmail)   SendMail(_Symbol,messageUP);  
         if (AlertsMobile)  SendNotification(messageUP);  
         if (AlertsSound)   PlaySound(SoundFile);   //"stops.wav"   //"news.wav"   //"alert2.wav"  //"expert.wav"  
         TimeBar=Time[0]; } //return(0);
   //------
     else 
     if (TimeBar!=Time[0] &&  (Array1[SIGNALBAR] < Array1[1+SIGNALBAR] && Array1[1+SIGNALBAR] >= Array1[2+SIGNALBAR])) {    ////(MAIN[SGB] < FINSIG[SGB] && MAIN[SGB+1] >= FINSIG[SGB+1])) {   
         if (AlertsMessage) Alert(messageDN);  
         if (AlertsEmail)   SendMail(_Symbol,messageDN);
         if (AlertsMobile)  SendNotification(messageDN);  
         if (AlertsSound)   PlaySound(SoundFile);   //"stops.wav"   //"news.wav"   //"alert2.wav"  //"expert.wav"                
         TimeBar=Time[0]; } //return(0); 
    } //*конец* Алертов    
//------
return(0);
}
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%                            iMAX AA MTF TT                            %%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
string stringMTF(int perMTF)
{  
   if (perMTF==0)      perMTF=_Period;
   if (perMTF==1)      return("M1");
   if (perMTF==5)      return("M5");
   if (perMTF==15)     return("M15");
   if (perMTF==30)     return("M30");
   if (perMTF==60)     return("H1");
   if (perMTF==240)    return("H4");
   if (perMTF==1440)   return("D1");
   if (perMTF==10080)  return("W1");
   if (perMTF==43200)  return("MN1");
   if (perMTF== 2 || 3  || 4  || 6  || 7  || 8  || 9 ||       /// нестандартные периоды для грфиков Renko
               10 || 11 || 12 || 13 || 14 || 16 || 17 || 18)  return("M"+(string)_Period);
//------
   return("Ошибка периода");
}
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%                            iMAX AA MTF TT                            %%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%