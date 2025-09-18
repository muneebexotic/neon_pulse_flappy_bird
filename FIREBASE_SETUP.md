# Firebase Setup Instructions

## Prerequisites

1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Authentication with Google Sign-In provider
3. Enable Firestore Database
4. Set up your app in the Firebase console

## Step-by-Step Firebase Console Setup

### 1. Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click "Create a project" or "Add project"
3. Enter your project name (e.g., "neon-pulse-flappy-bird")
4. Choose whether to enable Google Analytics (recommended)
5. Click "Create project"

### 2. Enable Authentication
1. In your Firebase project, click "Authentication" in the left sidebar
2. Click "Get started" if it's your first time
3. Go to the "Sign-in method" tab
4. Click on "Google" provider
5. Toggle "Enable" to ON
6. Enter your project support email
7. Click "Save"

### 3. Enable Firestore Database
1. In your Firebase project, click "Firestore Database" in the left sidebar
2. Click "Create database"
3. Choose "Start in test mode" (we'll add security rules later)
4. Select a location for your database (choose closest to your users)
5. Click "Done"

### 4. Set Up Security Rules
1. In Firestore Database, go to the "Rules" tab
2. Replace the default rules with the content from `firestore.rules` file in your project
3. Click "Publish" to deploy the rules

### 5. Add Your Apps
1. In Project Overview, click the Android icon to add Android app
2. Enter package name: `com.example.neon_pulse_flappy_bird`
3. Download `google-services.json` (you've already done this ✅)
4. For iOS: Click the iOS icon and add iOS app
5. Enter bundle ID: `com.example.neonPulseFlappyBird`
6. Download `GoogleService-Info.plist`

## Configuration Files

### Android Setup

1. In the Firebase console, add an Android app with package name: `com.example.neon_pulse_flappy_bird`
2. Download the `google-services.json` file
3. Place it in `android/app/google-services.json` (replace the template file)

### iOS Setup

1. In the Firebase console, add an iOS app with bundle ID: `com.example.neonPulseFlappyBird`
2. Download the `GoogleService-Info.plist` file
3. Place it in `ios/Runner/GoogleService-Info.plist` (replace the template file)
4. Add the file to your Xcode project

### iOS Additional Configuration

Add the following to `ios/Runner/Info.plist` inside the `<dict>` tag:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID_FROM_PLIST</string>
        </array>
    </dict>
</array>
```

Replace `YOUR_REVERSED_CLIENT_ID_FROM_PLIST` with the actual value from your GoogleService-Info.plist file.

## Firestore Security Rules

After enabling Firestore Database, you need to set up security rules:

### Deploy Security Rules
1. In Firebase Console, go to "Firestore Database" > "Rules" tab
2. Copy the content from the `firestore.rules` file in your project root
3. Paste it into the rules editor, replacing the default rules
4. Click "Publish" to deploy the rules

### What the Rules Do
- **Leaderboards**: Anyone can read scores, only authenticated users can write their own scores
- **User Profiles**: Users can only read/write their own profile data
- **Score Validation**: Prevents invalid scores (negative, too high, etc.)
- **Data Structure**: Ensures all required fields are present

### Test the Rules
1. In the Rules tab, click "Rules playground"
2. Test different scenarios:
   - Authenticated user writing their score
   - Unauthenticated user trying to write
   - Reading leaderboard data

## Testing

### Quick Verification Steps

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Test Firebase Connection**
   ```bash
   flutter run
   ```
   - Check the debug console for "Firebase initialized successfully"
   - If you see this message, Firebase is connected ✅

3. **Verify Firestore Connection**
   - In Firebase Console, go to "Firestore Database"
   - You should see your database is ready
   - The collections will be created automatically when first data is written

4. **Test Authentication (Optional)**
   - The authentication services are ready but UI isn't implemented yet
   - You can test programmatically or wait for the authentication UI tasks

### Troubleshooting

**If Firebase initialization fails:**
- Check that `google-services.json` is in `android/app/` directory
- Verify the package name matches in the JSON file
- Run `flutter clean` and `flutter pub get`

**If Firestore rules fail:**
- Check the rules syntax in Firebase Console
- Make sure you clicked "Publish" after pasting the rules
- Test rules in the Rules playground

**Common Issues:**
- **"Default FirebaseApp is not initialized"**: Firebase configuration file missing
- **"Permission denied"**: Security rules not deployed or incorrect
- **"Network error"**: Check internet connection and Firebase project status

## Important Notes

- Never commit the actual `google-services.json` or `GoogleService-Info.plist` files to version control
- The template files are provided for reference only
- Make sure to update the package name and bundle ID if you change them in your app