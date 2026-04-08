#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  Habit Tracker — Build Script for GitHub Codespaces
#  Run this once inside your Codespace terminal
# ─────────────────────────────────────────────────────────────

set -e

echo "📦 Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter
export PATH="$PATH:$HOME/flutter/bin"
flutter --version

echo ""
echo "📱 Accepting Android licenses..."
yes | flutter doctor --android-licenses 2>/dev/null || true

echo ""
echo "🔧 Getting dependencies..."
cd /workspaces/habit_tracker   # ← adjust if your repo is named differently
flutter pub get

echo ""
echo "🔨 Building APK (release mode)..."
flutter build apk --release

echo ""
echo "✅ Done! Your APK is at:"
echo "   build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "Download it from the Codespaces file explorer and install on your phone."
echo "On Android: enable 'Install from unknown sources' in Settings > Security"
