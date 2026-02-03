//+------------------------------------------------------------------+
//| Custom helper function to check calculation time                 |
//+------------------------------------------------------------------+
bool IsStdCalculationTime(datetime time) {
  MqlDateTime dt;
  TimeToStruct(time, dt);

  int currentMinutes = dt.hour * 60 + dt.min;
  int startMinutes = StdCalcStartTimeHour * 60 + StdCalcStartTimeMinute;
  int endMinutes = StdCalcEndTimeHour * 60 + StdCalcEndTimeMinute;

  // Case 1: Start < End (e.g., 01:30 to 23:30)
  if (startMinutes < endMinutes) {
    return (currentMinutes >= startMinutes && currentMinutes < endMinutes);
  }
  // Case 2: Start > End (e.g., 22:00 to 06:00)
  else {
    return (currentMinutes >= startMinutes || currentMinutes < endMinutes);
  }
}

