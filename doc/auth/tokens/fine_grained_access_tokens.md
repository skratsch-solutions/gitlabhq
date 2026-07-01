---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Fine-grained permissions for personal access tokens
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/18555) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 18.10.

{{< /history >}}

Fine-grained personal access tokens are scoped to only access the specific resources and permissions
you define. When creating the token, you define the following attributes:

- Resources: A collection of API operations. Resources are grouped into larger boundaries (
  `Group and project`, `User`, and `Global`).
- Permissions: The specific actions the token can perform on a resource. Generally, this conforms to
  Create, Read, Update, and Delete actions.

## Create a fine-grained personal access token

To create a fine-grained personal access token:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Access** > **Personal access tokens**.
1. From the **Generate token** dropdown list, select **Fine-grained token**.
1. In **Token name**, enter a name for the token.
1. In **Token description**, enter a description for the token.
1. In **Expiration date**, enter an expiry date for the token.
   - The token expires at midnight UTC on that date.
   - If you do not enter a date, the expiry date is set to 365 days from today.
   - By default, the expiry date cannot be more than 365 days from today. On GitLab 17.6 and later,
     administrators can [modify the maximum lifetime of access tokens](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens).
1. Define the scope of the personal access token.
   1. In the left panel, select one or more resources.
   1. If including group or project resources, select an option in the
     `Group and project access` section.
   1. In the right panel, select an available permission for each resource.
1. Select **Generate token**.

A personal access token is displayed. Save the personal access token somewhere safe. After you leave
or refresh the page, you cannot view it again.

## Impersonate users with sudo

Administrators can create a fine-grained personal access token that can impersonate other users
with the [`sudo`](../../api/rest/authentication.md#sudo) parameter on the REST API.

Only an administrator can create a token with the sudo capability. A non-administrator that tries
to create one receives an error.

A fine-grained token continues to enforce its own permissions while impersonating. The token can
perform an action only when both of the following are true:

- The impersonated user is allowed to perform the action.
- The token has a permission that allows the action.

This behavior differs from a legacy personal access token with the `sudo` scope, which can perform
any action as the impersonated user.

> [!warning]
> A token with the sudo capability can act as any user. Restrict its permissions and boundaries to
> the minimum required, and store it securely.

## Available fine-grained permissions

The permissions a fine-grained personal access token can use depend on the API the token calls:

- [REST API endpoints with fine-grained personal access token support](fine_grained_access_tokens_rest.md)
- [GraphQL fields with fine-grained personal access token support](fine_grained_access_tokens_graphql.md)
