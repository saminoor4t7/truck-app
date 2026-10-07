# Truck App

A local-first Flutter app for delivery routes, proof of delivery, fleet tools, GPS tracking, barcode scanning, receipt printing, and a driver KPI dashboard.

## Local setup

```powershell
flutter pub get
flutter run
```

The app does not require sign-in or a cloud account. Orders, delivery evidence, dashboard settings, and GPS samples are stored on the device. Delivery evidence is not uploaded, GPS tracking is not shared with a fleet, and push notifications are not configured.

The bottom navigation provides Home (today's assigned work), Scan, Tracking, Signature, and Dashboard. The dashboard includes a locally saved, editable driver profile and performance cards.

Admin Dashboard is available from the navigation drawer. It can assign local tasks to the saved driver, view the latest recorded truck location, and open saved delivery signatures. Admin and driver data remain on this device and are not shared with other devices.

## Main code locations

- `lib/src/features/orders`: locally persisted sample deliveries and delivery workflow.
- `lib/src/features/tracking`: on-device GPS tracking, telemetry, and geofences.
- `lib/src/features/printing`, `lib/src/features/scanner`, `lib/src/features/pod_signature`: BLE receipt printing, barcode scanning, and signature capture.
- `lib/src/features/dashboard`: local driver KPI dashboard.
- `lib/core/di`: local dependency registration.

## Verify

```powershell
flutter test
flutter analyze
flutter build apk --debug
```

Location and Bluetooth permission prompts, printer behavior, and background tracking should be validated on physical devices.
