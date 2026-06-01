---
source_checksum: 60e066e57bebbe7e
distilled_at_sha: 4bdca94fd505e9510cf535c34f2343e7b91332fe
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Analytics Instrumentation Principles

## Checklist

### Event Definitions

- Ensure every fired event has a corresponding definition file in `config/events` or `ee/config/events`.
- Verify the [event definition file](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/event_definition_guide/) is correct and complete.
- DO NOT include sensitive information (per the [data classification standard](https://handbook.gitlab.com/handbook/security/data-classification-standard/)) in tracking parameters.
- DO NOT use deprecated analytics methods (`Gitlab::Tracking.event`, Redis, or RedisHLL tracking); use `track_internal_event` (backend) or `trackEvent` (frontend) instead.
- Ensure the `action` name follows the [naming convention](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/quick_start/#defining-event-and-metrics).
- Ensure the event `description` is clear to readers outside the team.
- Place the event definition file under `ee/config/events` if the event fires only from EE code.
- When the `action` field of an existing event changes, confirm the author considered the [renaming implications](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/event_definition_guide/#changing-the-action-property-in-event-definitions).
- When removing an event, verify the [event removal process](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/event_lifecycle/#remove-an-event) was followed.

### Metric Definitions

- Add the `~database` label and request a database review for metrics based on database queries.
- Verify the metric's `description` field is accurate and meaningful.
- Verify the metric's `key_path` is correct.
- Check the `product_group` field corresponds to the [stages file](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml)
- Verify the file location reflects the correct time frame and whether it belongs under `ee/`.
- Verify the metric's tiers are correctly set.
- Prefer `data_source: internal_events` for new metrics; hand off to the Analytics Instrumentation team if `data_source: database` is used.
- DO NOT use deprecated `redis` or `redis_hll` data sources for new metrics; see the [migration guide](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/migration/).
- Ensure changed or removed metrics have notified `@csops-team`, `@gitlab-data/analytics-engineers`, and `@gitlab-data/product-analysts` via a comment on the issue, and all groups have acknowledged the change.
- When updating an existing metric, verify the [metric change procedure](https://docs.gitlab.com/development/internal_analytics/metrics/metrics_lifecycle/#change-an-existing-metric) was followed.

### Event Firing Verification

- Verify new events fire correctly locally using the available [testing tools](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/local_setup_and_debugging/).
- Verify new metrics appear in the Service Ping payload by running `require_relative 'spec/support/helpers/service_ping_helpers.rb'; ServicePingHelpers.get_current_usage_metric_value(key_path)` with the metric's `key_path`.

### Internal Events CLI Changes

- Ensure CLI changes follow the [CLI style guide](https://docs.gitlab.com/development/internal_analytics/cli_contribution_guidelines/).
- Verify CLI UX: content is easy to skim, meaningful to people outside the team, and all inputs have clear meaning and effect.
- Verify edge cases and caveats include instructions to validate whether the user needs to act on them.

### Review Labels

- Apply `~analytics instrumentation` and `~analytics instrumentation::review pending` labels when an Analytics Instrumentation review is needed but was not assigned automatically.
- Approve the MR and relabel with `~"analytics instrumentation::approved"` upon completion.
- DO NOT require a maintainer review for `~analytics instrumentation` reviews.

## Authoritative sources

For the full picture, see:

- doc/development/internal_analytics/review_guidelines.md

