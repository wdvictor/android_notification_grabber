# AGENTS.md

## Purpose

This file defines the engineering guidelines that Codex must follow when working on this software project.

## Technology Preference

- Prefer implementing as much as possible in **Flutter**.
- Use **Kotlin** only for parts that cannot be properly implemented in Flutter, such as platform-specific Android integrations or native APIs.

## Architecture

- Always follow **Clean Architecture** principles.
- Keep responsibilities clearly separated across layers, such as:
  - presentation
  - domain
  - data
- Ensure the codebase remains modular, maintainable, testable, and easy to evolve.

## Testing Requirements

- For every new feature, always create:
  - **unit tests**
  - **widget tests** (when applicable to Flutter UI behavior)
- Tests must cover the main expected behavior, critical flows, and edge cases relevant to the new functionality.

## Validation After Changes

- Whenever a new feature is created, run the tests related to that feature.
- Make sure the related tests pass before considering the work complete.

## Implementation Rules

- Prefer simple, readable, and maintainable solutions.
- Reuse existing patterns and project conventions whenever possible.
- Avoid unnecessary duplication.
- Keep platform-specific code isolated and minimal.

## Definition of Done

A task is only considered complete when:

1. The feature is implemented with Flutter whenever possible.
2. Kotlin is used only when strictly necessary.
3. The solution follows Clean Architecture.
4. Unit tests and widget tests for the new functionality are created.
5. The related tests are executed and passing.
