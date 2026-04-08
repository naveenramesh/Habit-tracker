# 🧠 Habit Tracker

Personal habit tracker — offline first, export/import supported.

## Features (MVP)
- ✅ Binary and quantitative habits
- 🔥 Streak tracking (current + longest)
- 📊 Completion rate (7-day, 30-day, all-time)
- 🗓️ Heatmap calendar (last 16 weeks)
- 📝 Notes + skip with reason
- 🌙 Light / dark / system theme
- 💾 Export to JSON (share anywhere)
- 📥 Import from JSON backup
- 📴 100% offline — SQLite on device

---

## 🚀 How to build the APK (GitHub Codespaces)

### Step 1 — Push this project to GitHub
```bash
git init
git add .
git commit -m "Initial habit tracker"
git remote add origin https://github.com/YOUR_USERNAME/habit_tracker.git
git push -u origin main
```

### Step 2 — Open in Codespaces
- Go to your GitHub repo → **Code** → **Codespaces** → **Create codespace on main**

### Step 3 — Set up Java (required for Android build)
In the Codespace terminal:
```bash
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

### Step 4 — Install Flutter
```bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter
export PATH="$PATH:$HOME/flutter/bin"
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
flutter --version
```

### Step 5 — Install Android command-line tools
```bash
mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip
mv cmdline-tools latest

export ANDROID_HOME=~/android-sdk
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
echo 'export ANDROID_HOME=~/android-sdk' >> ~/.bashrc
echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"' >> ~/.bashrc

yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

### Step 6 — Build the APK
```bash
cd /workspaces/habit_tracker
flutter pub get
flutter build apk --release
```

### Step 7 — Download the APK
Your APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```
In Codespaces: right-click the file → **Download**

### Step 8 — Install on Android
1. Transfer APK to your phone
2. Go to **Settings → Security → Install unknown apps** → allow your browser/file manager
3. Tap the APK file to install

---

## 📁 Project structure
```
lib/
├── main.dart              # App entry
├── models/
│   ├── habit.dart         # Habit model
│   └── habit_log.dart     # Log model
├── database/
│   └── db_helper.dart     # SQLite operations + stats
├── services/
│   └── export_import_service.dart
├── screens/
│   ├── home_screen.dart        # Today + All habits tabs
│   ├── add_edit_habit_screen.dart
│   ├── habit_detail_screen.dart  # Heatmap + stats
│   └── settings_screen.dart
├── widgets/
│   ├── habit_card.dart
│   └── heatmap_widget.dart
└── theme/
    └── app_theme.dart
```

---

## 🔄 Export / Import
- **Export**: Settings → Export data → share the `.json` file to yourself (email, Drive, etc.)
- **Import**: Settings → Import data → pick the `.json` file → confirms before replacing data

The backup file contains all habits and all logs in a portable JSON format.
