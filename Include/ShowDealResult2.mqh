//+------------------------------------------------------------------+
//|                                              SgiwDeakResult2.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+ 
//| Create Sell sign                                                 | 
//+------------------------------------------------------------------+ 
bool ArrowSellCreate(
                     const string          name="ArrowSell",  // sign name 
                     datetime              time=0,            // anchor point time 
                     double                price=0,           // anchor point price 
                     const long            chart_ID=0,        // chart's ID 
                     const int             sub_window=0,      // subwindow index 
                     const color           clr=C'225,68,29',  // sign color 
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // line style (when highlighted) 
                     const int             width=1,           // line size (when highlighted) 
                     const bool            back=false,        // in the background 
                     const bool            selection=false,   // highlight to move 
                     const bool            hidden=true,       // hidden in the object list 
                     const long            z_order=0)         // priority for mouse click 
  { 
//--- set anchor point coordinates if they are not set 
   ChangeArrowEmptyPoint(time,price); 
//--- reset the error value 
   ResetLastError(); 
//--- create the sign 
   if(!ObjectCreate(chart_ID,name,OBJ_ARROW_SELL,sub_window,time,price)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create \"Sell\" sign! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- set a sign color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- set a line style (when highlighted) 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- set a line size (when highlighted) 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- enable (true) or disable (false) the mode of moving the sign by mouse 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- successful execution 
   return(true); 
  } 
  
  


//+------------------------------------------------------------------+ 
//| Create Buy sign                                                  | 
//+------------------------------------------------------------------+ 
bool ArrowBuyCreate(
                    const string          name="ArrowBuy",   // sign name 
                    datetime              time=0,            // anchor point time 
                    double                price=0,           // anchor point price 
                    const long            chart_ID=0,        // chart's ID 
                    const int             sub_window=0,      // subwindow index 
                    const color           clr=C'3,95,172',   // sign color 
                    const ENUM_LINE_STYLE style=STYLE_SOLID, // line style (when highlighted) 
                    const int             width=1,           // line size (when highlighted) 
                    const bool            back=false,        // in the background 
                    const bool            selection=false,   // highlight to move 
                    const bool            hidden=true,       // hidden in the object list 
                    const long            z_order=0)         // priority for mouse click 
  { 
//--- set anchor point coordinates if they are not set 
   ChangeArrowEmptyPoint(time,price); 
//--- reset the error value 
   ResetLastError(); 
//--- create the sign 
   if(!ObjectCreate(chart_ID,name,OBJ_ARROW_BUY,sub_window,time,price)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create \"Buy\" sign! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- set a sign color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- set a line style (when highlighted) 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- set a line size (when highlighted) 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- enable (true) or disable (false) the mode of moving the sign by mouse 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- successful execution 
   return(true); 
  } 


//+------------------------------------------------------------------+ 
//| Create an arrowed line by the given coordinates                  | 
//+------------------------------------------------------------------+ 
bool ArrowedLineCreate(
                       const string          name="ArrowedLine", // line name 
                       datetime              time1=0,            // first point time 
                       double                price1=0,           // first point price 
                       datetime              time2=0,            // second point time 
                       double                price2=0,           // second point price 
                       const long            chart_ID=0,         // chart's ID 
                       const int             sub_window=0,       // subwindow index 
                       const color           clr=clrRed,         // line color 
                       const ENUM_LINE_STYLE style=STYLE_DOT,  // line style 
                       const int             width=1,            // line width 
                       const bool            back=false,         // in the background 
                       const bool            selection=true,     // highlight to move 
                       const bool            hidden=true,        // hidden in the object list 
                       const long            z_order=0 )          // priority for mouse click 
  { 
//--- set anchor points' coordinates if they are not set 
   ChangeArrowedLineEmptyPoints(time1,price1,time2,price2); 
//--- reset the error value 
   ResetLastError(); 
//--- create an arrowed line by the given coordinates 
   if(!ObjectCreate(chart_ID,name,OBJ_ARROWED_LINE,sub_window,time1,price1,time2,price2)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create an arrowed line! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- enable (true) or disable (false) the mode of moving the line by mouse 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- successful execution 
   return(true); 
  } 
  
  



//+------------------------------------------------------------------+ 
//| Move the anchor point                                            | 
//+------------------------------------------------------------------+ 
bool ArrowBuyMove(const long   chart_ID=0,      // chart's ID 
                  const string name="ArrowBuy", // object name 
                  datetime     time=0,          // anchor point time coordinate 
                  double       price=0)         // anchor point price coordinate 
  { 
//--- if point position is not set, move it to the current bar having Bid price 
   if(!time) 
      time=TimeCurrent(); 
   if(!price) 
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
//--- reset the error value 
   ResetLastError(); 
//--- move the anchor point 
   if(!ObjectMove(chart_ID,name,0,time,price)) 
     { 
      Print(__FUNCTION__, 
            ": failed to move the anchor point! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- successful execution 
   return(true); 
  } 




//+------------------------------------------------------------------+ 
//| Delete Buy sign                                                  | 
//+------------------------------------------------------------------+ 
bool ArrowBuyDelete(const long   chart_ID=0,      // chart's ID 
                    const string name="ArrowBuy") // sign name 
  { 
//--- reset the error value 
   ResetLastError(); 
//--- delete the sign 
   if(!ObjectDelete(chart_ID,name)) 
     { 
      Print(__FUNCTION__, 
            ": failed to delete \"Buy\" sign! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- successful execution 
   return(true); 
  } 


//+------------------------------------------------------------------+ 
//| Check anchor point values and set default values                 | 
//| for empty ones                                                   | 
//+------------------------------------------------------------------+ 
void ChangeArrowEmptyPoint(datetime &time,double &price) 
  { 
//--- if the point's time is not set, it will be on the current bar 
   if(!time) 
      time=TimeCurrent(); 
//--- if the point's price is not set, it will have Bid value 
   if(!price) 
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
  } 


//+------------------------------------------------------------------+ 
//| The function removes the arrowed line from the chart             | 
//+------------------------------------------------------------------+ 
bool ArrowedLineDelete(const long   chart_ID=0,         // chart's ID 
                       const string name="ArrowedLine") // line name 
  { 
//--- reset the error value 
   ResetLastError(); 
//--- delete an arrowed line 
   if(!ObjectDelete(chart_ID,name)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create an arrowed line! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- successful execution 
   return(true); 
  } 

//+------------------------------------------------------------------+ 
//| Check anchor points' values and set default values               | 
//| for empty ones                                                   | 
//+------------------------------------------------------------------+ 
void ChangeArrowedLineEmptyPoints(datetime &time1,double &price1, 
                                  datetime &time2,double &price2) 
  { 
//--- if the first point's time is not set, it will be on the current bar 
   if(!time1) 
      time1=TimeCurrent(); 
//--- if the first point's price is not set, it will have Bid value 
   if(!price1) 
      price1=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
//--- if the second point's time is not set, it is located 9 bars left from the second one 
   if(!time2) 
     { 
      //--- array for receiving the open time of the last 10 bars 
      datetime temp[10]; 
      CopyTime(Symbol(),Period(),time1,10,temp); 
      //--- set the second point 9 bars left from the first one 
      time2=temp[0]; 
     } 
//--- if the second point's price is not set, it is equal to the first point's one 
   if(!price2) 
      price2=price1; 
  } 
  