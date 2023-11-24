// More information about this indicator can be found at:
// https://fxcodebase.com/code/viewtopic.php?f=38&t=73873 

//+------------------------------------------------------------------------------------------------+
//|                                                            Copyright © 2023, Gehtsoft USA LLC  | 
//|                                                                         http://fxcodebase.com  |
//+------------------------------------------------------------------------------------------------+
//|                                                                   Developed by : Mario Jemic   |                    
//|                                                                       mario.jemic@gmail.com    |
//|                                                        https://AppliedMachineLearning.systems  |
//|                                                                       https://mario-jemic.com/ |
//+------------------------------------------------------------------------------------------------+

//+------------------------------------------------------------------------------------------------+
//|                                           Our work would not be possible without your support. |
//+------------------------------------------------------------------------------------------------+
//|                                                               Paypal: https://goo.gl/9Rj74e    |
//|                                                             Patreon :  https://goo.gl/GdXWeN   |  
//+------------------------------------------------------------------------------------------------+


#property copyright "Copyright © 2023, Gehtsoft USA LLC"
#property link      "http://fxcodebase.com"
#property version "1.0"
#property strict
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots 2
#property indicator_label1 "Line Up"
#property indicator_type1  DRAW_LINE
#property indicator_color1 clrBlue
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1
#property indicator_label2 "Line Down"
#property indicator_type2  DRAW_LINE
#property indicator_color2 clrRed
#property indicator_style2 STYLE_SOLID
#property indicator_width2 1

//--- indicator buffers
double Data [];
double LineUp [];
double LineDn [];
double Max [];
double Min [];

// ------------------------------------------------------------------
input int period_high = 100; // HHV:
input int period_lows = 100; // LLV:

string T1 = "== Notifications ==";  // ————————————
bool   notifications = false;                  // Notifications On?
bool   desktop_notifications = false;                  // Desktop MT4 Notifications
bool   email_notifications = false;                  // Email Notifications
bool   push_notifications = false;                  // Push Mobile Notifications
input string T2 = "== Set Lines ==";      // ————————————
input color  LineUpClr = clrBlue;                // Line Up Color:
input color  LineDnClr = clrRed;                 // Line Down Color:
// ------------------------------------------------------------------

class CNewCandle
{
    private:
    int    _initialCandles;
    string _symbol;
    int    _tf;

    public:
    CNewCandle(string symbol, int tf) : _symbol(symbol), _tf(tf), _initialCandles(iBars(symbol, tf)) {}
    CNewCandle()
    {
        // toma los valores del chart actual
        _initialCandles = iBars(Symbol(), Period());
        _symbol = Symbol();
        _tf = Period();
    }
    ~CNewCandle() { ; }

    bool IsNewCandle()
    {
        int _currentCandles = iBars(_symbol, _tf);
        if(_currentCandles > _initialCandles)
        {
            _initialCandles = _currentCandles;
            return true;
        }

        return false;
    }
};
CNewCandle newCandle();

// ------------------------------------------------------------------
int OnInit()
{
    //--- indicator buffers mapping
    int b = 0;
    SetIndexBuffer(b, LineUp, INDICATOR_DATA);
    SetIndexStyle(b, DRAW_LINE, EMPTY, 2, LineUpClr);
    b = 1;
    SetIndexBuffer(b, LineDn, INDICATOR_DATA);
    SetIndexStyle(b, DRAW_LINE, EMPTY, 2, LineDnClr);
    b = 2;
    SetIndexBuffer(b, Data, INDICATOR_DATA);
    SetIndexStyle(b, DRAW_NONE);
    b = 3;
    SetIndexBuffer(b, Max, INDICATOR_DATA);
    SetIndexStyle(b, DRAW_NONE);
    b = 4;
    SetIndexBuffer(b, Min, INDICATOR_DATA);
    SetIndexStyle(b, DRAW_NONE);

    //---
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}
// ------------------------------------------------------------------

