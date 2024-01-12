//+------------------------------------------------------------------+
//|                                                   FantailVMA.mq5 |
//+------------------------------------------------------------------+
#property copyright   "2007, www.forex-tsd"
#property link        "http://www.forex-tsd.com"
#property description "FantailVMA"
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  Red
#property indicator_width1  2

//--- input parameters
input int MA_Length    =  1; // Period of MA 

input int VarMA_Length =  4; // Period of VarMA 
input int ADX_Length   =  8; // Period of ADX

double dSmoothFactor;
//--- indicator buffers
double MA[];
double VarMA[];
double VMA[];
double ADX[];
double sPDI[];
double sMDI[];
double STR[];
//--- global variable

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input
   dSmoothFactor=2.0/(1.0+MA_Length);

//--- indicator buffers mapping
   SetIndexBuffer(0,MA,INDICATOR_DATA);
   SetIndexBuffer(1,VarMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,VMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ADX,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,sPDI,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,sMDI,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,STR,INDICATOR_CALCULATIONS);

//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ADX_Length);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"FantailVMA");
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Relative Strength Index                                          |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,      // ������ ������� ���������
                 const int prev_calculated,  // ���������� ����� �� ���������� ������
                 const datetime& time[],     // Time
                 const double& open[],       // Open
                 const double& high[],       // High
                 const double& low[],        // Low
                 const double& close[],      // Close
                 const long& tick_volume[],  // Tick Volume
                 const long& volume[],       // Real Volume
                 const int& spread[])        // Spread
  {
   int i;

   int pos=prev_calculated;
   int shift,counted_bars=rates_total;

   double alfa=1.0/ADX_Length;

   if(pos==rates_total) pos-=2;

   for(shift=pos+1; shift<rates_total; shift++)
     {

      double Hi  = high[shift];
      double Hi1 = high[shift-1];
      double Lo  = low[shift];
      double Lo1 = low[shift-1];
      double Close1=close[shift-1];

      double Bulls = 0.5*(MathAbs(Hi-Hi1)+(Hi-Hi1));
      double Bears = 0.5*(MathAbs(Lo1-Lo)+(Lo1-Lo));

      if(Bulls>Bears) Bears=0;
      else
         if(Bulls<Bears) Bulls=0;
      else
      if(Bulls==Bears) {Bulls=0;Bears=0;}

      sPDI[shift] = sPDI[shift-1] + alfa * (Bulls - sPDI[shift-1]);
      sMDI[shift] = sMDI[shift-1] + alfa * (Bears - sMDI[shift-1]);

      double   TR = MathMax(Hi-Lo,Hi-Close1);
      STR[shift]  = STR[shift-1] + alfa * (TR - STR[shift-1]);

      double PDI=0,MDI=0,DX,MaInd,Const;

      if(STR[shift]>0)
        {
         PDI = 100*sPDI[shift]/STR[shift];
         MDI = 100*sMDI[shift]/STR[shift];
        }

      if((PDI+MDI)>0)
         DX=100*MathAbs(PDI-MDI)/(PDI+MDI);
      else DX=0;

      ADX[shift]=ADX[shift-1]+alfa *(DX-ADX[shift-1]);

      double vADX=ADX[shift];

      if(VarMA_Length>0) MaInd=2.0/(1.0+VarMA_Length); else MaInd=0.2;

      double ADXmin = ADX[shift];
      double ADXmax = ADX[shift];

      for(i=0; i<=ADX_Length-1;i++)
        {
         if((shift-i)<0) break;
         if(ADXmin>ADX[shift-i]) ADXmin=ADX[shift-i];
         if(ADXmax<ADX[shift-i]) ADXmax=ADX[shift-i];
        }

      double Diff=ADXmax-ADXmin;
      if(Diff>0) Const=(vADX-ADXmin)/Diff; else Const=MaInd;
      if(Const>MaInd) Const=MaInd; else Const=Const;

      VarMA[shift]=((2-Const)*VarMA[shift-1]+Const*close[shift])/2;

     }

   for(i=pos+1;i<rates_total;i++)
      MA[i]=VarMA[i]*dSmoothFactor+MA[i-1]*(1.0-dSmoothFactor);

   return(rates_total);

  }
//+------------------------------------------------------------------+
