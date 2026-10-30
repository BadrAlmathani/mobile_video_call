@echo off
chcp 65001 > nul
echo ==========================================
echo  🔨 بناء ملف APK لتطبيق Flutter WebRTC (ويندوز)
echo ==========================================

cd /d "%~dp0"

echo 1. التحقق من تثبيت Flutter...
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ❌ خطأ: لم يتم العثور على أمر flutter في PATH. يرجى تثبيت Flutter SDK.
    pause
    exit /b 1
)

echo 2. تنزيل حزم واعتماديات Dart...
call flutter pub get

echo 3. بناء نسخة Release APK المخصصة للهواتف...
call flutter build apk --release

echo ==========================================
echo ✅ تم البناء بنجاح!
echo 📁 مسار ملف الـ APK:
echo    %~dp0build\app\outputs\flutter-apk\app-release.apk
echo ==========================================
pause
