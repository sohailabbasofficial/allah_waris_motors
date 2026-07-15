param([Parameter(ValueFromRemainingArguments=$true)]$Args)
$FlutterRoot = Join-Path $env:USERPROFILE "develop\flutter"
$Dart = Join-Path $FlutterRoot "bin\cache\dart-sdk\bin\dart.exe"
$Snapshot = Join-Path $FlutterRoot "bin\cache\flutter_tools.snapshot"
$Packages = Join-Path $FlutterRoot "packages\flutter_tools\.dart_tool\package_config.json"
& $Dart --packages=$Packages $Snapshot @Args
exit $LASTEXITCODE