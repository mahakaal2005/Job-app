# Google Sign-In Setup Guide

## Problem: Google Sign-In Network Error

If you see this error:
```
Error: Exception: Google Sign-Up failed: Exception: Google Sign-In failed:
PlatformException(network_error, com.google.android.gms.common.api.i: 7: null, null)
```

This means Google Sign-In is not properly configured in Firebase Console.

---

## Root Cause

The error occurs because:
1. Firebase Console doesn't have your app's SHA-1 and SHA-256 certificates
2. Google cannot verify your app's identity
3. Authentication fails with "network_error" (misleading name - it's actually an auth failure)

---

## Step-by-Step Fix

### Step 1: Get SHA Certificates

#### On Windows:
```cmd
cd android
gradlew signingReport
```

#### On Mac/Linux:
```bash
cd android
./gradlew signingReport
```

#### Output will look like:
```
Variant: debug
Config: debug
Store: C:\Users\YourName\.android\debug.keystore
Alias: AndroidDebugKey
MD5: 12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
SHA-256: 11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00
Valid until: Friday, January 1, 2050
```

**Copy both SHA1 and SHA-256 values.**

---

### Step 2: Add Certificates to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click the **gear icon** (⚙️) → **Project settings**
4. Scroll down to **Your apps** section
5. Find your Android app
6. Scroll to **SHA certificate fingerprints**
7. Click **Add fingerprint**
8. Paste the **SHA-1** value
9. Click **Add fingerprint** again
10. Paste the **SHA-256** value
11. Click **Save**

---

### Step 3: Download Updated Configuration

1. In Firebase Console, still in Project Settings
2. Scroll to your Android app
3. Click **Download google-services.json**
4. Replace the file in your project:
   - Location: `android/app/google-services.json`
5. **Important**: Overwrite the existing file

---

### Step 4: Enable Google Sign-In

1. In Firebase Console, go to **Authentication**
2. Click **Sign-in method** tab
3. Find **Google** in the list
4. Click **Google**
5. Toggle **Enable**
6. Add a **Support email** (required)
7. Click **Save**

---

### Step 5: Rebuild the App

```bash
flutter clean
flutter pub get
flutter run
```

**Important**: Don't use hot reload - do a full rebuild!

---

## For Release Builds

When you create a release build, you'll need to:

1. Get SHA certificates from your **release keystore**:
   ```bash
   keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
   ```

2. Add those SHA certificates to Firebase Console (same steps as above)

3. Download updated google-services.json

4. Rebuild the release version

---

## Verification Checklist

- [ ] SHA-1 certificate added to Firebase Console
- [ ] SHA-256 certificate added to Firebase Console
- [ ] Google Sign-In enabled in Firebase Authentication
- [ ] Support email added in Google Sign-In settings
- [ ] google-services.json downloaded and replaced
- [ ] App rebuilt with `flutter clean` and `flutter run`
- [ ] Tested on physical device (not just emulator)

---

## Common Issues

### Issue: Still getting network_error after adding SHA certificates

**Solution**: 
- Wait 5-10 minutes for Firebase to propagate changes
- Do a full rebuild: `flutter clean && flutter run`
- Uninstall and reinstall the app
- Clear app data on the device

### Issue: Works on emulator but not on physical device

**Solution**:
- Physical devices use different certificates
- Get SHA from the actual device's keystore
- Add those certificates to Firebase Console

### Issue: Works in debug but not in release

**Solution**:
- Release builds use a different keystore
- Get SHA from your release keystore
- Add those certificates to Firebase Console

---

## Testing

After setup, test Google Sign-In:

1. Open the app
2. Go to Sign Up screen
3. Click "SIGN UP WITH GOOGLE"
4. Select a Google account
5. Should successfully create account and log in

If it works, you'll see:
```
DEBUG [GOOGLE_SIGNUP] Google Sign-In successful
DEBUG [GET_ROLE] Getting role for user: [user-id]
```

---

## Prevention

To prevent this error in the future:

1. **Document your keystores**: Keep track of which keystores are used for debug/release
2. **Add all SHA certificates**: Add certificates for all build variants
3. **Test early**: Test Google Sign-In as soon as you add it
4. **Version control**: Don't commit google-services.json if it contains sensitive data
5. **Team coordination**: Ensure all team members have correct configuration

---

## Need Help?

If you're still having issues:

1. Check Firebase Console logs
2. Check Android logcat for detailed errors
3. Verify package name matches in:
   - `android/app/build.gradle` (applicationId)
   - Firebase Console (package name)
4. Ensure Google Play Services is up to date on the device

---

## Related Documentation

- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
