# Gitlab::PolicyStore

The storage-agnostic management layer for GitLab security policies (the "Policy
Store"), distinct from the stateless Policy Engine that evaluates them.

Callers use a single public facade (`Gitlab::PolicyStore`) and never
touch persistence directly. All storage goes through an injectable repository
port (`Gitlab::PolicyStore::Ports::PolicyRepository`), so the
in-monolith backend used today can be swapped for a remote service later without
changing any caller.

```
Facade  →  Port (interface)  →  Adapter (in-memory today, remote later)
```

The facade returns `Gitlab::PolicyStore::Policy` value objects, so no
persistence object ever crosses the component boundary.

## Usage

```ruby
policy = Gitlab::PolicyStore.store(
  organization_id: 1,
  name: "My approval policy",
  trigger_id: "merge_request",
  rules: { rules: [{ type: "scan_finding" }] },
  actions: [{ type: "require_approval" }],
  policy_scope: { compliance_frameworks: [] },
  scope_rego: "package gitlab.policy.scope",
  mode: "audit"
)

Gitlab::PolicyStore.find(policy.id)
Gitlab::PolicyStore.list(organization_id: 1)
```

Swap the storage backend by injecting a different repository:

```ruby
Gitlab::PolicyStore.configure do |config|
  config.repository = MyRemotePolicyRepository.new
end
```
