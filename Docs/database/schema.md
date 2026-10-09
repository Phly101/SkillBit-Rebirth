# SkillBit-Rebirth: Database Design Notes

Target: PostgreSQL 13 or newer. The API rules this is built from live in [`../api/README.md`](../api/README.md).

## Conventions (decided)

- **IDs:** `uuid` for every table whose IDs appear in the API. `bigint` identity for internal append-only logs that
  never leave the backend (the points ledger, payment events).
- **Enum-like columns:** `text` plus a `CHECK` constraint, not native PostgreSQL enums. They are easier to change in
  Flyway and to map in Hibernate. The migrations use `VARCHAR(50)` plus the `CHECK`.
- **Timestamps:** `timestamptz`, stored in UTC.
- **Points** are whole numbers (rounded once per attempt and once after the contest bonus, decided).
- **Deleting:** no hard-deleting users in v1. Purely personal rows (tokens, OTPs, enrollments, friendships) may cascade.
  Shared history (attempts, contest results, the points ledger) must not.
- **Hibernate** runs with `ddl-auto=validate`. Flyway owns the schema.
- **Derived, never stored:** contest status (upcoming, live, ended), lesson counts, progress percentage, whether a level
  is unlocked, `Relationship` between two users, a growth point's `badgeChange`, **a user's result on a section quiz (
  computed from quiz attempts)**, and the number of questions in a friendly match (counted from its question list).
- **Naming:** constraints use the prefixes `chk_` (check), `uk_` (unique, including partial unique indexes) and `idx_`
  (plain index). Enum-like values are UPPERCASE (`'PENDING'`, `'GOOGLE'`).
- **Slugs:** levels, courses, sections, lessons and roadmaps have a `slug`, which is what the importer upserts by.
  Level, course and roadmap slugs are unique globally; section and lesson slugs are unique **within their parent**
  (course, section). `sequence_order` is also unique within its parent, never globally.
- **`ON DELETE`:** content and shared history use `RESTRICT` (a lesson, course, question or contest that is in use
  cannot be deleted). Purely personal rows cascade from the user. Child rows that only exist for their parent (options,
  blocks, link tables, match questions) cascade from that parent.
- **Icons and images:** the database stores a short relative path (`icons/badges/bronze.svg`), never an absolute path on
  a developer machine. The app decides where the files live.
- **Redundant indexes:** do not add a single-column index when a unique constraint or primary key already starts with
  that column.

## Migration plan (Flyway)

Files live in `Backend/skillbit_Backend/src/main/resources/db/migration/` and are named `V<number>__<description>.sql`
(two underscores). Group by feature, in foreign-key order: a file may only reference tables created in an earlier file
or in itself.

| File                        | Contains                                                                                                      | Depends on                 | Why it is its own file                                                                                |
|-----------------------------|---------------------------------------------------------------------------------------------------------------|----------------------------|-------------------------------------------------------------------------------------------------------|
| `V1__extensions`            | trigram extension                                                                                             | nothing                    | Needs privileges the app user may lack. If it fails you know at once and nothing else is half applied |
| `V2__badges`                | badges                                                                                                        | nothing                    | Configuration table that users point to                                                               |
| `V3__users_and_auth`        | users, social identities, refresh tokens, OTP codes, reset tokens                                             | V2                         | The auth feature. You can start coding signup and login as soon as this exists                        |
| `V4__seed_badges`           | the five badge rows                                                                                           | V2                         | Required reference data. Kept apart from structure because it changes for different reasons           |
| `V5__learning_content`      | levels, courses, sections, lessons, topics, lesson-topics, roadmaps, course-roadmaps,quizzes                  | nothing from earlier files | Authored content, filled by the importer                                                              |
| `V6__learner_progress`      | enrollments, lesson completions                                                                               | V3, V5                     | User-generated data, with a different lifecycle from content                                          |
| `V7__questions_and_quizzes` | questions, question topics, options, blocks, quiz questions                                                   | V5                         | The question bank and section-quiz question lists                                                     |
| `V8__contests`              | contests, contest entries, contest questions                                                                  | V2, V3, V7                 | The contest feature, including its results                                                            |
| `V9__social`                | friendships, friend requests, friendly matches, match topics, match questions                                 | V3, V7                     | **Before attempts**, because an attempt can point at a friendly match                                 |
| `V10__attempts_and_points`  | quiz attempts, contest attempts, friendly match attempts, a served-questions snapshot per kind, points ledger | V3, V5, V7, V8, V9         | Everything produced by answering questions                                                            |
| `V11__achievements`         | achievements, user achievements                                                                               | V3                         | Independent feature                                                                                   |
| `V12__store_and_payments`   | payment events, cosmetic items, donation products, user cosmetics, equipped cosmetics                         | V3                         | Independent feature                                                                                   |

