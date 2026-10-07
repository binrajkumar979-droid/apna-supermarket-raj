# 🛒 Apna Supermarket & Kirana Mobile App - Deployment Guide

## 1. Firebase Backend Deployment

### Prerequisites
Make sure Firebase CLI is installed:
```bash
npm install -g firebase-tools
firebase login
```

### Deploy Firestore Rules, Storage Rules & Cloud Functions
From the root of `supermarket_app`:
```bash
# 1. Initialize project link
firebase use --add apna-supermarket

# 2. Configure Razorpay API Keys in Cloud Functions
firebase functions:config:set razorpay.key_id="rzp_live_YOUR_KEY" razorpay.key_secret="YOUR_SECRET"

# 3. Deploy everything
firebase deploy
```

---

## 2. Generating Release Keystore & App Signing

### Step 1: Generate Release Keystore
Run in PowerShell (replace `apna-supermarket-key` with your filename):
```powershell
keytool -genkey -v -keystore C:\Users\Raj\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias apna-key
```

### Step 2: Configure `android/key.properties`
Create `android/key.properties` file:
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=apna-key
storeFile=C:/Users/Raj/upload-keystore.jks
```

---

## 3. Building Release Artifacts for Android & Play Store

### A. Build Google Play Store App Bundle (.aab)
```bash
flutter build appbundle --release
```
Artifact generated at: `build/app/outputs/bundle/release/app-release.aab`
*(Upload this file to Google Play Console under Production / Closed Testing).*

### B. Build Universal Release APK (.apk) for Direct Shop Phone Install
```bash
flutter build apk --release --split-per-abi
```
Artifacts generated at: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
*(Transfer this APK to the store owner's phone via WhatsApp or USB for immediate use).*

---

## 4. Google Play Store Mandatory Requirements Checklist

- [x] **FSSAI Number**: Displayed in app info, cart bill summary, and WhatsApp receipts ([app_config.dart](lib/config/app_config.dart)).
- [x] **In-App Account Deletion**: Play Store compliant account removal handler.
- [x] **Privacy Policy URL**: Host policy stating data usage for delivery and order fulfillment.
- [x] **64-bit Architecture**: Fully compatible with ARM64 devices and Android 14+.
