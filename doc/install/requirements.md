---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Prerequisites for installation.
title: GitLab installation requirements
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab has specific installation requirements.

## Storage

The necessary storage space largely depends on the size of the repositories you want to have in GitLab.
As a guideline, you should have at least as much free space as all your repositories combined.

The Linux package requires about 2.5 GB of storage space for installation.
When combined with PostgreSQL, logs, temporary files, and operating system overhead,
plan for at least 40 GB of disk space for a basic GitLab installation with no repository data.
For storage flexibility, consider mounting your hard drive through logical volume management.
You should have a hard drive with at least 7,200 RPM or a solid-state drive to reduce response times.

Because file system performance might affect the overall performance of GitLab, you should
[avoid using cloud-based file systems for storage](../administration/nfs.md#avoid-using-cloud-based-file-systems).

## CPU

CPU requirements depend on the number of users and expected workload.
The workload includes your users' activity, use of automation and mirroring, and repository size.

For a maximum of 20 requests per second or 1,000 users, you should have 8 vCPU.
For more users or higher workload,
see [reference architectures](../administration/reference_architectures/_index.md).

## Memory

Memory requirements depend on the number of users and expected workload.
The workload includes your users' activity, use of automation and mirroring, and repository size.

For a maximum of 20 requests per second or 1,000 users, you should have 16 GB of memory.
For more users or higher workload,
see [reference architectures](../administration/reference_architectures/_index.md).

In some cases, GitLab can run with at least 8 GB of memory.
For more information, see
[running GitLab in a memory-constrained environment](https://docs.gitlab.com/omnibus/settings/memory_constrained_envs/).

## PostgreSQL

[PostgreSQL](https://www.postgresql.org/) is the only supported database and is bundled with the Linux package.
You can also use an [external PostgreSQL database](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server),
which must be [configured correctly](../administration/postgresql/tune.md#required-settings-for-external-instances).

### Supported versions

For the following versions of GitLab, use these PostgreSQL versions:

| GitLab version | Helm chart version | Minimum PostgreSQL version | Maximum PostgreSQL version |
| -------------- | ------------------ | -------------------------- | -------------------------- |
| 19.x           | 10.x               | 17.x                       | 17.x                       |
| 18.x           | 9.x                | [16.5](https://gitlab.com/gitlab-org/gitlab/-/issues/508672) | 17.x ([tested against GitLab 17.10 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/521159)) |
| 17.x           | 8.x                | [14.14](https://gitlab.com/gitlab-org/gitlab/-/issues/508672) | 16.x ([tested against GitLab 16.10 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145298)) |
| 16.x           | 7.x                | 13.6                       | 15.x ([tested against GitLab 16.1 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119344)) |

Minor PostgreSQL releases [include only bug and security fixes](https://www.postgresql.org/support/versioning/).
Always use the latest minor version to avoid known issues in PostgreSQL.
For more information, see [issue 364763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763).

To use a later major version of PostgreSQL than specified, check if a
[later version is bundled with the Linux package](http://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html).

### Storage requirements

Depending on the [number of users](../administration/reference_architectures/_index.md),
the PostgreSQL server should have:

- For most GitLab instances, at least 5 to 10 GB of storage.
- For GitLab Ultimate, at least 12 GB of storage
  (1 GB of vulnerability data must be imported).

### Extensions

To install extensions, PostgreSQL requires superuser privileges. For instructions, see
[Manage PostgreSQL extensions](../administration/postgresql/extensions.md).

| Extension            | Minimum GitLab version | Type        | Database |
|----------------------|------------------------|-------------|----------|
| `amcheck`            | 18.4                   | Required    | Main |
| `btree_gist`         | 13.1                   | Required    | Main |
| `pg_trgm`            | 8.6                    | Required    | Main |
| `plpgsql`            | 11.7                   | Required    | Main, [Geo secondary tracking databases](../administration/geo/_index.md) (minimum version 9.0) |
| `pg_stat_statements` | -                      | Recommended | All |

### GitLab Geo

For [GitLab Geo](../administration/geo/_index.md), you should use the Linux package or
[supported infrastructure](../administration/reference_architectures/_index.md#infrastructure-and-services)
to install GitLab.
Compatibility with other external databases is not guaranteed.

For more information, see [requirements for running Geo](../administration/geo/_index.md#requirements-for-running-geo).

For external PostgreSQL instances, see:

- [Required settings](../administration/postgresql/tune.md#required-settings-for-external-instances) for externally managed instances.
- [Database schemas](../administration/postgresql/external.md#database-schemas) for schema guidance.
- [When to check locale compatibility](../administration/postgresql/upgrading_os.md#when-to-check-locale-compatibility) for locale considerations.

## Puma

The recommended [Puma](https://puma.io/) settings depend on your [installation](install_methods.md).
By default, the Linux package uses the recommended settings.

To adjust Puma settings:

- For the Linux package, see [Puma settings](../administration/operations/puma.md).
- For the GitLab Helm chart, see the
  [`webservice` chart](https://docs.gitlab.com/charts/charts/gitlab/webservice/).

For worker and thread sizing guidance, see
[Puma worker and thread sizing](../administration/operations/puma.md#worker-and-thread-sizing).

## Redis

[Redis](https://redis.io/) or [Valkey](https://valkey.io/) stores all user sessions and background tasks
and requires about 25 kB per user on average.

Redis 7.2 or Valkey 7.2 is required.
For more information about end-of-life dates, see the
[Redis documentation](https://redis.io/docs/latest/operate/oss_and_stack/install/version-mgmt/).

- Use a standalone instance (with or without high availability).
  Redis Cluster is not supported.
- Set the [eviction policy](../administration/redis/replication_and_failover_external.md#setting-the-eviction-policy) as appropriate.

## Sidekiq

[Sidekiq](https://sidekiq.org/) uses a multi-threaded process for background jobs.
This process initially consumes more than 200 MB of memory
and might grow over time due to memory leaks.

On a very active server with more than 10,000 billable users,
the Sidekiq process might consume more than 1 GB of memory.

## Prometheus

By default, [Prometheus](https://prometheus.io) and its related exporters are enabled to monitor GitLab.
These processes consume approximately 200 MB of memory.

For more information, see
[monitoring GitLab with Prometheus](../administration/monitoring/prometheus/_index.md).

## Supported web browsers

GitLab supports the following web browsers:

- [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [Google Chrome](https://www.google.com/chrome/)
- [Chromium](https://www.chromium.org/getting-involved/dev-channel/)
- [Apple Safari](https://www.apple.com/safari/)
- [Microsoft Edge](https://www.microsoft.com/en-us/edge?form=MA13QK)

GitLab targets the [Baseline](https://web-platform-dx.github.io/baseline/) Widely available
browser set. These are the browser versions that support web platform features stable across
all core browsers. A feature reaches Widely available status after at least 30 months. The
Widely available browser set includes both desktop and mobile versions of these browsers.

Running GitLab with JavaScript disabled in these browsers is not supported.

## Related topics

- [Install GitLab Runner](https://docs.gitlab.com/runner/install/)
- [Secure your installation](../security/_index.md)
