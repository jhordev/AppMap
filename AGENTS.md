# Repository Guidelines

## Project Structure & Module Organization
App source lives in `lib/` with feature-first layout. `lib/features/{auth,home,maps,places}` hold views, controllers, and Riverpod logic. Shared widgets belong in `lib/components/`. `lib/core/providers` exposes app-wide dependencies; `lib/routes` centralizes navigation; `lib/utils` keeps helpers. Configuration such as Firebase and environment constants resides in `lib/config` and `firestore.rules`. Native scaffolding stays inside `android/`, while `web/` contains the HTML shell. Tests mirror source under `test/`, and build outputs stay in `build/`.

## Build, Test, and Development Commands
- `flutter pub get`: install and lock dependencies.
- `flutter run --dart-define=MAPS_KEY=...`: launch on the selected device with runtime secrets.
- `flutter test`: run all unit and widget tests.
- `flutter analyze`: surface lint and type issues from `analysis_options.yaml`.
- `flutter build apk --release`: produce a signed Android package; run from CI before store submissions.

## Coding Style & Naming Conventions
Target Dart SDK 3.8 with Flutter lints enabled. Use two-space indentation, trailing commas on multi-line literals, and `//` comments for context only. Classes, enums, and typedefs use `UpperCamelCase`; variables and functions use `lowerCamelCase`; files stay in `snake_case.dart`. Favor Riverpod providers over global state and keep feature folders free of cross-layer imports; re-export from `lib/core/` when needed.

## Testing Guidelines
Place tests beside the feature they cover using `_test.dart` suffixes. Use `flutter_test`'s `testWidgets` for UI contracts and keep asynchronous expectations awaited. Stub Firebase and HTTP calls with fakes or `setUpAll` overrides. Aim for smoke coverage of every route change and new provider; add golden tests for complex map overlays when UI changes are risky.

## Commit & Pull Request Guidelines
Write imperative, <=72-character commit subjects (example: `Add place search provider`). Describe rationale and side effects in the body when change is non-trivial. Branch names should follow `feature/short-topic` or `fix/...`. Pull requests must link tracking issues, list testing evidence (`flutter test`, device smoke runs), and include screenshots or screen recordings for UI updates.

## Configuration & Security Notes
Keep API keys out of source; follow `SOLUCION_API_KEY.md` for local `.env` scaffolding and pass secrets via `--dart-define`. Review `firestore.rules` before deployments and update together with schema migrations. Never check in device-specific `google-services.json`; provide setup steps in the PR if configuration changes.
