---
stage: AI-Powered
group: Custom Models
description: Get started with self-hosted AI models.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo Self-Hosted Models

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** GitLab Self-Managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.
> - [Enabled on GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.
> - Feature flag `ai_custom_model` removed in GitLab 17.8

To maintain full control over your data privacy, security, and the deployment of large language models (LLMs) in your own infrastructure, use GitLab Duo Self-Hosted Models.

By deploying self-hosted models, you can manage the entire lifecycle of requests made to LLM backends for GitLab Duo features, ensuring that all requests stay in your enterprise network, and avoiding external dependencies.

## Why use self-hosted models

With self-hosted models, you can:

- Choose any GitLab-approved LLM.
- Retain full control over data by keeping all request/response logs in your domain, ensuring complete privacy and security with no external API calls.
- Isolate the GitLab instance, AI gateway, and models in your own environment.
- Select specific GitLab Duo features tailored to your users.
- Eliminate reliance on the shared GitLab AI gateway.

This setup ensures enterprise-level privacy and flexibility, allowing seamless integration of your LLMs with GitLab Duo features.

### Prerequisites

Before setting up a self-hosted model infrastructure, you must have:

- A [supported model](supported_models_and_hardware_requirements.md) (either cloud-based or on-premises).
- A [supported serving platform](supported_llm_serving_platforms.md) (either cloud-based or on-premises).
- A [locally hosted AI gateway](../../install/install_ai_gateway.md).
- [Ultimate with GitLab Duo Enterprise](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?toggle=gitlab-duo-pro).

## Decide on your configuration type

The configuration for self-hosted models is different to the default configuration
that uses GitLab external AI vendors.

NOTE:
Both of the following configuration types are for GitLab Self-Managed instances.

### Self-hosted AI gateway and LLMs

In a fully self-hosted configuration, you deploy your own AI gateway and LLMs in your infrastructure, without relying on external public services. This gives you full control over your data and security.

If you have an offline environment with physical barriers or security policies that prevent or limit internet access, and comprehensive LLM controls, you can use self-hosted models.

For licensing, you must have a GitLab Ultimate subscription and GitLab Duo Enterprise. Offline Enterprise licenses are available for those customers with fully isolated offline environments. To get access to your purchased subscription, request a license through the [Customers Portal](../../subscriptions/customers_portal.md).

For more information, see the
[self-hosted AI gateway configuration diagram](configuration_types.md#self-hosted-ai-gateway).

To set up a self-hosted infrastructure, see
[Set up a self-hosted infrastructure](#set-up-a-self-hosted-infrastructure).

### GitLab.com AI gateway with default GitLab external vendor LLMs

If you do not meet the use case criteria for self-hosted models, you can use the
GitLab.com AI gateway with default GitLab external vendor LLMs.

The GitLab.com AI gateway is the default Enterprise offering and is not self-hosted. In this configuration,
you connect your instance to the GitLab-hosted AI gateway, which
integrates with external vendor LLM providers (such as Google Vertex or Anthropic).

These LLMs communicate through the [GitLab Cloud Connector](../../development/cloud_connector/index.md),
offering a ready-to-use AI solution without the need for on-premise infrastructure.

For licensing, you must have a GitLab Ultimate subscription, and either [GitLab Duo Pro](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial) or [GitLab Duo Enterprise](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial). To get access to your purchased subscription, request a license through the [Customers Portal](../../subscriptions/customers_portal.md)

For more information, see the
[GitLab.com AI gateway configuration diagram](configuration_types.md#gitlabcom-ai-gateway).

To set up this infrastructure, see [how to configure GitLab Duo on a self-managed instance](../../user/gitlab_duo/setup.md).

## Set up a self-hosted infrastructure

To set up a fully isolated self-hosted model infrastructure:

1. **Install a Large Language Model (LLM) Serving Infrastructure**

   - We support various platforms for serving and hosting your LLMs, such as vLLM, AWS Bedrock, and Azure OpenAI. To help you choose the most suitable option for effectively deploying your models, see the [supported LLM platforms documentation](supported_llm_serving_platforms.md) for more information on each platform's features.

   - We provide a comprehensive matrix of supported models along with their specific features and hardware requirements. To help select models that best align with your infrastructure needs for optimal performance, see the [supported models and hardware requirements documentation](supported_models_and_hardware_requirements.md).

1. **Install the GitLab AI gateway**
   [Install the AI gateway](../../install/install_ai_gateway.md) to efficiently configure your AI infrastructure.

1. **Configure GitLab Duo features**
   See the [Configure GitLab Duo features documentation](configure_duo_features.md) for instructions on how to customize your environment to effectively meet your operational needs.

1. **Enable logging**
   You can find configuration details for enabling logging in your environment. For help in using logs to track and manage your system's performance effectively, see the [logging documentation](logging.md).

## Related topics

- [Import custom models into Amazon Bedrock](https://www.youtube.com/watch?v=CA2AXfWWdpA)
- [Troubleshooting](troubleshooting.md)
