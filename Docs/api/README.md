# SkillBit-Rebirth: API Overview

Three transports, one rule: **GraphQL asks, REST commands, the socket pushes.**

| Transport | Use it for | Source of truth |
|---|---|---|
| GraphQL | Reading data shaped around a screen (home, course content, course search, quiz and contest details, profile header, achievements, friends list, store catalog) | `Backend/skillbit_Backend/src/main/resources/graphql/*.graphqls` |
| REST | Anything that changes state or must be an explicit action (auth, enroll, lesson completion, start/autosave/submit, friend actions, profile edits) | [`../../preview/openapi.yaml`](../../preview/openapi.yaml) |
| WebSocket | Server-to-client change events so the UI updates without reloading | [`../../preview/events.md`](../../preview/events.md) |

The database schema is described in [`../database/schema.md`](../database/schema.md).

Status legend: **[notes]** came from the original design notes, **[decided]** was agreed during design discussion, **[proposed]** is a suggestion to confirm.

## Conventions

- **Base paths:** REST under `/api/v1`, GraphQL at `/graphql`, socket at `/ws`.
- **Auth:** one JWT (access + refresh) used for all three transports. REST and GraphQL send it as `Authorization: Bearer <token>`. The socket validates it during the handshake. The one exception is the RevenueCat webhook, which uses a shared secret instead (see Cosmetics and purchases).
- **Timestamps:** ISO-8601 UTC. **IDs:** opaque strings in the API, even if they are numeric in the DB.
- **Errors (REST):** `{ "code": "QUIZ_ALREADY_SUBMITTED", "message": "...", "details": {} }`. Codes are stable, messages are not.
- **Pagination:** cursor-based (`first`, `after`) in GraphQL; `?limit=&cursor=` in REST.
- **Idempotency:** `submit` endpoints must be safe to retry (same attempt submitted twice returns the first result).

## GraphQL (reads)

Single endpoint, schema split by domain (`user`, `course`, `quiz`, `contest`).

| Query | Used by | Notes |
|---|---|---|
| `me { name avatarUrl points badge { ... } nextBadge pointsToNextBadge }` | Home header, profile | Initial snapshot; the socket keeps it fresh afterwards |
| `levels { name isUnlocked courses(first) { ... myProgress } }` | Home | Levels are plain data. Lazy-load other levels with `level(id)` |
| `course(id)` | Course preview and details | Same type; details also requests `sections` (each with its `lessons` and its `quiz`). `roadmaps { title url }` feeds the "see roadmap" button |
| `courses(search, levelId, first, after)` | Course search | [decided] Returns the same `Course` type as the home cards |
| `quiz(id)` | Quiz details | Metadata and questions per the start rules; never expose correct answers before submit |
| `contest(id)` / `contests` | Contest details and list | Schedule, level tier, and `myStatus` (not enrolled, enrolled, in progress, submitted, result ready) |
| `me { achievements }` | Achievements detail | [decided] Read-only, nested under the user |
| `badgeLadder` | Ranks screen | [decided] All five badges with tier and thresholds |
| `searchUsers(query, first, after)` | Friends search | [decided] Moved from REST. `relationship` on each result drives the Add/Remove/Pending button |
| `user(id)` | Another user's public profile | [decided] Anyone can view anyone. Adds `relationship`, `recentAchievements`, `growth`, `courseProgress` on top of the basic `User` fields |
| `me { recentAchievements growth }` | Own profile | [decided] Same growth graph as `user(id)` |
| `storeItems(type)` | Store | [proposed] Catalog with `isOwned` for the logged-in user. Prices come from the store SDK, not from here |
| `me { cosmetics ownedCosmetics isSupporter }` | Own profile, inventory | [proposed] `cosmetics` and `isSupporter` are also on `user(id)`, so others see your frame, title and badge skin |
| `me { friends }` | Friends list | [decided] Friend actions stay REST |
| `me { friendRequests }` | Incoming friend requests | [proposed] |
| `friendMatch(id)` | Friendly match status and scores | [proposed] Scores stay hidden until both players finish |
| `friendMatchLimits`, `matchTopics` | Friendly match setup screen | [proposed] The allowed ranges for questions and time, and the topics the host can choose |
| `me { weakTopics }` | Home "review these" card | [proposed] |

## REST (commands)

### Auth [notes]

