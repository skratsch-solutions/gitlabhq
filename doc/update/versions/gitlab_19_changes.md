---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 19 upgrade notes
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This page contains upgrade information for minor and patch versions of GitLab 19.
Ensure you review these instructions for:

- Your installation type.
- All versions between your current version and your target version.

For additional information for Helm chart installations, see
[the Helm chart 10.0 upgrade notes](https://docs.gitlab.com/charts/releases/10_0/).

## Required upgrade stops

To provide a predictable upgrade schedule for instance administrators,
required upgrade stops occur at versions:

- `19.2`
- `19.5`
- `19.8`
- `19.11`

## Upgrade notes reference

The following is a reference list of upgrade notes for each minor GitLab version.
Each list item points to a specific section that holds more information.

Items marked with an installation method, like `(Geo)` or `(Linux package)`,
apply only to that method. All other items apply to all installation methods.

### Upgrade to 19.0

Before upgrading to GitLab 19.0, review the following:

- [19.0.0] - [PostgreSQL 17 minimum requirement](#postgresql-17-minimum-requirement)
- [19.0.0] - [Linux package support for Ubuntu 20.04 discontinued](#linux-package-support-for-ubuntu-2004-discontinued) (Linux package)
- [19.0.0] - [Redis 6 support removed](#redis-6-support-removed) (Linux package)
- [19.0.0] - [Mattermost removed from the Linux package](#mattermost-removed-from-the-linux-package) (Linux package)
- [19.0.0] - [Linux package support for SUSE distributions discontinued](#linux-package-support-for-suse-distributions-discontinued) (Linux package)
- [19.0.0] - [Spamcheck removed from Linux package and GitLab Helm chart](#spamcheck-removed-from-linux-package-and-gitlab-helm-chart) (Linux package, Helm chart)
- [19.0.0] - [NGINX Ingress replaced by Gateway API with Envoy Gateway](#nginx-ingress-replaced-by-gateway-api-with-envoy-gateway) (Helm chart)
- [19.0.0] - [Bundled PostgreSQL, Redis, and MinIO removed from GitLab Helm chart](#bundled-postgresql-redis-and-minio-removed-from-gitlab-helm-chart) (Helm chart)

## Upgrade notes

Specific upgrade notes for GitLab 19.

### PostgreSQL 17 minimum requirement

- Affects: All installation methods
- Affected versions: 19.0.0

The minimum supported version of PostgreSQL is now version 17. Before installing GitLab 19.0:

- If you use the packaged PostgreSQL 16,
  [upgrade the packaged PostgreSQL server](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server).
- If you use an [external PostgreSQL](../../administration/postgresql/external.md) instance,
  upgrade it to PostgreSQL 17.

### Linux package support for Ubuntu 20.04 discontinued

- Affects: Linux package
- Affected versions: 19.0.0

Ubuntu 20.04 reached end of standard support in May 2025. From GitLab 19.0, Linux packages are no
longer provided for Ubuntu 20.04. GitLab 18.11 is the last release with packages for this
distribution. Before upgrading to GitLab 19.0, migrate to Ubuntu 22.04 or another
[supported operating system](../../install/package/_index.md#supported-platforms).

### Redis 6 support removed

- Affects: Linux package
- Affected versions: 19.0.0

Support for Redis 6 is removed in GitLab 19.0. If you use an external Redis 6 deployment, migrate
to Redis 7.2 or Valkey 7.2 before upgrading. The bundled Redis included with the Linux package has
used Redis 7 since GitLab 16.2 and is not affected.

### Mattermost removed from the Linux package

- Affects: Linux package
- Affected versions: 19.0.0

Bundled Mattermost is removed from the Linux package in GitLab 19.0. If you currently use the
bundled Mattermost, see
[Migrating from the Linux package to Mattermost Standalone](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html)
for migration instructions. If you do not use the bundled Mattermost, you are not impacted.

### Linux package support for SUSE distributions discontinued

- Affects: Linux package
- Affected versions: 19.0.0

Linux package support for SUSE distributions ends in GitLab 19.0, which affects openSUSE Leap 15.6,
SUSE Linux Enterprise Server 12.5, and SUSE Linux Enterprise Server 15.6. GitLab 18.11 is the last
version with Linux packages for these distributions. To continue to use SUSE distributions, migrate
to a [Docker deployment of GitLab](../../install/docker/installation.md).

### Spamcheck removed from Linux package and GitLab Helm chart

- Affects: Linux package, Helm chart
- Affected versions: 19.0.0

[Spamcheck](../../administration/reporting/spamcheck.md) is removed from the Linux package and
GitLab Helm chart in GitLab 19.0. Customers not currently using Spamcheck are not impacted. If you
use the bundled Spamcheck, you can deploy it separately using
[Docker](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck).
No data migration is required.

### NGINX Ingress replaced by Gateway API with Envoy Gateway

- Affects: Helm chart
- Affected versions: 19.0.0

Gateway API with Envoy Gateway becomes the default networking configuration in the GitLab Helm chart
in GitLab 19.0, replacing NGINX Ingress which reached end-of-life in March 2026. If migration to
Envoy Gateway is not immediately feasible, you can explicitly re-enable the bundled NGINX Ingress,
which remains available until its proposed removal in GitLab 20.0. This change does not impact the
NGINX used in the Linux package, or Helm chart instances using an externally managed Ingress or
Gateway API controller.

For detailed migration steps, see the
[Helm chart 10.0 upgrade notes](https://docs.gitlab.com/charts/releases/10_0/).

### Bundled PostgreSQL, Redis, and MinIO removed from GitLab Helm chart

- Affects: Helm chart
- Affected versions: 19.0.0

The bundled Bitnami PostgreSQL, Bitnami Redis, and MinIO charts are removed from the GitLab Helm
chart and GitLab Operator in GitLab 19.0 with no replacement. These components were intended only
for proof-of-concept and test environments and are not recommended for production use. If you run an
instance with any of these bundled services, follow the
[migration guide](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/)
to configure external services before upgrading to GitLab 19.0.
