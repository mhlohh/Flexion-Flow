# 🔒 Security Setup for Flexion Flow

## ⚠️ IMPORTANT: API Key Protection

This project uses Firebase for authentication and data storage. To prevent exposing sensitive API keys on GitHub, we use the following approach:

### 🚫 Files That Should NEVER Be Committed

These files contain your actual Firebase credentials and are listed in `.gitignore`:

1. **`.env`** - Contains your actual API keys
2. **`android/app/google-services.json`** - Android Firebase config  
3. **`ios/Runner/GoogleService-Info.plist`** - iOS Firebase config
4. **`lib/firebase_options.dart`** - Web Firebase config (contains hardcoded keys)

### ✅ What IS Safe to Commit

- `.env.example` - Template file without real keys
- All other code files
- Configuration files without credentials

---

## 🛠️ Setup Instructions for New Developers

### Step 1: Get Your Firebase Configuration Files

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Download the configuration files:
   - **For Android:** Download `google-services.json` → Place in `android/app/`
   - **For iOS:** Download `GoogleService-Info.plist` → Place in `ios/Runner/`
   - **For Web:** Copy the config values from Firebase Console

### Step 2: Create Your `.env` File

```bash
# Copy the example file
cp .env.example .env

# Edit .env and add your actual Firebase credentials
```

### Step 3: Update `lib/firebase_options.dart`

Replace the placeholder values in `firebase_options.dart` with your actual Firebase web configuration:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_WEB_API_KEY',
  appId: 'YOUR_ACTUAL_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'your-project-id',
  authDomain: 'your-project.firebaseapp.com',
  storageBucket: 'your-project.firebasestorage.app',
);
```

---

## 🔐 GitHub Security Best Practices

### Before Your First Push

1. ✅ Check that `.gitignore` includes sensitive files
2. ✅ Verify `.env` is gitignored
3. ✅ Ensure `google-services.json` is gitignored
4. ✅ Confirm `GoogleService-Info.plist` is gitignored
5. ✅ Run `git status` to verify no sensitive files are staged

### What If You Already Committed API Keys?

If you accidentally committed API keys to GitHub:

1. **🚨 IMMEDIATELY regenerate your Firebase API keys** in Firebase Console
2. Remove the files from git history:
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch lib/firebase_options.dart" \
     --prune-empty --tag-name-filter cat -- --all
   ```
3. Force push (⚠️ only if you're the only developer):
   ```bash
   git push origin --force --all
   ```

---

## 📱 Platform-Specific Notes

### Android
- `google-services.json` is automatically used by the Google Services plugin
- No code changes needed, just place the file in `android/app/`

### iOS  
- `GoogleService-Info.plist` is automatically detected
- Ensure it's added to your Xcode project

### Web
- Credentials are hardcoded in `lib/firebase_options.dart`
- **This file should be gitignored** or use environment variables

---

## 🔍 Verify Your Setup

Run this command to check for exposed secrets:

```bash
# Check what files would be committed
git status

# Search for potential API keys in committed files
git grep -i "AIza" -- "*.dart" "*.json"
```

If you see any API keys, **DO NOT COMMIT**!

---

## 🆘 Need Help?

- Check that `.gitignore` includes all sensitive files
- Verify `.env` is not staged for commit
- Make sure `google-services.json` and `GoogleService-Info.plist` are not tracked by git

**Remember: When in doubt, keep it out (of GitHub)!** 🔒
