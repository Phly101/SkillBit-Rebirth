# SkillBit-Rebirth

> A gamified, competitive learning platform for programmers: learn through structured courses, prove it in timed contests, and climb a ranked badge ladder.

SkillBit-Rebirth is a from-scratch rebuild of SkillBit, a graduation project. The first version worked, but its backend was messy and its Flutter code was rushed, so refactoring cost more than starting clean. This repository is the clean start: designed first, then built feature by feature.

**Status:** documentation phase finished, UI design done, development has started. See [Project status](#project-status).

---

## Table of contents

- [What is SkillBit?](#what-is-skillbit)
- [Core features](#core-features)
- [How the scoring and ranking work](#how-the-scoring-and-ranking-work)
- [How it is built](#how-it-is-built)
- [Repository layout](#repository-layout)
- [Project status](#project-status)
- [Getting started](#getting-started)
- [Contributing](#contributing)
- [Documentation](#documentation)

---

## What is SkillBit?

Most learning apps do one of two things well: teach you (courses) or test you (competitions). SkillBit combines both in one loop:

1. **Learn** in structured levels made of courses, sections, lessons and quizzes.
2. **Compete** in contests and friendly matches against other users.
3. **Progress** by earning points that move you up through five badge tiers.
4. **Improve** with a weak-point detector that tells you what to review after a quiz or contest.

Course content is free. The lessons mostly link to existing free videos and open articles; SkillBit's value is the structure, the practice, and the competition around them.

## Core features

### Learning
- **Levels:** three levels. Each has mandatory courses and optional ones. Finishing every mandatory course at 100% unlocks the next level. Optional courses never block progress but give more points.
- **Courses:** course > sections > lessons, plus one quiz per section drawing on that section's lessons. Courses inside a level unlock one after another (locked ones are visible but not tappable).
- **Lessons:** a description plus a video and/or an article, each marked as Arabic or English. Users can move freely between lessons and mark them complete.
- **Quizzes:** retryable, every attempt judged on its own. Passing needs 75% correct. Quizzes decide completion; they do not award points.
- **Question types:** multiple choice and **Parsons problems** (arrange code blocks in the correct order to build the target code).
- **Interactive examples:** per-course visualizations (how sorting runs, how data structures store data, and so on) and read-only code examples in C++, Java and Python, with pre-computed output in a result widget. There is no live code execution inside the app.

### Competition
- **Contests:** Codeforces-style. Unlocked after finishing level 1, you enroll first, questions come from all three levels, and results are ranked by points then by least time. Points are awarded when the contest ends.
- **Friendly matches:** two users face each other; the host picks topics, number of questions and time limit. Friendly matches award no points.
- **Leaderboard:** live ranking with a podium, top 20, and your surrounding positions.

### Progress and social
- **Badges:** five tiers (Bronze, Silver, Gold, Platinum, Diamond), earned and lost through total points. Demotion uses a point buffer so rank does not flicker around a threshold.
- **Achievements:** separate from badges; unlocked by conditions checked against the user's own progress data.
- **Profiles:** anyone can view anyone's profile: image, score, badge, tier, recent achievements, and a Codeforces-style growth graph of contest points.
- **Friends:** search, add, remove, challenge.
- **Weak-point detector:** after a quiz or contest, suggests which topics to review.
- **Hints:** solving hints (quizzes only, free to use) and review hints that explain why the correct answer is right. Both are available in English and Arabic.

### Language
The app UI is localized to Arabic and English. Question and answer text is **English only**, because there is no reliable Arabic equivalent for technical terms and code.

### Monetization
Free to use. Ads appear after quiz and contest results, after achievements and badges, and as a banner on the home screen. A one-time purchase removes them.

## How the scoring and ranking work

| Concept | Rule |
|---|---|
| Question value | Easy 1, Medium 3, Hard 5 |
| Contest modifiers | Higher badge tiers get a bigger multiplier on correct answers (x1.0 at tier 1 up to x1.8 at tier 5) but also lose a bigger share on wrong answers (0% up to 40% of the question's value); they apply **only in contests** |
| Contest ranking | Highest points, then least time; exact ties share a rank |
| Contest top-3 bonus | +50% / +40% / +30% on total contest score |
| Course completion | Mandatory courses give 100 / 200 / 350 points (levels 1 / 2 / 3); optional courses give 2.5x |
| Quizzes | Pass at 75% in a single attempt; no points |
| Friendly matches | No points |

> Check the exact formulas in [`Docs/`](Docs/) before relying on this table; the docs are the source of truth.

## How it is built

SkillBit-Rebirth is a **monorepo** with a Spring Boot backend and a Flutter mobile app, talking over three channels, each picked for what it does best:

| Channel | Used for |
|---|---|
| **REST** | Actions: auth, starting/submitting quizzes and contests, friends, enrolling, finishing courses |
| **GraphQL** | Reading content: home, courses, lessons, quiz details, search, profiles, achievements, badges |
| **WebSockets** | Live data: leaderboard, score/rank changes, and profile updates that appear without reopening the app |

### Backend
- Java 25, Spring Boot 4, Maven
- PostgreSQL with Flyway migrations (V1 to V14)
- **Modular monolith, package by feature:** `achievement`, `admin`, `auth`, `common`, `contest`, `examples`, `friendly_matches`, `learning`, `question`, `quiz`, `realtime`, `social`, `user`. Each module has `domain`, `dto`, `event`, `repository`, `service`, `web`.
- Architecture rules enforced by **ArchUnit** tests (no cycles between modules, controllers never touch repositories, DTOs never depend on entities, and so on)
- Caffeine for in-memory caching
- Spring Security with email/password plus Google and GitHub sign-in

### Mobile
- Flutter, feature-first structure (`lib/app`, `lib/core`, `lib/features`)
- Cubits/bloc for state, `get_it` for dependency injection, `go_router` for navigation, `freezed` and `json_serializable` for models
- Decoupled Material UI package, Plus Jakarta Sans via `google_fonts`
- Android flavors: `development` and `production`
- future: Rive animations for badges and avatar frames

## Repository layout

```
.
├── backend/skillbit_Backend/   # Spring Boot backend
├── mobile/                     # Flutter app
├── Docs/                       # Schema, API specs, diagrams, design docs
├── .github/workflows/          # CI: PR checks for backend and Flutter
└── .env.example                # Shared environment variable template
```

Each side has its own README with setup details: [`backend/README.md`](backend/README.md) and [`mobile/README.md`](mobile/README.md).

## Project status

| Phase | State |
|---|---|
| API design (REST, GraphQL, WebSocket events) | Done |
| Database schema and migrations | Done |
| Documentation | Done |
| UI/UX design (Figma) | Done |
| Content gathering (courses, sections, lessons) | Next |
| Flutter base setup (theme, DI, config) | Done |
| Backend base setup (profiles, CI, ArchUnit, error handling) | Done |
| Backend features | Starting with auth, then feature by feature |

**Development approach:** each feature is built and tested in Spring first, then implemented and tested in Flutter, then we move to the next one.

**Scope is frozen for now.** Ideas beyond the current design (streaks, leagues, a cosmetics store, an admin desktop app, comments) are future plans that depend on how the app does after launch. Please open a discussion before proposing new features.

## Getting started


### Prerequisites
- Git
- JDK 25
- PostgreSQL
- Flutter SDK (check `mobile/pubspec.yaml` for the required version)

### Backend
1. Copy the root `.env.example` to `backend/skillbit_Backend/.env` and fill in the database values. There are three sets (`_DEV`, `_TEST`, `_PROD`), one per Spring profile.
2. Create an empty PostgreSQL database matching your `_DEV` values.
3. Run the app with the `dev` profile. Flyway applies all migrations automatically on startup.

### Mobile
1. `cd mobile`
2. `flutter pub get`
3. `dart run build_runner build` (generates `freezed` / JSON code)
4. `flutter run --flavor development`

## Contributing

We are glad to have you. A few rules keep the project consistent, and they apply to everyone including the maintainer.

### Workflow
- Never push to `main`. Open a pull request; required checks must pass before merging.
- **Branch names:** `<stack>/<type>/<name>`
  - `stack`: `mobile`, `backend`, `docs`, `ci` or `repo` (root files and shared config)
  - `type`: `feature`, `fix` or `setup` (`docs`, `ci` and `repo` use only `setup` or `fix`)
  - Example: `mobile/feature/profile`, `backend/fix/common-config`
- **Commit messages** start with the matching prefix: `mobile:`, `backend:`, `docs:`, `ci:`, `repo:`
- Fill in the PR template. CI runs only the checks relevant to what you changed.

### Code rules (Flutter)
- Follow the linter rules; do not silence them to make a warning go away.
- Responsive layouts are always a priority.
- Keep UI modular. **Do not return widgets from functions**; make a widget class instead.
- Use AI sparingly for logic. **Any AI-written code must carry a comment saying so**, whoever wrote it.

### Code rules (Backend)
- Respect the module boundaries; the ArchUnit tests will fail the build if you break them.
- Errors go through the shared exception types and error response shape in `common`.
- Schema changes go through Flyway migrations.

### Before you start
Read the relevant docs in [`Docs/`](Docs/) first. Most "how should this work?" questions are already answered there, and where they are not, please ask before building.

## Documentation

Everything that defines how the system works lives in [`Docs/`](Docs/):

- Database schema and relationship diagrams
- REST API (OpenAPI) and GraphQL schema
- WebSocket event catalog
- User flow diagram
- UI designs

## Maintainer

Built and maintained by Basel as a full-stack project (Spring Boot + Flutter).

License

SkillBit-Rebirth is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0). See LICENSE for the full text.

In plain terms: you are free to read, run, modify and share this code, but if you distribute a modified version, or let users interact with it over a network, you must make your complete source available under the same license and keep the original copyright and license notices. You cannot take this code, close it, and present it as your own.

Copyright (C) 2026 Basel.
