//+------------------------------------------------------------------+
//|                                               BrainTrend2Sig.mq5 |
//|                               Copyright © 2005, BrainTrading Inc |
//|                                      http://www.braintrading.com |
//+------------------------------------------------------------------+
//---- авторство индикатора
#property copyright "Copyright © 2005, BrainTrading Inc."
//---- ссылка на сайт автора
#property link      "http://www.braintrading.com/"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- для расчета и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//---- использовано всего два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//|  Параметры отрисовки медвежьего индикатора   |
//+----------------------------------------------+
//---- отрисовка индикатора 1 в виде символа
#property indicator_type1   DRAW_ARROW
//---- в качестве цвета медвежьей линии индикатора использован красный цвет
#property indicator_color1  Red
//---- толщина линии индикатора 1 равна 4
#property indicator_width1  4
//---- отображение метки медвежьей линии индикатора
#property indicator_label1  "Brain2Sell"
//+----------------------------------------------+
//|  Параметры отрисовки бычьго индикатора       |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде символа
#property indicator_type2   DRAW_ARROW
//---- в качестве цвета бычей линии индикатора использован синий цвет
#property indicator_color2  Blue
//---- толщина линии индикатора 2 равна 4
#property indicator_width2  4
//---- отображение метки бычьей линии индикатора
#property indicator_label2 "Brain2Buy"

//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input int ATR_Period=7;
//+----------------------------------------------+

//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double SellBuffer[];
double BuyBuffer[];
//---
bool   river=true,river_;
int    glava,glava_,StartBars,OldTrend,ATR_Handle;
double s,dartp,cecf,Emaxtra,Emaxtra_,Values_[],Values[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- инициализация глобальных переменных 
   s=1.5;
   dartp=7.0;
   cecf=0.7;
   StartBars=ATR_Period+2;

//---- распределение памяти под массивы переменных   
   if(ArrayResize(Values,ATR_Period)<ATR_Period)
      Print("Не удалось распределить память под массив Values");
   if(ArrayResize(Values_,ATR_Period)<ATR_Period)
      Print("Не удалось распределить память под массив Values_");

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчета отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
//--- создание метки для отображения в DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"Brain2Sell");
//---- символ для индикатора
   PlotIndexSetInteger(0,PLOT_ARROW,234);
//---- индексация элементов в буфере, как в таймсерии
   ArraySetAsSeries(SellBuffer,true);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчета отрисовки индикатора 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
//--- создание метки для отображения в DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"Brain2Buy");
//---- символ для индикатора
   PlotIndexSetInteger(1,PLOT_ARROW,233);
//---- индексация элементов в буфере, как в таймсерии
   ArraySetAsSeries(BuyBuffer,true);

//---- Установка формата точности отображения индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- имя для окон данных и отметки для подокон 
   string short_name="BrainTrend2Sig";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----   
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- проверка количества баров на достаточность для расчета
   if(rates_total<StartBars) return(0);

//---- объявления локальных переменных    
   int bar,J,limit,Curr;
   double ATR,widcha,TR,Spread,range2;
   double Weight,Series1,High,Low;

//---- расчет стартового номера limit для цикла пересчета баров и стартовая инициализация переменных
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-StartBars; // стартовый номер для расчета всех баров
      Emaxtra=close[limit+1];
      glava=0;
      double T_Series2=close[limit+2];
      double T_Series1=close[limit+1];
      if(T_Series2>T_Series1)
         river=true;
      else river=false;

      TR=spread[limit]+high[limit]-low[limit];

      if(MathAbs(spread[limit]+high[limit]-T_Series1)>TR)
         TR=MathAbs(spread[limit]+high[limit]-T_Series1);

      if(MathAbs(low[limit]-T_Series1)>TR)
         TR=MathAbs(low[limit]-T_Series1);

      ArrayInitialize(Values,TR);
     }
   else
     {
      limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров
     }

//---- индексация элементов в массивах, как в таймсериях  
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(spread,true);
   ArraySetAsSeries(Values,true);
   ArraySetAsSeries(Values_,true);

//---- восстанавливаем значения переменных
   glava=glava_;
   Emaxtra=Emaxtra_;
   river=river_;
   ArrayCopy(Values,Values_,0,WHOLE_ARRAY);
   
//---- основной цикл расчета индикатора
   for(bar=limit; bar>=0; bar--)
     {
      //---- запоминаем значения переменных перед прогонами на текущем баре
      if(rates_total!=prev_calculated && bar==0)
        {
         glava_=glava;
         Emaxtra_=Emaxtra;
         river_=river;
         ArrayCopy(Values_,Values,0,WHOLE_ARRAY);
        }

      SellBuffer[bar]=0.0;
      BuyBuffer[bar]=0.0;
    
      Spread=spread[bar]*_Point;

      High=high[bar];
      Low=low[bar];
      Series1=close[bar+1];
      TR=Spread+High-Low;

      if(MathAbs(Spread+High-Series1)>TR)
         TR=MathAbs(Spread+High-Series1);

      if(MathAbs(Low-Series1)>TR)
         TR=MathAbs(Low-Series1);

      Values[glava]=TR;

      ATR=0;
      Weight=ATR_Period;
      Curr=glava;

      for(J=0; J<=ATR_Period-1; J++)
        {
         ATR+=Values[Curr]*Weight;
         Weight-=1.0;
         Curr--;
         if(Curr==-1) Curr=ATR_Period-1;
        }

      ATR=2.0*ATR/(dartp *(dartp+1.0));
      glava++;
      
      range2=ATR*s/4;

      if(glava==ATR_Period) glava=0;

      widcha=cecf*ATR;

      if(river && Low<Emaxtra-widcha)
        {
         river=false;
         Emaxtra=Spread+High;
        }

      if(!river && Spread+High>Emaxtra+widcha)
        {
         river=true;
         Emaxtra=Low;
        }

      if(river && Low>Emaxtra)
        {
         Emaxtra=Low;
        }

      if(!river && Spread+High<Emaxtra)
        {
         Emaxtra=Spread+High;
        }

      if(river)
        {
         if(OldTrend<0) BuyBuffer[bar]=Low-range2;
         if(bar!=0)OldTrend=+1;
        }
      else
        {
         if(OldTrend>0) SellBuffer[bar]=High+range2;
         if(bar!=0)OldTrend=-1;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