int OnCalculate(const int       rates_total,
                const int       prev_calculated,
                const datetime& time [],
                const double& open [],
                const double& high [],
                const double& low [],
                const double& close [],
                const long& tick_volume [],
                const long& volume [],
                const int& spread [])
{
    int start, i;
    int periods = fmax(period_lows, period_high);
    if(prev_calculated == 0) { start = rates_total - periods; }
    else { start = rates_total - (prev_calculated - 1); }

    for(i = start; i >= 0; i--)
    {

        double min = 0;
        double max = 0;

        for(int j = 0; j < period_lows; j++)
        {
            if(min == 0 || Low[i + j] < min)
                min = Low[i + j];
        }

        for(int j = 0; j < period_high; j++)
        {
            if(max == 0 || High[i + j] > max)
                max = High[i + j];
        }

        Data[i] = Data[i + 1];
        Max[i] = max;
        Min[i] = min;

        if(isGoingUp(i)) // cierre > data
        {
            LineUp[i] = Min[i];
            Data[i] = LineUp[i];
            LineDn[i]=EMPTY_VALUE;

        }


        if(isGoingDown(i))
        {
            LineDn[i] = Max[i];
            Data[i] = LineDn[i];
            LineUp[i]=EMPTY_VALUE;

        }

    }
    return (rates_total);
}

// ------------------------------------------------------------------

bool isGoingUp(int i)
{
    return iClose(NULL, 0, i) > Data[i + 1];
}

bool isGoingDown(int i)
{
    return iClose(NULL, 0, i) < Data[i + 1];
}



void Notifications(int type)
{
    string text = "";
    if(type == 0)
        text += _Symbol + " " + GetTimeFrame(_Period) + " BUY ";
    else
        text += _Symbol + " " + GetTimeFrame(_Period) + " SELL ";

    text += " ";

    if(!notifications) return;
    if(desktop_notifications) Alert(text);
    if(push_notifications)    SendNotification(text);
    if(email_notifications)   SendMail("MetaTrader Notification", text);
}

string GetTimeFrame(int lPeriod)
{
    switch(lPeriod)
    {
        case PERIOD_M1:
            return ("M1");
        case PERIOD_M5:
            return ("M5");
        case PERIOD_M15:
            return ("M15");
        case PERIOD_M30:
            return ("M30");
        case PERIOD_H1:
            return ("H1");
        case PERIOD_H4:
            return ("H4");
        case PERIOD_D1:
            return ("D1");
        case PERIOD_W1:
            return ("W1");
        case PERIOD_MN1:
            return ("MN1");
    }
    return IntegerToString(lPeriod);
}


// MULTITIMEFRAME:
// te dá la correspondencia de la vela en tf inferior con la vela de tf superior:
// int i_TFsup = iBarShift(NULL, TFsup, time[i],false);

// ------------------------------------------------------------------

//+------------------------------------------------------------------------------------------------+
//|                                                                    We appreciate your support. | 
//+------------------------------------------------------------------------------------------------+
//|                                                               Paypal: https://goo.gl/9Rj74e    |
//|                                                             Patreon :  https://goo.gl/GdXWeN   |  
//+------------------------------------------------------------------------------------------------+
//|                                                                   Developed by : Mario Jemic   |                    
//|                                                                       mario.jemic@gmail.com    |
//|                                                        https://AppliedMachineLearning.systems  |
//|                                                                       https://mario-jemic.com/ |
//+------------------------------------------------------------------------------------------------+

//+------------------------------------------------------------------------------------------------+
//|BitCoin                    : 15VCJTLaz12Amr7adHSBtL9v8XomURo9RF                                 |  
//|Ethereum                   : 0x8C110cD61538fb6d7A2B47858F0c0AaBd663068D                         |  
//|SOL Address                : 4tJXw7JfwF3KUPSzrTm1CoVq6Xu4hYd1vLk3VF2mjMYh                       |
//|Cardano/ADA                : addr1v868jza77crzdc87khzpppecmhmrg224qyumud6utqf6f4s99fvqv         |  
//|Dogecoin Address           : DBGXP1Nc18ZusSRNsj49oMEYFQgAvgBVA8                                 |
//|SHIB Address               : 0x1817D9ebb000025609Bf5D61E269C64DC84DA735                         |              
//|Binance(ERC20 & BSC only)  : 0xe84751063de8ade7c5fbff5e73f6502f02af4e2c                         | 
//|BitCoin Cash               : 1BEtS465S3Su438Kc58h2sqvVvHK9Mijtg                                 | 
//|LiteCoin                   : LLU8PSY2vsq7B9kRELLZQcKf5nJQrdeqwD                                 |  
//+------------------------------------------------------------------------------------------------+