# Firebase Console Setup for Google Sign-In

## ⚠️ CRITICAL: Complete These Steps Before Testing

Google Sign-In will **ALWAYS FAIL** with a generic "API Exception" if you skip these steps.

---

## Step 1: Get SHA-1 and SHA-256 Fingerprints

### On macOS/Linux:
```bash
cd android
./gradlew signingReport
```

### On Windows:
```bash
cd android
gradlew signingReport
```

### What to Look For:
The command output will show something like:

```
Variant: debug
Config: debug
Store: ~/.android/debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
SHA-256: 11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00
Valid until: ...
```

**Copy both the SHA1 and SHA-256 values.**

---

## Step 2: Add Fingerprints to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create one if you haven't)
3. Click the gear icon ⚙️ next to "Project Overview"
4. Click **"Project Settings"**
5. Scroll down to **"Your apps"** section
6. Click on your Android app (package name: `com.example.flutter_application_1`)
   - If you don't have an Android app registered, click "Add app" → Android
7. Click **"Add fingerprint"**
8. Paste your **SHA-1** key, click Save
9. Click **"Add fingerprint"** again
10. Paste your **SHA-256** key, click Save

---

## Step 3: Download google-services.json

1. Still in Project Settings
2. Scroll to your Android app
3. Click **"Download google-services.json"**
4. Replace the file at: `android/app/google-services.json`

---

## Step 4: Enable Google Sign-In in Firebase

1. In Firebase Console, go to **"Authentication"** (left sidebar)
2. Click **"Sign-in method"** tab
3. Click on **"Google"**
4. Toggle **"Enable"**
5. Enter support email (your email)
6. Click **"Save"**

---

## Step 5: iOS Setup (if testing on iOS)

1. In Firebase Console → Project Settings
2. Add iOS app with Bundle ID: `com.example.flutterApplication1`
3. Download `GoogleService-Info.plist`
4. Add to `ios/Runner/` directory in Xcode
5. Update `ios/Runner/Info.plist` with:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- REPLACE WITH YOUR REVERSED_CLIENT_ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR-ID-HERE</string>
        </array>
    </dict>
</array>
```

---

## Verification Checklist

- [ ] Ran `./gradlew signingReport` and got SHA keys
- [ ] Added SHA-1 to Firebase Console
- [ ] Added SHA-256 to Firebase Console
- [ ] Downloaded and replaced `google-services.json`
- [ ] Enabled Google Sign-In in Authentication → Sign-in method

---

## Common Errors

### "API Exception" or "Sign-in failed"
- **Cause**: Missing or incorrect SHA fingerprints
- **Fix**: Re-run `./gradlew signingReport` and verify keys in Firebase

### "The given sign-in provider is disabled for this Firebase project"
- **Cause**: Google Sign-In not enabled in Firebase Console
- **Fix**: Go to Authentication → Sign-in method → Enable Google

### Sign-in works but then immediately signs out
- **Cause**: Mismatched package name
- **Fix**: Verify package name in Firebase matches `android/app/build.gradle`
