---
stage: Release Notes
group: Monthly Release
title: "GitLab 19.1 release notes - not yet released"
description: "Summary of features included in 19.1"
---

The following features are being delivered for GitLab 19.1.
These features are now available on GitLab.com.

<!-- Copy this template, and paste it into the doc section where it belongs:

Primary feature, Agentic Core, Scale and Deployments, or Unified DevOps and Security.

Update all the information as needed.

### Feature explanation here

<!-- categories: <name value from categories.yml> --

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/yaml/_index.md), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

Now write 125 words or fewer to explain the value of this improvement.
Use phrases that start with, "In previous versions of GitLab, you couldn't... Now you can..."

Use present tense, and speak about "you" instead of "the user."
-->

<!-- ## Primary features

The first person to add a feature in this area, please make the title visible and delete this comment -->

<!-- ## Agentic Core

The first person to add a feature in this area, please make the title visible and delete this comment -->

<!-- ## Scale and Deployments

The first person to add a feature in this area, please make the title visible and delete this comment -->

## Unified DevOps and Security

### Clearer, security industry-standard labels in vulnerability details

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/vulnerabilities/_index.md), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/21978)

{{< /details >}}

In GitLab 19.1, the vulnerability results details page uses consistent, descriptive, and security industry-standard terminology for scan results:

- **Scanner** is now **Detected by**
- **EPSS** is now **Exploit Probability (EPSS)**
- **Has Known Exploit (KEV)** is now **Known Exploited (CISA KEV)**
- **Reachable** is now **Reachability**
- **Image** is now **Container Image** (Container Scanning)
- **Location** is now **Affected Location**
- **URL** is now **Affected Endpoint** (DAST, API fuzzing)
- **Method** is now **HTTP Method** (DAST, API fuzzing)
- **Solution** is now **Remediation Guidance**
- **Links** is now **References**
