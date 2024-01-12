
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Orange
 double     akk_range=100;
 double     ima_range = 1;
input int config_param = 60;
double     akk_factor= config_param/10.;

 int        Mode = 0;
 double     DeltaPrice = 30;

double TrStop[],STOOP;
double ATR[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {


   SetIndexStyle(0, DRAW_LINE,STYLE_SOLID,5);
   SetIndexBuffer(0, TrStop);

   SetIndexStyle(1, DRAW_NONE);
   SetIndexBuffer(1, ATR);

   string short_name = "TREND";
   IndicatorShortName(short_name);
   SetIndexLabel(1,"AKKAM");


   
//----
   return(0);
  }
  

  

//----

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
 
  
   int counted_bars = IndicatorCounted();
   int limit;
   int i;

   double DeltaStop;
   
   limit = Bars;

   for(i = 0; i < limit; i ++) {
      ATR[i] = iATR(NULL,0,akk_range,i);
   }

   for(i = limit - 1; i >= 0; i --) {
      if (Mode == 0) {
         DeltaStop = iMAOnArray(ATR,0,ima_range,0,MODE_EMA,i) * akk_factor;
      } else {
         DeltaStop = DeltaPrice*Point;
      }

      if (Open[i] == TrStop[i + 1]) {
         TrStop[i] = TrStop[i + 1];
      } else {
         if (Open[i+1]<TrStop[i+1] && Open[i]<TrStop[i+1]) {
            TrStop[i] = MathMin(TrStop[i + 1], Open[i] + DeltaStop);
         } else {
            if (Open[i+1]>TrStop[i+1] && Open[i]>TrStop[i+1]) {
               TrStop[i] = MathMax(TrStop[i+1], Open[i] - DeltaStop);         
            } else {
               if (Open[i] > TrStop[i+1]) TrStop[i] = Open[i] - DeltaStop; else TrStop[i] = Open[i] + DeltaStop;
            }
         }
      }
   }
   



akkam("Panel_DMRAT2",1,20,21,"TREND AKKAM",15,"",Lime);


   return(0);
  }
  
  
  
  
  
//+------------------------------------------------------------------+


  void 
  akkam(string a_name_0, double a_corner_8, int a_y_16, int a_x_20, string a_text_24, int a_fontsize_32, string a_fontname_36, color a_color_44) {
   ObjectCreate(a_name_0, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(a_name_0, a_text_24, a_fontsize_32, a_fontname_36, a_color_44);
   ObjectSet(a_name_0, OBJPROP_CORNER, a_corner_8);
   ObjectSet(a_name_0, OBJPROP_XDISTANCE, a_x_20);
   ObjectSet(a_name_0, OBJPROP_YDISTANCE, a_y_16);
 } 
 