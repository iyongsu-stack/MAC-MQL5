---
description: MQL5 소스 파일 컴파일 (MetaEditor64)
---
// turbo-all

## MQL5 컴파일 워크플로우

1. 컴파일 대상 파일 경로를 확인합니다.
2. MetaEditor64로 컴파일을 실행합니다:
```powershell
& "C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:"<대상파일경로>" /log
```
3. 컴파일 로그 파일(.log)을 확인하여 오류 여부를 점검합니다:
```powershell
Get-Content "<대상파일경로>.log"
```
4. 오류가 있으면 코드를 수정하고 2번부터 반복합니다 (최대 3회).
5. 컴파일 성공 시 결과를 사용자에게 보고합니다.
