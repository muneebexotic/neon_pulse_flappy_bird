# Firebase Deployment Guide - Fix Leaderboard Issues

## Issues Found
1. **Permission Denied**: Firestore rules were too restrictive for guest users
2. **Missing Index**: Composite index needed for leaderboard queries
3. **Authentication**: Guest users couldn't submit scores

## Manual Deployment Steps

### Step 1: Update Firestore Security Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `neon-pulse-flappy-bird`
3. Click "Firestore Database" in the left sidebar
4. Click the "Rules" tab
5. Replace the existing rules with the updated rules from `firestore.rules` file
6. Click "Publish" to deploy

**Key Changes Made:**
- Changed leaderboard write permissions from `request.auth != null` to allow all users to create scores
- Added proper validation to prevent abuse
- Maintained security for updates and deletes

### Step 2: Create Required Firestore Indexes

1. In Firebase Console, go to "Firestore Database"
2. Click the "Indexes" tab
3. Click "Create Index" and add these two composite indexes:

**Index 1: For user-specific score queries**
- Collection ID: `scores`
- Fields:
  - `userId` (Ascending)
  - `score` (Descending)
  - `__name__` (Descending)

**Index 2: For global leaderboard queries**
- Collection ID: `scores`
- Fields:
  - `score` (Descending)
  - `__name__` (Descending)

**Alternative: Use the provided index file**
- You can also use the `firestore.indexes.json` file created in your project
- If you have Firebase CLI installed, run: `firebase deploy --only firestore:indexes`

### Step 3: Verify the Changes

After deploying the rules and indexes:

1. **Test Score Submission**
   - Play the game and get a score
   - Check if the score submits without permission errors

2. **Test Leaderboard Loading**
   - Go to the leaderboard screen
   - Verify that scores appear (may take a few minutes for indexes to build)

3. **Check Firebase Console**
   - Go to Firestore Database > Data
   - Look for the `leaderboards/classic/scores` collection
   - Verify that scores are being saved

### Step 4: Monitor Logs

After deployment, check the app logs for:
- ✅ "Score submitted successfully"
- ✅ Leaderboard data loading
- ❌ No more "Permission denied" errors
- ❌ No more "requires an index" errors

## Expected Behavior After Fix

1. **Score Submission**: Scores should submit immediately when online
2. **Offline Queuing**: Scores should queue when offline and submit when back online
3. **Leaderboard Display**: Global leaderboard should show all submitted scores
4. **Real-time Updates**: Leaderboard should update in real-time as new scores are submitted

## Troubleshooting

**If you still see permission errors:**
- Double-check that the rules were published correctly
- Wait a few minutes for rules to propagate
- Clear app data and restart

**If you still see index errors:**
- Verify both indexes were created
- Wait for indexes to finish building (can take several minutes)
- Check the "Indexes" tab for build status

**If scores still don't appear:**
- Check that Firebase project is correctly configured
- Verify internet connection
- Look for any remaining errors in the logs

## Firebase CLI Installation (Optional)

If you want to use Firebase CLI for future deployments:

1. Install Node.js from https://nodejs.org/
2. Install Firebase CLI: `npm install -g firebase-tools`
3. Login: `firebase login`
4. Initialize project: `firebase init` (select Firestore)
5. Deploy: `firebase deploy`

This will allow you to deploy rules and indexes from the command line using the configuration files in your project.