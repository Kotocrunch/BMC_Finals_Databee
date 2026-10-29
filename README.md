# DataBee

DataBee is a Flutter shopping app with a Supabase backend. It can also run in a
local demo mode without a Supabase project.

## Requirements

- Git
- Flutter SDK with a Dart SDK satisfying the constraint in `pubspec.yaml`
  (Dart `^3.13.5`)
- Android Studio and the Android SDK to run or build for Android

Install Flutter and Android Studio, then check your setup:

```sh
flutter doctor
```

Resolve any missing Flutter or Android toolchain requirements reported by that
command before continuing.

## Get the project

Clone the repository and enter the Flutter project directory:

```sh
git clone https://github.com/Kotocrunch/BMC_Finals_Databee.git
cd BMC_Finals_Databee/databee
```

On Windows PowerShell, the directory command is:

```powershell
cd BMC_Finals_Databee\databee
```

Make sure this directory contains `pubspec.yaml`, then fetch the Flutter
packages:

```sh
flutter pub get
```

## Run a local demo

Demo mode uses the sample products and stores demo data locally; it does not
need Supabase credentials or database setup.

```sh
flutter run --dart-define=DEMO_MODE=true
```

To select a device, first list available targets with `flutter devices`, then
pass its ID, for example:

```sh
flutter run -d <device-id> --dart-define=DEMO_MODE=true
```

For a browser, use `flutter run -d chrome --dart-define=DEMO_MODE=true`.

## Run with Supabase

For accounts and shared, server-backed store data, use your own Supabase
project:

1. Create a Supabase project and open **SQL Editor** in its dashboard.
2. Run the SQL files in this order:
   1. `supabase/schema.sql`
   2. `supabase/delivery_tracking.sql`
   3. `supabase/shopping_delivery.sql`
   4. `supabase/delivery_preview.sql`
3. Start the app with your project's URL and publishable key:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

In PowerShell, run the command on one line:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

Use the **publishable** (client-side) key from your Supabase project settings.
Never put a Supabase service-role key or a payment-provider secret in the app.
Xendit checkout requires additional server-side setup; see
[`supabase/XENDIT_SETUP.md`](supabase/XENDIT_SETUP.md).
If your Supabase project already has the shopping delivery setup, run
`supabase/delivery_preview.sql` once to enable saving completed delivery
previews. To add the sample product catalog, also run
`supabase/demo_products.sql` after `supabase/schema.sql`.

## Build an Android APK

With the Android toolchain installed, build a release APK:

```sh
flutter build apk --release --dart-define=DEMO_MODE=true
```

The APK is written to
`build/app/outputs/flutter-apk/app-release.apk`. To build an APK connected to
your Supabase project instead, replace the demo-mode define with the
`SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` defines shown above.

## Useful commands

```sh
flutter analyze
flutter test
```
