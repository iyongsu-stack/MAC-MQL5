//+------------------------------------------------------------------+
//|                                                       IncGUI.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

class CGraphicObjectShell
  {
   protected:
      string            m_name;
      long              m_id;

   public:
      void Attach(string aName,long aChartID=0)
        {
         m_name=aName;
         m_id=aChartID;
        }
      string Name()
        {
         return(m_name);
        }    
      long ChartID()
        {
        return(m_id);
        }
  };


ObjectCreate(m_id,m_name,OBJ_VLINE,aSubWindow,0,0);