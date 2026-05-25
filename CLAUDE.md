# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NestWay（栖途）— 女性独旅安全 Flutter App. Virtual escort, SOS emergency help, AI-powered city safety analysis.

Tech: Flutter 3.x + Provider + Supabase (PostgreSQL + Auth) + DeepSeek API + 高德地图 (amap_flutter_map).

## Commands

```bash
flutter pub get              # Install dependencies
flutter run                  # Run on connected device/emulator
flutter analyze              # Static analysis / lint
flutter test                 # Run all tests
flutter test test/location_service_test.dart  # Run a single test file
flutter build apk --debug    # Build debug APK (CI uses this)
```

## Architecture

### State management
Provider (`lib/main.dart:11-18`). Two providers registered at root:
- **AuthProvider** — demo login flow, tracks `_currentUser` and `_isDemoMode`. Sets `SosService().currentUserId` on login/logout.
- **ContactsProvider** — wraps `SosService` emergency contact CRUD, calls `loadContacts()` after mutations.

### Service layer
- **SupabaseService** (`lib/services/supabase_service.dart`) — static init wrapper. Supabase URL + anonKey are hardcoded (not from .env). `.env` is optional and for local overrides only.
- **SosService** (`lib/services/sos_service.dart`) — **singleton** (factory constructor). SOS trigger flow: get GPS → call top contact → share location link → report to `sos_logs` table → send SMS via Edge Function. Also handles emergency contacts CRUD against Supabase. `currentUserId` is set externally by AuthProvider.
- **EscortLocationService** (`lib/services/location_service.dart`) — **singleton**. GPS tracking via geolocator + 高德 reverse geocode (falls back to mock addresses). All `report*` methods are stubs (print + Future.delayed, no real backend).

### Platform channels
Two MethodChannels for native Android/iOS calls (原生实现待完善):
- `com.nestway/phone` — `makePhoneCall`, `openDialer`
- `com.nestway/location` — `getCurrentLocation`

### Navigation
Named routes defined in `lib/routes/app_routes.dart`. All pages mapped in a static `routes` map. Bottom nav (`AppBottomNav`) uses `pushReplacementNamed` for tab switching (home/SOS/profile).

### Demo mode
No real SMS verification needed for development. Login page offers demo users (from `lib/data/demo_users.dart`) that bypass Supabase Auth entirely via `AuthProvider.loginAsDemoUser()`. Mock data in `lib/mock/` provides contacts, SOS logs, city safety data.

### Supabase Edge Functions (Deno/TypeScript)
- `supabase/functions/send-sms-alicloud/` — OTP verification code SMS via Alibaba Cloud
- `supabase/functions/send-sos-sms/` — SOS bulk SMS to emergency contacts via Alibaba Cloud
Both use HMAC-SHA1 signing, require `FUNCTION_SECRET` Bearer token for auth. Deploy with `supabase functions deploy`.

### Backend tables (Supabase)
`users`, `sos_logs`, `emergency_contacts` — all accessed via `SupabaseService.instance.from()`.

## Key conventions

- Theme primary color: `Color(0xFFFFE066)` (yellow)
- Scaffold background: `Color(0xFFF3F0FF)` (light purple)
- App uses Chinese UI strings throughout
- CI/CD: Codemagic (`codemagic.yaml`) builds Android debug APK on push
