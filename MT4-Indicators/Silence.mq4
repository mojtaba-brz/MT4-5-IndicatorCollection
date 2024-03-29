//+---------------------------------------------------------------------+
//|                                                      Silence.mq4    |
//|                                         Copyright © Trofimov 2009   |
//+---------------------------------------------------------------------+
//| Òèøèíà                                                              |
//|                                                                     |
//| Îïèñàíèå: Ïîêàçûâàåò íà ñêîëüêî ïðîöåíòîâ àêòèâåí ðûíîê             |
//| Ñèíÿÿ - ïðîöåíò àãðåññèâíîñòè (ñêîðîñòè èçìåíåíèÿ öåíû)             |
//| Êðàñíàÿ - ïðîöåíò âîëàòèëüíîñòè (âåëè÷èíà êîðèäîðà)                 |
//| Àâòîðñêîå ïðàâî ïðèíàäëåæèò Òðîôèìîâó Åâãåíèþ Âèòàëüåâè÷ó, 2009     |
//+---------------------------------------------------------------------+


#property copyright "Copyright © Trofimov Evgeniy Vitalyevich, 2009"
#property link      "http://TrofimovVBA.narod.ru/"

//---- Ñâîéñòâà èíäèêàòîðà
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 MidnightBlue
#property indicator_width1 1
#property indicator_color2 Maroon
#property indicator_width2 1
#property indicator_maximum 100
#property indicator_minimum 0
#property indicator_level1 50

//---- Âõîäÿùèå ïàðàìåòðû
extern int MyPeriod=12;

int BuffSize=MyPeriod*9;
bool ReDraw=true; //-åñëè âêëþ÷åí, òî ïåðåðèñîâûâàåò íóëåâîé áàð ïðè êàæäîì íîâîì òèêå
// åñëè âûêëþ÷åí, òî íóëåâîé áàð ñîäåðæèò ôèêñèðîâàííîå çíà÷åíèå, âû÷èñëåííîå ïî ïðåäûäóùèì (ãîòîâûì) áàðàì
double Buff_line1[]; // - àãðåññèâíîñòü 
double Buff_line2[]; // - âîëàòèëüíîñòü
double Aggress[], Volatility[];
//+------------------------------------------------------------------+
//|                Ôóíêöèÿ èíèöèàëèçàöèè èíäèêàòîðà                  |
//+------------------------------------------------------------------+
int init()
  {
//---- x äîïîëíèòåëüíûõ áóôåðà, èñïîëüçóåìûõ äëÿ ðàñ÷åòà
   IndicatorBuffers(2);
   IndicatorDigits(2); 
//---- ïàðàìåòðû ðèñîâàíèÿ (óñòàíîâêà íà÷àëüíîãî áàðà)
   SetIndexDrawBegin(0,BuffSize+MyPeriod);
   SetIndexDrawBegin(1,BuffSize+MyPeriod);
//---- x ðàñïðåäåëåííûõ áóôåðà èíäèêàòîðà
   SetIndexBuffer(0,Buff_line1);
   SetIndexBuffer(1,Buff_line2);
//---- èìÿ èíäèêàòîðà è ïîäñêàçêè äëÿ ëèíèé
   IndicatorShortName("Silence("+MyPeriod+","+BuffSize+") = ");
   SetIndexLabel(0,"Aggressiveness");
   SetIndexLabel(1,"Volatility");
   ArrayResize(Aggress,BuffSize);
   ArrayResize(Volatility,BuffSize);
   return(0);
  }
//+------------------------------------------------------------------+
//|                Ôóíêöèÿ èíäèêàòîðà                                |
//+------------------------------------------------------------------+
int start() {
   static datetime LastTime;
   int limit, RD;
   double MAX,MIN;
   double upPrice,downPrice;
   if(ReDraw) RD=1;
   // Ïðîïóùåííûå áàðû
   int counted_bars=IndicatorCounted();
//---- îáõîäèì âîçìîæíûå îøèáêè
   if(counted_bars<0) return(-1);
//---- íîâûå áàðû íå ïîÿâèëèñü è ïîýòîìó íè÷åãî ðèñîâàòü íå íóæíî
   limit=Bars-counted_bars-1+RD;
   
//---- out of range fix
   if(counted_bars==0) limit-=RD+MyPeriod;
   
//---- îñíîâíûå ïåðåìåííûå
   double B;
//---- îñíîâíîé öèêë
   for(int t=limit-RD; t>-RD; t--) {
      
      //Âû÷èñëåíèå àãðåññèâíîñòè áàðà t
      B=0;
      for(int x=t+MyPeriod-1; x>=t; x--) { 
         if(Close[x]>Open[x]) {
            //áåëàÿ ñâå÷à
            B=B+(Close[x]-Close[x+1]);
         }else{
            //÷¸ðíàÿ ñâå÷à
            B=B+(Close[x+1]-Close[x]);
         }
      }//Next x
      
      //Âû÷èñëåíèå âîëàòèëüíîñòè áàðà t
      upPrice=High[iHighest(Symbol(),0,MODE_HIGH,MyPeriod,t)];//ìàêñèìóì çà N áàðîâ 
      downPrice=Low[iLowest(Symbol(),0,MODE_LOW,MyPeriod,t)]; //ìèíèìóì çà N áàðîâ 
      
      //Åñëè îáðàçîâàëñÿ íîâûé áàð, òî ïðîèçâîäèòñÿ ñäâèæêà ìàññèâà
      if(LastTime!=Time[t+1]){
         for(x=BuffSize-1; x>0; x--) {
            Aggress[x]=Aggress[x-1];
            Volatility[x]=Volatility[x-1];
         }//Next x
         LastTime=Time[t+1];
      }
      //Êîíåö ñäâèæêè ìàññèâà
      
      //Ïåðåðèñîâêà àãðåññèâíîñòè
      Aggress[0]=B/Point/MyPeriod;
      MAX=Aggress[ArrayMaximum(Aggress)];
      MIN=Aggress[ArrayMinimum(Aggress)];
      Buff_line1[t]=Èíòåðïîëÿöèÿ(MAX,MIN,100,0,Aggress[0]);
      if(!ReDraw && t==1) Buff_line1[0]=Buff_line1[1];
      //Êîíåö ïåðåðèñîâêà àãðåññèâíîñòè
      
      //Ïåðåðèñîâêà âîëàòèëüíîñòè
      Volatility[0]=(upPrice-downPrice)/Point/MyPeriod;
      MAX=Volatility[ArrayMaximum(Volatility)];
      MIN=Volatility[ArrayMinimum(Volatility)];
      Buff_line2[t]=Èíòåðïîëÿöèÿ(MAX,MIN,100,0,Volatility[0]);
      if(!ReDraw && t==1) Buff_line2[0]=Buff_line2[1];
      //Êîíåö ïåðåðèñîâêà âîëàòèëüíîñòè
      
   }//Next t
   return(0);
}
//+------------------------------------------------------------------+
double Èíòåðïîëÿöèÿ(double a,double b,double c,double d,double X) {
//a; X; b - ñòîëáåö èçâåòíûõ ÷èñåë, c; d; - ñòîëáåö ñî ñòîðîíû íåèçâåñòíîé.
    if(b - a == 0)
        return(10000000); //áåñêîíå÷íîñòü
    else
        return(d - (b - X) * (d - c) / (b - a));
}//Èíòåðïîëÿöèÿ
//+------------------------------------------------------------------+

