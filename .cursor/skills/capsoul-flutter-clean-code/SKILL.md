---
name: capsoul-flutter-clean-code
description: >-
  Use when writing or reviewing Capsoul Dart/Flutter code for principles,
  patterns, and maintainability.
---
# Capsoul Flutter clean code

Use when writing or reviewing Dart/Flutter code for Capsoul: principles, patterns, readability, and maintainability.

## Principles (practical)
1. Single responsibility per class/file role (screen ≠ repository ≠ model).
2. Depend on abstractions at feature boundaries (repository interfaces) once data layer exists.
3. Prefer immutability for models (`freezed`/`equatable` when the team adopts them).
4. Explicit null handling; no silent `!` without a proven invariant.
5. Side effects at the edges (Firebase, plugins); pure logic in domain helpers when non-trivial.

## Patterns for Capsoul
- Feature-first folders
- Repository for Firebase
- Router-driven navigation
- Unidirectional UI state (Provider/Riverpod/Bloc — pick one per app and stick to it; do not mix casually)
- Result/Either or explicit try/catch mapped to UI states: loading / data / error / empty

## Flutter practices
1. `const` constructors where possible.
2. Keys for list items with stable ids.
3. Dispose controllers/subscriptions.
4. Avoid `BuildContext` across async gaps without mounted checks.
5. Keep `build()` dull: compute elsewhere.
6. Widget tests for critical UI; unit tests for repositories/parsers.

## Code review bar
- Names say intent
- No dead code or commented-out blocks in main
- Spanish user-facing strings; English code
- Matches Capsoul architecture and theme skills
