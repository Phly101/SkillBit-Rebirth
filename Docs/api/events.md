# SkillBit-Rebirth: WebSocket Event Catalog

The socket pushes small change events so the UI stays current without reloading. It never replaces the initial GraphQL load: **snapshot via GraphQL, deltas via the socket.**

## Connection

- Endpoint: `/ws`. Same JWT as REST and GraphQL, validated during the handshake. An invalid or expired token closes the connection.
- One connection per app session, opened after login and closed on logout.
- Each user is automatically subscribed to their own events (profile, score, rank, badges, matches). Contest leaderboards are opt-in.

## Envelope

Every message, both directions:

```json
{
  "id": "evt_01HZ...",
  "type": "profile.updated",
  "ts": "2026-10-01T16:42:10Z",
  "payload": {}
}
```

- `id` lets the client drop duplicates after a reconnect.
- `type` is `domain.action` in lowercase.
- Payloads carry only what changed. The client merges them into its current state.

## Reconnect rules

1. The client reconnects with exponential backoff (for example 1s, 2s, 4s, capped at 30s).
2. After every successful reconnect, refetch `me` through GraphQL, because events may have been missed while offline.
3. Re-send any `leaderboard.subscribe` messages.

## Server to client

### `profile.updated`

Emitted after `PATCH /me/profile` or `PUT /me/avatar` succeeds, and after a cosmetic is equipped or unequipped. Also reaches other users' sessions for places that show this user (leaderboard rows, friends list).

```json
{
  "type": "profile.updated",
  "payload": {
    "userId": "42",
    "fields": {
      "name": "Basel",
      "avatarUrl": "https://cdn.example.com/avatars/42_v8.jpg"
    }
  }
}
```

`avatarUrl` is versioned (`_v8`), so the app's image cache sees a new URL and fetches the new image.

Equipping a cosmetic sends the changed slots only, with `null` for a slot that was emptied:

```json
{
  "type": "profile.updated",
  "payload": {
    "userId": "42",
    "fields": {
      "cosmetics": {
        "avatarFrame": { "id": "12", "name": "Neon Ring", "assetUrl": "https://cdn.example.com/frames/neon_v2.svg" },
        "title": null
      }
    }
  }
}
```

`isSupporter` can also appear in `fields` when the tip jar flag changes.

### `inventory.updated`

Sent to the user whenever cosmetics are granted or removed, or the supporter flag changes. The app never unlocks anything on its own: after a purchase the Play sheet closes and the app shows a "processing" state until this event arrives.

```json
{
  "type": "inventory.updated",
  "payload": {
    "reason": "PURCHASE",
    "productId": "frame_neon_01",
    "granted": ["12"],
    "revoked": [],
    "isSupporter": false
  }
}
```

`reason` is `PURCHASE` (also covers the tip jar), `REFUND` or `ACHIEVEMENTS` (the reward for earning everything). `productId` is only present for `PURCHASE` and `REFUND`. On a refund, `revoked` lists the removed items and a `profile.updated` follows for any slot that was emptied.

The webhook can arrive a few seconds after a purchase. If nothing has arrived after about 30 seconds, the app refetches `me { ownedCosmetics isSupporter }` through GraphQL instead of giving up.

### `score.changed`

Emitted when points change. `reason` is `COURSE_FINISHED` or `CONTEST_RESULT`. Quizzes and friendly matches award no points, so they never emit this event.

```json
{
  "type": "score.changed",
  "payload": { "points": 3620, "delta": 120, "reason": "CONTEST_RESULT" }
}
```

### `badge.changed`

Emitted when points move the user to a different badge (promotion, or demotion once points fall below the buffer threshold).

```json
{
  "type": "badge.changed",
  "payload": {
    "badge": { "id": "3", "name": "Silver", "iconUrl": "...", "tier": 3 },
    "previous": { "id": "4", "name": "Gold", "iconUrl": "...", "tier": 4 },
    "direction": "DEMOTED"
  }
}
```

### `progress.updated`

Emitted when course or lesson progress changes (useful for a second device).

```json
{
  "type": "progress.updated",
  "payload": { "courseId": "7", "completedLessons": 5, "totalLessons": 12, "completedQuizzes": 1, "totalQuizzes": 3 }
}
```

### `course.finished`

