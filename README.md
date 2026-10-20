# Dropzy — Mobile (Customer App)

Flutter customer app for **Dropzy** (_Send parcels across cities_), rebuilt to
match the official Dropzy app (`com.dropzy.dropzy_marketplace`) — same brand,
same OTP flow, same screens — wired to the same Go backend.

## Flow & screens

| Screen | Purpose |
| --- | --- |
| **Login** | Mobile number (+91) → **Get OTP**. |
| **Verify OTP** | 4-digit code → **Verify & Continue** (demo code `1234`). |
| **Home** | "Hi, Customer 👋", pickup/destination + Book a parcel, Quick actions, FIRST20 offer, Recent shipments. |
| **Book a parcel** | 6-step stepper: Sender → Receiver → Shipment → Route → Fare → Payment → `POST /shipments`. |
| **Track** | Look up a shipment / DCN by ID → live tracking. |
| **Shipments** | History list (`/shipments`) with status pills. |
| **Shipment detail** | Route, package, fare, OpenStreetMap live tracking, timeline. |
| **Support** | Call / email / chat / FAQs. |
| **Profile** | Account, mobile, sign out. |

Bottom nav (5 tabs): **Home · Track · Shipments · Support · Profile**.

## Brand

- Primary red **`#C0392B`** (decoded from the official app icon), light `#F7F7F8` surfaces, truck logo.

## Architecture

```
lib/
├── core/          constants (API base), theme, api_client (Bearer + 401 auto-logout)
├── models/        User, Shipment, Order, Estimate, Tracking, Notification
├── services/      auth (OTP), shipments, rates, orders, tracking, notifications
├── state/         Services container + AuthProvider (mobile/OTP, persisted token)
├── widgets/       logo, status chips, cards, loading/empty views
└── screens/       splash, login, otp, home + tabs, booking, shipment detail, ...
main.dart          MultiProvider + auth gate
```

## Auth notes (important)

The official app signs in with **mobile + OTP**. The deployed OTP endpoint is
**not** present in the `dropzy-backend` repo (that repo's `main` still has auth
as `// TODO` stubs — the **deployed server is ahead of the repo**). So:

- `AuthService.requestOtp` / `verifyOtp` try the likely OTP paths, then fall
  back to the **confirmed-working** `/auth/register` + `/auth/login` endpoints,
  mapping the phone to a stable account (`<mobile>@dropzy.mobile`). Demo OTP
  **`1234`** therefore authenticates for real and returns a valid JWT.
- To make it fully-native OTP, point `verifyOtp` at the real endpoint (body:
  `{ "mobile": ..., "otp": ... }`) once you have the deployed path.

Cleartext HTTP is enabled (`android:usesCleartextTraffic="true"`) because the
backend is plain HTTP — matching the official app. Use HTTPS for release.

## Run

```bash
cd dropzy_mobile
flutter pub get
flutter run
```

Different backend:

```bash
flutter run --dart-define=API_URL=https://your-api/api/v1
```

Default backend: `http://16.112.168.63:8080/api/v1`.

## PRD v2.0 core client (`CORE_API`)

| dart-define | Default | Meaning |
|-------------|---------|---------|
| `API_URL` | `http://16.112.168.63:8080/api/v1` | API base URL |
| `CORE_API` | `false` | `true` → PRD v2.0 core client only (`lib/core_api/`, `lib/screens/v2/`, `lib/navigation/`). `false` → legacy demo app, unchanged. |
| `DEMO_MODE` | `false` | Shows the dev OTP echo on the OTP screen (core) when the server returns `devCode`. |

```bash
# local core backend from the Android emulator (dev OTP 1234)
flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8080/api/v1 --dart-define=CORE_API=true
```

Core builds never call the legacy `/shipments` mock, guessed OTP endpoints or the
demo register/login fallback, and never derive money or payment state on the device
(amounts are server `*Paise` fields, buttons follow `allowedActions`/`blockedActions`,
"Paid" only from the server). Tokens are kept in `flutter_secure_storage`. Deep links:
`dropzy://shipments/{id}`, `dropzy://shipments/{id}/pay`, `dropzy://payments/return?intentId=`.
Android cleartext HTTP is limited by `res/xml/network_security_config.xml`
(debug: 10.0.2.2 / localhost / 127.0.0.1; all builds: the legacy demo host until it has TLS).
