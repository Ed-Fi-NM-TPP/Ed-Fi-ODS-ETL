ECHO OFF

set root=\\PED-UDP_DB\Ed-Fi
rem set root=%~dp0..\..
set source=PED-UDP_DB
set db=EdFi_Ods_Sandbox_FVApuqeYBgIx

ECHO ON

%root%\EdFi.Ods.BulkLoad.Console\EdFi.Ods.BulkLoad.Console.exe /f %root%\interchange\xml /m %root%\interchange\manifest\%1.xml > %root%\interchange\out\%1.txt /c "Data Source=%source%;Initial Catalog=%db%;Integrated Security=True"