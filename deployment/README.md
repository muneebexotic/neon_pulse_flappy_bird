# Neon Pulse Deployment Guide

This directory contains all the necessary files and documentation for deploying Neon Pulse to app stores.

## Prerequisites

### Android Deployment
1. **Google Play Console Account**: Set up a developer account
2. **Keystore File**: Generate a release keystore for app signing
3. **Service Account**: Create a service account for automated uploads
4. **App Bundle**: Configure app bundle settings in Google Play Console

### iOS Deployment
1. **Apple Developer Account**: Enroll in the Apple Developer Program
2. **App Store Connect**: Set up your app in App Store Connect
3. **Certificates**: Generate distribution certificates
4. **Provisioning Profiles**: Create App Store provisioning profiles
5. **API Keys**: Generate App Store Connect API keys for automation

## Setup Instructions

### 1. Android Setup

#### Generate Keystore
```bash
keytool -genkey -v -keystore neon-pulse-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias neon-pulse-key
```

#### Configure GitHub Secrets
Add these secrets to your GitHub repository:
- `ANDROID_KEYSTORE`: Base64 encoded keystore file
- `KEYSTORE_PASSWORD`: Keystore password
- `KEY_PASSWORD`: Key password
- `KEY_ALIAS`: Key alias (neon-pulse-key)
- `GOOGLE_PLAY_SERVICE_ACCOUNT`: Service account JSON

#### Create Service Account
1. Go to Google Cloud Console
2. Create a new service account
3. Download the JSON key file
4. Grant necessary permissions in Google Play Console

### 2. iOS Setup

#### Generate Certificates
1. Open Xcode
2. Go to Preferences > Accounts
3. Add your Apple ID
4. Download certificates and provisioning profiles

#### Configure GitHub Secrets
Add these secrets to your GitHub repository:
- `IOS_CERTIFICATE`: Base64 encoded P12 certificate
- `IOS_CERTIFICATE_PASSWORD`: Certificate password
- `APPSTORE_ISSUER_ID`: App Store Connect issuer ID
- `APPSTORE_KEY_ID`: API key ID
- `APPSTORE_PRIVATE_KEY`: Private key content

## Build Scripts

### Local Development
```bash
# Build debug versions
dart build_scripts/build_release.dart android
dart build_scripts/build_release.dart ios

# Build all platforms
dart build_scripts/build_release.dart all
```

### Asset Optimization
```bash
# Optimize assets before building
dart build_scripts/optimize_assets.dart
```

## CI/CD Pipeline

The project includes automated CI/CD pipelines:

### Continuous Integration (`ci.yml`)
- Runs on every push and pull request
- Performs code quality checks
- Runs automated tests
- Builds debug versions for testing

### Release Deployment (`release.yml`)
- Triggers on GitHub releases
- Builds production versions
- Deploys to app stores automatically
- Creates deployment summaries

## Manual Deployment

### Android (Google Play)
1. Build the app bundle:
   ```bash
   flutter build appbundle --release --shrink --obfuscate
   ```
2. Upload to Google Play Console
3. Fill in store listing information
4. Submit for review

### iOS (App Store)
1. Build and archive:
   ```bash
   flutter build ios --release --obfuscate
   xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive
   ```
2. Export IPA:
   ```bash
   xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath build/ipa -exportOptionsPlist ios/ExportOptions.plist
   ```
3. Upload to App Store Connect using Xcode or Transporter
4. Submit for review

## Store Listing Assets

### Required Assets
- App icons (various sizes)
- Screenshots (multiple device sizes)
- Feature graphics
- App descriptions
- Privacy policy
- Terms of service

### Asset Locations
- Icons: `assets/icons/`
- Screenshots: `store_assets/screenshots/`
- Descriptions: `store_assets/`
- Legal documents: `legal/`

## Version Management

### Version Numbering
- Use semantic versioning (e.g., 1.0.0)
- Increment build numbers for each release
- Update `pubspec.yaml` version field

### Release Process
1. Create a new branch for the release
2. Update version numbers
3. Update changelog and release notes
4. Create a GitHub release
5. CI/CD pipeline handles the rest

## Monitoring and Analytics

### Crash Reporting
- Debug symbols are automatically uploaded
- Configure crash reporting in app store consoles
- Monitor crash rates and fix critical issues

### Performance Monitoring
- Use built-in performance monitoring tools
- Track app startup times and frame rates
- Monitor memory usage and battery consumption

## Troubleshooting

### Common Issues
1. **Build Failures**: Check Flutter and dependency versions
2. **Signing Issues**: Verify certificates and provisioning profiles
3. **Upload Failures**: Check API keys and permissions
4. **Review Rejections**: Follow app store guidelines carefully

### Support Resources
- Flutter documentation
- App store developer guides
- GitHub Actions documentation
- Community forums and Stack Overflow

## Security Considerations

### Secrets Management
- Never commit sensitive information to version control
- Use GitHub Secrets for CI/CD
- Rotate keys and certificates regularly
- Use least-privilege access principles

### Code Protection
- Enable code obfuscation for release builds
- Use ProGuard rules for Android optimization
- Implement certificate pinning if needed
- Regular security audits and dependency updates

## Post-Deployment

### Launch Checklist
- [ ] Verify app store listings are live
- [ ] Test download and installation
- [ ] Monitor initial user feedback
- [ ] Prepare customer support resources
- [ ] Plan marketing and promotion activities

### Ongoing Maintenance
- Regular updates and bug fixes
- Performance optimization
- New feature development
- User feedback incorporation
- Security updates and patches