Content (courses, lessons, questions, topics, achievements, cosmetics) is **not** loaded by migrations. It comes from
the importer, which upserts by a stable slug. Only data the app cannot run without (the badges) is a migration.

Rules for writing them:

1. Never edit a migration that has been applied anywhere you care about. Fix forward with a new file. While only your
   local database has seen it, you may edit and reset.
2. A table, its indexes and its constraints live in the same file.
3. Name every constraint and index yourself, so errors, logs and later `ALTER` statements use names you know.
4. Do not use `IF NOT EXISTS` to make a script pass (extensions are the exception). It hides a database that has drifted
   from the history.
5. Save as UTF-8 without BOM, with LF line endings.
6. Test by running every migration from scratch on an empty database, with Hibernate on `ddl-auto=validate`.

## What each area must represent

### 1. Badges, users, authentication

- Exactly five badges: tier 1 to 5, name, icon, the points needed for promotion, and a lower points value below which a
  user is demoted (the buffer). Data, seeded later.
- Users: unique lowercase email, optional password (social-only accounts have none), name, avatar storage key, cached
  total points, current badge, supporter flag, and whether the email is verified.
- Social identities (Google, GitHub), unique per provider account, many per user.
- Refresh tokens (store only a hash, support rotation and revocation), OTP codes (purpose, hashed code, expiry,
  wrong-guess counter, used or not, and the new address for an email change), password reset tokens.
- Name search on users and titles needs "contains" matching. Look at trigram indexes.

### 2. Learning content

- Levels are ordered. A level holds courses, and a course is **mandatory or optional**.
- A course has an image, a title and summary, a published flag (`is_published`, false by default, so a course stays
  hidden while it is being written), and the points it awards when finished, stored as a whole number on the course:
  100, 200 or 350 for a mandatory course of level 1, 2 or 3, and 2.5 times that for an optional course (250, 500, 875).
  The multiplier is applied when you seed the data, so the schema just holds the final amount.
- A course has ordered **sections**. A section has ordered **lessons** and one quiz (`quizzes.section_id` is required
  and unique, so a quiz exists only inside a course and a section has at most one).
- A lesson has a title, a description, and a video link and/or an article link. **At least one of the two links must
  exist.** Think about how to make the database enforce that.
- Topics (tags) and which lessons teach which topic. This is how a weak topic turns into "review these lessons".
- Roadmaps: roadmap.sh slug and title, linked to courses (many to many).
- Enrollments (user, course, when, finished when) and lesson completions (user, lesson, when).
- Progress, "course finished" and "level unlocked" are derived from lesson completions **and completed section
  quizzes**. A section quiz counts as completed once some attempt reached at least 75% correct answers, and it stays
  completed (each attempt is judged on its own). **Decided: this is derived from quiz attempts, not stored.**

### 3. Questions and quizzes

- Question types: multiple choice and Parsons. Every question has a difficulty (easy, medium, hard), one or more topics,
  an explanation and hint, a language (for code), a status (draft, reviewed, published, retired), and a source.
- **Questions are immutable once published.** A fix is a new row (new version) that points at the one it replaces. Old
  attempts must keep pointing at the exact text they showed.
- Every question belongs to one of two **separate pools**: quiz questions or contest questions. A quiz question belongs
  to a lesson (that is how a section quiz covers "all the lessons in the section"). Contest questions belong to no
  lesson, and they are also the questions friendly matches use. A quiz or contest never holds the same question twice,
  but a question may be reused in a later contest.
- Multiple-choice options: ordered, one flagged correct. Parsons blocks: code, indentation, and the correct position,
  where "no position" means the block is a distractor. The database refuses a second correct option on the same
  question, and refuses two blocks claiming the same correct position.
