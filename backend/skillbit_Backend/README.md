# SkillBit Backend

Spring Boot backend for **SkillBit-Rebirth**: REST (auth, quizzes, contests, friends), GraphQL (course content, search, profiles) and WebSockets (live profile data and leaderboard).

## Tech stack

| Area             | Choice                                   |
|------------------|------------------------------------------|
| Language / build | Java 25, Maven                           |
| Framework        | Spring Boot 4.1.x                        |
| Database         | PostgreSQL, migrations with Flyway       |
| API styles       | REST, GraphQL, WebSocket                 |
| Security         | Spring Security, OAuth2 (Google, GitHub) |
| Cache            | Caffeine (in-memory Spring cache)        |
| Tests            | JUnit, Spring Boot Test, ArchUnit        |
| Local services   | Docker Compose                           |

## Prerequisites

- JDK 25
- Docker and Docker Compose
- Git

## Getting started

1. Clone the repository and go to `backend/skillbit_Backend`.
2. Start the local database with Docker Compose (`compose.yaml`).
3. Make sure the required environment variables are set (see [Configuration](#configuration)).
4. Run the app with the `dev` and `local` profiles active.
5. Flyway applies all migrations automatically on startup.

## Configuration

Profiles:

| Profile | Purpose                                      |
|---------|----------------------------------------------|
| `dev`   | Shared development settings                  |
| `local` | Your own machine (local DB, local overrides) |

Environment variables:

Copy the root `.env.example` to `backend/skillbit_Backend/.env` (git-ignored) and fill in your values.

| Variable set | Used by              | Variables                                                                          |
|--------------|----------------------|------------------------------------------------------------------------------------|
| `*_DEV`      | development          | `DB_HOST_DEV`, `DB_PORT_DEV`, `DB_NAME_DEV`, `DB_USER_DEV`, `DB_PASSWORD_DEV`      |
| `*_TEST`     | tests (local and CI) | `DB_HOST_TEST`, `DB_PORT_TEST`, `DB_NAME_TEST`, `DB_USER_TEST`, `DB_PASSWORD_TEST` |
| `*_PROD`     | production only      | `DB_HOST_PROD`, `DB_PORT_PROD`, `DB_NAME_PROD`, `DB_USER_PROD`, `DB_PASSWORD_PROD` |

Rules:

- Secrets (DB password, OAuth client secrets, mail credentials, JWT keys) come from **environment variables**. Never commit them.
- `.env` is never committed. Only `.env.example` (placeholder values) is.
- Production values live only on the production host, never in CI for pull requests.

## Project structure

Modular monolith, **package by feature**. Base package: `phly101.example.skillbit_backend`.

```
achievement  admin  auth  common  contest  examples
friendly_matches  learning  question  quiz  realtime  social  user
```

Every module uses the same sub-packages:

```
domain      entities and business rules
dto         request/response objects
event       events published/consumed by the module
repository  database access
service     business logic
web         controllers and resolvers
```

### Module rules (enforced by ArchUnit tests)

1. No dependency cycles between modules.
2. `common` depends on no other module.
3. Controllers and resolvers never use repositories directly.
4. Entities never leave the service layer: the API only exposes DTOs.
5. A module talks to another module through its service or events, never its repository.

## Database

- Migrations live in `src/main/resources/db/migration` and are named `V<number>__description.sql` (capital `V`, two underscores).
- Never edit a migration that is already applied on a shared or production database. Add a new one.
- The full schema is documented in `Docs/schema.md`.

## API contracts

The contracts in `Docs` are the source of truth. If code and contract disagree, fix one of them in the same PR.

- REST: `openapi.yaml`
- GraphQL: schema files
- WebSocket: `events.md`

## Development workflow

Each feature follows the same loop:

1. Read the contract for the feature.
2. Entities and repositories (matching the Flyway tables).
3. Service layer (business rules).
4. Web layer and DTOs.
5. Tests: unit (services), slice (web), integration (full flow).
6. Update the docs if anything changed.
7. Open a PR. Then implement the feature on the Flutter side.

## Testing

- Run the full suite with the Maven wrapper (`./mvnw verify`).
- Every PR must pass the tests and the ArchUnit rules before merging.

## Git conventions

- Commit prefix: `backend:` (for example `backend: add global exception handler`).
- Branch names follow `backend/<type>/<name>`, where type is `feature`, `fix` or `setup` and the name uses hyphens (for example `backend/feature/auth-login`). Changes to root files or shared config use `repo/setup/...` or `repo/fix/...` with the `repo:` commit prefix.
- Work on a branch, open a PR into `main`. Direct pushes to `main` are blocked by the repository ruleset.
- PR checks (build, tests, ArchUnit) must be green.
- Any code written with AI assistance carries a comment saying so.

## Documentation

- `Docs/schema.md`: database schema
- `Docs/openapi.yaml`: REST contract
- GraphQL schema and `events.md`: GraphQL and WebSocket contracts