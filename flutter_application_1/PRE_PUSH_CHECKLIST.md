# ✅ Pre-Push Security Checklist

Run this script before pushing to GitHub to verify no secrets are exposed.

## Quick Verification

```bash
# 1. Check git status
git status

# 2. Verify only safe files are staged
# Should see: .gitignore, .env.example, README_SECURITY.md, *.template files
# Should NOT see: firebase_options.dart, google-services.json (without .template)

# 3. Check for API keys in ADDED files only (deletions are OK)
git diff --cached --diff-filter=A | grep -i "AIza" && echo "❌ STOP! API keys found!" || echo "✅ Safe to push"

# 4. Double-check .gitignore includes sensitive files
grep "firebase_options.dart" .gitignore
grep "google-services.json" .gitignore

# 5. If all checks pass, commit and push:
git commit -m "🔒 Secure API keys and add security documentation"
git push origin main
```

## What Should Be Committed
- ✅ `.gitignore` (modified)
- ✅ `.env.example` (new)
- ✅ `README_SECURITY.md` (new)
- ✅ `lib/firebase_options.dart.template` (new)
- ✅ `android/app/google-services.json.template` (new)

## What Should Be Deleted from Git
- 🗑️ `lib/firebase_options.dart` (contains real API keys)
- 🗑️ `android/app/google-services.json` (contains real API keys)
- 🗑️ `FIREBASE_SETUP.md` (may contain sensitive info)
- 🗑️ `YOUR_SHA_KEYS.md` (contains SHA fingerprints)

## What Should NOT Be in Commit
- ❌ Any file with actual API keys
- ❌ `.env` file (if you created one)
- ❌ Real `google-services.json` or `GoogleService-Info.plist`

---

**When in doubt, run the grep check above. If it finds "AIza" in added files, DO NOT PUSH!**
