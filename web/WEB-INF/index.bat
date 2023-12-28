@echo off 
setlocal
SET DIR=%~dp0
java -cp "%DIR%/lib/*" com.github.oeuvres.alix.cli.Load %*
REM TOUCH ?
REM @COPY /B %DIR%web.xml +,,

