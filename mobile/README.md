# SkillBit-Rebirth: Mobile (Flutter)

The Flutter app for SkillBit-Rebirth, a gamified, competitive learning platform: courses, quizzes, contests, friendly matches, a global leaderboard, badges and achievements.

The backend lives in `../Backend/skillbit_Backend` (Spring Boot). API contracts are in `../Docs/` (OpenAPI for REST, GraphQL schema files, WebSocket events).

## Getting started

```bash
flutter pub get
flutter run
```

Before opening a PR, all three of these must pass:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Project structure

```
lib/
├── app/        # app-wide setup: config (router, theme, l10n), global bloc, observers
├── core/       # shared plumbing: errors, network, services (DI, storage), usecases, utils, widgets
└── features/   # one folder per feature
```

Each feature has three layers:

```
features/<name>/
├── data/          # remote datasources (REST / GraphQL / WebSocket), models, repository implementations
├── domain/        # entities, repository interfaces, use cases (pure Dart)
└── presentation/  # bloc/cubit, pages, widgets
```

Features: `achievement`, `auth`, `contest`, `examples`, `friendly_match`, `leaderboard`, `learning`, `onboarding`, `profile`, `quiz`, `settings`, `social`.

Feature names match the backend modules wherever possible (`profile` is the screen side of the backend `user` module).

### Architecture rules

1. Dependencies point inward: `presentation` depends on `domain`, and `data` depends on `domain`. `domain` is pure Dart: no Flutter, no Dio, no JSON.
2. Models (data layer) are converted to entities (domain layer). The UI only ever sees entities.
3. A feature never imports another feature's `data` or `presentation`. If two features need the same thing, move it to `core/widgets` or depend on the other feature's `domain` interface.
4. Don't add a layer where it adds nothing (for example, a simple settings toggle doesn't need a use case).
5. The server decides points, ranks and badges. The app only displays them and never calculates them.

## Code rules

### Linter
Follow the analyzer and lint rules in `analysis_options.yaml`. No `// ignore:` comments without a written reason on the same line.

### No widget-returning functions
Widgets must be classes, never functions or methods that return a widget.

```dart
// Not allowed
Widget _buildHeader() => const Text('Header');

// Required
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => const Text('Header');
}
```

Classes get their own rebuild boundary, can be `const`, and show up properly in DevTools.

### Modular UI
Build screens from small, reusable widgets, each in its own class. A page composes widgets and holds no layout details itself. A widget used by more than one feature goes in `core/widgets`. A widget used by one feature stays in that feature's `presentation/widgets`.

### Responsiveness is always a priority
- No hard-coded screen sizes, and no layouts that assume one phone.
- Use `LayoutBuilder`, `MediaQuery`, `Flexible`/`Expanded`, `Wrap` and similar tools.
- Check every screen on a small phone, a large phone and a tablet, in portrait and landscape, and with large system text sizes.
- Text must never overflow. Long text wraps or truncates on purpose.
- The app is localised in Arabic and English, so layouts must also work right-to-left.

### AI use
AI may help, but with limits:
- Limit AI use in business logic. You must understand and be able to explain every line you commit.
- Any code written by AI, by either contributor, must carry a comment saying so, directly above the code:

```dart
// AI-GENERATED (<tool name>): reviewed by <your name>
```

- Unmarked AI code found in review will be sent back.

## Git workflow

### Branches
`main` always works. Nothing is committed to it directly. Work happens on short-lived branches:

- `feature/<name>`, for example `feature/auth`
- `fix/<name>`, for example `fix/leaderboard-overflow`
- `setup/<name>`, for example `setup/flutter-foundation`

### Commit messages
Start every commit with the part of the project it touches, then a short description in the present tense:

```
mobile: add login screen
mobile: fix overflow on contest results
backend: add login endpoint
docs: update openapi
ci: add workflow
```

### Pull requests
Every change goes through a PR into `main`. A PR is mergeable when:

1. It is small and about one thing.
2. `dart format`, `flutter analyze` and `flutter test` all pass.
3. New logic has tests.
4. Any AI-written code is marked as described above.
5. UI changes include screenshots (small phone and tablet).
6. It has been reviewed and approved by someone other than its author.
7. Review comments are resolved.

The PR template in `.github/` has this checklist.
