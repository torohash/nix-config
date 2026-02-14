# Coding Principles

Core coding rules to always follow.
Apply these principles idiomatically in whatever language the project uses.

## Simplicity First

- Choose readable code over complex code
- Avoid over-abstraction
- Prioritize "understandable" over "working"

## Single Responsibility

- One function does one thing only
- One class has one responsibility only
- Target 200-400 lines per file (max 800)

## Early Return

- Avoid deep nesting by returning early for guard conditions
- Flatten control flow: validate preconditions at the top, then proceed with the main logic

## Type Safety

- All functions must have type annotations using the language's type system
- Leverage compile-time or static checks wherever available

## Immutability

- Create new objects instead of mutating existing ones
- Prefer immutable data structures and const/readonly bindings

## Naming Conventions

- **Constants**: UPPER_SNAKE_CASE (English)
- **Meaningful names**: `user_count` over `x`
- **Casing style**: Follow the project's existing convention (e.g., camelCase, snake_case, PascalCase)

## No Magic Numbers

- Extract numeric/string literals into named constants
- The name should convey the intent (e.g., `MAX_RETRIES = 3`)
