//+------------------------------------------------------------------+
//|                                           objectcreateandset.mqh |
//|                                                2015, Dina Paches |
//|                           https://login.mql5.com/ru/users/dipach |
//+------------------------------------------------------------------+
#property copyright "Dina Paches"
#property link      "https://login.mql5.com/ru/users/dipach"
#define LINE_NUMBER    "Line: ",__LINE__,", "
/*To use the library in your code, copy this line from and paste it
to your code:
#include <objectcreateandset.mqh>*/
//+------------------------------------------------------------------+
//| Functions for working with graphical objects                     |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Create the vertical line                                         |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  / Objects Constants  /  Object Types / OBJ_VLINE     |
//+------------------------------------------------------------------+
bool VLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="VLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 datetime              time=0,            // line time
                 const string          toolTip="\n",      // tooltip's text
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            ray=true,          // line's continuation down
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0,         // priority for mouse click
                 const int             timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- if the line time is not set, draw it via the last bar
   if(!time)
      time=TimeCurrent();
//--- reset the error value
   ResetLastError();
//--- create a vertical line
   if(!ObjectCreate(chart_ID,name,OBJ_VLINE,sub_window,time,0))
     {
      Print(LINE_NUMBER,__FUNCTION__,
            ": failed to create a vertical line! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set line color
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObSetIntegerLineStyle(chart_ID,name,style);
//--- set line width
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- enable (true) or disable (false) the mode of displaying the line in the chart subwindows
   ObSetIntegerBool(chart_ID,name,OBJPROP_RAY,ray);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the horizontal line                                       |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_HLINE    |
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="HLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 double                price=0,           // line price
                 const string          toolTip="\n",      // tooltip's text
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             line_width=1,      // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0,         // priority for mouse click
                 const int             timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create a horizontal line
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
     {
      Print(LINE_NUMBER,__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set line color  
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObSetIntegerLineStyle(chart_ID,name,style);
//--- set line width
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create a trend line by the given coordinates                     |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_TREND    |
//+------------------------------------------------------------------+
bool TrendCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="TrendLine",  // line name
                 const int             sub_window=0,      // subwindow index
                 datetime              time1=0,           // first point time
                 double                price1=0,          // first point price
                 datetime              time2=0,           // second point time
                 double                price2=0,          // second point price
                 const string          toolTip="\n",      // tooltip's text    
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            ray_left=false,    // line's continuation to the left
                 const bool            ray_right=false,   // line's continuation to the right
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0,         // priority for mouse click
                 const int             timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create a trend line by the given coordinates
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2))
     {
      Print(LINE_NUMBER,__FUNCTION__,
            ": failed to create a trend line! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set line color  
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObSetIntegerLineStyle(chart_ID,name,style);
//--- set line width
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- enable (true) or disable (false) the mode of continuation of the line's display to the left
   ObSetIntegerBool(chart_ID,name,OBJPROP_RAY_LEFT,ray_left);
//--- enable (true) or disable (false) the mode of continuation of the line's display to the right
   ObSetIntegerBool(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create an arrowed line by the given coordinates                  |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types /              |
//| OBJ_ARROWED_LINE                                                 |
//+------------------------------------------------------------------+
bool ArrowedLineCreate(const long            chart_ID=0,         // chart's ID
                       const string          name="ArrowedLine", // line name
                       const int             sub_window=0,       // subwindow index
                       datetime              time1=0,            // first point time
                       double                price1=0,           // first point price
                       datetime              time2=0,            // second point time
                       double                price2=0,           // second point price
                       const string          toolTip="\n",       // tooltip's text
                       const color           clr=clrRed,         // line color
                       const ENUM_LINE_STYLE style=STYLE_SOLID,  // line style
                       const int             width=1,            // line width
                       const bool            back=false,         // in the background
                       const bool            selection=true,     // highlight to move
                       const bool            hidden=true,        // hidden in the object list
                       const long            z_order=0,          // priority for mouse click
                       const int             timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create an arrowed line by the given coordinates
   if(!ObjectCreate(chart_ID,name,OBJ_ARROWED_LINE,sub_window,time1,price1,time2,price2))
     {
      Print(__FUNCTION__,
            ": failed to create an arrowed line! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set line color
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObSetIntegerLineStyle(chart_ID,name,style);
//--- set line width
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create an equidistant channel by the given coordinates           |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_CHANNEL  |
//+------------------------------------------------------------------+
bool ChannelCreate(const long            chart_ID=0,        // chart's ID
                   const string          name="Channel",    // channel name
                   const int             sub_window=0,      // subwindow index
                   datetime              time1=0,           // first point time
                   double                price1=0,          // first point price
                   datetime              time2=0,           // second point time
                   double                price2=0,          // second point price
                   datetime              time3=0,           // third point time
                   double                price3=0,          // third point price
                   const string          toolTip="\n",      // tooltip's text
                   const color           clr=clrRed,        // channel color
                   const ENUM_LINE_STYLE style=STYLE_SOLID, // style of channel lines
                   const int             line_width=1,      // width of channel lines
                   const bool            fill=false,        // filling the channel with color
                   const bool            back=false,        // in the background
                   const bool            selection=true,    // highlight to move
                   const bool            ray_left=false,    // channel's continuation to the left
                   const bool            ray_right=false,   // channel's continuation to the right
                   const bool            hidden=true,       // hidden in the object list
                   const long            z_order=0,         // priority for mouse click
                   const int             timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create a channel by the given coordinates
   if(!ObjectCreate(chart_ID,name,OBJ_CHANNEL,sub_window,time1,price1,time2,price2,time3,price3))
     {
      Print(__FUNCTION__,
            ": failed to create an equidistant channel! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set channel color
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set style of the channel lines
   ObSetIntegerLineStyle(chart_ID,name,style);
//--- set width of the channel lines
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- enable (true) or disable (false) the mode of filling the channel
   ObSetIntegerBool(chart_ID,name,OBJPROP_FILL,fill);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of highlighting the channel for moving
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- enable (true) or disable (false) the mode of continuation of the channel's display to the left
   ObSetIntegerBool(chart_ID,name,OBJPROP_RAY_LEFT,ray_left);
//--- enable (true) or disable (false) the mode of continuation of the channel's display to the right
   ObSetIntegerBool(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create rectangle by the given coordinates                        |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_RECTANGLE|    
//+------------------------------------------------------------------+
bool RectangleCreate(const long            chart_ID=0,        // chart's ID
                     const string          name="Rectangle",  // rectangle name
                     const int             sub_window=0,      // subwindow index
                     datetime              time1=0,           // first point time
                     double                price1=0,          // first point price
                     datetime              time2=0,           // second point time
                     double                price2=0,          // second point price
                     const string          toolTip="\n",      // tooltip's text
                     const color           clr=clrRed,        // rectangle color
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // style of rectangle lines
                     const int             line_width=1,      // width of rectangle lines
                     const bool            fill=false,        // filling rectangle with color
                     const bool            back=false,        // in the background
                     const bool            selection=true,    // highlight to move
                     const bool            hidden=true,       // hidden in the object list
                     const long            z_order=0,         // priority for mouse click
                     const int             timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create a rectangle by the given coordinates
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE,sub_window,time1,price1,time2,price2))
     {
      Print(LINE_NUMBER,__FUNCTION__,
            ": failed to create a rectangle! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set rectangle color
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set the style of rectangle lines
   ObSetIntegerLineStyle(chart_ID,name,style);
//--- set width of the rectangle lines
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- enable (true) or disable (false) the mode of filling the rectangle
   ObSetIntegerBool(chart_ID,name,OBJPROP_FILL,fill);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of highlighting the rectangle for moving
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create triangle by the given coordinates                         |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_TRIANGLE |
//+------------------------------------------------------------------+
bool TriangleCreate(const long            chart_ID=0,        // chart's ID
                    const string          name="Triangle",   // triangle name
                    const int             sub_window=0,      // subwindow index
                    datetime              time1=0,           // first point time
                    double                price1=0,          // first point price
                    datetime              time2=0,           // second point time
                    double                price2=0,          // second point price
                    datetime              time3=0,           // third point time
                    double                price3=0,          // third point price
                    const string          toolTip="\n",      // tooltip's text
                    const color           clr=clrRed,        // triangle color
                    const ENUM_LINE_STYLE style=STYLE_SOLID, // style of triangle lines
                    const int             width=1,           // width of triangle lines
                    const bool            fill=false,        // filling triangle with color
                    const bool            back=false,        // in the background
                    const bool            selection=true,    // highlight to move
                    const bool            hidden=true,       // hidden in the object list
                    const long            z_order=0,         // priority for mouse click
                    const int             timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create triangle by the given coordinates
   if(!ObjectCreate(chart_ID,name,OBJ_TRIANGLE,sub_window,time1,price1,time2,price2,time3,price3))
     {
      Print(__FUNCTION__,
            ": failed to create a triangle! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set triangle color
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set width of triangle lines
   ObSetIntegerLineStyle(chart_ID,name,style);
//--- set width of triangle lines
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,width);
//--- enable (true) or disable (false) the mode of filling the triangle
   ObSetIntegerBool(chart_ID,name,OBJPROP_FILL,fill);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of highlighting the triangle for moving
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create an ellipse by the given coordinates                       |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_ELLIPSE  |
//+------------------------------------------------------------------+
bool EllipseCreate(const long            chart_ID=0,        // chart's ID
                   const string          name="Ellipse",    // ellipse name
                   const int             sub_window=0,      // subwindow index
                   datetime              time1=0,           // first point time
                   double                price1=0,          // first point price
                   datetime              time2=0,           // second point time
                   double                price2=0,          // second point price
                   datetime              time3=0,           // third point time
                   double                price3=0,          // third point price
                   const string          toolTip="\n",      // tooltip's text
                   const color           clr=clrRed,        // ellipse color
                   const ENUM_LINE_STYLE style=STYLE_SOLID, // style of ellipse lines
                   const int             width=1,           // width of ellipse lines
                   const bool            fill=false,        // filling ellipse with color
                   const bool            back=false,        // in the background
                   const bool            selection=true,    // highlight to move
                   const bool            hidden=true,       // hidden in the object list
                   const long            z_order=0,         // priority for mouse click
                   const int             timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create an ellipse by the given coordinates
   if(!ObjectCreate(chart_ID,name,OBJ_ELLIPSE,sub_window,time1,price1,time2,price2,time3,price3))
     {
      Print(__FUNCTION__,
            ": failed to create an ellipse! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set an ellipse color
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set style of ellipse lines
   ObSetIntegerLineStyle(chart_ID,name,style);
//--- set width of ellipse lines
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,width);
//--- enable (true) or disable (false) the mode of filling the ellipse
   ObSetIntegerBool(chart_ID,name,OBJPROP_FILL,fill);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of highlighting the ellipse for moving
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create an OBJ_ARROW                                              |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_ARROW    |
//+------------------------------------------------------------------+
bool ArrowCreate(const long              chart_ID=0,           // chart's ID
                 const string            name="Arrow",         // arrow name
                 const int               sub_window=0,         // subwindow index
                 datetime                time=0,               // anchor point time
                 double                  price=0,              // anchor point price
                 const uchar             arrow_code=252,       // arrow code
                 const string            toolTip="\n",         // tooltip's text
                 const ENUM_ARROW_ANCHOR anchor=ANCHOR_BOTTOM, // anchor point position
                 const color             clr=clrRed,           // arrow color
                 const ENUM_LINE_STYLE   style=STYLE_SOLID,    // border line style
                 const int               line_width=3,         // arrow size
                 const bool              back=false,           // in the background
                 const bool              selection=true,       // highlight to move
                 const bool              hidden=true,          // hidden in the object list
                 const long              z_order=0,            // priority for mouse click
                 const int               timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create an arrow
   if(!ObjectCreate(chart_ID,name,OBJ_ARROW,sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": failed to create an arrow! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set the arrow code
   ObSetIntegerArrowCode(chart_ID,name,arrow_code);
//--- set anchor type
   ObSetIntegerArrowAncor(chart_ID,name,anchor);
//--- set the arrow color
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set the border line style
   ObSetIntegerLineStyle(chart_ID,name,style);
//--- set the arrow's size
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the arrow by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Creating Text object                                             |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_TEXT     |
//+------------------------------------------------------------------+
bool TextCreate(const long              chart_ID=0,               // chart's ID
                const string            name="Text",              // object name
                const int               sub_window=0,             // subwindow index
                datetime                time=0,                   // anchor point time
                double                  price=0,                  // anchor point price
                const string            text="Text",              // the text itself
                const string            toolTip="\n",             // tooltip's text
                const string            font="Arial",             // font
                const int               font_size=10,             // font size
                const color             clr=clrRed,               // color
                const double            angle=0.0,                // text slope
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                const bool              back=false,               // in the background
                const bool              selection=false,          // highlight to move
                const bool              hidden=true,              // hidden in the object list
                const long              z_order=0,                // priority for mouse click
                const int               timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create Text object
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": failed to create \"Text\" object! Error code = ",GetLastError());
      return(false);
     }
//--- set the text
   ObSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set text font
   ObSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObSetIntegerInt(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text
   ObSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type
   ObSetIntegerAncorPoint(chart_ID,name,anchor);
//--- set color
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the object by mouse
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create a text label                                              |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_LABEL    |
//+------------------------------------------------------------------+
bool LabelCreate(const long              chart_ID=0,               // chart's ID
                 const string            name="Label",             // label name
                 const int               sub_window=0,             // subwindow index
                 const int               x=0,                      // X coordinate
                 const int               y=0,                      // Y coordinate
                 const string            toolTip="\n",             // tooltip's text
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                 const string            text="Label",             // text
                 const string            font="Arial",             // font
                 const int               font_size=10,             // font size
                 const color             clr=clrRed,               // color
                 const double            angle=0.0,                // text slope
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                 const bool              back=false,               // in the background
                 const bool              selection=false,          // highlight to move
                 const bool              hidden=true,              // hidden in the object list
                 const long              z_order=0,                // priority for mouse click
                 const int               timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create a text label
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create text label! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set label coordinates
   ObSetIntegerInt(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObSetIntegerInt(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set the chart's corner, relative to which point coordinates are defined
   ObSetIntegerCorner(chart_ID,name,corner);//ENUM_BASE_CORNER
//--- set the text
   ObSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObSetIntegerInt(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text
   ObSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type
   ObSetIntegerAncorPoint(chart_ID,name,anchor);
//--- set color
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the button                                                |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_BUTTON   |
//+------------------------------------------------------------------+
bool ButtonCreate(const long              chart_ID=0,               // chart's ID
                  const string            name="Button",            // button name
                  const int               sub_window=0,             // subwindow index
                  const int               x=0,                      // X coordinate
                  const int               y=0,                      // Y coordinate
                  const int               width=50,                 // button width
                  const int               height=18,                // button height
                  const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                  const string            text="Button",            // text
                  const string            toolTip="\n",             // tooltip's text
                  const string            font="Arial",             // font
                  const int               font_size=10,             // font size
                  const color             clr=clrBlack,             // text color
                  const color             back_clr=C'236,233,216',  // background color
                  const color             border_clr=clrNONE,       // border color
                  const bool              state=false,              // pressed/released
                  const bool              back=false,               // in the background
                  const bool              selection=false,          // highlight to move
                  const bool              hidden=true,              // hidden in the object list
                  const long              z_order=0,                // priority for mouse click
                  const int               timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create the button
   if(!ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0))
     {
      Print(LINE_NUMBER,__FUNCTION__,
            ": failed to create the button! Error code = ",GetLastError());
      return(false);
     }
//--- set button coordinates
   ObSetIntegerInt(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObSetIntegerInt(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set button size
   ObSetIntegerInt(chart_ID,name,OBJPROP_XSIZE,width);
   ObSetIntegerInt(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the chart's corner, relative to which point coordinates are defined
   ObSetIntegerCorner(chart_ID,name,corner);
//--- set the text
   ObSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObSetIntegerInt(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set text color
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set background color
   ObSetIntegerColor(chart_ID,name,OBJPROP_BGCOLOR,back_clr);//Set background color for: OBJ_EDIT, OBJ_BUTTON, OBJ_RECTANGLE_LABEL
//--- set border color
   ObSetIntegerColor(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);//Set border color for: OBJ_EDIT, OBJ_BUTTON
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- set button state
   ObSetIntegerBool(chart_ID,name,OBJPROP_STATE,state);
//--- enable (true) or disable (false) the mode of moving the button by mouse
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create a bitmap in the chart window                              |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_BITMAP   |
//+------------------------------------------------------------------+
bool BitmapCreate(const long            chart_ID=0,        // chart's ID
                  const string          name="Bitmap",     // bitmap name
                  const int             sub_window=0,      // subwindow index
                  datetime              time=0,            // anchor point time
                  double                price=0,           // anchor point price
                  const string          file="",           // bitmap file name
                  const int             width=10,          // visibility scope X coordinate
                  const int             height=10,         // visibility scope Y coordinate
                  const int             x_offset=0,        // visibility scope shift by X axis
                  const int             y_offset=0,        // visibility scope shift by Y axis
                  const string          toolTip="\n",      // tooltip's text
                  const color           clr=clrRed,        // border color when highlighted
                  const ENUM_LINE_STYLE style=STYLE_SOLID, // line style when highlighted
                  const int             point_width=1,     // move point size
                  const bool            back=false,        // in the background
                  const bool            selection=false,   // highlight to move
                  const bool            hidden=true,       // hidden in the object list
                  const long            z_order=0,         // priority for mouse click
                  const int             timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create a bitmap
   if(!ObjectCreate(chart_ID,name,OBJ_BITMAP,sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": failed to create a bitmap in the chart window! Error code = ",GetLastError());
      return(false);
     }
//--- set the path to the image file
   if(!ObjectSetString(chart_ID,name,OBJPROP_BMPFILE,file))
     {
      Print(__FUNCTION__,
            ": failed to load the image! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set visibility scope for the image; if width or height values
//--- exceed the width and height (respectively) of a source image,
//--- it is not drawn; in the opposite case,
//--- only the part corresponding to these values is drawn
   ObSetIntegerInt(chart_ID,name,OBJPROP_XSIZE,width);
   ObSetIntegerInt(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the part of an image that is to be displayed in the visibility scope
//--- the default part is the upper left area of an image; the values allow
//--- performing a shift from this area displaying another part of the image
   ObSetIntegerInt(chart_ID,name,OBJPROP_XOFFSET,x_offset);
   ObSetIntegerInt(chart_ID,name,OBJPROP_YOFFSET,y_offset);
//--- set the border color when object highlighting mode is enabled
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set the border line style when object highlighting mode is enabled
   ObSetIntegerLineStyle(chart_ID,name,style);
//--- set a size of the anchor point for moving an object
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,point_width);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create Bitmap Label object                                       |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types /              |
//| OBJ_BITMAP_LABEL                                                 |
//+------------------------------------------------------------------+
bool BitmapLabelCreate(const long              chart_ID=0,               // chart's ID
                       const string            name="BmpLabel",          // label name
                       const int               sub_window=0,             // subwindow index
                       const int               x=0,                      // X coordinate
                       const int               y=0,                      // Y coordinate
                       const string            toolTip="\n",             // tooltip's text
                       const string            file_on="",               // image in On mode
                       const string            file_off="",              // image in Off mode
                       const int               width=0,                  // visibility scope X coordinate
                       const int               height=0,                 // visibility scope Y coordinate
                       const int               x_offset=10,              // visibility scope shift by X axis
                       const int               y_offset=10,              // visibility scope shift by Y axis
                       const bool              state=false,              // pressed/released
                       const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                       const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                       const color             clr=clrRed,               // border color when highlighted
                       const ENUM_LINE_STYLE   style=STYLE_SOLID,        // line style when highlighted
                       const int               point_width=1,            // move point size
                       const bool              back=false,               // in the background
                       const bool              selection=false,          // highlight to move
                       const bool              hidden=true,              // hidden in the object list
                       const long              z_order=0,                // priority for mouse click
                       const int              timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create a bitmap label
   if(!ObjectCreate(chart_ID,name,OBJ_BITMAP_LABEL,sub_window,0,0))
     {
      Print(LINE_NUMBER,__FUNCTION__,
            ": failed to create \"Bitmap Label\" object! Error code = ",GetLastError());
      return(false);
     }
//--- set the images for On and Off modes
   if(!ObjectSetString(chart_ID,name,OBJPROP_BMPFILE,0,file_on))
     {
      Print(LINE_NUMBER,__FUNCTION__,
            ": failed to load the image for On mode! Error code = ",GetLastError());
      return(false);
     }
   if(!ObjectSetString(chart_ID,name,OBJPROP_BMPFILE,1,file_off))
     {
      Print(LINE_NUMBER,__FUNCTION__,
            ": failed to load the image for Off mode! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set label coordinates
   ObSetIntegerInt(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObSetIntegerInt(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set visibility scope for the image; if width or height values
//--- exceed the width and height (respectively) of a source image,
//--- it is not drawn; in the opposite case,
//--- only the part corresponding to these values is drawn
   ObSetIntegerInt(chart_ID,name,OBJPROP_XSIZE,width);
   ObSetIntegerInt(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the part of an image that is to be displayed in the visibility scope
//--- the default part is the upper left area of an image; the values allow
//--- performing a shift from this area displaying another part of the image
   ObSetIntegerInt(chart_ID,name,OBJPROP_XOFFSET,x_offset);
   ObSetIntegerInt(chart_ID,name,OBJPROP_YOFFSET,y_offset);
//--- define the label's status (pressed or released)
   ObSetIntegerBool(chart_ID,name,OBJPROP_STATE,state);
//--- set the chart's corner, relative to which point coordinates are defined
   ObSetIntegerCorner(chart_ID,name,corner);//ENUM_BASE_CORNER;
//--- set anchor type
   ObSetIntegerAncorPoint(chart_ID,name,anchor);
//--- set the border color when object highlighting mode is enabled
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set the border line style when object highlighting mode is enabled
   ObSetIntegerLineStyle(chart_ID,name,style);
//--- set a size of the anchor point for moving an object
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,point_width);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create Edit object                                               |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_EDIT     |
//+------------------------------------------------------------------+
bool EditCreate(const long             chart_ID=0,               // chart's ID
                const string           name="Edit",              // object name
                const int              sub_window=0,             // subwindow index
                const int              x=0,                      // X coordinate
                const int              y=0,                      // Y coordinate
                const int              width=50,                 // width
                const int              height=18,                // height
                const string           text="Text",              // text
                const string           font="Arial",             // font
                const int              font_size=10,             // font size
                const string           toolTip="\n",             // tooltip's text
                const ENUM_ALIGN_MODE  align=ALIGN_CENTER,       // alignment type
                const bool             read_only=false,          // ability to edit
                const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                const color            clr=clrBlack,             // text color
                const color            back_clr=clrWhite,        // background color
                const color            border_clr=clrNONE,       // border color
                const bool             back=false,               // in the background
                const bool             selection=false,          // highlight to move
                const bool             hidden=true,              // hidden in the object list
                const long             z_order=0,                // priority for mouse click
                const int             timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create edit field
   if(!ObjectCreate(chart_ID,name,OBJ_EDIT,sub_window,0,0))
     {
      Print(LINE_NUMBER,__FUNCTION__,
            ": failed to create \"Edit\" object! Error code = ",GetLastError());
      return(false);
     }
//--- set object coordinates
   ObSetIntegerInt(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObSetIntegerInt(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set object size
   ObSetIntegerInt(chart_ID,name,OBJPROP_XSIZE,width);
   ObSetIntegerInt(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the text
   ObSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObSetIntegerInt(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the type of text alignment in the object
   ObSetIntegerAlign(chart_ID,name,align);
//--- enable (true) or cancel (false) read-only mode
   ObSetIntegerBool(chart_ID,name,OBJPROP_READONLY,read_only);
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set the chart's corner, relative to which object coordinates are defined
   ObSetIntegerCorner(chart_ID,name,corner);
//--- set text color
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set background color
   ObSetIntegerColor(chart_ID,name,OBJPROP_BGCOLOR,back_clr);//Set background color for: OBJ_EDIT, OBJ_BUTTON, OBJ_RECTANGLE_LABEL
//--- set border color
   ObSetIntegerColor(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);//Set border color for: OBJ_EDIT и OBJ_BUTTON
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create Event object on the chart                                 |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types / OBJ_EVENT    |
//+------------------------------------------------------------------+
bool EventCreate(const long            chart_ID=0,      // chart's ID
                 const string          name="Event",    // event name
                 const int             sub_window=0,    // subwindow index
                 const string          text="Text",     // event text
                 datetime              time=0,          // time
                 const string          toolTip="\n",    // tooltip's text
                 const color           clr=clrRed,      // color
                 const int             line_width=1,    // point width when highlighted
                 const bool            back=false,      // in the background
                 const bool            selection=false, // highlight to move
                 const bool            hidden=true,     // hidden in the object list
                 const long            z_order=0,       // priority for mouse click
                 const int             timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- if time is not set, create the object on the last bar
   if(!time)
      time=TimeCurrent();
//--- reset the error value
   ResetLastError();
//--- create Event object
   if(!ObjectCreate(chart_ID,name,OBJ_EVENT,sub_window,time,0))
     {
      Print(__FUNCTION__,
            ": failed to create \"Event\" object! Error code = ",GetLastError());
      return(false);
     }
//--- set here text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set event text
   ObSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set color
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set anchor point width if the object is highlighted
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving event by mouse
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create rectangle label                                           |
//+------------------------------------------------------------------+
//| From the original:                                               |
//| MQL5 Reference  /  Standard Constants, Enumerations and          |
//| Structures  /  Objects Constants  /  Object Types /              |
//| OBJ_RECTANGLE_LABEL                                              |
//+------------------------------------------------------------------+
bool RectLabelCreate(const long             chart_ID=0,               // chart's ID
                     const string           name="RectLabel",         // label name
                     const int              sub_window=0,             // subwindow index
                     const int              x=0,                      // X coordinate
                     const int              y=0,                      // Y coordinate                    
                     const int              width=50,                 // width
                     const int              height=18,                // height
                     const string           toolTip="\n",             // tooltip's text
                     const color            back_clr=C'236,233,216',  // background color
                     const ENUM_BORDER_TYPE border=BORDER_SUNKEN,     // border type
                     const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                     const color            clr=clrRed,               // flat border color (Flat)
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // flat border style
                     const int              line_width=1,             // flat border width
                     const bool             back=false,               // in the background
                     const bool             selection=false,          // highlight to move
                     const bool             hidden=true,              // hidden in the object list                  
                     const long             z_order=0,                // priority for mouse click
                     const int              timeFrames=OBJ_ALL_PERIODS)//chart timeframes, where the object is visible
  {
//--- reset the error value
   ResetLastError();
//--- create a rectangle label
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0))
     {
      Print(LINE_NUMBER,__FUNCTION__,
            ": failed to create a rectangle label! Error code = ",GetLastError());
      return(false);
     }
//--- set the text of a tooltip
   ObSetString(chart_ID,name,OBJPROP_TOOLTIP,toolTip);
//--- set label coordinates
   ObSetIntegerInt(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObSetIntegerInt(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set label size
   ObSetIntegerInt(chart_ID,name,OBJPROP_XSIZE,width);
   ObSetIntegerInt(chart_ID,name,OBJPROP_YSIZE,height);
//--- set background color
   ObSetIntegerColor(chart_ID,name,OBJPROP_BGCOLOR,back_clr);//Set background color for: OBJ_EDIT, OBJ_BUTTON, OBJ_RECTANGLE_LABEL
//--- set border type
   ObSetIntegerBorderType(chart_ID,name,border);
//--- set the chart's corner, relative to which point coordinates are defined
   ObSetIntegerCorner(chart_ID,name,corner);
//--- set flat border color (in Flat mode)
   ObSetIntegerColor(chart_ID,name,OBJPROP_COLOR,clr);
//--- set flat border line style
   ObSetIntegerLineStyle(chart_ID,name,style);
//--- set flat border width
   ObSetIntegerInt(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- display in the foreground (false) or background (true)
   ObSetIntegerBool(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObSetIntegerBool(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObSetIntegerBool(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObSetIntegerLong(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- set visibility of an object at timeframes  
   ObSetIntegerInt(chart_ID,name,OBJPROP_TIMEFRAMES,timeFrames);
//--- successful execution
   return(true);
  }
//+--------------------------------------------------------------------+
//|Functions for setting object properties, without specifying a       |
//|modifier:                                                           |
//+--------------------------------------------------------------------+
//+--------------------------------------------------------------------+
//| ObSetDouble (Setting property value, without modifier)             |
//| the values of the enumeration ENUM_OBJECT_PROPERTY_DOUBLE:         |
//+--------------------------------------------------------------------+
//| OBJPROP_SCALE - Scale (properties of Gann objects and Fibonacci    |
//| Arcs)   - double;                                                  |
//+--------------------------------------------------------------------+
//| OBJPROP_ANGLE - Angle.  For the objects with no angle specified,   |
//| created from a program, the value is equal to EMPTY_VALUE          |
//| - double;                                                          |
//+--------------------------------------------------------------------+
//| OBJPROP_DEVIATION - Deviation of the standard deviation channel    |
//| - double;                                                          |
//+--------------------------------------------------------------------+
bool ObSetDouble(long chart_ID,// chart identifier
                 string name,// object name
                 ENUM_OBJECT_PROPERTY_DOUBLE prop_id,// property
                 double prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetDouble(chart_ID,name,prop_id,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| ObSetIntegerAlign (Setting property value, without modifier)     |
//+------------------------------------------------------------------+
//| Set horizontal text alignment in the "Edit" object (OBJ_EDIT)    |
//+------------------------------------------------------------------+
//| OBJPROP_ALIGN - Horizontal text alignment in the "Edit" object   |
//| (OBJ_EDIT) - ENUM_ALIGN_MODE;                                    |
//+------------------------------------------------------------------+
bool ObSetIntegerAlign(long chart_ID,// chart identifier
                       string name,// object name
                       ENUM_ALIGN_MODE prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| ObSetIntegerAncorPoint (Setting property value, without modifier)|
//+------------------------------------------------------------------+
//| OBJPROP_ANCHOR - Location of the anchor point                    |
//| - ENUM_ANCHOR_POINT (for OBJ_LABEL, OBJ_BITMAP_LABEL и OBJ_TEXT);|
//+------------------------------------------------------------------+
bool ObSetIntegerAncorPoint(long chart_ID,// chart identifier
                            string name,// object name
                            ENUM_ANCHOR_POINT prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| ObSetIntegerArrowAncor (Setting property value, without modifier)|
//+------------------------------------------------------------------+
//| OBJPROP_ANCHOR - Location of the anchor point                    |
//| - ENUM_ARROW_ANCHOR (для OBJ_ARROW);                             |
//+------------------------------------------------------------------+
bool ObSetIntegerArrowAncor(long chart_ID,// chart identifier
                            string name,// object name
                            ENUM_ARROW_ANCHOR prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| ObSetIntegerArrowCode (Setting property value, without modifier) |
//+------------------------------------------------------------------+
//| OBJPROP_ARROWCODE - Arrow code for OBJ_ARROW - char              |
//+------------------------------------------------------------------+
bool ObSetIntegerArrowCode(long chart_ID,// chart identifier
                           string name,// object name
                           char prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_ARROWCODE,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+-------------------------------------------------------------------+
//| ObSetIntegerBool (Setting property value, without modifier)       |
//| the values of the enumeration ENUM_OBJECT_PROPERTY_INTEGER:       |
//+-------------------------------------------------------------------+
//| OBJPROP_BACK - Object in the background - bool;                   |
//+-------------------------------------------------------------------+
//| OBJPROP_FILL Fill an object with color (для OBJ_RECTANGLE,        |
//| OBJ_TRIANGLE, OBJ_ELLIPSE, OBJ_CHANNEL, OBJ_STDDEVCHANNEL,        |
//| OBJ_REGRESSION) - bool;                                           |
//+-------------------------------------------------------------------+
//| OBJPROP_HIDDEN - Prohibit showing the name of a graphical object  |
//| in the list of objects from the terminal menu "Charts" -          |
//| "Objects" - "List of objects". "true" hides an object from the    |
//| list. By default, "true" is set to objects displaying calendar    |
//| events, trading history and to objects created from MQL5 programs.|
//| To see such graphical objects and access their properties, click  |
//| "All" button in the "List of objects" window. - bool              |
//+-------------------------------------------------------------------+
//| OBJPROP_SELECTED - Object is selected - bool;                     |
//+-------------------------------------------------------------------+
//| OBJPROP_READONLY - Ability to edit text in the Edit object - bool;|
//+-------------------------------------------------------------------+
//| OBJPROP_SELECTABLE - Object availability - bool;                  |
//+-------------------------------------------------------------------+
//| OBJPROP_RAY_LEFT - Ray goes to the left - bool;                   |
//+-------------------------------------------------------------------+
//| OBJPROP_RAY_RIGHT - Ray goes to the right - bool;                 |
//+-------------------------------------------------------------------+
//| OBJPROP_RAY - A vertical line goes through all the windows of a   |
//| chart - bool;                                                     |
//+-------------------------------------------------------------------+
//| OBJPROP_ELLIPSE - Showing the full ellipse of the Fibonacci Arc   |
//| object (OBJ_FIBOARC) - bool;                                      |
//+-------------------------------------------------------------------+
//| OBJPROP_DRAWLINES - Displaying lines for marking the Elliott Wave |
//| - bool;                                                           |
//+-------------------------------------------------------------------+
//| OBJPROP_STATE - Button state (pressed / depressed) - bool;        |
//+-------------------------------------------------------------------+
//| OBJPROP_DATE_SCALE - Displaying the time scale for the Chart      |
//| object - bool;                                                    |
//+-------------------------------------------------------------------+
//| OBJPROP_PRICE_SCALE - Displaying the price scale for the Chart    |
//| object - bool;                                                    |
//+-------------------------------------------------------------------+
bool ObSetIntegerBool(long chart_ID,// chart identifier
                      string name,// object name
                      ENUM_OBJECT_PROPERTY_INTEGER prop_id,// property
                      bool prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,prop_id,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| ObSetIntegerBorderType (Setting property value, without modifier)|
//+------------------------------------------------------------------+
//| Set border type for the "Rectangle label" object                 |
//+------------------------------------------------------------------+
//| OBJPROP_BORDER_TYPE - Border type for the "Rectangle label"      |
//| object - ENUM_BORDER_TYPE;                                       |
//+------------------------------------------------------------------+
bool ObSetIntegerBorderType(long chart_ID,// chart identifier
                            string name,// object name
                            ENUM_BORDER_TYPE prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+--------------------------------------------------------------------+
//| ObSetIntegerColor (Setting property value, without modifier)       |
//| the values of the enumeration ENUM_OBJECT_PROPERTY_INTEGER:        |
//+--------------------------------------------------------------------+
//| OBJPROP_COLOR - Color (depending on the object type, controls      |
//| the color of lines, text etc.) - color                             |
//+--------------------------------------------------------------------+
//| OBJPROP_BGCOLOR -   Background color for OBJ_EDIT, OBJ_BUTTON,     |
//| OBJ_RECTANGLE_LABEL - color;                                       |
//+--------------------------------------------------------------------+
//| OBJPROP_BORDER_COLOR - Border color for OBJ_EDIT and               |
//| OBJ_BUTTON - color;                                                |
//+--------------------------------------------------------------------+
bool ObSetIntegerColor(long chart_ID,// chart identifier
                       string name,// object name
                       ENUM_OBJECT_PROPERTY_INTEGER prop_id,// property
                       color prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,prop_id,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| ObSetIntegerCorner (Setting property value, without modifier)    |
//+------------------------------------------------------------------+
//| Set the corner of the chart to link a graphical object           |
//+------------------------------------------------------------------+
//| OBJPROP_CORNER - Chart corner for attaching a graphical object   |
//| - ENUM_BASE_CORNER;                                              |
//+------------------------------------------------------------------+
bool ObSetIntegerCorner(long chart_ID,// chart identifier
                        string name,// object name
                        ENUM_BASE_CORNER prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+--------------------------------------------------------------------+
//| ObSetIntegerInt (Setting property value, without modifier)         |
//| модификатора)                                                      |
//| the values of the enumeration ENUM_OBJECT_PROPERTY_INTEGER:        |
//+--------------------------------------------------------------------+
//| OBJPROP_WIDTH - Line width - int;                                  |
//+--------------------------------------------------------------------+
//| OBJPROP_LEVELS - Number of levels - int;                           |
//+--------------------------------------------------------------------+
//| OBJPROP_FONTSIZE - Font size - int;                                |
//+--------------------------------------------------------------------+
//| OBJPROP_TIMEFRAMES - Visibility of an object at timeframes (a set  |
//| of flags) - int;                                                   |
//+--------------------------------------------------------------------+
//| OBJPROP_XDISTANCE - The distance in pixels along the X axis from   |
//| the binding corner (see note in MQL5 Reference) - int;             |
//+--------------------------------------------------------------------+
//| OBJPROP_YDISTANCE - The distance in pixels along the Y axis from   |
//| the binding corner (see note in MQL5 Reference) - int;             |
//+--------------------------------------------------------------------+
//| OBJPROP_XSIZE - The object's width along the X axis in pixels.     |
//| Specified for OBJ_LABEL (read only), OBJ_BUTTON, OBJ_CHART,        |
//| OBJ_BITMAP, OBJ_BITMAP_LABEL, OBJ_EDIT, OBJ_RECTANGLE_LABEL        |
//| objects. - int;                                                    |
//+--------------------------------------------------------------------+
//| OBJPROP_YSIZE - The object's height along the Y axis in pixels.    |
//| Specified for OBJ_LABEL (read only), OBJ_BUTTON, OBJ_CHART,        |
//| OBJ_BITMAP, OBJ_BITMAP_LABEL, OBJ_EDIT, OBJ_RECTANGLE_LABEL        |
//| objects. - int;                                                    |
//+--------------------------------------------------------------------+
//| OBJPROP_XOFFSET - The X coordinate of the upper left corner of the |
//| rectangular visible area in Bitmap Label and Bitmap graphical      |
//| objects (OBJ_BITMAP_LABEL и OBJ_BITMAP). The value is set in pixels|
//| relative to the upper left corner of the original image. - int;    |
//+--------------------------------------------------------------------+
//| OBJPROP_YOFFSET - The Y coordinate of the upper left corner of the |
//| rectangular visible area in Bitmap Label and Bitmap graphical      |
//| objects (OBJ_BITMAP_LABEL и OBJ_BITMAP). The value is set in pixels|
//| relative to the upper left corner of the original image. - int;    |
//+--------------------------------------------------------------------+
//| OBJPROP_CHART_SCALE - The scale for the Chart object  - int        |
//| value in the range 0–5                                             |
//+--------------------------------------------------------------------+
bool ObSetIntegerInt(long chart_ID,// chart identifier
                     string name,// object name
                     ENUM_OBJECT_PROPERTY_INTEGER prop_id,// property
                     int prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,prop_id,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| ObSetIntegerLineStyle (Setting property value, without modifier) |
//| the values of the enumeration ENUM_OBJECT_PROPERTY_INTEGER:      |
//+------------------------------------------------------------------+
//| OBJPROP_STYLE - Style - ENUM_LINE_STYLE;                         |
//+------------------------------------------------------------------+
bool ObSetIntegerLineStyle(long chart_ID,// chart identifier
                           string name,// object name
                           ENUM_LINE_STYLE prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+-------------------------------------------------------------------+
//| ObSetIntegerLong (Setting property value, without modifier)       |                                  
//| the values of the enumeration ENUM_OBJECT_PROPERTY_INTEGER:       |
//+-------------------------------------------------------------------+
//| OBJPROP_ZORDER - Priority of a graphical object for receiving the |
//| event of clicking on a chart (CHARTEVENT_CLICK). The default zero |
//| value is set when creating an object, but the priority can be     |
//| increased if necessary. When applying objects one over another    |
//| only one of them with the highest priority will receive the       |
//| CHARTEVENT_CLICK event.- long;                                    |
//+-------------------------------------------------------------------+
bool ObSetIntegerLong(long chart_ID,// chart identifier
                      string name,// object name
                      ENUM_OBJECT_PROPERTY_INTEGER prop_id,// property
                      long prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,prop_id,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+--------------------------------------------------------------------+
//| ObSetString (Setting property value, without modifier)             |
//| the values of the enumeration ENUM_OBJECT_PROPERTY_STRING:         |
//+--------------------------------------------------------------------+
//| OBJPROP_NAME - Object name - string;                               |
//+--------------------------------------------------------------------+
//| OBJPROP_TEXT -   Object description (text contained in the object)-|
//| string;                                                            |
//+--------------------------------------------------------------------+
//| OBJPROP_TOOLTIP - The text of a tooltip. If the property is not    |
//| set, then the tooltip generated automatically by the terminal is   |
//| shown. A tooltip can be disabled by setting the "\n" (line feed)   |
//| value to it - string;                                              |
//+--------------------------------------------------------------------+
//| OBJPROP_FONT - Font - string;                                      |
//+--------------------------------------------------------------------+
//| OBJPROP_SYMBOL Symbol for the Chart object - string.               |
//+--------------------------------------------------------------------+
bool ObSetString(long chart_ID,// chart identifier
                 string name,// object name
                 ENUM_OBJECT_PROPERTY_STRING prop_id,// property
                 string prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetString(chart_ID,name,prop_id,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| Functions for setting object properties with specifying a        |
//| modifier:                                                        |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| ObSetDoubleMod (Setting a property value indicating the modifier)|
//| the values of the enumeration ENUM_OBJECT_PROPERTY_DOUBLE:       |
//+------------------------------------------------------------------+
//| OBJPROP_PRICE - Price coordinate - double  modifier=number of    |
//| anchor point;                                                    |
//+------------------------------------------------------------------+
//| OBJPROP_LEVELVALUE - Level value - double  modifier=level number |
//+------------------------------------------------------------------+
bool ObSetDoubleMod(long chart_ID,// chart identifier
                    string name,// object name
                    ENUM_OBJECT_PROPERTY_DOUBLE prop_id,// property
                    int prop_modifier,// modifier
                    double prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetDouble(chart_ID,name,prop_id,prop_modifier,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| ObSetIntegerLelelColorMod (Setting a property value indicating   |
//| the modifier)                                                    |
//| the values of the enumeration ENUM_OBJECT_PROPERTY_INTEGER:      |
//+------------------------------------------------------------------+
//| OBJPROP_LEVELCOLOR - Color of the line-level - color modifier =  |
//| level number;                                                    |
//+------------------------------------------------------------------+
bool ObSetIntegerLevelColorMod(long chart_ID,// chart identifier
                               string name,// object name
                               int prop_modifier,// modifier
                               color prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_LEVELCOLOR,
      prop_modifier,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| ObSetIntegerLevelStyleMod (Setting a property value indicating   |
//| the modifier)                                                    |
//| the values of the enumeration ENUM_OBJECT_PROPERTY_INTEGER:      |
//+------------------------------------------------------------------+
//| OBJPROP_LEVELSTYLE - Style of the line-level ENUM_LINE_STYLE     |
//| modifier=level number;                                           |
//+------------------------------------------------------------------+
bool ObSetIntegerLevelStyleMod(long chart_ID,// chart identifier
                               string name,// object name
                               int prop_modifier,// modifier
                               ENUM_LINE_STYLE prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_LEVELSTYLE,
      prop_modifier,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| ObSetIntegerLevelWidthMod (Setting a property value indicating   |
//| the modifier)                                                    |
//| the values of the enumeration ENUM_OBJECT_PROPERTY_INTEGER:      |
//+------------------------------------------------------------------+
//| OBJPROP_LEVELWIDTH - Thickness of the line-level - int           |
//| modifier=level number;                                           |
//+------------------------------------------------------------------+
bool ObSetIntegerLevelWidthMod(long chart_ID,// chart identifier
                               string name,// object name
                               int prop_modifier,// modifier
                               int prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_LEVELWIDTH,
      prop_modifier,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| ObSetIntegerTimeMod (Setting a property value indicating the     |
//| modifier)                                                        |
//| the values of the enumeration ENUM_OBJECT_PROPERTY_INTEGER:      |
//+------------------------------------------------------------------+
//| OBJPROP_TIME - Time coordinate - datetime  modifier=number of    |
//| anchor point;                                                    |
//+------------------------------------------------------------------+
bool ObSetIntegerTimeMod(long chart_ID,// chart identifier
                         string name,// object name
                         int prop_modifier,// modifier
                         datetime prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_TIME,prop_modifier,
      prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+-----------------------------------------------------------------------+
//| ObSetStringMod (Setting a property value indicating the modifier)     |
//| the values of the enumeration ENUM_OBJECT_PROPERTY_STRING:            |
//+-----------------------------------------------------------------------+
//| OBJPROP_LEVELTEXT - Level description - string    modifier=level      |
//| number;                                                               |
//+-----------------------------------------------------------------------+
//| OBJPROP_BMPFILE - The name of BMP-file for Bitmap Label.              |
//| See also Resources - string                                           |
//| modifier: 0-state ON, 1-state OFF;                                    |
//+-----------------------------------------------------------------------+
bool ObSetStringMod(long chart_ID,// chart identifier
                    string name,// object name
                    ENUM_OBJECT_PROPERTY_STRING prop_id,// property
                    int prop_modifier,// modifier
                    string prop_value)// value
  {
   ResetLastError();
   if(!ObjectSetString(chart_ID,name,prop_id,prop_modifier,prop_value))
     {
      Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
            GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| Deleting objects                                                 |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Delete a single object with specified name                       |
//+------------------------------------------------------------------+
bool ObDelete(long chart_ID,string name)
  {
   if(ObjectFind(chart_ID,name)>-1)
     {
      ResetLastError();
      if(!ObjectDelete(chart_ID,name))
        {
         Print(LINE_NUMBER,__FUNCTION__,", Error Code = ",
               GetLastError(),", name: ",name);
         return(false);
        }
     }
   return(true);
  }
//+------------------------------------------------------------------+