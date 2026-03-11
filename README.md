# Total Athlete 💪

> A powerful mobile-first fitness app designed for serious lifters, offering data-driven workout tracking and advanced training analytics.

[![Flutter](https://img.shields.io/badge/Flutter-Stable-02569B?logo=flutter)](https://flutter.dev)
[![iOS](https://img.shields.io/badge/iOS-12.0+-000000?logo=apple)](https://www.apple.com/ios)
[![Android](https://img.shields.io/badge/Android-API%2021+-3DDC84?logo=android)](https://www.android.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🎯 Features

### Core Functionality
- **Workout Tracking** - Log exercises, sets, reps, and weight with intuitive UI
- **Smart Progressions** - AI-powered suggestions based on previous workouts
- **Training Programs** - Pre-built and custom workout routines
- **Bodyweight Tracking** - Monitor weight trends with linear regression analysis
- **Exercise Analytics** - Detailed progress charts for every movement
- **Personal Records** - Automatic PR detection and celebration
- **Muscle Heat Maps** - Visual representation of muscle group training volume
- **Load Score Trends** - Track training load over time
- **Recovery Calculator** - Optimize rest periods between sessions

### Advanced Features
- **Spreadsheet Import** - Import workout data from Excel/CSV files
- **Plate Calculator** - Quick barbell loading calculations
- **Custom Exercises** - Create and track your own movements
- **Workout History** - Complete training log with filtering and search
- **Dark Mode** - Eye-friendly interface for gym lighting
- **Offline First** - All data stored locally with SharedPreferences

### Developer Features
- **Firebase Crashlytics** - Production crash reporting
- **Route-level Analytics** - Track user navigation patterns
- **Non-fatal Error Reporting** - Debug issues in beta testing
- **Developer Tools** - Hidden settings for testing crash reporting

---

## 📱 Screenshots

*(Add screenshots here after app is built)*

---

## 🏗️ Tech Stack

- **Framework:** Flutter (Stable)
- **State Management:** Provider
- **Navigation:** GoRouter
- **Charts:** FL Chart
- **Persistence:** SharedPreferences
- **Crash Reporting:** Firebase Crashlytics
- **UI:** Material Design with custom theming

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Stable channel)
- Xcode 13+ (for iOS development)
- Android Studio (for Android development)
- CocoaPods (for iOS dependencies)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/total-athlete.git
   cd total-athlete
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Install iOS dependencies**
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. **Run the app**
   ```bash
   # iOS
   flutter run -d ios
   
   # Android
   flutter run -d android
   ```

### Local Build Verification

Run the verification script to ensure everything is configured correctly:

```bash
chmod +x verify_build.sh
./verify_build.sh
```

---

## 🔧 Configuration

### iOS Setup

- **Bundle ID:** `com.justingallahar.totalathlete`
- **Display Name:** Total Athlete
- **Deployment Target:** iOS 12.0+
- **Signing:** Configured via Codemagic

### Android Setup

- **Package Name:** `com.justingallahar.totalathlete`
- **Min SDK:** 21 (Android 5.0)
- **Target SDK:** 34 (Android 14)

### Firebase Setup

Firebase Crashlytics is integrated for crash reporting. To enable:

1. Add your `GoogleService-Info.plist` (iOS) to `ios/Runner/`
2. Add your `google-services.json` (Android) to `android/app/`
3. Configure Firebase project at https://console.firebase.google.com

---

## 📦 CI/CD

This project uses **Codemagic** for automated builds and TestFlight distribution.

### Codemagic Configuration

The `codemagic.yaml` file includes:
- ✅ Automatic iOS builds
- ✅ TestFlight publishing
- ✅ Android APK/AAB builds
- ✅ Automated version bumping
- ✅ Email notifications

### Build Workflows

**iOS Workflow:**
1. Flutter pub get
2. CocoaPods install
3. Code signing setup
4. Flutter analyze
5. Build IPA
6. Upload to TestFlight

**Android Workflow:**
1. Flutter pub get
2. Flutter analyze
3. Build APK
4. Build AAB
5. Upload to Google Play (internal track)

---

## 📊 Project Structure

```
total_athlete/
├── android/              # Android platform files
├── ios/                  # iOS platform files
├── lib/
│   ├── main.dart        # App entry point
│   ├── models/          # Data models
│   ├── screens/         # UI screens
│   ├── services/        # Business logic
│   ├── widgets/         # Reusable components
│   ├── utils/           # Helper functions
│   ├── providers/       # State management
│   ├── nav.dart         # GoRouter configuration
│   └── theme.dart       # App theming
├── assets/
│   ├── icons/           # App icons
│   └── images/          # Exercise images
├── web/                 # Web platform files
├── codemagic.yaml       # CI/CD configuration
├── pubspec.yaml         # Dependencies
└── README.md
```

---

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Run Analyzer
```bash
flutter analyze
```

### Test Crash Reporting
1. Open app
2. Go to Settings → Developer Tools
3. Tap "Test Non-Fatal Error"
4. Check Firebase Console for logged error

---

## 🐛 Known Issues

- None currently reported

---

## 🗺️ Roadmap

- [ ] Cloud sync with Firebase/Supabase
- [ ] Social features (share workouts, PRs)
- [ ] Video exercise demonstrations
- [ ] Apple Health integration
- [ ] Google Fit integration
- [ ] Nutrition tracking
- [ ] Custom workout builder UI
- [ ] Export workouts to PDF

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Justin Gallahar**

- Email: justin@example.com
- GitHub: [@justingallahar](https://github.com/justingallahar)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for crash reporting
- FL Chart for beautiful charts
- All contributors and testers

---

## 📞 Support

For support, email justin@example.com or open an issue on GitHub.

---

**Built with ❤️ and Flutter**