| Method | Path | Purpose |
|---|---|---|
| POST | `/auth/signup` | Create account, triggers OTP |
| POST | `/auth/login` | Email + password |
| POST | `/auth/google` | Google sign-in (exchange ID token) |
| POST | `/auth/github` | GitHub sign-in (exchange code) |
| POST | `/auth/otp/send` | Send OTP |
| POST | `/auth/otp/resend` | Resend OTP (rate limited) |
| POST | `/auth/verify` | Verify OTP |
| POST | `/auth/forgot-password` | Start reset |
| POST | `/auth/reset-password` | [proposed] Finish reset with the token from `/auth/verify` |
| POST | `/auth/logout` | Revoke refresh token |
| POST | `/auth/refresh` | [proposed] Rotate tokens |

### Account [notes]

| Method | Path | Purpose |
|---|---|---|
| PATCH | `/me/profile` | Change name. On success, emits `profile.updated` |
| PUT | `/me/avatar` | Upload image (multipart). Server bumps the version and emits `profile.updated` with the new versioned URL |
| POST | `/me/email-change` | Request email change (OTP confirm) |
| POST | `/me/password-change` | Change password |

### Learning and contests

| Method | Path | Purpose |
|---|---|---|
| POST | `/courses/{id}/enroll` | Enroll in course [notes] |
| POST | `/lessons/{id}/complete` | Mark a lesson completed (lessons change only by this button). Idempotent, emits `progress.updated`. When progress (lessons and quizzes) reaches 100% the course finishes automatically (`course.finished`) |
| POST | `/contests/{id}/enroll` | Enroll in contest [notes]. 403 until level 1 is finished |
| POST | `/quizzes/{id}/attempts` | Start quiz [notes] |
| POST | `/contests/{id}/attempts` | Start contest [notes] |
| POST | `/attempts/{id}/submit` | Submit quiz or contest. Response includes score and `weakTopics` |
| POST | `/attempts/{id}/restart` | Restart quiz [notes] |
| GET | `/attempts/{id}/results` | Results [notes] |
| GET | `/attempts/{id}/review` | Review answers with hints [notes] |
| GET | `/contests/{id}/leaderboard` | Leaderboard snapshot [notes]. Live updates come from the socket. Ranks are provisional until the contest ends |

### Friends and friendly matches

| Method | Path | Purpose |
|---|---|---|
| POST | `/friends` | Add friend (sends request) [notes] |
| DELETE | `/friends/{userId}` | Remove friend [notes] |
| POST | `/friends/{userId}/challenge` | Challenge a friend and set up the match: the host picks topics, number of questions and time limit within server-configured limits [notes] |
| POST | `/friend-matches/{id}/accept` | [proposed] Accept challenge |
| POST | `/friend-matches/{id}/decline` | [proposed] Decline challenge |
| POST | `/friend-matches/{id}/attempts` | [proposed] Play your side of the match (same questions for both players) |
| POST | `/friend-requests/{id}/accept` | [proposed] Accept a friend request |
| POST | `/friend-requests/{id}/decline` | [proposed] Decline a friend request |

Friendly match flow (1v1, highest score wins), async version: challenge, accept, both play the same set of questions (a random set from the contest pool, using the topics, question count and time limit the host chose) within a window via the shared attempt endpoints, server compares scores and emits `match.finished`. Friendly matches award no points. See [`../../preview/events.md`](../../preview/events.md).

### Cosmetics

| Method | Path | Purpose |
|---|---|---|
| PUT | `/me/cosmetics/{type}` | [proposed] Equip an owned item in that slot (`AVATAR_FRAME`, `PROFILE_THEME`, `BADGE_SKIN`, `TITLE`) |
| DELETE | `/me/cosmetics/{type}` | [proposed] Empty that slot |
| POST | `/payments/revenuecat-webhook` | [proposed] Called by RevenueCat, never by the app. Grants purchases |

## Course structure and levels

