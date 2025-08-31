# Firebase Setup Guide for HabitGo

## Prerequisites

- Google account
- Flutter project set up

## Step 1: Create Firebase Project

1. **Go to Firebase Console**

   - Visit [https://console.firebase.google.com/](https://console.firebase.google.com/)
   - Sign in with your Google account

2. **Create New Project**

   - Click "Create a project" or "Add project"
   - Enter project name: `habitgo` (or your preferred name)
   - Choose whether to enable Google Analytics (recommended: Yes)
   - Click "Create project"

3. **Wait for Project Creation**
   - Firebase will create your project (this may take a few minutes)
   - Click "Continue" when ready

## Step 2: Enable Authentication

1. **Navigate to Authentication**

   - In the left sidebar, click "Authentication"
   - Click "Get started"

2. **Enable Email/Password Sign-in**
   - Click on "Email/Password" provider
   - Toggle "Enable" to turn it on
   - Click "Save"

## Step 3: Create Firestore Database

1. **Navigate to Firestore Database**

   - In the left sidebar, click "Firestore Database"
   - Click "Create database"

2. **Choose Security Rules**

   - Select "Start in test mode" (we'll secure it later)
   - Click "Next"

3. **Choose Location**
   - Select a location closest to your users
   - Click "Enable"

## Step 4: Set Up Firestore Security Rules

1. **Go to Rules Tab**

   - In Firestore Database, click "Rules" tab

2. **Replace Default Rules**
   - Replace the existing rules with the following secure rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Users can access their own habits
      match /habits/{habitId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      // Users can access their own favorite quotes
      match /favorites/quotes/{quoteId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

3. **Publish Rules**
   - Click "Publish"

## Step 5: Get Firebase Configuration

1. **Open Project Settings**

   - Click the gear icon (⚙️) next to "Project Overview"
   - Select "Project settings"

2. **Add Web App**

   - Scroll down to "Your apps" section
   - Click the web icon (</>)
   - Register app with nickname: `HabitGo Web`
   - Click "Register app"

3. **Copy Configuration**
   - Copy the Firebase config object that looks like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyC...",
  authDomain: "habitgo-12345.firebaseapp.com",
  projectId: "habitgo-12345",
  storageBucket: "habitgo-12345.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123def456",
  measurementId: "G-ABC123DEF4",
};
```

## Step 6: Update Your App Configuration

1. **Update `lib/config/firebase_options.dart`**
   - Replace all `YOUR_*` values with your actual Firebase configuration
   - Example for web:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyC...', // Your actual API key
  appId: '1:123456789:web:abc123def456', // Your actual app ID
  messagingSenderId: '123456789', // Your actual sender ID
  projectId: 'habitgo-12345', // Your actual project ID
  authDomain: 'habitgo-12345.firebaseapp.com', // Your actual auth domain
  storageBucket: 'habitgo-12345.appspot.com', // Your actual storage bucket
  measurementId: 'G-ABC123DEF4', // Your actual measurement ID
);
```

2. **Update `web/firebase-config.js`**
   - Replace all `YOUR_*` values with your actual Firebase configuration

## Step 7: Test Your Setup

1. **Run the App**

   ```bash
   flutter run -d chrome
   ```

2. **Check Firebase Connection**
   - Open browser console (F12)
   - Look for "Firebase initialized successfully" message
   - Check for any Firebase-related errors

## Step 8: Create Test Data (Optional)

1. **Go to Firestore Database**
   - Click "Start collection"
   - Collection ID: `users`
   - Document ID: `test-user-123`
   - Add fields:
     - `displayName`: "Test User"
     - `email`: "test@example.com"
     - `createdAt`: Current timestamp

## Troubleshooting

### Common Issues:

1. **"Firebase not initialized" error**

   - Check that your configuration values are correct
   - Ensure Firebase SDK scripts are loaded in index.html

2. **Authentication errors**

   - Verify Email/Password provider is enabled
   - Check security rules are published

3. **Firestore permission errors**

   - Ensure security rules are correct
   - Check that rules are published

4. **Web compatibility issues**
   - Use the Firebase compat version scripts
   - Ensure all required Firebase services are enabled

## Security Best Practices

1. **Never expose API keys in public repositories**
2. **Use environment variables for production**
3. **Regularly review and update security rules**
4. **Enable Firebase App Check for production apps**

## Next Steps

After successful setup:

1. Test user registration and login
2. Test habit creation and storage
3. Test quote favoriting functionality
4. Deploy to production with proper security rules

## Support

If you encounter issues:

1. Check Firebase Console for error logs
2. Review Firebase documentation
3. Check Flutter Firebase plugin documentation
4. Use Firebase support channels
