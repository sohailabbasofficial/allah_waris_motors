$ErrorActionPreference = 'Stop'
$path = 'C:\src\car_rental_manager\pubspec.yaml'
$content = @'
name: car_rental_manager
description: Allah Waris Motors - local SQLite app with Riverpod and Clean Architecture.
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ^3.8.0

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  sqflite: ^2.4.2
  path: ^1.9.1
  path_provider: ^2.1.5
  shared_preferences: ^2.5.3
  intl: ^0.20.2
  cupertino_icons: ^1.0.8
  local_auth: ^2.3.0
  crypto: ^3.0.6
  package_info_plus: ^8.3.0
  google_sign_in: ^7.2.0
  googleapis: ^16.0.0
  googleapis_auth: ^2.3.3
  extension_google_sign_in_as_googleapis_auth: ^3.0.0
  connectivity_plus: ^7.2.0
  http: ^1.6.0
  flutter_local_notifications: ^22.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.14.4

flutter:
  uses-material-design: true
  assets:
    - assets/images/logo.png
    - assets/images/splash_bg.png
    - assets/images/app_icon.png

flutter_launcher_icons:
  android: true
  ios: true
  image_path: assets/images/app_icon.png
  adaptive_icon_background: "#F8F9FA"
  adaptive_icon_foreground: assets/images/app_icon.png
  adaptive_icon_foreground_inset: 16
  remove_alpha_ios: true
  web:
    generate: true
    image_path: assets/images/app_icon.png
    background_color: "#F8F9FA"
    theme_color: "#003B95"
  windows:
    generate: true
    image_path: assets/images/app_icon.png
    icon_size: 256
'@
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($path, $content, $utf8)
$bytes = [System.IO.File]::ReadAllBytes($path)
Write-Host ("Wrote UTF-8 pubspec, first bytes: " + ($bytes[0..7] -join ','))
