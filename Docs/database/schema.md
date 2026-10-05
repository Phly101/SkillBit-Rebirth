# SkillBit-Rebirth: Database Design Notes

Target: PostgreSQL 13 or newer. The API rules this is built from live in [`../api/README.md`](../api/README.md).

## Conventions (decided)

- **IDs:** `uuid` for every table whose IDs appear in the API. `bigint` identity for internal append-only logs that never leave the backend (the points ledger, payment events).
- **Enum-like columns:** `text` plus a `CHECK` constraint, not native PostgreSQL enums. They are easier to change in Flyway and to map in Hibernate.
- **Timestamps:** `timestamptz`, stored in UTC.
- **Points** are whole numbers (rounded once per attempt and once after the contest bonus, decided).
- **Deleting:** no hard-deleting users in v1. Purely personal rows (tokens, OTPs, enrollments, friendships) may cascade. Shared history (attempts, contest results, the points ledger) must not.
- **Hibernate** runs with `ddl-auto=validate`. Flyway owns the schema.
- **Derived, never stored:** contest status (upcoming, live, ended), lesson counts, progress percentage, whether a level is unlocked, `Relationship` between two users, and a growth point's `badgeChange`.

## Migration plan (Flyway)

Files live in `Backend/skillbit_Backend/src/main/resources/db/migration/` and are named `V<number>__<description>.sql`
(two underscores). Group by feature, in foreign-key order: a file may only reference tables created in an earlier file
or in itself.

| File | Contains | Depends on | Why it is its own file |
|---|---|---|---|
| `V1__extensions` | trigram extension | nothing | Needs privileges the app user may lack. If it fails you know at once and nothing else is half applied |
| `V2__badges` | badges | nothing | Configuration table that users point to |
| `V3__users_and_auth` | users, social identities, refresh tokens, OTP codes, reset tokens | V2 | The auth feature. You can start coding signup and login as soon as this exists |
| `V4__seed_badges` | the five badge rows | V2 | Required reference data. Kept apart from structure because it changes for different reasons |
| `V5__learning_content` | levels, courses, sections, lessons, topics, lesson-topics, roadmaps, course-roadmaps | nothing from earlier files | Authored content, filled by the importer |
| `V6__learner_progress` | enrollments, lesson completions | V3, V5 | User-generated data, with a different lifecycle from content |
| `V7__questions_and_quizzes` | questions, question topics, options, blocks, quizzes, quiz questions | V5 | The question bank and quiz definitions |
| `V8__contests` | contests, contest entries | V2, V3, V7 | The contest feature, including its results |
| `V9__social` | friendships, friend requests, friend matches | V3, V7 | **Before attempts**, because an attempt can point at a friendly match |
| `V10__attempts_and_points` | attempts, attempt questions, the per-user quiz result (if stored), points ledger | V3, V7, V8, V9 | Everything produced by answering questions |
| `V11__achievements` | achievements, user achievements | V3 | Independent feature |
| `V12__store_and_payments` | payment events, cosmetic items, donation products, user cosmetics, equipped cosmetics | V3 | Independent feature |

Content (courses, lessons, questions, topics, achievements, cosmetics) is **not** loaded by migrations. It comes from
the importer, which upserts by a stable slug. Only data the app cannot run without (the badges) is a migration.

Rules for writing them:

1. Never edit a migration that has been applied anywhere you care about. Fix forward with a new file. While only your local database has seen it, you may edit and reset.
2. A table, its indexes and its constraints live in the same file.
3. Name every constraint and index yourself, so errors, logs and later `ALTER` statements use names you know.
4. Do not use `IF NOT EXISTS` to make a script pass (extensions are the exception). It hides a database that has drifted from the history.
5. Save as UTF-8 without BOM, with LF line endings.
6. Test by running every migration from scratch on an empty database, with Hibernate on `ddl-auto=validate`.

## What each area must represent

### 1. Badges, users, authentication

