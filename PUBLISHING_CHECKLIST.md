# Play Store & App Store Publishing Checklist

## ⚠️ IMPORTANT ISSUES TO FIX BEFORE PUBLISHING

### 🔴 Critical Issues (Must Fix):

1. **Package Name/Application ID**
   - Current: `com.example.pdfviewver` ❌
   - Issue: "com.example" cannot be used in Play Store
   - Fix: Change to your own unique package name (e.g., `com.yourcompany.pdfviewer`)

2. **Release Signing**
   - Current: Using debug signing keys ❌
   - Issue: Cannot publish with debug keys
   - Fix: Create release keystore and configure signing

3. **App Description**
   - Current: "A new Flutter project." ❌
   - Issue: Generic description not allowed
   - Fix: Add proper app description

4. **Privacy Policy & Terms URLs**
   - Current: Demo URLs ❌
   - Issue: Must have real, working URLs
   - Fix: Create actual Privacy Policy and Terms pages

5. **Rate Us URL**
   - Current: `com.example.pdfviewver` ❌
   - Issue: Wrong package name in URL
   - Fix: Update with correct package name after changing it

### 🟡 Important Issues (Should Fix):

6. **usesCleartextTraffic**
   - Current: `android:usesCleartextTraffic="true"`
   - Issue: Security concern for Play Store
   - Fix: Remove if only using HTTPS, or add network security config

7. **App Icon**
   - Current: Default Flutter icon
   - Fix: Create custom app icon (1024x1024 for Play Store)

8. **Screenshots**
   - Required: At least 2 screenshots for Play Store
   - Required: Screenshots for different device sizes

9. **App Store (iOS) Configuration**
   - Need: Info.plist configuration
   - Need: iOS signing certificates
   - Need: App Store Connect setup

---

## 📋 Step-by-Step Fix Guide

### Step 1: Change Package Name

1. Update `android/app/build.gradle.kts`:
   - Change `applicationId = "com.example.pdfviewver"` to your unique ID
   - Change `namespace = "com.example.pdfviewver"` to match

2. Update `MainActivity.kt` package declaration
3. Update `AndroidManifest.xml` if needed
4. Update `profile_screen.dart` Rate Us URL

### Step 2: Configure Release Signing

1. Create keystore file
2. Create `android/key.properties`
3. Update `build.gradle.kts` with signing config

### Step 3: Update App Information

1. Update `pubspec.yaml` description
2. Update Privacy Policy & Terms URLs
3. Create app icon
4. Prepare screenshots

---

## ✅ Pre-Publishing Checklist

- [ ] Package name changed from com.example.*
- [ ] Release signing configured
- [ ] App description updated
- [ ] Privacy Policy URL is real and working
- [ ] Terms & Conditions URL is real and working
- [ ] Rate Us URL has correct package name
- [ ] App icon created (all sizes)
- [ ] Screenshots prepared
- [ ] App tested on real devices
- [ ] No debug code/logs in release build
- [ ] Version number updated
- [ ] All permissions justified in Play Store listing

---

## 🚀 Ready to Publish?

After fixing all issues above, your app should be ready for Play Store publication!

