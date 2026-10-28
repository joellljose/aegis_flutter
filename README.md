# AEGIS One (IPSD) - Flutter Mobile & Cross-Platform App

**AEGIS One** is a smart Personal Emergency Response Device (IPSD) companion application built in Flutter with multiplatform support (Android, iOS, Web, Windows).

Designed with KnightMaster Innovations Pvt. Ltd. specifications, it features the signature 3-button safety interface, mistouch prevention countdown, real-time GPS telemetry, multi-channel dispatch (WhatsApp, SMS, Phone dialer, Native OS Share), encrypted medical ID QR codes, and Firebase Cloud Database integration.

---

## 🛡️ Core Capabilities

1. **Hardware Companion Hub**:
   - **Paired Wearable Monitoring**:
     - Real-time BLE 5.0 connection link status (`AEGIS One #882`, -58 dBm signal).
     - Live battery telemetry (94%, ~5 days standby, charging indicator).
     - Cellular eSIM connection (LTE-M 4G) and GNSS GPS lock status.
   - **Physical Hardware Sensor Lines**:
     - Monitored Line 1: `Button 1: POLICE` (Red) - Direct Police Control Room SOS dispatch
     - Monitored Line 2: `Button 2: MEDICAL` (Green) - Ambulance & paramedic emergency broadcast
     - Monitored Line 3: `Button 3: CONTACT` (Blue) - Priority family & friend alert
   - **Mistouch Prevention & Cancellation**:
     - When a physical button is pressed on the wearable pendant, the companion app manages the 120s cancellation window with warning beeps and PIN verification (`1234`).
   - **Find My AEGIS Acoustic Locator**:
     - Sounds high-decibel acoustic beacon on the physical hardware device.
   - **Hardware Signal Testing Deck**:
     - Integrated developer simulator to test incoming BLE signals from Button 1, 2, 3, or Crash sensor.

2. **Live GPS & Safe Zones**:
   - Interactive OpenStreetMap via `flutter_map`.
   - Real-time GPS coordinate acquisition (`geolocator`), accuracy radius, speed, and altitude.
   - Live reverse geocoding via OpenStreetMap Nominatim.
   - Geofenced Safe Zones (Home, Campus, Work) with Add/Remove manager.
   - External Google Maps deep linking.

3. **Emergency Network & Multi-Channel Dispatch**:
   - Priority 1 & Priority 2 emergency contacts manager.
   - Simulated & real dispatch delivery queue (Sending -> Delivered -> Acknowledged).
   - Direct action buttons on each contact for **WhatsApp**, **SMS**, and **Phone Calls**.
   - Immediate National Emergency Hotlines: **112** (National SOS), **100** (Police), **108** (EMS Ambulance).
   - Native OS Share sheet (`share_plus`) to broadcast live location and emergency status across any installed messenger.

4. **Medical Profile & Paramedic QR Code**:
   - Blood Group, Allergies, Medical Conditions, Emergency Notes, and National ID.
   - Live dynamic QR code generator (`qr_flutter`) for first responders to scan on-scene directly from a smartphone screen.

5. **Firebase Cloud Database & Offline-First Architecture**:
   - **Cloud Firestore**: Real-time sync for `emergencies` and `users` collections.
   - **Offline-First Resilience**: If offline or if Firebase credentials are not yet configured, the app seamlessly runs using local caching (`SharedPreferences`), ensuring emergency features never fail during network outages.

---

## 🚀 Running the Project

### 1. Requirements
- Flutter SDK (v3.24+ / 3.47+)
- Dart 3.13+

### 2. Run Locally on Chrome or Web
```bash
cd aegis_flutter
flutter run -d chrome
```

### 3. Run on Android Device / Emulator
```bash
cd aegis_flutter
flutter run -d android
```

### 4. Run on Windows Desktop
```bash
cd aegis_flutter
flutter run -d windows
```

---

## 🔥 Linking Firebase (Optional)

To connect your own Google Firebase project to Cloud Firestore:
1. Run FlutterFire CLI inside the `aegis_flutter` directory:
   ```bash
   flutterfire configure
   ```
2. Or place your `google-services.json` in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/`.
3. If not configured, the app automatically runs in **Offline-First Mode** without errors.

---

## 📁 Architecture Overview

```
aegis_flutter/
├── lib/
│   ├── main.dart                      # App entry point with MultiProvider
│   ├── models/
│   │   ├── alert_types.dart           # Police, Medical, Contact, Crash
│   │   ├── system_state.dart          # AllSafe, MistouchWindow, ActiveDispatch, Resolved
│   │   ├── emergency_contact.dart     # Contact model with serialization
│   │   ├── medical_profile.dart       # Medical ID & QR generator
│   │   ├── emergency_record.dart      # Authoritative emergency event model
│   │   ├── telemetry.dart             # Battery, LTE-M, BLE, IP67 status
│   │   └── log_entry.dart             # Timestamped incident logs
│   ├── providers/
│   │   └── aegis_provider.dart        # Central state machine & business logic
│   ├── services/
│   │   ├── firebase_service.dart      # Cloud Firestore integration & fallback
│   │   ├── location_service.dart      # Geolocator & Nominatim reverse geocode
│   │   ├── sound_service.dart         # Alarm sirens & haptic vibration
│   │   ├── dispatch_service.dart      # WhatsApp, SMS, Tel, SharePlus launcher
│   │   └── storage_service.dart       # SharedPreferences persistence
│   ├── theme/
│   │   └── aegis_theme.dart           # AEGIS Obsidian dark theme & palette
│   ├── widgets/
│   │   ├── hardware_pendant_widget.dart # 3 recessed buttons with hold progress
│   │   ├── mistouch_countdown_card.dart # 120s digital clock & cancel flow
│   │   ├── dispatch_dialog.dart       # Broadcast payload & direct actions
│   │   └── pin_dialog.dart            # Security PIN confirmation
│   └── screens/
│       ├── home_screen.dart           # Navigation shell & dynamic status pill
│       └── tabs/
│           ├── safety_hub_tab.dart    # 3 Buttons, telemetry, crash sim, logs
│           ├── map_tab.dart           # Live OpenStreetMap & Safe Zones
│           ├── contacts_tab.dart      # Emergency network & hotlines
│           ├── medical_id_tab.dart    # Medical profile & QR code
│           └── settings_tab.dart      # Mistouch slider, PIN, specs sheet
└── test/
    └── aegis_test.dart                # Unit tests for models & dispatch engine
```
