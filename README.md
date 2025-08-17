# HabitGo - Habit Tracking App

A comprehensive Flutter-based habit tracking application that helps users create, manage, and track daily habits with progress visualization and motivational quotes.

## 🚀 Features

### Core Functionality
- **User Authentication & Registration**
  - Email/password registration with validation
  - Secure login with session management
  - User profile management with editable fields
  - Terms & conditions acceptance

- **Habit Management**
  - Create, edit, and delete habits
  - Categorize habits (Health, Study, Fitness, Productivity, Mental Health, Others)
  - Set frequency (Daily/Weekly)
  - Add notes and start dates
  - Track completion status

- **Progress Tracking**
  - Real-time streak calculation
  - Completion history tracking
  - Visual progress charts using fl_chart
  - Today's habit overview with completion status

- **Motivational Quotes**
  - Fetch quotes from external API (Quotable)
  - Add/remove quotes to favorites
  - Copy quotes to clipboard
  - Fallback quotes when API is unavailable

- **Theme & Personalization**
  - Light/Dark mode toggle
  - Theme preference synced with Firebase
  - Modern Material Design 3 UI
  - Responsive design for all screen sizes

### Technical Features
- **Firebase Integration**
  - Authentication (Firebase Auth)
  - Real-time database (Cloud Firestore)
  - Data synchronization across devices
  - Offline support with local caching

- **State Management**
  - Provider pattern for efficient state management
  - Real-time updates and notifications
  - Optimized performance with minimal rebuilds

- **Data Persistence**
  - Local storage with SharedPreferences
  - Firebase cloud synchronization
  - Automatic data backup and restore

## 📱 Screenshots

*[Screenshots will be added here after app testing]*

## 🛠️ Technology Stack

- **Frontend**: Flutter 3.8+
- **Backend**: Firebase (Auth, Firestore)
- **State Management**: Provider
- **Charts**: fl_chart
- **Local Storage**: SharedPreferences
- **HTTP Requests**: http package
- **Date Handling**: intl package

## 📋 Requirements

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Android Studio / VS Code
- Firebase project setup
- Android API level 21+ / iOS 11.0+

## 🔧 Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/habitgo.git
cd habitgo
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable Authentication (Email/Password)
4. Create Firestore database
5. Set security rules for Firestore

#### Configure Firebase in Flutter
1. Download `google-services.json` for Android
2. Download `GoogleService-Info.plist` for iOS
3. Place files in respective platform directories

#### Android Setup
- Place `google-services.json` in `android/app/`
- Update `android/build.gradle` with Firebase classpath
- Update `android/app/build.gradle` with Firebase plugin

#### iOS Setup
- Place `GoogleService-Info.plist` in `ios/Runner/`
- Update `ios/Runner/Info.plist` with Firebase configuration

### 4. Run the App
```bash
flutter run
```

## 🗄️ Database Structure

### Firestore Collections

#### Users Collection
```
users/{userId}
├── displayName: string
├── email: string
├── gender: string (optional)
├── dateOfBirth: timestamp (optional)
├── height: number (optional)
├── createdAt: timestamp
├── lastUpdated: timestamp
├── isDarkMode: boolean
└── favoriteQuotes: array
```

#### Habits Collection
```
users/{userId}/habits/{habitId}
├── userId: string
├── title: string
├── category: string
├── frequency: string
├── startDate: timestamp (optional)
├── notes: string (optional)
├── createdAt: timestamp
├── currentStreak: number
├── completionHistory: array<timestamp>
└── isActive: boolean
```

#### Favorites Collection
```
users/{userId}/favorites/quotes/{quoteId}
├── text: string
├── author: string
└── isFavorite: boolean
```

## 🎯 Usage Guide

### Getting Started
1. **Register/Login**: Create an account or sign in with existing credentials
2. **Create Habits**: Add your first habit with title, category, and frequency
3. **Track Progress**: Mark habits as completed daily/weekly
4. **View Progress**: Check streaks and completion history
5. **Stay Motivated**: Read and save inspirational quotes

### Creating Habits
- Choose a descriptive title
- Select appropriate category
- Set frequency (daily for regular habits, weekly for occasional ones)
- Add optional notes for context
- Set start date if different from today

### Tracking Completion
- Mark habits as completed on the home screen
- View current streak and total completions
- Check progress charts for visual feedback
- Filter habits by category for better organization

### Managing Profile
- Update personal information
- Toggle between light and dark themes
- View account statistics
- Manage favorite quotes

## 🔒 Security Features

- Firebase Authentication with email/password
- Secure Firestore rules
- Input validation and sanitization
- Session management with local storage
- Secure API communication

## 📊 Performance Features

- Efficient state management with Provider
- Real-time data synchronization
- Offline support with local caching
- Optimized UI rendering
- Minimal network requests

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

## 🚀 Deployment

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Developer

**Zia Khan**
- Email: developer.ziakhan@gmail.com
- GitHub: [@ziakhan](https://github.com/ziakhan)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Quotable API for motivational quotes
- Open source community for packages and inspiration

## 📞 Support

For support, email developer.ziakhan@gmail.com or create an issue in the repository.

## 🔄 Version History

- **v1.0.0** - Initial release with core features
  - User authentication and registration
  - Habit creation and management
  - Progress tracking and visualization
  - Motivational quotes system
  - Theme customization
  - Firebase integration

---

**HabitGo** - Track your habits, achieve your goals! 🎯
# Habit_GO
