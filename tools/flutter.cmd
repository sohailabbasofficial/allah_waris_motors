@echo off
setlocal
set "FLUTTER_ROOT=%USERPROFILE%\develop\flutter"
set "DART=%FLUTTER_ROOT%\bin\cache\dart-sdk\bin\dart.exe"
set "SNAPSHOT=%FLUTTER_ROOT%\bin\cache\flutter_tools.snapshot"
set "PACKAGES=%FLUTTER_ROOT%\packages\flutter_tools\.dart_tool\package_config.json"
if not exist "%DART%" (
  echo Flutter SDK not found at %FLUTTER_ROOT%
  exit /b 1
)
"%DART%" --packages="%PACKAGES%" "%SNAPSHOT%" %*
exit /b %ERRORLEVEL%