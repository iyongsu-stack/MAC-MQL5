//+------------------------------------------------------------------+
//|                                                  BrainTrend1.mq4 |
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
//---- в качестве цвета медвежьей линии индикатора использован розовый цвет
#property indicator_color1  Magenta
//---- толщина линии индикатора 1 равна 4
#property indicator_width1  4
//---- отображение метки медвежьей линии индикатора
#property indicator_label1  "Brain1Sell"
//+----------------------------------------------+
//|  Параметры отрисовки бычьго индикатора       |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде символа
#property indicator_type2   DRAW_ARROW
//---- в качестве цвета бычей линии индикатора использован зеленый цвет
#property indicator_color2  Lime
//---- толщина линии индикатора 2 равна 4
#property indicator_width2  4
//---- отображение метки бычьей линии индикатора
#property indicator_label2 "Brain1Buy"

//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input int ATR_Period=7; //период ATR 
input int STO_Period=9; //период стохастика
input ENUM_MA_METHOD MA_Method = MODE_SMA; //метод усреднения
input ENUM_STO_PRICE STO_Price = STO_LOWHIGH; //метод расчета цен 
//+----------------------------------------------+

//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов
double SellBuffer[];
double BuyBuffer[];
//---
double d,s;
int p,x1,x2,P_,StartBars,OldTrend;
int ATR_Handle,STO_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- инициализация глобальных переменных 
   d=2.3;
   s=1.5;
   x1 = 53;
   x2 = 47;
   StartBars=MathMax(ATR_Period,STO_Period)+2;
//---- получение хендла индикатора ATR
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)Print(" Не удалось получить хендл индикатора ATR");
//---- получение хендла индикатора Stochastic
   STO_Handle=iStochastic(NULL,0,STO_Period,STO_Period,1,MA_Method,STO_Price);
   if(STO_Handle==INVALID_HANDLE)Print(" Не удалось получить хендл индикатора Stochastic");

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчета отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
//--- создание метки для отображения в DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"Brain1Sell");
//---- символ для индикатора
   PlotIndexSetInteger(0,PLOT_ARROW,108);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(SellBuffer,true);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчета отрисовки индикатора 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
//--- создание метки для отображения в DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"Brain1Buy");
//---- символ для индикатора
   PlotIndexSetInteger(1,PLOT_ARROW,108);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(BuyBuffer,true);

//---- установка формата точности отображения индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- имя для окон данных и лэйба для субъокон 
   string short_name="BrainTrend1Sig";
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
   if(BarsCalculated(ATR_Handle)<rates_total
      || BarsCalculated(STO_Handle)<rates_total
      || rates_total<StartBars)
      return(0);

//---- объявления локальных переменных 
   int to_copy,limit,bar;
   double value2[],Range[],range,range2,val1,val2,val3;

//---- расчеты необходимого количества копируемых данных и
//стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      to_copy=rates_total; // расчетное количество всех баров
      limit=rates_total-StartBars; // стартовый номер для расчета всех баров
     }
   else
     {
      to_copy=rates_total-prev_calculated+1; // расчетное количество только новых баров
      limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров
     }

//---- копируем вновь появившиеся данные в массивы Range[] и value2[]
   if(CopyBuffer(ATR_Handle,0,0,to_copy,Range)<=0) return(0);
   if(CopyBuffer(STO_Handle,0,0,to_copy,value2)<=0) return(0);

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(Range,true);
   ArraySetAsSeries(value2,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

//---- восстанавливаем значения переменных
   p=P_;

//---- основной цикл расчета индикатора
   for(bar=limit; bar>=0; bar--)
     {
      //---- запоминаем значения переменных перед прогонами на текущем баре
      if(rates_total!=prev_calculated && bar==0)
         P_=p;

      range=Range[bar]/d;
      range2=Range[bar]*s/4;
      val1 = 0.0;
      val2 = 0.0;
      SellBuffer[bar]=0.0;
      BuyBuffer[bar]=0.0;

      val3=MathAbs(close[bar]-close[bar+2]);
      if(value2[bar] < x2 && val3 > range) p = 1;
      if(value2[bar] > x1 && val3 > range) p = 2;

      if(val3<=range) continue;

      if(value2[bar]<x2 && (p==1 || p==0))
        {
         if(OldTrend>0) SellBuffer[bar]=high[bar]+range2;
         if(bar!=0)OldTrend=-1;
        }
      if(value2[bar]>x1 && (p==2 || p==0))
        {
         if(OldTrend<0) BuyBuffer[bar]=low[bar]-range2;
         if(bar!=0)OldTrend=+1;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
