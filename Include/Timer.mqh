//+------------------------------------------------------------------+
//|                                                        Timer.mqh |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+
#property copyright "Andrew Young"
#property link      "http://www.expertadvisorbook.com"

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/


#define TIME_ADD_MINUTE 60
#define TIME_ADD_HOUR 3600
#define TIME_ADD_DAY	86400
#define TIME_ADD_WEEK 604800


struct TimerBlock
{
	bool enabled;
	int start_day;
	int start_hour;
	int start_min;
	int end_day;
	int end_hour;
	int end_min;
};


//+------------------------------------------------------------------+
//| Timer Class                                                      |
//+------------------------------------------------------------------+

class CTimer
{
	private:
		bool TimerStarted, WeeklyTimerOn;
		datetime StartTime, EndTime;
		void PrintTimerMessage(bool pTimerOn);

	public:
      CTimer(){ WeeklyTimerOn = false;}
		bool CheckTimer(datetime pStartTime, datetime pEndTime, bool pLocalTime = true);
		bool DailyTimer(int pStartHour, int pStartMinute, int pEndHour, int pEndMinute, bool pLocalTime = false);
      bool WeeklyTimer(int pStartDay, int pStartHour, int pEndDay, int pEndHour, bool pLocalTime = false);
		bool BlockTimer(TimerBlock &pBlock[], bool pLocalTime = false);
//		bool DaylyTimer(int pStartHour, int pEndHour, bool pLocalTime = false);
		datetime GetStartTime() {return(StartTime);};
		datetime GetEndTime() {return(EndTime);};

};


// Daily timer
bool CTimer::DailyTimer(int pStartHour, int pStartMinute, int pEndHour, int pEndMinute, bool pLocalTime=false)
{
	datetime currentTime;
	if(pLocalTime == true) currentTime = TimeLocal();
	else currentTime = TimeCurrent();
	
	StartTime = CreateDateTime(pStartHour,pStartMinute, pLocalTime);	
	EndTime = CreateDateTime(pEndHour,pEndMinute, pLocalTime);
	
	if(EndTime <= StartTime)	
	{
		StartTime -= TIME_ADD_DAY;
		
		if(currentTime > EndTime)
		{
			StartTime += TIME_ADD_DAY;
			EndTime += TIME_ADD_DAY;
		}
	} 
	
	bool timerOn = CheckTimer(StartTime,EndTime,pLocalTime);
	PrintTimerMessage(timerOn);
	
	return(timerOn);
}

//Weekly timer
bool CTimer::WeeklyTimer(int pStartDay, int pStartHour, int pEndDay, int pEndHour, bool pLocalTime = false)
{
   datetime currentTime;
   MqlDateTime timeStruct;

   if(pLocalTime == true) currentTime = TimeLocal();
   else currentTime = TimeCurrent();
   
   TimeToStruct(currentTime, timeStruct);
   if( (timeStruct.day_of_week == pStartDay) && (timeStruct.hour >= pStartHour ))
         WeeklyTimerOn = true;
   else if((timeStruct.day_of_week == pEndDay ) && (timeStruct.hour >= pEndHour ))
         WeeklyTimerOn = false;
   
   return(WeeklyTimerOn);
}

/*
bool CTimer::DaylyTimer(int pStartHour, int pEndHour, bool pLocalTime = false)
{
   datetime currentTime;
   MqlDateTime timeStruct;
   bool _DaylyTimerOn;

   if(pLocalTime == true) currentTime = TimeLocal();
   else currentTime = TimeCurrent();
   
   TimeToStruct(currentTime, timeStruct);
   if( (timeStruct.day_of_week != SUNDAY) && (timeStruct.day_of_week != SATURDAY) && 
                           (timeStruct.hour >= pStartHour ) && (timeStruct.hour < pEndHour ) ) _DaylyTimerOn = true;
   else _DaylyTimerOn = false;
   
   return(_DaylyTimerOn);
}
*/

// Block timer
bool CTimer::BlockTimer(TimerBlock &pBlock[], bool pLocalTime=false)
{
	MqlDateTime today;
	bool timerOn = false;
	int timerCount = ArraySize(pBlock);
	
	for(int i = 0; i < timerCount; i++)
	{
		if(pBlock[i].enabled == false) continue;
		
		StartTime = CreateDateTime(pBlock[i].start_hour, pBlock[i].start_min);	
		EndTime = CreateDateTime(pBlock[i].end_hour, pBlock[i].end_min);
		
		TimeToStruct(StartTime,today);
		int dayShift = pBlock[i].start_day - today.day_of_week;
		if(dayShift != 0) StartTime += TIME_ADD_DAY * dayShift;
		
		TimeToStruct(EndTime,today);
		dayShift = pBlock[i].end_day - today.day_of_week;
		if(dayShift != 0) EndTime += TIME_ADD_DAY * dayShift;
		
		timerOn = CheckTimer(StartTime,EndTime,pLocalTime);
		if(timerOn == true) break;
	}
	
	PrintTimerMessage(timerOn);
	
	return(timerOn);
}


// Check timer
bool CTimer::CheckTimer(datetime pStartTime, datetime pEndTime, bool pLocalTime=true)
{
	if(pStartTime >= pEndTime)
	{
		Alert("Error: Invalid start or end time");
		return(false);
	}
	
	datetime currentTime;
	if(pLocalTime == true) currentTime = TimeLocal();
	else currentTime = TimeCurrent();
	
	bool timerOn = false;
	if(currentTime >= pStartTime && currentTime < pEndTime) 
	{
		timerOn = true;
	}
	
	return(timerOn);
}


// Print a message to the screen
void CTimer::PrintTimerMessage(bool pTimerOn)
{
	if(pTimerOn == true && TimerStarted == false)
	{
		string message = "Timer started";
		Print(message);
		Comment(message);
		TimerStarted = true;
	}
	else if(pTimerOn == false && TimerStarted == true)
	{
		string message = "Timer stopped";
		Print(message);
		Comment(message);
		TimerStarted = false;
	}
}


// Create datetime value
datetime CreateDateTime(int pHour = 0, int pMinute = 0, bool pLocalTime = false) 
{
	MqlDateTime timeStruct;
	if(pLocalTime == true) TimeToStruct(TimeLocal(), timeStruct);
	else TimeToStruct(TimeCurrent(),timeStruct);
	
	timeStruct.hour = pHour;
	timeStruct.min = pMinute;
	
	datetime useTime = StructToTime(timeStruct);
	
	return(useTime);
}


//+------------------------------------------------------------------+
//| Check for New Bar                                                |
//+------------------------------------------------------------------+

class CNewBar
{
	private:
		datetime Time[], LastTime;
	
	public:
		void CNewBar();
		bool CheckNewBar(string pSymbol, ENUM_TIMEFRAMES pTimeframe);
};


void CNewBar::CNewBar(void)
{
	ArraySetAsSeries(Time,true);
}


bool CNewBar::CheckNewBar(string pSymbol,ENUM_TIMEFRAMES pTimeframe)
{
	bool firstRun = false, newBar = false;
	CopyTime(pSymbol,pTimeframe,0,2,Time);
	
	if(LastTime == 0) firstRun = true;
	
	if(Time[0] > LastTime)
	{
		if(firstRun == false) newBar = true;
		LastTime = Time[0];
	}
	
	return(newBar);
}