- A **level** holds **mandatory** and **optional** courses. Completing every mandatory course of a level (100%) unlocks the next level. Optional courses never unlock anything, and many achievements revolve around finishing them.
- A **course** has an image and is split into **sections**, like Udemy. Each section has its **lessons** and one **quiz** with questions from all the lessons of that section.
- A **lesson** has a title, a description and at least one kind of content: a video (YouTube or similar), an article, or both.
- Users can open any lesson, section or quiz in any order.
- A lesson is completed only when the user presses the button (`POST /lessons/{id}/complete`). **Progress counts lessons and section quizzes**: each lesson and each quiz is one item, and progress is completed items divided by all items (equal weight is the proposed rule). A section quiz counts as **completed once an attempt reaches at least 75% correct answers**, and a passed quiz never becomes unpassed. Every attempt is judged on its own. Once a quiz is passed, retrying can only raise the percentage that counts (the best attempt is kept). Before it is passed, the latest attempt is the one that counts, even if it is worse than an earlier one. Compare as `correct x 4 >= total x 3` so rounding never decides it.
- At 100% progress the course finishes **automatically**: the server emits `course.finished`, and if that completed the mandatory courses of the level it unlocks the next one (`unlockedLevelId`). There is no finish button. Finishing awards a small number of points (see Points).

## Contest rules

- **Locked until level 1 is finished.** Enrollment is required before joining, like Codeforces. Contest questions come from all three levels, which is why finishing levels 2 and 3 matters for the top places.
- Contests have **tags** (topics) but no difficulty. The questions inside do have a difficulty.
- Contests have their **own question pool**, separate from the quiz questions. Friendly matches draw their questions from this same pool. A contest never contains the same question twice, but it can reuse questions from older contests.
- **Scoring:** per-question points with the badge tier modifiers and penalties (these exist only in contests), then a bonus on the **total** contest points: 1st place +50%, 2nd +40%, 3rd +30%. Example: 200 points and first place gives 300 (second place 280, third 260).
- **Ranking:** highest points first, then least time (from start to close). If two users are equal on both they share the rank for now (1, 1, 3): both get that place's bonus and the next place is skipped.
- **Rank and points are final only when the contest ends.** See Contest flow below.

## Contest flow

1. **Enroll** (REST). Only possible once level 1 is finished (`myStatus` is `LOCKED` until then). Afterwards `myStatus` is `ENROLLED`.
2. **Start** (REST). The response carries the questions. `expiresAt` is the earlier of the time limit and the contest end. Starting again while the attempt is in progress resumes it: the same questions in the same order, plus `savedAnswers`.
3. **Answer** (REST, autosave). The app calls `PUT /attempts/{id}/answers/{questionId}` whenever an answer changes. Nothing is graded yet.
4. **Submit** (REST). The result is `PENDING`: the score is known, but rank, points and weak topics are `null`. `myStatus` is `SUBMITTED`.
5. **The contest keeps running.** The user cannot get back to the questions (starting again returns 409, review is blocked) and sees a waiting state.
6. **If the timer runs out before the user submitted** (idle, lost connection, app killed), the server closes the attempt itself at `expiresAt` using the saved answers. Unanswered questions count as skipped. The user gets `attempt.closed` and the same `PENDING` result as a normal submit. A closed attempt cannot be changed: any later submit returns 409 `ATTEMPT_CLOSED`, and the app fetches the results instead. The server clock is authoritative, the countdown in the app is only a display.
7. **The contest ends.** The server finalizes it in one transaction: ranks, points, growth point and any badge change. Then it pushes `score.changed`, `badge.changed` if needed, and finally `contest.results_ready`.
8. **The app opens the results page** and loads `GET /attempts/{id}/results`, which is now `FINAL`. Review is available too.

If the app was closed at step 7, `myStatus` is `RESULT_READY` on the next launch and the app goes straight to the results page.

The same autosave and close-at-expiry rule can be added to timed quizzes and friendly matches later.

## Cosmetics and purchases

Principle: **the store sells, RevenueCat notifies, the backend grants, the socket tells the app.** The app never unlocks anything by itself.

