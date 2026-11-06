## What does this PR do?

<!-- One or two sentences. What changed and why. -->

## Type of change

<!-- Keep the one that applies and delete the others. -->

- [ ] mobile (Flutter)
- [ ] backend (Spring Boot)
- [ ] docs
- [ ] ci (workflows, repo settings)

## Related feature / issue

<!-- Feature name (e.g. quiz, auth) or issue link. -->

## How to test

<!-- Steps a reviewer can follow to check that it works. -->

## Screenshots (UI changes only)

<!-- Small phone and tablet. Delete this section if there is no UI change. -->

## Checklist: everyone

- [ ] The PR is small and about one thing
- [ ] The branch name is `<stack>/<type>/<name>` (stack: `mobile`, `backend`, `docs` or `ci`; type: `feature`, `fix` or `setup`)
- [ ] Commit messages start with `mobile:`, `backend:`, `docs:` or `ci:`
- [ ] Any AI-written code is marked with the `AI-GENERATED` comment
- [ ] No secrets or `.env` files are committed
- [ ] Docs or README updated if needed

## Checklist: mobile only

<!-- Delete this section if the PR does not touch mobile. -->

- [ ] `dart format`, `flutter analyze` and `flutter test` pass locally
- [ ] New logic has tests
- [ ] No widgets are returned from functions (widgets are classes)
- [ ] UI is responsive (small phone, tablet, large text, right-to-left)

## Checklist: backend only

<!-- Delete this section if the PR does not touch the backend. -->

- [ ] The full Maven verify (tests and ArchUnit rules) passes locally
- [ ] New logic has tests
- [ ] Database changes are a new Flyway migration, not an edit to an applied one
- [ ] The API contract (OpenAPI, GraphQL schema, events) matches the code
- [ ] Entities are not exposed in the API, only DTOs

## Checklist: ci only

<!-- Delete this section if the PR does not touch workflows or repo settings. -->

- [ ] The workflow started and finished on this PR (or a test PR)
- [ ] Required check names in the ruleset match the job names
- [ ] No path filter on the trigger that could leave a required check pending