- Exactly five badges: tier 1 to 5, name, icon, the points needed for promotion, and a lower points value below which a user is demoted (the buffer). Data, seeded later.
- Users: unique lowercase email, optional password (social-only accounts have none), name, avatar storage key, cached total points, current badge, supporter flag, and whether the email is verified.
- Social identities (Google, GitHub), unique per provider account, many per user.
- Refresh tokens (store only a hash, support rotation and revocation), OTP codes (purpose, hashed code, expiry, wrong-guess counter, used or not, and the new address for an email change), password reset tokens.
- Name search on users and titles needs "contains" matching. Look at trigram indexes.

### 2. Learning content

- Levels are ordered. A level holds courses, and a course is **mandatory or optional**.
- A course has an image, a title and summary, a published flag, and the points it awards when finished, stored as a whole number on the course: 100, 200 or 350 for a mandatory course of level 1, 2 or 3, and 2.5 times that for an optional course (250, 500, 875). The multiplier is applied when you seed the data, so the schema just holds the final amount.
- A course has ordered **sections**. A section has ordered **lessons** and one quiz.
- A lesson has a title, a description, and a video link and/or an article link. **At least one of the two links must exist.** Think about how to make the database enforce that.
- Topics (tags) and which lessons teach which topic. This is how a weak topic turns into "review these lessons".
- Roadmaps: roadmap.sh slug and title, linked to courses (many to many).
- Enrollments (user, course, when, finished when) and lesson completions (user, lesson, when).
- Progress, "course finished" and "level unlocked" are derived from lesson completions **and completed section quizzes**. Decide which parts you query and which you cache. A section quiz counts as completed once some attempt reached at least 75% correct answers, and it stays completed (each attempt is judged on its own). Decide whether you store that fact (and when it happened) or derive it from attempts.

### 3. Questions and quizzes

- Question types: multiple choice and Parsons. Every question has a difficulty (easy, medium, hard), one or more topics, an explanation and hint, a language (for code), a status (draft, reviewed, published, retired), and a source.
- **Questions are immutable once published.** A fix is a new row (new version) that points at the one it replaces. Old attempts must keep pointing at the exact text they showed.
- Every question belongs to one of two **separate pools**: quiz questions or contest questions. A quiz question belongs to a lesson (that is how a section quiz covers "all the lessons in the section"). Contest questions belong to no lesson, and they are also the questions friendly matches use. A quiz or contest never holds the same question twice, but a question may be reused in a later contest.
- Multiple-choice options: ordered, one flagged correct. Parsons blocks: code, indentation, and the correct position, where "no position" means the block is a distractor.
- A quiz is an ordered list of questions. It is the quiz of a section, or the quiz of a contest, or the question set of a friendly match. A match takes its questions from the contest pool: decide whether each match gets its own generated quiz row or its own list of questions. Both players must get the same set, fixed once the challenge is accepted.

### 4. Contests, attempts, answers, points

- Contests: title, a window (start and end), their quiz, and a "results applied at" moment. Status is derived from the times. Tags come from the questions.
- An **attempt** is one user working through one quiz, contest or match. It needs: the kind, the user, what it belongs to, a seed for the stable Parsons shuffle, start time, deadline, close time and close reason (submitted or time ran out), number correct, points (contests only), and **the user's badge tier when it started** (only contests use the tier modifiers, so this can be empty for quiz attempts).
- Per user and quiz, **the result that counts**: once the quiz is passed it never goes back and keeps the best percentage, before that it is the latest attempt's percentage. Decide whether to store this (updated when an attempt closes) or derive it from attempts each time.
- Quizzes and friendly matches award no points: a quiz attempt only records how many answers were correct, and so whether it passed. Only contests and finished courses produce points, and only contests have tier modifiers and penalties.
- Per attempt, a snapshot of the questions that were served, in order, with the user's answer to each (an option, or an ordered list of blocks) and whether it was correct. Autosave updates these answers.
- A contest entry per (contest, user): enrolled at, and once results are applied the final rank, the points from the contest, the bonus, the points after, and the badge held afterwards. **Each finished entry is one growth-graph point.**
- The points ledger: one row per change (amount actually applied, total afterwards, reason, which attempt, course or contest caused it). Reasons are course finished and contest result. The same source must not be able to award the same user twice. The user's cached total must always equal the sum of the ledger.
- Constraints worth thinking about: one attempt per user per contest, one per user per friendly match, and a contest attempt must have a contest while a quiz attempt must not.

