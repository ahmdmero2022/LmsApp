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
Use the one-tap demo-account buttons on the login screen (no password). For
password login/change tests, the demo password is `password123` (see
`kDemoPassword` in `lib/data/seed.dart`).

## Auth / password testing
- Password auth: signup requires password + confirm (min 6 chars); login verifies
  it; storage is salted PBKDF2 (`lib/utils/password.dart`). Login errors are
  generic ("Incorrect email or password").
- Change password lives in Profile → "Change password" tile → dialog with
  current/new/confirm fields (`lib/screens/profile_screen.dart`,
  `ChangePasswordDialog`).
- Strongest end-to-end proof that a password change persisted: change it, sign
  out, confirm the OLD password is rejected, then confirm the NEW password logs
  in. A no-op/broken change would let the old password still work.

## Completion certificates
- A "View certificate" button appears in the course detail's enrolled panel ONLY
  when `enrollment.isCompleted(course.lessons.length)` is true (100%) — see
  `lib/screens/course_detail_screen.dart`. Verify it is absent at <100%.
- The certificate (`lib/screens/certificate_screen.dart`) shows student name,
  course title, instructor, and completion date (`Enrollment.completedAt`,
  stamped once on first completion).
- "Print / Save as PDF" is web-only (`canExportCertificate`); on web it opens a
  NEW browser tab with a standalone styled HTML certificate + Print button
  (`lib/utils/certificate_export_web.dart`). Adversarial check: the button must
  NOT appear before 100%, and the exported tab must show the correct identity
  fields (a broken data wiring would show blank/wrong name/course).

## Course ratings & reviews
- Only an **enrolled** student (not the course owner) sees a "Leave a review" /
  "Edit your review" button in the course detail's `_ReviewsSection`
  (`lib/screens/course_detail_screen.dart`); `AppState.saveReview` guards on
  `isEnrolled`. There is one review per (student, course) — re-reviewing updates
  in place (upsert), it does NOT append.
- Average rating + count show on `CourseCard` (Catalog + My Learning) and in the
  reviews section header; `averageRating` returns null → card shows "No reviews
  yet". The review dialog's Submit is disabled until a star is picked.
- Adversarial test: use a course with NO seeded reviews (e.g. "UI/UX Design
  Principles") so the average only appears if the write works. Verify: card "No
  reviews yet" → enroll → leave 4★ → header "Reviews (1)" + 4.0 avg → edit rating
  → count stays "Reviews (1)" and avg recomputes → catalog card shows the new
  average. Seeded reviews exist on Flutter (4.5, 2) and Databases 101 (4.0, 1).

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
