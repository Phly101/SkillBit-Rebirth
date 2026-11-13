# SkillBit-Rebirth: Error Codes

Every REST error has the same shape (see `Error` in `openapi.yaml`):

```json
{
  "status": 409,
  "code": "EMAIL_TAKEN",
  "message": "An account with this email already exists.",
  "timestamp": "2026-11-13T10:15:30Z",
  "path": "/api/v1/auth/signup",
  "traceId": "9f3c1b7e"
}
```

`details` is added only on validation failures: a list of `{ "field", "message" }`.

## Rules

- **The app decides from `code`, never from `message` or from the status alone.** Several different problems share a status (for example every bad-input case is `400`).
- Codes are stable. Messages may change.
- One row per code. A code lives in the `ErrorCode` enum in `common` and is listed here, in the same words.
- Status legend, as in the API README: **docs** means it already appeared in the design docs, **proposed** needs confirming.

## Common

These come from the exception types in `common`. Check the codes against the `ErrorCode` enum, because the enum is the source of truth for the names.

| Code                  | Status | When                                                                 | Source   |
|-----------------------|--------|----------------------------------------------------------------------|----------|
| `VALIDATION_FAILED`   | 400    | The request body or a parameter failed validation. Carries `details` | proposed |
| `BAD_REQUEST`         | 400    | Malformed request that is not a validation failure                   | proposed |
| `UNAUTHORIZED`        | 401    | Missing, expired or invalid access token                             | proposed |
| `FORBIDDEN`           | 403    | Authenticated but not allowed                                        | proposed |
| `NOT_FOUND`           | 404    | The resource does not exist                                          | proposed |
| `CONFLICT`            | 409    | Generic state conflict. Prefer a specific code when one exists       | proposed |
| `TOO_MANY_REQUESTS`   | 429    | Generic rate limit. Prefer a specific code when one exists           | proposed |
| `INTERNAL_ERROR`      | 500    | Unexpected server error. The message never shows internals           | proposed |
| `SERVICE_UNAVAILABLE` | 503    | A dependency (database, mail, an outside provider) is down           | proposed |

## Auth

| Code                    | Status | When                                                                                       | Endpoints                                 | Source   |
|-------------------------|--------|--------------------------------------------------------------------------------------------|-------------------------------------------|----------|
| `EMAIL_TAKEN`           | 409    | The email already belongs to an account                                                    | `/auth/signup`, `/me/email-change`        | proposed |
| `INVALID_CREDENTIALS`   | 401    | Wrong email or wrong password. One code for both, so nobody can learn which emails exist   | `/auth/login`                             | proposed |
| `EMAIL_NOT_VERIFIED`    | 403    | Correct credentials, but the email was never verified                                      | `/auth/login`                             | proposed |
| `OTP_INVALID`           | 400    | The code does not match                                                                    | `/auth/verify`                            | proposed |
| `OTP_EXPIRED`           | 400    | The code was right but too old, or already used                                            | `/auth/verify`                            | proposed |
| `OTP_ATTEMPTS_EXCEEDED` | 429    | Too many wrong guesses. The user must ask for a new code                                   | `/auth/verify`                            | proposed |
| `OTP_RESEND_TOO_SOON`   | 429    | A new code was requested before `resendAfterSeconds` passed                                | `/auth/otp/send`, `/auth/otp/resend`      | proposed |
| `RESET_TOKEN_INVALID`   | 400    | The reset token is unknown, expired or already used                                        | `/auth/reset-password`                    | proposed |
| `REFRESH_TOKEN_INVALID` | 401    | The refresh token is unknown, expired or revoked. The app must send the user back to login | `/auth/refresh`, `/auth/logout`           | proposed |
| `SOCIAL_TOKEN_INVALID`  | 401    | Google rejected the ID token, or GitHub rejected the code                                  | `/auth/google`, `/auth/github`            | proposed |
| `PASSWORD_INCORRECT`    | 400    | The current password the user typed to confirm a change is wrong                           | `/me/email-change`, `/me/password-change` | proposed |

## Account

| Code         | Status | When                                                               | Endpoints     | Source   |
|--------------|--------|--------------------------------------------------------------------|---------------|----------|
| `NAME_TAKEN` | 409    | Another user already has this name (ignoring upper and lower case) | `/me/profile` | proposed |

## Learning and contests

Only the codes that already appear in the docs. The rest are added when those modules are built.

| Code                     | Status | When                                                         | Source |
|--------------------------|--------|--------------------------------------------------------------|--------|
| `QUIZ_ALREADY_SUBMITTED` | 409    | The attempt was already submitted                            | docs   |
| `ATTEMPT_CLOSED`         | 409    | The server already closed the attempt when its timer ran out | docs   |
| `COURSE_LOCKED`          | 403    | Enrolling in a course that is still locked                   | docs   |

## Notes

- **`PASSWORD_INCORRECT` is a `400`, not a `401`.** The app treats every `401` as "my access token expired" and tries to refresh it. A wrong confirmation password is not a token problem, so using `401` would send the app into a pointless refresh loop.
- **Login never says which half was wrong.** `INVALID_CREDENTIALS` covers both an unknown email and a wrong password, for the same reason forgot-password always answers `202`.
- `openapi.yaml` also lists `413` (file too large) and `415` (file type not allowed) for avatar upload. `common` has no exception type for them yet, so they need codes and handlers when the upload is built.