1. The app shows the catalog from `storeItems` and reads each item's localized price from the store SDK using its `storeProductId`.
2. The user buys through Google Play Billing (via RevenueCat's Flutter SDK).
3. RevenueCat calls `POST /payments/revenuecat-webhook`.
4. The backend authenticates the call, ignores duplicates, and records the grant: an owned cosmetic, or `isSupporter = true` for the tip-jar product.
5. After the commit the server pushes `inventory.updated`. The app updates its inventory and the store shows the item as owned.
6. The user equips it with `PUT /me/cosmetics/{type}`. The server checks ownership and slot, then pushes `profile.updated`, so other screens and other users see the new frame, title or badge skin.

How a cosmetic is obtained (`CosmeticItem.unlock`), and nothing else grants one:

| `unlock` | How |
|---|---|
| `PURCHASE` | Bought with Google Play Billing |
| `DONATION` | Granted for donating through the tip jar (also a Play Billing product) |
| `ALL_ACHIEVEMENTS` | Granted by the server when the user has earned all achievements and badges |

Rules that make this safe:

- **Link purchases to users.** Right after login the app calls RevenueCat's `logIn` with our user ID. Otherwise the webhook arrives with an anonymous ID that cannot be matched.
- **Authenticate the webhook** with the shared secret from the RevenueCat dashboard (Authorization header, constant-time compare). It does not use the user JWT.
- **Be idempotent.** Retries reuse the same `event.id`, so store processed event IDs (and transaction IDs) with a unique constraint and answer 200 for repeats.
- **Handle few event types.** `NON_RENEWING_PURCHASE` grants. `CANCELLATION` covers refunds: the item is removed from the inventory, any slot holding it is emptied, and the app gets `profile.updated` and `inventory.updated` (reason `REFUND`). Everything else, including `TEST`, is acknowledged and ignored.
- **No prices in our API.** The store is the source of truth for price and currency, and money is never a float.
- **Earned rewards come from the server.** When the last achievement is earned, the backend grants the reward and pushes `inventory.updated` (reason `ACHIEVEMENTS`).
- **`isSupporter` is derived, not toggled.** It is true while any qualifying source remains (for example a donation), so one refund does not remove it if another source still counts.
- **Items are data.** `CosmeticItem` rows come from a table, so adding a frame or theme needs no deploy. Assets are versioned in their URLs like avatars.

For the database schema step, this means: a `cosmetic_items` table, an ownership table (user, item, when, transaction), an equipped table with one row per user per `type` (not extra columns on `users`), and a table of processed payment events.

Not covered here: streak savers (see Future plans), Patreon (parked, see Future plans) and ads (under discussion).

## Points

In this project **points** always means the score that moves badges. It comes from two places only: finishing courses and contests. Quizzes and friendly matches award none.

| Source | Points |
|---|---|
| Contests | The most: per-question points with the badge tier modifiers and penalties, plus the top-3 bonus. Applied when the contest ends |
| Finishing a course | A flat amount per course: 100 for a mandatory course of level 1, 200 for level 2, 350 for level 3. An optional course gives 2.5 times a normal course of its level (250, 500, 875). No tier modifiers |
| Quizzes | None. A quiz only decides whether it counts as passed (see below), which feeds course progress |
| Friendly matches | None |

**Contest scoring.** Base points by difficulty: easy 1, medium 3, hard 5. The badge tier modifiers exist only in contests, and the tier is the user's own badge tier when the attempt starts:

| Tier | Correct answer | Wrong answer |
|---|---|---|
| 1 | base | no penalty |
| 2 | base x 1.2 | minus 10% of base |
| 3 | base x 1.4 | minus 20% of base |
| 4 | base x 1.6 | minus 30% of base |
| 5 | base x 1.8 | minus 40% of base |

Skipped questions score nothing.

**Quiz scoring.** A quiz question is worth 1 if answered correctly and 0 otherwise, whatever its difficulty, with no modifiers, bonuses or penalties. The attempt passes with at least 75% correct answers. This keeps quiz progress manageable and stops people from targeting a handful of questions to pass instead of mastering the whole quiz. Every attempt is judged on its own, with no history carried over: if a user failed with 60%, then fixes the question that held them back on the retry but gets a different question wrong that they had right before, that attempt still fails.

**Whole points.** Course points are whole numbers already. Only contests produce fractions (tier modifiers and the bonus), so they are computed exactly, rounded once per attempt (half up), and once more after the contest bonus. Points are whole numbers everywhere, and the rank uses the rounded value.

## Badges

Five badges form a ladder (`tier` 1 to 5). Every user holds exactly one, and it moves with points:

- **Promotion** happens when points reach the next badge's `minPoints`.
- **Demotion** uses a buffer: a user is demoted only when points fall below the current badge's `demoteBelowPoints`, which is lower than its `minPoints`. This stops users near a boundary from flipping up and down after every quiz. (`demoteBelowPoints` is backend-only; clients just see `minPoints`.)
- Every change emits `badge.changed` with a `direction` of `PROMOTED` or `DEMOTED` (see [`../../preview/events.md`](../../preview/events.md)).
- "Rank" in this project means **leaderboard position** only. The badge level is called `tier`.

## Growth graph

Codeforces-style: one point per **finished contest**, never per quiz or course. Each `GrowthPoint` has the contest, date, placement (`rank`), points change (`delta`, can be negative), points after (`points`, the value to plot), the badge held afterwards and a `badgeChange` (`PROMOTED` or `DEMOTED`) when the badge differs from the previous graph point's. `points` is the user's total at that moment, so it can include quiz and course points earned since the previous contest, while `delta` is that contest's own change. Flutter draws the chart (for example with `fl_chart`) and can shade bands from `badgeLadder` thresholds. The backend needs a record of each contest result with the points change, so growth is a plain query over that history.

## Question types

Every question has a `type`. Questions are served only in the start-attempt response (REST), never through GraphQL, because they are served per attempt and must never carry the answers.

| Type | Served as | The user answers with |
|---|---|---|
| `MULTIPLE_CHOICE` | `text` and `options` | `selectedOptionId` |
| `PARSONS` | `text`, `language` and `blocks` (lines of code) | `orderedBlockIds`: the block IDs in the order the user arranged them |

How `PARSONS` (the "lego" arranging question) works:

- **The server shuffles the blocks**, once per attempt. Starting the same attempt again returns the same order. Block IDs are opaque, so neither the IDs nor the array order give the answer away.
- **Grading is server-side only.** The correct order never leaves the server until review, which is after the attempt is finished (for contests, after the contest ends). Review returns `submittedBlockIds` and `correctBlockIds`.
- **Distractors are supported without any contract change.** The answer is the list of blocks the user used, so a question may include extra blocks that don't belong, and leaving them out is part of the solution.
- **`indent` is display only.** Blocks appear indented as in the final code. Arranging them changes order only.
- The weak-point detector works as before: Parsons questions carry a topic tag like any other question.

**Scoring.** A Parsons question is all or nothing, like a multiple-choice one, so `score` stays a whole number of correct questions. Partial credit is a future plan.

**Question data.** Where the questions come from is not decided yet, and the API does not depend on it. Whatever the source, each question needs: a type, the question text, a difficulty (easy, medium or hard), at least one topic tag (the weak-point detector depends on it), the pool it belongs to (quiz or contest) and, for quiz questions, the lesson it belongs to, the correct answer, an optional explanation and hint for review, and for Parsons the solution stored as an ordered list of blocks with a flag that marks distractors. That shape works whether the data is imported, generated by a script, or written by hand.

## Roadmaps

We do not build or track roadmaps. A course can point to roadmaps on roadmap.sh, and the app opens them in the browser. `Course.roadmaps` is a list of `{ slug, title, url }` (an empty list means no button), read from our own table. The backend builds the URL from the slug. There are no REST endpoints and no socket events for roadmaps, and the backend never calls roadmap.sh.

## Achievements

Which achievements exist is seed content and is decided later. What the API and database need to know is that each achievement has a **condition** that is validated against the user's own progress data: how many courses they finished, how many optional courses, their current badge tier, how many first places they won, and similar counts. The server checks the conditions after events that change progress (a course finished, a contest finalized, a badge change). A user unlocks each achievement once. An unlock pushes `achievement.unlocked`, and some unlocks can also earn a cosmetic (`inventory.updated` with reason `ACHIEVEMENTS`).

## Weak-point detector

Computed on submit: group the attempt's answers by question topic tag, flag low-accuracy tags, and map them to lessons. Returned in the submit response and available through `me { weakTopics }`. Requires a **topic tag on every question** from day one.

## Future plans (not designed yet)

- Daily study streaks and streak savers.
- Partial credit for Parsons questions.
- An achievement for winning a number of friendly matches.
- Patreon is parked. Unlocking in-app perks from an outside payment may break Google Play's Payments policy, and that policy lists an ad-free version of an app as an example of in-app content that needs Play Billing, so "ads only" would not avoid the problem. If it is revisited, check the policy first, then design account linking and a webhook. Meanwhile a supporter can be ad-free through a Play Billing purchase, which fits the existing design.
- Ads are under discussion, with strict control. They would be handled by the client's ad SDK, and the API would only need an entitlement flag (for example no ads for supporters), so nothing is added until it is decided.

## Open questions

- **Friendly match limits.** The values for the minimum and maximum number of questions and time limit. They are server configuration, so they do not change the schema.
- **Interchangeable lines in Parsons questions.** Decide once the question data source is known. The API does not change either way.
- **Where the question data comes from**, and therefore how topic and difficulty tags are produced.
