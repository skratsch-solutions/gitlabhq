# GitLab Grape OpenAPI - Agent Guide

This document provides guidance for AI agents working with the
`gitlab-grape-openapi` gem. See `README.md` for the gem's public status,
configuration reference, and end-user usage examples.

## Isolation Rule

This gem MUST remain isolated from the wider GitLab monorepo:

- Runtime dependencies are limited to `grape` and `grape-entity`. Do not
  add Rails, ActiveRecord, GitLab application code, or anything from
  `lib/`, `app/`, or other monorepo paths as a runtime dependency.
- `spec/spec_helper.rb` loads only the gem and Grape — it does not boot
  Rails. Do not introduce `spec_helper` from the top-level gitlab repo,
  `fast_spec_helper`, or factories.
- Tests use plain Ruby objects and fixture Grape APIs/entities defined
  under `spec/fixtures/`. Add new fixtures there rather than importing
  real GitLab API classes.

This gem has no Rails, no database, no FactoryBot, no feature flags,
and no EE/SaaS split. Repo-level coding principles apply only where
they are not Rails/ActiveRecord/EE-specific.

## Project Structure

```
gems/gitlab-grape-openapi/
├── lib/
│   ├── gitlab-grape-openapi.rb              # Entry point — wires require_relative chain
│   └── gitlab/grape_openapi/
│       ├── configuration.rb                  # Gitlab::GrapeOpenapi.configure DSL
│       ├── generator.rb                      # Top-level orchestrator
│       ├── schema_registry.rb                # Entity → schema tracking
│       ├── request_body_registry.rb          # Request body schema tracking
│       ├── tag_registry.rb                   # API tag tracking
│       ├── converters/                       # Grape → OpenAPI conversion
│       │   ├── tag_converter.rb
│       │   ├── entity_converter.rb
│       │   ├── path_converter.rb
│       │   ├── operation_converter.rb
│       │   ├── parameter_converter.rb
│       │   ├── response_converter.rb
│       │   ├── request_body_converter.rb
│       │   ├── type_resolver.rb              # Ruby/Grape → OpenAPI type mapping
│       │   └── coercer_resolver.rb
│       ├── models/                           # OpenAPI 3.0 value objects
│       ├── concerns/                         # Serializable, LimitResolver, FailFastAnnotatable
│       └── serializers/
├── spec/
│   ├── spec_helper.rb                        # Plain RSpec, no Rails
│   ├── fixtures/                             # Grape API + Entity fixtures
│   └── gitlab/grape_openapi/                 # Mirrors lib/ structure
├── gitlab-grape-openapi.gemspec
├── Gemfile
├── .rubocop.yml                              # Inherits from gems/config/rubocop.yml
├── .gitlab-ci.yml                            # Uses gems/gem.gitlab-ci.yml template
└── README.md                                 # Public configuration + usage reference
```

## Development Workflow

All commands run from `gems/gitlab-grape-openapi/`.

### Testing

```shell
bundle exec rspec                            # Run all specs
bundle exec rspec spec/gitlab/grape_openapi/converters/entity_converter_spec.rb
```

Always run the full suite locally before pushing — lefthook may skip it
if it does not detect changes touching this gem.

### Linting

```shell
bundle exec rubocop
bundle exec rubocop -a spec/                  # Safe autofix
```

### Regenerating the gitlab-org/gitlab OpenAPI spec

After changes that affect converter output, regenerate the consumer spec
from the gitlab-org/gitlab repo root (not from this gem directory):

```shell
bundle exec rake gitlab:openapi:v3:generate
```

This writes `doc/api/openapi/openapi_v3.yaml`. Lint the result with
Redocly to catch regressions:

```shell
npx -y @redocly/cli@latest lint doc/api/openapi/openapi_v3.yaml
```

### CI

Changes to this gem trigger a child pipeline via
`.gitlab/ci/templates/gem.gitlab-ci.yml`. The gem's own `.gitlab-ci.yml`
declares `gem_name: gitlab-grape-openapi` and the child pipeline runs
specs and RuboCop in an isolated container.

## Architecture

Converter-based pipeline (see `README.md` for the full diagram):

```
Generator
├── TagConverter        → API class → OpenAPI tag
├── EntityConverter     → Grape::Entity → OpenAPI schema
├── PathConverter       → Grape route → OpenAPI path
│   ├── OperationConverter
│   ├── ParameterConverter
│   ├── ResponseConverter
│   └── RequestBodyConverter
└── TypeResolver        → Ruby/Grape types → OpenAPI types
```

Three registries (`SchemaRegistry`, `RequestBodyRegistry`, `TagRegistry`)
track per-generation state so converters can deduplicate references.

## Testing Guidelines

- Add fixture Grape APIs and Entities under `spec/fixtures/` and require
  them from `spec/spec_helper.rb` — do not depend on real GitLab APIs.
- Spec files mirror the `lib/` tree under `spec/gitlab/grape_openapi/`.
- Use plain `describe`/`context` — no `let_it_be`, no `feature_category`
  metadata, no factories. This is a vanilla RSpec project, not the main
  GitLab spec suite.

## Code Style

- Inherits gitlab-styles via `.rubocop.yml`
  (`inherit_from: ../config/rubocop.yml`).
- Ruby ≥ 3.2 (per gemspec).
- All files use `# frozen_string_literal: true`.
- Self-documenting code; minimal comments (see repo-root guidelines).

## Commits, Merge Requests, and Coding Principles

Defer to the repo-level conventions loaded from the repo-root
`AGENTS.md` / `CLAUDE.md` and the `gitlab-coding-principles` skill —
they cover branch naming, commit messages, merge request titles and
descriptions, backend Ruby style, and RSpec conventions.

Apply those principles in light of this gem's constraints: no Rails,
no database, no factories, no feature flags, and no EE/SaaS split.
Many Rails-specific rules will not apply here.

## Keeping Documentation in Sync

For every commit, consider whether the change requires updates to:

- `README.md` — public configuration reference, usage examples, supported
  options table, architecture diagram.
- `AGENTS.md` and `CLAUDE.md` (this file and its mirror) — project
  structure, development commands, isolation rule, architecture summary,
  testing guidance.

Update them in the same commit when the change affects user-facing
behavior, the public API, the conversion pipeline, or the development
workflow. `AGENTS.md` and `CLAUDE.md` MUST stay byte-identical — update
both together.

## Important Files

| File | Purpose |
|------|---------|
| `lib/gitlab-grape-openapi.rb` | Entry point and require chain |
| `lib/gitlab/grape_openapi/configuration.rb` | Public configure DSL |
| `lib/gitlab/grape_openapi/generator.rb` | Top-level conversion orchestrator |
| `gitlab-grape-openapi.gemspec` | Dependency manifest (keep narrow) |
| `README.md` | Public configuration and usage reference |
