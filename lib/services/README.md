# Firebase Services Documentation

This directory contains the Firebase integration services for the Neon Pulse Flappy Bird game.

## Services Overview

### FirebaseService
- **Purpose**: Core Firebase initialization and configuration
- **Features**: 
  - Firebase initialization check
  - Firestore configuration
  - Online/offline status detection
- **Usage**: Automatically initialized in main.dart

### AuthenticationService
- **Purpose**: User authentication management
- **Features**:
  - Google Sign-In integration
  - Guest/anonymous authentication
  - Account upgrade (guest to Google)
  - User profile management
- **Methods**:
  - `signInWithGoogle()`: Authenticate with Google account
  - `signInAsGuest()`: Create anonymous session
  - `upgradeGuestToGoogle()`: Convert guest to authenticated user
  - `signOut()`: Sign out current user

### LeaderboardService
- **Purpose**: Global leaderboard management
- **Features**:
  - Score submission with validation
  - Real-time leaderboard updates
  - Offline score queuing
  - Anti-cheat measures
- **Methods**:
  - `submitScore()`: Submit score to global leaderboard
  - `getLeaderboard()`: Fetch leaderboard data
  - `getLeaderboardStream()`: Real-time leaderboard updates

## Data Models

### User Model
```dart
class User {
  String? uid;
  String displayName;
  String email;
  String? photoURL;
  bool isGuest;
  DateTime? lastSignIn;
  UserGameStats gameStats;
}
```

### LeaderboardEntry Model
```dart
class LeaderboardEntry {
  String id;
  String userId;
  String playerName;
  int score;
  DateTime timestamp;
  String? photoURL;
  int rank;
}
```

## Security Features

### Score Validation
- Client-side validation prevents basic score manipulation
- Server-side Firestore rules provide additional security
- Maximum score limits prevent unrealistic submissions

### Authentication Security
- Firebase Authentication handles secure token management
- Google Sign-In provides OAuth2 security
- Anonymous accounts can be upgraded without data loss

### Data Access Control
- Firestore security rules restrict data access
- Users can only modify their own data
- Leaderboard scores are read-only after submission

## Offline Support

### Guest Mode
- Works completely offline
- Local score storage
- Can upgrade to authenticated account later

### Score Queuing
- Scores are queued when offline
- Automatic submission when connection restored
- No data loss during network interruptions

## Error Handling

### Graceful Degradation
- App continues to work if Firebase fails to initialize
- Offline mode provides full gameplay experience
- Network errors don't crash the application

### User Feedback
- Clear error messages for authentication failures
- Loading states during network operations
- Retry mechanisms for failed operations

## Configuration Requirements

### Firebase Console Setup
1. Create Firebase project
2. Enable Authentication with Google provider
3. Enable Firestore Database
4. Configure security rules (see firestore.rules)

### Android Configuration
- Add `google-services.json` to `android/app/`
- Configure `build.gradle.kts` with Google Services plugin
- Add Firebase dependencies

### iOS Configuration
- Add `GoogleService-Info.plist` to `ios/Runner/`
- Configure URL schemes in `Info.plist`
- Add to Xcode project

## Testing

### Unit Tests
- Authentication flow testing
- Score validation testing
- Offline mode testing

### Integration Tests
- End-to-end authentication flows
- Leaderboard submission and retrieval
- Network connectivity scenarios

## Performance Considerations

### Caching
- Firestore offline persistence enabled
- User profile caching
- Leaderboard data caching

### Optimization
- Batch operations for multiple writes
- Pagination for large leaderboards
- Efficient query structures

## Monitoring and Analytics

### Error Tracking
- Firebase Crashlytics integration ready
- Custom error logging
- Performance monitoring

### Usage Analytics
- Authentication method tracking
- Score submission patterns
- User engagement metrics