- A quiz is an ordered list of questions and belongs to a section; quizzes exist only inside courses. **Contests and
  friendly matches do not use quizzes.** Each contest has its own ordered question list, and each friendly match has its
  own ordered list picked from the contest pool (the same list for both players, fixed once the challenge is accepted).
  A friendly match is built like a contest but awards no points.

### 4. Contests, attempts, answers, points

- Contests: title, a window (start and end), their own question list, and a "results applied at" moment (never before
  the window ends). Status is derived from the times. Tags come from the questions.
- An **attempt** is one user working through one quiz, contest or match. **Decided: there is one attempts table per
  kind** (quiz attempt, contest attempt, friendly match attempt), not one shared table, so each kind has plain required
  foreign keys. Each attempt needs: the user, what it belongs to (a quiz, a contest or a match), a seed for the stable
  Parsons shuffle, start time, deadline, close time and close reason (submitted or time ran out), number correct, **the
  total number of questions served** (needed to compute the percentage), points (contests only), and **the user's badge
  tier when it started** (contest attempts only).
- Per user and quiz, **the result that counts**: once the quiz is passed it never goes back and keeps the best
  percentage, before that it is the latest attempt's percentage. **Decided: derived from the attempts each time, not
  stored.** `quiz attempts` therefore needs an index that starts with the user and the quiz.
- Quizzes and friendly matches award no points: a quiz attempt only records how many answers were correct, and so
  whether it passed. Only contests and finished courses produce points, and only contests have tier modifiers and
  penalties.
- Per attempt, a snapshot of the questions that were served, in order, with the user's answer to each (an option, or an
  ordered list of blocks) and whether it was correct. Autosave updates these answers. Each attempt kind has its own
  snapshot table.
- **Decided: answers use two tables per attempt kind**, one for multiple choice (the one option picked) and one for
  Parsons (the arranged blocks, one row per position), both pointing at the snapshot row. An option or block must belong
  to the question it answers (composite foreign key, which needs unique `(id, question_id)` on `question_options` and
  `parsons_blocks`). A contest attempt points at the user's contest entry, so only enrolled users can have one. The
  ledger has a `bigint` identity ID, an amount, a total after, a reason, and exactly one source (course or contest).
- A contest entry per (contest, user): enrolled at, and once results are applied the final rank, the contest points, the
  bonus, the user's total points after, and the badge held afterward. **Each finished entry is one growth-graph point.**
  The result columns are all empty before results are applied and all filled after. Ties may share a rank (there is no
  unique rule on rank). Entries cannot be deleted with their user or contest.
- **Contest points** (`contest_points`) are the contest's own score for that user, with all difficulty modifiers,
  penalties and the top-3 bonus already applied. It can be negative. **The bonus is already inside it, so never add
  `bonus` on top of it** (`bonus` is stored only to show and audit it). `user_points_after` is the user's **total**
  after the contest and is never below 0. When the total hits the floor of 0, the change actually applied is smaller
  than `contest_points`, and that applied amount is what the points ledger records.
- The points ledger: one row per change (amount actually applied, total afterward, reason, which attempt, course or
  contest caused it). Reasons are course finished and contest result. The same source must not be able to award the same
  user twice. The user's cached total must always equal the sum of the ledger. The source is a course or a contest, not
  an attempt (written in V10): exactly one source is set, and a partial unique index per source stops the same user
  being paid twice.
- Constraints for V10: one contest attempt per user per contest, one friendly match attempt per user per match, and no
  limit on quiz attempts (retries are allowed).

### 5. Social

- Friendships: one row per pair. The two user columns are stored in a fixed order (`user_id_1 < user_id_2`), so the
  primary key makes (Ali, Sara) and (Sara, Ali) the same row.
- Friend requests: sender, receiver, status (pending, accepted, declined, canceled). Only one **pending** request
  between two users, whichever direction it was sent in (a partial unique index on the pair compared in a fixed order).
  Old declined or canceled requests stay and do not block a new one.
