#!/usr/bin/env bash
set -e

echo "=========================================="
echo " 🔨 بناء ملف APK لتطبيق Flutter WebRTC"
echo "=========================================="

cd "$(dirname "$0")"

echo "1. التحقق من تثبيت Flutter..."
if ! command -v flutter &> /dev/null; then
    echo "❌ خطأ: لم يتم العثور على أمر flutter. يرجى تثبيت Flutter SDK أولاً."
    exit 1
fi

echo "2. تنزيل حزم واعتماديات Dart..."
flutter pub get

echo "3. بناء نسخة Release APK المخصصة للهواتف..."
flutter build apk --release

echo "=========================================="
echo "✅ تم البناء بنجاح!"
echo "📁 مسار ملف الـ APK:"
echo "   $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
echo "=========================================="