### 5. Social

- Friendships: one row per pair, however you order the two users.
- Friend requests: sender, receiver, status. Only one pending request between two users, whichever direction it was sent in.
- Friendly matches: challenger, opponent, the settings the host chose (topics, number of questions, time limit), the questions picked from the contest pool for those settings, status, invitation expiry, play deadline, winner (empty on a tie). Players cannot challenge themselves, and the winner must be one of the two.

### 6. Achievements, store, payments

- Achievements: title, description, icon, and a **condition** checked against the user's own progress data (courses finished, optional courses finished, current badge tier, number of first places, and so on). A user has each at most once, with the moment it was earned. Decide how the condition is stored: as data (a metric, a threshold and an optional scope such as a level), so new achievements need no code, or as a stable code that the backend maps to a rule. Also decide where the numbers come from: counted from the real tables when evaluated, or kept in a stats table updated by events. Which achievements exist is seed content.
- Cosmetics: type (avatar frame, profile theme, badge skin, title), how it is unlocked (purchase, donation, all achievements), asset path, and the Google Play product for purchasable ones.
- Tip-jar products: any of them makes the user a supporter and grants the donation cosmetics.
- Ownership per (user, item). Equipped items: one per user per type. **The database should make it impossible to equip something you do not own, or to put an item in the wrong slot.** Deleting ownership (a refund) should unequip it automatically.
- Payment events: provider, the provider's event ID (unique, this is the idempotency key), type, user (may be unknown), product, transaction, the raw payload, and what happened to it.

## Rules the database cannot enforce

The application and the seed validator must keep these:

- The cached total equals the ledger sum and never goes below 0 (the ledger records the change actually applied after clamping).
- A user's badge follows the ladder, including the demotion buffer.
- The supporter flag is true while at least one donation still counts.
- A multiple-choice question has exactly one correct option. Options belong to multiple-choice questions only and blocks to Parsons questions only. Parsons positions run 0, 1, 2 without gaps. Every question has at least one topic and a difficulty.
- An attempt's question count equals the number of questions in its snapshot.
- Only enrolled users, and only after finishing level 1, start a contest attempt, while the contest is live. Friendly matches are only created between friends.
- Finalizing a contest is idempotent and sets its "results applied at" moment last.
- Achievements are evaluated after each relevant event (course finished, contest finalized, badge change), and awarding one is idempotent.
- Points follow the scoring rules in the API README (contest difficulty points, tier modifiers, penalty, rounding, top-3 bonus, and the flat course amounts).

## Review checklist (what I will look at)

1. Primary keys, and foreign keys on every reference.
2. `NOT NULL`, `DEFAULT`, `CHECK` and `UNIQUE` where a rule can be enforced.
3. Partial unique indexes for "at most one of X per Y" rules.
4. `ON DELETE` behavior chosen on purpose, not left to default.
5. Types: `timestamptz`, `uuid`, `text`, and integers for points.
6. Indexes for the real queries (leaderboard, growth graph, jobs that close attempts and finalize contests), without indexing everything.
7. Naming consistency and Flyway file naming (`V1__description.sql`).

## Diagrams

You are drawing these. Suggested approach: draw one diagram per area (the six above) instead of one huge diagram, and put them in this folder as Mermaid (`erDiagram`, renders on GitHub), or as DBML from dbdiagram.io with an exported image. A useful check once your migrations run: generate a diagram from the real database (DBeaver, pgAdmin or SchemaSpy can do it) and compare it with the one you drew. Any difference is a mistake in one of them.

## Open questions

1. **Badge seed values:** names, icons, promotion thresholds and demotion thresholds for the five badges. With course amounts of 100, 200 and 350 per course, choose thresholds that make sense against those numbers.
2. **The achievement condition model** (data-driven or code-mapped, see area 6). The list of achievements itself is seed content for later.
3. **Where question data comes from**, which decides how you seed questions, topics and difficulty.
