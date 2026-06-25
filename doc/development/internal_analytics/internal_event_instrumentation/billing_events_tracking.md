---
stage: Analytics
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Billing event tracking (Ruby)
---

Track billable usage events from the GitLab Rails monolith with `Gitlab::BillingEvents::Client`. The client sends Snowplow structured events with a [`billable_usage`](https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/billable_usage/jsonschema/1-0-3) context to the Data Insights Platform billing collector.

For the schema field reference, see [Billable events schema](billable_events_schema.md).

## Track a billing event

To trigger a billing event, call the `Gitlab::BillingEvents::Client.track_billing_event` method with the desired arguments:

```ruby
Gitlab::BillingEvents::Client.track_billing_event(
  event_type: 'secret_read',
  category: self.class.name,
  unit_of_measure: 'request',
  quantity: 1,
  namespace: namespace,
  user: current_user,
  idempotency_key: "secret_read:#{unique_request_id}",
  metadata: {
    mount_path: '/secrets/group-123',
    audit_request_id: 'abc123'
  }
)
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `event_type` | Yes | | Billable event name, for example `secret_read`. |
| `category` | Yes | | Originating class or module. Use `self.class.name`. |
| `unit_of_measure` | Yes | | Billing unit: `request`, `secret`, `tokens`, `bytes`, or similar. |
| `quantity` | Yes | | Usage amount. Must be a positive number. |
| `namespace` | Yes | | `Namespace` record. Sets `namespace_id` and `root_namespace_id`. |
| `project` | No | `nil` | `Project` record. Sets `project_id`. |
| `user` | No | `nil` | `User` record. Sets `subject`, `subject_type`, and `global_user_id`. |
| `idempotency_key` | No | `nil` | String used for generating `event_id`. The downstream billing collector deduplicates events based on `event_id`, so the supplied value needs to be unique for each event that should be billed. When absent, a random UUID is generated on every `track_billing_event` call. |
| `timestamp` | No | `Time.current` | Time of the billable activity. Defaults to now. Pass a specific time for an event to represent a different reporting window. |
| `metadata` | No | `nil` | Hash with product-specific context. Stored as a JSON object in the event payload. |

## Emitted payload example

The following is an example of the `billable_usage` context the client produces. The payload follows the [billable events schema](billable_events_schema.md):

```json
{
  "event_id": "a1b2c3d4-5678-5aaa-bbbb-ccccddddeeee",
  "event_type": "secret_read",
  "unit_of_measure": "request",
  "quantity": 1,
  "timestamp": "2026-06-22T14:30:00Z",
  "namespace_id": 9870,
  "root_namespace_id": 9870,
  "project_id": null,
  "subject": "12345",
  "subject_type": "User",
  "global_user_id": "gid:abc123def456",
  "realm": "SaaS",
  "deployment_type": ".com",
  "instance_id": "b8e45d3c-57f8-4a6f-b106-511801fd1155",
  "unique_instance_id": "6680b88f-8a28-5d0b-8387-4c8d4e07d1bd",
  "instance_version": "19.2.0",
  "host_name": "gitlab.com",
  "correlation_id": "c15c2216ec4d0679bccead19f5e1e9d0",
  "metadata": {
    "mount_path": "/secrets/group-123",
    "audit_request_id": "abc123"
  }
}
```

## Test locally

1. Start Snowplow Micro:

   ```shell
   gdk start snowplow-micro
   ```

1. Open a Rails console and send an event, for example:

   ```ruby
   ns = Namespace.first
   Gitlab::BillingEvents::Client.track_billing_event(
     event_type: 'secret_read',
     category: 'TestConsole',
     unit_of_measure: 'request',
     quantity: 1,
     namespace: ns,
     metadata: { test: true }
   )
   ```

1. Visit [the UI dashboard](http://localhost:9091/micro/ui) to see the billing events received by Snowplow Micro.