Emitted when course progress (lessons and section quizzes) reaches 100%, whether the last item was a lesson or a quiz. It is automatic, there is no button. A `score.changed` with reason `COURSE_FINISHED` accompanies it. If this completed every mandatory course of the level, `unlockedLevelId` is set.

```json
{
  "type": "course.finished",
  "payload": { "courseId": "7", "pointsAwarded": 100, "unlockedLevelId": "2" }
}
```

`unlockedLevelId` is `null` when no level was unlocked (for example an optional course).

### `achievement.unlocked`

Emitted when a user's progress meets an achievement's condition. It is checked after events that change progress: a course finished, a contest finalized, a badge change.

```json
{
  "type": "achievement.unlocked",
  "payload": { "achievementId": "31", "title": "First Steps", "iconUrl": "https://cdn.example.com/achievements/first_steps.svg" }
}
```

If the unlock also earns a cosmetic reward, an `inventory.updated` with reason `ACHIEVEMENTS` follows.

### `rank.changed`

The user's own rank changed on a leaderboard they appear in.

```json
{
  "type": "rank.changed",
  "payload": { "contestId": "19", "rank": 14, "previousRank": 17 }
}
```

### `leaderboard.updated`

Only sent to clients subscribed to that contest. **Throttled**: at most one message per second per contest, batching all changes since the last one.

```json
{
  "type": "leaderboard.updated",
  "payload": {
    "contestId": "19",
    "entries": [
      { "rank": 1, "userId": "8", "name": "Sara", "avatarUrl": "...", "points": 940, "timeSeconds": 412 }
    ]
  }
}
```

Send only the changed rows, or the top N plus the current user's row. Decide when the leaderboard screen is built.

### `attempt.closed`

Sent to the user when the server closes their attempt itself because the timer ran out, using the answers saved so far. The app leaves the question screen and shows the waiting state. It matters most when the app lost its connection and comes back, or on a second device.

```json
{
  "type": "attempt.closed",
  "payload": { "attemptId": "5521", "contestId": "19", "reason": "TIME_UP" }
}
```

`reason` is only `TIME_UP` for now. If the app missed the event, `contest { myStatus }` already says `SUBMITTED` on the next fetch, so after reconnecting on a question screen the app refetches it.

### `contest.results_ready`

Sent to every participant when a contest has ended and its results are final. This is the trigger for the app to open the results page. Participants who submitted early get it as well.

```json
{
  "type": "contest.results_ready",
  "payload": { "contestId": "19", "attemptId": "5521" }
}
```

If the app was closed when it fired, nothing is lost: on the next launch GraphQL `contest { myStatus myAttemptId }` returns `RESULT_READY`, and the app shows the results page then.

### Friendly match events (async version)

| Type | Sent to | Payload |
|---|---|---|
| `match.invited` | Challenged user | `{ matchId, challenger: { userId, name, avatarUrl }, topics: [{ id, name }], questionCount, timeLimitSeconds, expiresAt }` |
| `match.accepted` | Challenger | `{ matchId, opponentId }` |
| `match.declined` | Challenger | `{ matchId }` |
| `match.opponent_finished` | The other player | `{ matchId }` (no score shown until both finish) |
| `match.finished` | Both players | `{ matchId, scores: { "<userId>": 8, "<userId>": 6 }, winnerId }` |

A tie sets `winnerId` to `null`.

### Friends

| Type | Sent to | Payload |
|---|---|---|
| `friend.request_received` | Receiver | `{ requestId, from: { userId, name, avatarUrl } }` |
| `friend.request_accepted` | Sender | `{ userId, name, avatarUrl }` |

## Client to server

| Type | Payload | Purpose |
|---|---|---|
| `leaderboard.subscribe` | `{ contestId }` | Start receiving `leaderboard.updated` for a contest |
| `leaderboard.unsubscribe` | `{ contestId }` | Stop (send when leaving the screen) |
| `ping` | `{}` | Keep-alive; server replies `pong` |

## Emission rules (for the backend)

- Events are emitted **after the transaction commits**, never before, so the client never sees a change that rolled back.
- REST endpoints that change state return the new state in their response too, so the acting client can update immediately and treat the matching event as a harmless duplicate.
- Contest results are applied in one transaction. Only after it commits does the server emit `score.changed`, `badge.changed` and `rank.changed`, and `contest.results_ready` last, so the app's state is already current when it navigates to the results page.
- Never put sensitive data in events (email, tokens, correct answers).
