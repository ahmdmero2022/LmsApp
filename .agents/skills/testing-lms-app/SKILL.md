---
name: testing-lms-app
description: Build, serve, and end-to-end test the Flutter web LMS app (roles, courses, enrollment/progress, notifications, sembast/IndexedDB persistence). Use when verifying LMS UI or data-layer changes.
---

# Testing the LMS Flutter web app

## Setup
- Flutter SDK is provisioned by the blueprint (cloned to `$HOME/flutter`, on PATH). If missing: `git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter && export PATH="$PATH:$HOME/flutter/bin" && flutter config --enable-web`.
- Install deps: `flutter pub get` (repo root contains `pubspec.yaml`).

## Static checks (shell)
- Lint: `flutter analyze`
- Unit tests: `flutter test`
- Build web: `flutter build web --release` (output in `build/web`).

## Running for UI testing
- Serve the release build statically: `cd build/web && python3 -m http.server <port>`, then open `http://localhost:<port>` in Chrome.
- Tip: the app persists data in IndexedDB keyed by origin. To get a **fresh DB seed**, serve on a NEW port (new origin) — this avoids needing devtools to clear storage.
- Alternatively `flutter run -d web-server --web-port <port>` for a dev run.

## Demo accounts (seeded on first run)
- `sara@lms.dev` / `omar@lms.dev` — Instructors
- `ali@lms.dev` — Student
Use the one-tap demo-account buttons on the login screen (no password).

## Key end-to-end flow that proves the headline features
1. Login as an instructor (Sara) → Teaching → New course → Publish. This should generate a "New course available" notification for every student.
2. Sign out, login as a student (Ali) → Notifications shows the unread badge + the cross-user notification. (Proves notifications + that the DB write from one user is read by another session.)
3. Catalog → open a seeded course with lessons (e.g. "Databases 101") → Enroll → mark each lesson complete. Progress bar goes 0% → 50% → 100%. On 100% a "Course completed! 🎉" notification fires.
4. Hard-reload the page. NOTE: login state is in-memory by design, so reload returns to the login screen. Re-login as the same student → My Learning still shows the enrollment at 100% and Notifications still lists prior notifications. (Proves sembast/IndexedDB persistence.)

## Gotchas
- A newly created course has 0 lessons, so it can't be used for the completion test — use a seeded course (Databases 101 / Flutter for Beginners) for progress/completion.
- Notifications are generated in `lib/state/app_state.dart` (`createCourse`, `enroll`, `addLesson`, `toggleLessonComplete`). If a notification doesn't appear, check that method.
- The seeder only runs when the users store is empty (`Seeder.seedIfEmpty`); an existing origin keeps old data.

## Devin Secrets Needed
- None. The app is fully self-contained (local IndexedDB, no backend/auth).
