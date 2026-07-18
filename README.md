# LMS — Learning Management System (Flutter Web)

A cross-platform Learning Management System built with **Flutter & Dart**. It
runs as a web app (and also builds for Android) and ships with a persistent
local **database** and an in-app **notification** system — no backend or cloud
credentials required.

**Live demo:** https://ahmdmero2022.github.io/LmsApp/ (published by GitHub
Actions from `main`; enable it once under Settings → Pages → Source: GitHub
Actions).

## Features

- **Authentication & roles** — sign in / sign up as a *Student* or *Instructor*
  (plus one-tap demo accounts).
- **Course catalog** — browse, search and filter courses by category.
- **Enrollment & progress tracking** — students enroll, mark lessons complete
  and see per-course progress.
- **Instructor tools** — create/delete courses, add lessons, see enrollment
  counts.
- **Notifications** — a notification center with unread badges. Notifications
  are generated automatically for:
  - a new course being published (to all students),
  - a new lesson added (to enrolled students),
  - a student enrolling (to the instructor),
  - course completion (to the student and instructor).
- **Persistent database** — all data (users, courses, enrollments,
  notifications) is stored with [`sembast`](https://pub.dev/packages/sembast)
  (IndexedDB on web) so it survives page reloads.
- **Responsive UI** — navigation rail on wide screens, bottom navigation on
  narrow screens; Material 3 theming.

## Architecture

```
lib/
  models/        # AppUser, Course, Lesson, Enrollment, AppNotification
  data/
    database.dart      # sembast database wrapper (IndexedDB on web)
    repositories.dart  # CRUD per store
    seed.dart          # first-run demo data
  state/
    app_state.dart     # ChangeNotifier — single source of truth + all writes
  widgets/       # reusable CourseCard / responsive CourseGrid
  screens/       # login, catalog, course detail, my learning,
                 # teaching, notifications, profile, root shell
```

State is managed with `provider` (`ChangeNotifier`). Every mutation goes through
`AppState`, which writes to the repositories and reloads the in-memory view.

## Running

```bash
flutter pub get
flutter run -d chrome        # run the web app
flutter build web --release  # production web build in build/web
flutter test                 # unit tests
flutter analyze              # static analysis
```

### Demo accounts

| Email          | Role       |
| -------------- | ---------- |
| sara@lms.dev   | Instructor |
| omar@lms.dev   | Instructor |
| ali@lms.dev    | Student    |