- Friendly matches: challenger, opponent, the settings the host chose (time limit on the match, topics in a link table,
  number of questions counted from the question list), status (pending, accepted, declined, expired, completed,
  canceled), two separate deadlines (`invitation_expires_at`, set at creation, and `play_deadline`, set together with
  `accepted_at` when the opponent accepts), the winner (empty on a tie), and a completion time. **Scores are not stored
  on the match**: each player's number correct lives on their attempt. Players cannot challenge themselves, and the
  winner must be one of the two. `accepted_at` is when the opponent accepted, not when play started (each player's real
  start is their attempt's start time). **Lifecycle:** when the host's time runs out the match ends automatically. If at
  least one player started, it becomes COMPLETED, unfinished attempts are closed as TIME_RAN_OUT, and the winner is
  decided by the scoring rules (a player with no attempt counts as 0 correct). If nobody started, it becomes EXPIRED.
  EXPIRED and CANCELED may or may not have an `accepted_at`, but never one of `accepted_at` and `play_deadline` without
  the other. Each player's attempt deadline equals the match's `play_deadline`.

### 6. Achievements, store, payments

- Achievements: slug, title, description, icon (relative path), and a **condition stored as data**: a `metric` name
  (text, no database list, so a new metric needs no migration), a positive `threshold`, and an optional `scope` (for
  example a level slug). **The database holds only this shape and who earned what (and when).** Whether a user has
  earned one is decided by the application, which counts from the real tables when it evaluates after an event (course
  finished, contest finalized, badge change). The meaning of each metric lives in the app and is checked by the seed
  validator. A user has each achievement at most once. Which achievements exist is seed content, still to be decided.
- Cosmetics: type (avatar frame, profile theme, badge skin, title), how it is unlocked (purchase, donation, all
  achievements), asset path, and the Google Play product for purchasable ones.
- **V12 shape:** ownership carries the item's type, and equipped items point at ownership by (user, item, type). That
  one composite foreign key makes it impossible to equip something you do not own or to put an item in the wrong slot,
  and deleting ownership (a refund) unequips it automatically. The primary key (user, type) allows one equipped item per
  type. A purchasable item must have a Google Play product, and only purchasable items may have one. Payment events are
  unique per (provider, provider event ID), keep the raw payload as JSONB, and have a status (received, processed,
  ignored, failed).
- Tip-jar products: any of them makes the user a supporter and grants the donation cosmetics.
- Ownership per (user, item). Equipped items: one per user per type. **The database should make it impossible to equip
  something you do not own, or to put an item in the wrong slot.** Deleting ownership (a refund) should unequip it
  automatically.
- Payment events: provider, the provider's event ID (unique, this is the idempotency key), type, user (maybe unknown),
  product, transaction, the raw payload, and what happened to it.

## Rules the database cannot enforce

The application and the seed validator must keep these:

- The cached total equals the ledger sum and never goes below 0 (the ledger records the change actually applied after
  clamping).
- A user's badge follows the ladder, including the demotion buffer.
- The supporter flag is true while at least one donation still counts.
- A multiple-choice question has **exactly** one correct option (the database only guarantees at most one). Options
  belong to multiple-choice questions only and blocks to Parsons questions only. Parsons positions run 0, 1, 2 without
  gaps (the database only blocks duplicates). Every question has at least one topic and a difficulty.
- An attempt's question count equals the number of questions in its snapshot.
- Expired-but-unused OTP codes must be marked used (or deleted) before a new code is issued, because only one unused
  code per user and purpose is allowed.
- Accepting a friend request creates the friendship row (in the same transaction). The friendly match winner is decided
  by the scoring rules from each player's attempt (empty on a tie).
- A contest attempt or friendly match may only start while the match or contest is in its valid state, and a quiz result
  is only computed from closed attempts.
- Only enrolled users, and only after finishing level 1, start a contest attempt, while the contest is live. Friendly
  matches are only created between friends.
- Finalizing a contest is idempotent and sets its "results applied at" moment last.
- Achievements are evaluated after each relevant event (course finished, contest finalized, badge change), and awarding
  one is idempotent.
- Points follow the scoring rules in the API README (contest difficulty points, tier modifiers, penalty, rounding, top-3
  bonus, and the flat course amounts).

## Diagrams

Can be found in ['../diagrams'](../diagrams)

## Open questions

1. **Where question data comes from**, which decides how you seed questions, topics and difficulty.
2. **Badge icon files:** bundled in the Flutter app's assets, or served from the backend's static folder? The database
   only stores the relative path.
   lifecycle above.
3. **Refresh token rotation:** does a token need a link to the one that replaced it?
