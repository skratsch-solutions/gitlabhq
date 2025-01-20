---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Configure the GitLab agent for workspaces."
---

# GitLab agent configuration

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112397) in GitLab 15.11 [with a flag](../../administration/feature_flags.md) named `remote_development_feature_flag`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/391543) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136744) in GitLab 16.7. Feature flag `remote_development_feature_flag` removed.

When you [set up workspace infrastructure](configuration.md#set-up-workspace-infrastructure), you must configure a GitLab agent to support workspaces. This guide assumes that a GitLab agent is already installed in the Kubernetes cluster.

Prerequisites:

- The agent configuration must have the `remote_development` module enabled, and the required fields of this module must be correctly set. For more information, see [workspace settings](#workspace-settings).
- The agent must be **allowed** in a group for the purpose of creating workspaces. During workspace creation, users can select allowed agents that are associated with any parent group of the workspace project.
- The workspace creator must have the Developer role to the project of the agent.

## Agent authorization in a group for creating workspaces

> - New authorization strategy [introduced](https://gitlab.com/groups/gitlab-org/-/epics/14025) in GitLab 17.2.

With the new authorization strategy that replaces the [legacy authorization strategy](#legacy-agent-authorization-strategy), group owners and administrators can control which cluster agents can be used for hosting workspaces in a group.

For example, if the path to your workspace project is `top-level-group/subgroup-1/subgroup-2/workspace-project`, you can use any configured agent for either `top-level-group`, `subgroup-1` or `subgroup-2` group.

```mermaid
%%{init: {'theme':'neutral'}}%%

graph TD;

    classDef active fill:lightgreen, stroke:#green, color:green, stroke-width:1px;

    topGroup[Top-Level Group, allowed Agent 1]
    subgroup1[Subgroup 1, allowed Agent 2]
    subgroup2[Subgroup 2, allowed Agent 3]
    wp(Workspace Project, Agent 1, 2 & 3 all available)

    topGroup --> subgroup1
    subgroup1 --> subgroup2
    subgroup2 --> wp

    class wp active;
```

If you allow a cluster agent for a specific group, for example, `subgroup-1`,
it is available to create workspaces in all projects under that group.
Consider the scope of the allowed group carefully, as it determines where the cluster agent can
host workspaces.

## Allow a cluster agent for workspaces in a group

Prerequisites:

- You must [set up workspace infrastructure](configuration.md#set-up-workspace-infrastructure).
- You must have administrator access to the instance or the Owner role for the group.

To allow a cluster agent for workspaces in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Settings > Workspaces**.
1. In the **Group agents** section, select the **All agents** tab.
1. From the list of available agents, find the agent with status **Blocked**, and select **Allow**.
1. On the confirmation dialog, select **Allow agent**.

GitLab updates the status of the selected agent to **Allowed**, and displays the agent in the **Allowed agents** tab.

## Remove an allowed cluster agent for workspaces within a group

Prerequisites:

- You must [set up workspace infrastructure](configuration.md#set-up-workspace-infrastructure).
- You must have administrator access to the instance or the Owner role for the group.

To remove an allowed cluster agent from a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Settings > Workspaces**.
1. In the **Group agents** section, select the **Allowed agents** tab.
1. From the list of allowed agents, find the agent you want to remove, and select **Block**.
1. On the confirmation dialog, select **Block agent**.

GitLab updates the status of the selected agent to **Blocked**, and removes the agent from the **Allowed agents** tab.

Removing an allowed cluster agent from a group does not immediately stop running workspaces using this agent.
Running workspaces stop when they are automatically terminated or manually stopped.

## Legacy agent authorization strategy

In GitLab 17.1 and earlier, the availability of an agent in a group was not a prerequisite for
creating workspaces.
You can use any agent in the top-level group of a workspace project to create a workspace,
if both of the following are true:

- The remote development module is enabled.
- You have at least the Developer role for the top-level group.

For example, if the path to your workspace project is `top-level-group/subgroup-1/subgroup-2/workspace-project`,
you can use any configured agent in `top-level-group` and in any of its subgroups.

## Workspace settings

| Setting                                                                                   | Required | Default value                           | Description |
|-------------------------------------------------------------------------------------------|----------|-----------------------------------------|-------------|
| [`enabled`](#enabled)                                                                     | Yes      | `false`                                 | Indicates whether remote development is enabled for the GitLab agent. |
| [`dns_zone`](#dns_zone)                                                                   | Yes      | None                                    | DNS zone where workspaces are available. |
| [`gitlab_workspaces_proxy`](#gitlab_workspaces_proxy)                                     | No       | `gitlab-workspaces`                     | Namespace where [`gitlab-workspaces-proxy`](set_up_workspaces_proxy.md) is installed. |
| [`network_policy`](#network_policy)                                                       | No       | See [`network_policy`](#network_policy) | Firewall rules for workspaces. |
| [`default_resources_per_workspace_container`](#default_resources_per_workspace_container) | No       | `{}`                                    | Default requests and limits for CPU and memory per workspace container. |
| [`max_resources_per_workspace`](#max_resources_per_workspace)                             | No       | `{}`                                    | Maximum requests and limits for CPU and memory per workspace. |
| [`workspaces_quota`](#workspaces_quota)                                                   | No       | `-1`                                    | Maximum number of workspaces for the GitLab agent. |
| [`workspaces_per_user_quota`](#workspaces_per_user_quota)                                 | No       | `-1`                                    | Maximum number of workspaces per user. |
| [`use_kubernetes_user_namespaces`](#use_kubernetes_user_namespaces)                       | No       | `false`                                 | Indicates whether to use user namespaces in Kubernetes. |
| [`default_runtime_class`](#default_runtime_class)                                         | No       | `""`                                    | Default Kubernetes `RuntimeClass`. |
| [`allow_privilege_escalation`](#allow_privilege_escalation)                               | No       | `false`                                 | Allow privilege escalation. |
| [`image_pull_secrets`](#image_pull_secrets)                                               | No       | `[]`                                    | Existing Kubernetes secrets to pull private images for workspaces. |
| [`annotations`](#annotations)                                                             | No       | `{}`                                    | Annotations to apply to Kubernetes objects. |
| [`labels`](#labels)                                                                       | No       | `{}`                                    | Labels to apply to Kubernetes objects. |
| [`max_active_hours_before_stop`](#max_active_hours_before_stop) | No | `36` | Maximum number of hours a workspace can be active before it is stopped. |
| [`max_stopped_hours_before_termination`](#max_stopped_hours_before_termination) | No | `744` | Maximum number of hours a workspace can be stopped before it is terminated. |

NOTE:
If a setting has an invalid value, it's not possible to update any setting until you fix that value.
Updating any of these settings (except `enabled`) does not affect existing workspaces.

### `enabled`

Use this setting to define whether:

- The GitLab agent can communicate with the GitLab instance.
- You can [create a workspace](configuration.md#create-a-workspace) with the GitLab agent.

The default value is `false`.

To enable remote development in the agent configuration, set `enabled` to `true`:

```yaml
remote_development:
  enabled: true
```

If remote development is disabled, an administrator must manually delete any
running workspaces to remove those workspaces from the Kubernetes cluster.

### `dns_zone`

Use this setting to define the DNS zone of the URL where workspaces are available.

**Example configuration:**

```yaml
remote_development:
  dns_zone: "<workspaces.example.dev>"
```

### `gitlab_workspaces_proxy`

Use this setting to define the namespace where
[`gitlab-workspaces-proxy`](set_up_workspaces_proxy.md) is installed.
The default value for `gitlab_workspaces_proxy.namespace` is `gitlab-workspaces`.

**Example configuration:**

```yaml
remote_development:
  gitlab_workspaces_proxy:
    namespace: "<custom-gitlab-workspaces-proxy-namespace>"
```

### `network_policy`

Use this setting to define the network policy for each workspace.
This setting controls network traffic for workspaces.

The default value is:

```yaml
remote_development:
  network_policy:
    enabled: true
    egress:
      - allow: "0.0.0.0/0"
        except:
          - "10.0.0.0/8"
          - "172.16.0.0/12"
          - "192.168.0.0/16"
```

In this configuration:

- The network policy is generated for each workspace because `enabled` is `true`.
- The egress rules allow all traffic to the internet (`0.0.0.0/0`) except to the
  IP CIDR ranges `10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16`.

The behavior of the network policy depends on the Kubernetes network plugin.
For more information, see the [Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

#### `network_policy.enabled`

Use this setting to define whether the network policy is generated for each workspace.
The default value for `network_policy.enabled` is `true`.

#### `network_policy.egress`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11629) in GitLab 16.7.

Use this setting to define a list of IP CIDR ranges to allow as egress destinations from a workspace.

Define egress rules when:

- The GitLab instance is on a private IP range.
- The workspace must access a cloud resource on a private IP range.

Each element of the list defines an `allow` attribute with an optional `except` attribute.
`allow` defines an IP range to allow traffic from.
`except` lists IP ranges to exclude from the `allow` range.

**Example configuration:**

```yaml
remote_development:
  network_policy:
    egress:
      - allow: "0.0.0.0/0"
        except:
          - "10.0.0.0/8"
          - "172.16.0.0/12"
          - "192.168.0.0/16"
      - allow: "172.16.123.1/32"
```

In this example, traffic from the workspace is allowed if:

- The destination IP is any range except `10.0.0.0/8`, `172.16.0.0/12`, or `192.168.0.0/16`.
- The destination IP is `172.16.123.1/32`.

### `default_resources_per_workspace_container`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11625) in GitLab 16.8.

Use this setting to define the default [requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits)
for CPU and memory per workspace container.
Any resources you define in your [devfile](index.md#devfile) override this setting.

For `default_resources_per_workspace_container`, `requests` and `limits` are required.
For more information about possible CPU and memory values, see [Resource units in Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes).

**Example configuration:**

```yaml
remote_development:
  default_resources_per_workspace_container:
    requests:
      cpu: "0.5"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "1Gi"
```

### `max_resources_per_workspace`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11625) in GitLab 16.8.

Use this setting to define the maximum [requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits)
for CPU and memory per workspace.

For `max_resources_per_workspace`, `requests` and `limits` are required.
For more information about possible CPU and memory values, see:

- [Resource units in Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes)
- [Resource quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)

Workspaces fail when they exceed the values you set for `requests` and `limits`.

**Example configuration:**

```yaml
remote_development:
  max_resources_per_workspace:
    requests:
      cpu: "1"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "2Gi"
```

The maximum resources you define must include any resources required for init containers
to perform bootstrapping operations such as cloning the project repository.

### `workspaces_quota`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11586) in GitLab 16.9.

Use this setting to set the maximum number of workspaces for the GitLab agent.

You cannot create new workspaces for an agent when:

- The number of workspaces for the agent has reached the defined `workspaces_quota`.
- `workspaces_quota` is set to `0`.

If `workspaces_quota` is set to a value below the number of non-terminated workspaces
for an agent, the agent's workspaces are not terminated automatically.

The default value is `-1` (unlimited).
Possible values are greater than or equal to `-1`.

**Example configuration:**

```yaml
remote_development:
  workspaces_quota: 10
```

### `workspaces_per_user_quota`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11586) in GitLab 16.9.

Use this setting to set the maximum number of workspaces per user.

You cannot create new workspaces for a user when:

- The number of workspaces for the user has reached the defined `workspaces_per_user_quota`.
- `workspaces_per_user_quota` is set to `0`.

If `workspaces_per_user_quota` is set to a value below the number of non-terminated workspaces
for a user, the user's workspaces are not terminated automatically.

The default value is `-1` (unlimited).
Possible values are greater than or equal to `-1`.

**Example configuration:**

```yaml
remote_development:
  workspaces_per_user_quota: 3
```

### `use_kubernetes_user_namespaces`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

Use this setting to specify whether to use the user namespaces feature in Kubernetes.

[User namespaces](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/) isolate the user
running inside the container from the user on the host.

The default value is `false`. Before you set the value to `true`, ensure your Kubernetes cluster supports user namespaces.

**Example configuration:**

```yaml
remote_development:
  use_kubernetes_user_namespaces: true
```

For more information about `use_kubernetes_user_namespaces`, see
[user namespaces](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/).

### `default_runtime_class`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

Use this setting to select the container runtime configuration used to run the containers in the workspace.

The default value is `""`, which denotes the absence of a value.

**Example configuration:**

```yaml
remote_development:
  default_runtime_class: "example-runtime-class-name"
```

A valid value:

- Contains 253 characters or less.
- Contains only lowercase letters, numbers, `-`, or `.`.
- Starts with an alphanumeric character
- Ends with an alphanumeric character.

For more information about `default_runtime_class`, see
[Runtime Class](https://kubernetes.io/docs/concepts/containers/runtime-class/).

### `allow_privilege_escalation`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

Use this setting to control whether a process can gain more privileges than its parent process.

This setting directly controls whether the [`no_new_privs`](https://www.kernel.org/doc/Documentation/prctl/no_new_privs.txt)
flag gets set on the container process.

The default value is `false`. The value can be set to `true` only if either:

- [`default_runtime_class`](#default_runtime_class) is set to a non-empty value.
- [`use_kubernetes_user_namespaces`](#use_kubernetes_user_namespaces) is set to `true`.

**Example configuration:**

```yaml
remote_development:
  default_runtime_class: "example-runtime-class-name"
  allow_privilege_escalation: true
```

For more information about `allow_privilege_escalation`, see
[Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/).

### `image_pull_secrets`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14664) in GitLab 17.6.

Use this setting to specify existing Kubernetes secrets of the type `kubernetes.io/dockercfg`
or `kubernetes.io/dockerconfigjson` required by workspaces to pull private images.

The default value is `[]`.

**Example configuration:**

```yaml
remote_development:
  image_pull_secrets:
    - name: "image-pull-secret-name"
      namespace: "image-pull-secret-namespace"
```

In this example, the secret `image-pull-secret-name` from the namespace
`image-pull-secret-namespace` is synced to the namespace of the workspace.

For `image_pull_secrets`, the `name` and `namespace` attributes are required.
The name of the secret must be unique.

If the secret you've specified does not exist in the Kubernetes cluster, the secret is ignored.
When you delete or update the secret, the secret is deleted or updated
in all the namespaces of the workspaces where the secret is referenced.

### `annotations`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

Use this setting to attach arbitrary non-identifying metadata to the Kubernetes objects.

The default value is `{}`.

**Example configuration:**

```yaml
remote_development:
  annotations:
    "example.com/key": "value"
```

A valid annotation key is a string made of two parts:

- Optional. A prefix. The prefix must be 253 characters or less, and contain period-separated DNS labels. The prefix must end with a slash (`/`).
- A name. The name must be 63 characters or less and contain only alphanumeric characters, dashes (`-`), underscores (`_`), and periods (`.`). The name must begin and end with an alphanumeric character.

You shouldn't use prefixes that end with `kubernetes.io` and `k8s.io` because they are reserved for Kubernetes core components.
Prefixes that end with `gitlab.com` are also reserved.

A valid annotation value is a string.

For more information about `annotations`, see
[Annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/).

### `labels`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

Use this setting to attach arbitrary identifying metadata to the Kubernetes objects.

The default value is `{}`.

**Example configuration:**

```yaml
remote_development:
  labels:
    "example.com/key": "value"
```

A label key is a string made of two parts:

- Optional. A prefix. The prefix must be 253 characters or less, and contain period-separated DNS labels. The prefix must end with a slash (`/`).
- A name. The name must be 63 characters or less and contain only alphanumeric characters, dashes (`-`), underscores (`_`), and periods (`.`). The name must begin and end with an alphanumeric character.

You shouldn't use prefixes that end with `kubernetes.io` and `k8s.io` because they are reserved for Kubernetes core components.
Prefixes that end with `gitlab.com` are also reserved.

A valid label value:

- Contains 63 characters or less. The value can be empty.
- Begins and ends with an alphanumeric character.
- Can contain dashes (`-`), underscores (`_`), and periods (`.`).

For more information about `labels`, see
[Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/).

### `max_active_hours_before_stop`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14910) in GitLab 17.6.

Use this setting to automatically stop the agent's workspaces after the specified number of hours
have passed, because the workspace last transitioned to an active state.
An "active state" is defined as any non-stopped or non-terminated state.

The timer for this setting starts when you create the workspace, and is reset every time you
restart the workspace.
It also applies even if the workspace is in an error or failure state.

The default value is `36`, or one and a half days. This avoids stopping the workspace during
the user's typical working hours.

**Example configuration:**

```yaml
remote_development:
  max_active_hours_before_stop: 60
```

A valid value:

- Is an integer.
- Is greater than or equal to `1`.
- Is less than or equal to `8760` (one year).
- `max_active_hours_before_stop` + `max_stopped_hours_before_termination` must be less than or equal to `8760`.

The automatic stop is only triggered on a full reconciliation, which happens every hour.
This means that the workspace might be active for up to one hour longer than the configured value.

### `max_stopped_hours_before_termination`

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14910) in GitLab 17.6.

Use this setting to automatically terminate the agent's workspaces after they have been in the stopped
state for the specified number of hours.

The default value is `722`, or approximately one month.

**Example configuration:**

```yaml
remote_development:
  max_stopped_hours_before_termination: 4332
```

A valid value:

- Is an integer.
- Is greater than or equal to `1`.
- Is less than or equal to `8760` (one year).
- `max_active_hours_before_stop` + `max_stopped_hours_before_termination` must be less than or equal to `8760`.

The automatic termination is only triggered on a full reconciliation, which happens every hour.
This means that the workspace might stop for up to one hour longer than the configured value.

## Configuring user access with remote development

You can configure the `user_access` module to access the connected Kubernetes cluster with your GitLab credentials.
This module is configured and runs independently of the `remote_development` module.

Be careful when configuring both `user_access` and `remote_development` in the same GitLab agent.
The `remote_development` clusters manage user credentials (such as personal access tokens) as Kubernetes Secrets.
Any misconfiguration in `user_access` might cause this private data to be accessible over the Kubernetes API.

For more information about configuring `user_access`, see
[Configure Kubernetes access](../../user/clusters/agent/user_access.md#configure-kubernetes-access).
