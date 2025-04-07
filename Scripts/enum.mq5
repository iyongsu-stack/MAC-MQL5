
void OnStart()
  {
   
  int intergerArray1[10];
  int fullIntergerArray[10]={1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
  
  int dynamicArray[] = {1, 2, 3};
  int dynamicArray2[];
  
   
  int arraySize = ArraySize(dynamicArray);
  //PrintFormat("The array has %d elements", arraySize);
  
  for(int i=0; i<= arraySize-1; i++){


//   PrintFormat("index %d, array value is %d", i, dynamicArray[i]);
      int value = dynamicArray[i];
      
      ArrayResize(dynamicArray2, ArraySize(dynamicArray2)+1, 0);
      dynamicArray2[i] = dynamicArray[i]*3;
         
      value = dynamicArray2[i];
      PrintFormat("The array element of index %d has value %d", i, value);
         
   }
   
      
  }
//+------------------------------------------------------------------+
