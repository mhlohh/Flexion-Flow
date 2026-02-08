# 🔑 Your SHA Fingerprints for Firebase

## Copy These Values:

**SHA-1:**
```
73:B9:A3:97:7C:13:13:51:E5:35:E8:25:7B:1F:BA:88:25:CC:F5:E8
```

**SHA-256:**
```
EB:C0:BD:D0:A2:A0:A4:D0:6C:5E:2F:96:29:81:AC:C4:7F:AA:44:62:34:C2:9E:54:B7:6B:F0:D4:63:39:FD:C1
```

---

## 📋 Step-by-Step Firebase Console Setup

### Step 1: Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create one if needed)

### Step 2: Add SHA Fingerprints
1. Click the **⚙️ gear icon** next to "Project Overview"
2. Click **"Project Settings"**
3. Scroll to **"Your apps"** section
4. Find your Android app or click **"Add app" → Android** if not added
   - Package name: `com.example.flutter_application_1`
5. Click **"Add fingerprint"** button
6. Paste SHA-1: `73:B9:A3:97:7C:13:13:51:E5:35:E8:25:7B:1F:BA:88:25:CC:F5:E8`
7. Click **Save**
8. Click **"Add fingerprint"** again
9. Paste SHA-256: `EB:C0:BD:D0:A2:A0:A4:D0:6C:5E:2F:96:29:81:AC:C4:7F:AA:44:62:34:C2:9E:54:B7:6B:F0:D4:63:39:FD:C1`
10. Click **Save**

### Step 3: Download google-services.json
1. Still in Project Settings
2. Scroll to your Android app
3. Click **"Download google-services.json"**
4. Replace the file at: `android/app/google-services.json`

### Step 4: Enable Google Sign-In
1. In Firebase Console sidebar, click **"Authentication"**
2. Click **"Sign-in method"** tab
3. Click **"Google"**
4. Toggle **Enable**
5. Enter your support email
6. Click **Save**

### Step 5: Restart Your App
```bash
flutter run
```

---

## ✅ Verification
After completing these steps:
1. Open the app
2. Click "Sign in with Google"
3. You should see Google account picker
4. Sign in should succeed!
