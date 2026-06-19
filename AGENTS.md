# AGENTS.md

## Snapshot
- Flutter app repo with all platform folders present: `android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`.
- Dart package name is `i_miner` (`pubspec.yaml`), even though the repo folder is `flutter_alpa` and `README.md` is still template-level.
- No repo CI workflows, task runner config, pre-commit config, Cursor rules, Copilot instructions, or repo-local OpenCode config were found.

## Verified Commands
- Install deps: `flutter pub get`
- Analyze: `flutter analyze`
- Test: `flutter test`
- Regenerate launcher icons after changing `assets/icon/logo.png`: `flutter pub run flutter_launcher_icons`

## Environment Constraint
- `pubspec.yaml` requires Dart `^3.11.1`.
- In the current environment, both `flutter analyze` and `flutter test` stop at dependency resolution because installed Dart is `3.4.3`.
- Do not trust local verification until the Flutter/Dart SDK matches `pubspec.yaml`.

## App Entry And Flow
- Entry point is `lib/main.dart`.
- App bootstraps a single global provider: `ConnectionProvider`.
- `MaterialApp.home` is `LoginScreen`; there is no named-route setup in `main.dart`.
- Login flow in `lib/screens/login/login_screen.dart` is online-first, then offline fallback.
- Successful online login stores the user locally via `DatabaseHelper().saveUser(...)` before navigating to `DashboardScreen`.

## Data And Sync
- `lib/config/data/database_helper.dart` is the central SQLite layer.
- Always set the active user first with `DatabaseHelper().setCurrentUserDni(dni)` before DB work; the database file is user-scoped.
- Local DB filename is `Seminco_db_catalina_huanca_<dni>.db` and schema version is `20`.
- Desktop builds switch to `sqflite_common_ffi`; mobile uses the normal `sqflite` path.
- The DB enables `PRAGMA foreign_keys = ON` during configure.
- Connectivity recovery triggers sync automatically: `ConnectionProvider` listens for offline -> online transitions and calls `SyncService().syncData()`.
- `SyncService` uploads per operation type through `lib/services/envio nube/...` export services and removes `local_id` before POSTing.

## Codebase Gotchas
- Several directories in `lib/` contain spaces, for example `lib/screens/Envio a nube/` and `lib/services/get nube/`.
- Package imports encode those spaces as `%20`, for example `package:i_miner/screens/Envio%20a%20nube/...`.
- Be careful when renaming or moving these folders: imports are already brittle and widespread.
- `test/widget_test.dart` is still the default counter smoke test and does not match the current `LoginScreen` app shell.

## High-Value Files
- `pubspec.yaml`: SDK constraint, dependencies, assets, launcher icon config.
- `analysis_options.yaml`: only `flutter_lints` defaults; no custom analyzer rules.
- `lib/main.dart`: app bootstrap.
- `lib/screens/login/login_screen.dart`: online/offline auth handoff.
- `lib/screens/Dash/reporte_sreen.dart`: dashboard entry after login.
- `lib/config/api/api_config.dart`: hard-coded backend base URL and endpoint map.
- `lib/config/data/database_helper.dart`: schema, migrations, offline auth, local persistence.
- `lib/core/network/connection_provider.dart` and `lib/core/sync/sync_service.dart`: automatic upload-on-reconnect flow.
