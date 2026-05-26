---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Code Review Guidelines
---

All merge requests for GitLab CE and EE must go through code review to ensure the code is
effective, understandable, maintainable, and secure.

## Getting your merge request reviewed, approved, and merged

Before you begin, familiarize yourself with the
[contribution acceptance criteria](contributing/merge_request_workflow.md#contribution-acceptance-criteria).

Have your code **reviewed** by a
[reviewer](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#reviewer)
from your group or a [domain expert](#domain-experts).

For small, straightforward changes, you can skip the reviewer step and go directly to a
[maintainer](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#maintainer).
Examples of small and straightforward changes:

- Fixing a typo or making small copy changes.
- A tiny refactor that doesn't change any behavior.
- Removing a feature flag that has been default-enabled for more than one month.
- Removing unused methods or classes.
- A well-understood logic change that requires changes to fewer than five lines of code.

Otherwise, have a reviewer in each [category](#approval-guidelines) the MR touches before passing
to a maintainer. For security assistance, include `@gitlab-com/gl-security/appsec`.

After the reviewer approves, a maintainer reviews and merges. The last required approver merges.

For CODEOWNERS-required approvals, seek domain-specific approvals before generic ones.
Domain-specific approvers who are also maintainers should review both aspects and approve once.

### Approval guidelines

As described in the section on the responsibility of the maintainer below, you
are recommended to get your merge request approved and merged by maintainers
with [domain expertise](#domain-experts). The optional approval of the first
reviewer is not covered here. However, your merge request should be reviewed
by a reviewer before passing it to a maintainer as described in the
[overview](#getting-your-merge-request-reviewed-approved-and-merged) section.

| If your merge request includes                                                                                                                                                   | It must be approved by a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `~backend` changes <sup>1</sup>                                                                                                                                                  | [Backend maintainer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_backend).                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `~database` migrations or changes to expensive queries <sup>2</sup>                                                                                                              | [Database maintainer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_database). Refer to the [database review guidelines](database_review.md) for more details.                                                                                                                                                                                                                                                                                                                                                                                      |
| `~workhorse` changes                                                                                                                                                             | [Workhorse maintainer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_workhorse).                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `~frontend` changes <sup>1</sup>                                                                                                                                                 | [Frontend maintainer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_frontend).                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `~UX` user-facing changes <sup>3</sup>                                                                                                                                           | [Product Designer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_reviewers_UX). Refer to the [design and user interface guidelines](contributing/design.md) for details.                                                                                                                                                                                                                                                                                                                                                                                        |
| Adding a new JavaScript library <sup>1</sup>                                                                                                                                     | - [Frontend Design System member](https://about.gitlab.com/direction/foundations/design_system/) if the library significantly increases the [bundle size](https://gitlab.com/gitlab-org/frontend/playground/webpack-memory-metrics/-/blob/main/doc/report.md).<br/>- A [legal department member](https://handbook.gitlab.com/handbook/legal/) if the license used by the new library hasn't been approved for use in GitLab.<br/><br/>More information about license compatibility can be found in our [GitLab Licensing and Compatibility documentation](licensing.md).            |
| A new dependency or a file system change                                                                                                                                         | - [Distribution team member](https://about.gitlab.com/company/team/). See how to work with the [Distribution team](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/distribution/#how-to-work-with-distribution) for more details.<br/>- For RubyGems, request an [AppSec review](gemfile.md#request-an-appsec-review).                                                                                                                                                                                                                    |
| `~documentation` or `~UI text` changes                                                                                                                                           | [Technical writer](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments) based on assignments in the appropriate [DevOps stage group](https://handbook.gitlab.com/handbook/product/categories/#devops-stages).                                                                                                                                                                                                                                                                                                                                            |
| Changes to development guidelines                                                                                                                                                | Follow the [review process](development_processes.md#development-guidelines-review) and get the approvals accordingly.                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| End-to-end **and** non-end-to-end changes <sup>4</sup>                                                                                                                           | [Software Engineer in Test](https://handbook.gitlab.com/handbook/engineering/quality/#individual-contributors).                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Only End-to-end changes <sup>4</sup> **or** if the MR author is a [Software Engineer in Test](https://handbook.gitlab.com/handbook/engineering/quality/#individual-contributors) | [Quality maintainer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_qa).                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| A new or updated [application limit](https://handbook.gitlab.com/handbook/product/product-processes/#introducing-application-limits)                                             | [Product manager](https://about.gitlab.com/company/team/).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| Analytics Instrumentation (telemetry or analytics) changes                                                                                                                       | [Analytics Instrumentation engineer](https://gitlab.com/gitlab-org/analytics-section/analytics-instrumentation/engineers).                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| A new service to GitLab (Puma, Sidekiq, Gitaly are examples)                                                                                                                     | [Product manager](https://about.gitlab.com/company/team/). See the [process for adding a service component to GitLab](adding_service_component.md) for details.                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Changes related to authentication                                                                                                                                                | [Manage:Authentication](https://about.gitlab.com/company/team/). Check the [code review section on the group page](https://handbook.gitlab.com/handbook/engineering/development/sec/software-supply-chain-security/authentication/#code-review) for more details. Patterns for files known to require review from the team are listed in the in the `Authentication` section of the [`CODEOWNERS`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/CODEOWNERS) file, and the team will be listed in the approvers section of all merge requests that modify these files. |
| Changes related to custom roles or policies                                                                                                                                      | [Manage:Authorization Engineer](https://gitlab.com/gitlab-org/software-supply-chain-security/authorization/approvers/).                                                                                                                                                                                                                                                                                                                                                                                                                                                             |

1. Specs other than JavaScript specs are considered `~backend` code. Haml markup is considered `~frontend` code.
   However, Ruby code in Haml templates is considered `~backend` code. When in doubt, request both a frontend and
   backend review.

   For Haml template changes specifically:
   - **Request backend review** when changes include Ruby logic, method calls,
     variable assignments, conditionals, loops, data preparation, security checks,
     or any server-side processing in the template.
   - **Request frontend review** when changes affect DOM structure, CSS classes,
     HTML attributes, accessibility features, user interactions, and responsive design,
     or visual presentation.
   - **Request both reviews** for complex changes that involve both Ruby logic and significant UI modifications, or when
     backend and frontend are intertwined (such as when backend serves data that is consumed by Vue or JavaScript), to
     ensure both the backend functionality and frontend user experience are properly evaluated.
     - **Example:** A Haml template that calls Ruby methods to prepare data attributes for
       a Vue.js component (for example, `project_id: @project&.to_global_id`) would benefit from a backend review for Ruby logic
       correctness and frontend review for the component integration.
1. We encourage you to seek guidance from a database maintainer if your merge
   request is potentially introducing expensive queries. It is most efficient to comment
   on the line of code in question with the SQL queries so they can give their advice.
1. User-facing changes include both visual changes (regardless of how minor),
   and changes to the rendered DOM which impact how a screen reader may announce
   the content. Groups that do not have dedicated Product
   Designers do not require a Product Designer to approve feature changes, unless the changes are community contributions.
1. End-to-end changes include all files in the `qa` directory.

### Reviewing a merge request

Understand why the change is necessary (fixes a bug, improves the user
experience, refactors the existing code). Then:

- Try to be thorough in your reviews to reduce the number of iterations.
- Communicate which ideas you feel strongly about and those you don't.
- Identify ways to simplify the code while still solving the problem.
- Offer alternative implementations, but assume the author already considered
  them. ("What do you think about using a custom validator here?")
- Seek to understand the author's perspective.
- Check out the branch, and test the changes locally. You can decide how much manual testing you want to perform.

  - If the merge request requires significant GDK modifications (such as adding new services, modifying environment variables, or complex configuration changes), consider these approaches:
    - **Skip local testing** and perform a thorough code review instead, then request a domain expert from the author's team to do local verification.
    - **Request additional verification** such as screenshots, videos, or detailed testing steps from the author.
    - **Identify the minimal change** needed to trigger the code path (for example, setting a condition to `true` in the code) rather than full environment setup.

  Your testing might result in opportunities to add automated tests.
- If you don't understand a piece of code, _say so_. There's a good chance
  someone else would be confused by it as well.
- Ensure the author is clear on what is required from them to address/resolve the suggestion.
  - Consider using the [Conventional Comment format](https://conventionalcomments.org#format) to
    convey your intent.
  - For non-mandatory suggestions, decorate with (non-blocking) so the author knows they can
    optionally resolve within the merge request or follow-up at a later stage. When the only suggestions are
    non-blocking, move the MR onto the next stage to reduce async cycles. When you are a first round
    reviewer, pass to a maintainer to review. When you are the final approving maintainer,
    generate follow-ups from the non-blocking suggestions and merge or set auto-merge.
    The author then has the option to either cancel the auto-merge by implementing the non-blocking suggestions,
    they provide a follow-up MR after the MR got merged, or decide to not implement the suggestions.
  - There's a [Chrome/Firefox add-on](https://gitlab.com/conventionalcomments/conventional-comments-button) which you can use to apply [Conventional Comment](https://conventionalcomments.org/) prefixes.
- Ensure there are no open dependencies. Check [linked issues](../user/project/issues/related_issues.md) for blockers. Clarify with the authors
  if necessary. If blocked by one or more open MRs, set an [MR dependency](../user/project/merge_requests/dependencies.md).
- After a round of line notes, it can be helpful to post a summary note such as
  "Looks good to me", or "Just a couple things to address."
- Let the author know if changes are required following your review.

> [!warning]
> **If the merge request is from a fork, also check the [additional guidelines for community contributions](#community-contributions).**

### GitLab-specific concerns

GitLab is used in a lot of places. Many users use
our [Omnibus packages](https://about.gitlab.com/install/), but some use
the [Docker images](../install/docker/_index.md), some are
[installed from source](../install/self_compiled/_index.md),
and there are other installation methods available. GitLab.com itself is a large
Enterprise Edition instance. This has some implications:

1. **Query changes** should be tested to ensure that they don't result in worse
   performance at the scale of GitLab.com:
   1. Generating large quantities of data locally can help.
   1. Asking for query plans from GitLab.com is the most reliable way to validate
      these.
1. **Database migrations** must be:
   1. Reversible.
   1. Performant at the scale of GitLab.com - ask a maintainer to test the
      migration on the staging environment if you aren't sure.
   1. Categorized correctly:
      - Regular migrations run before the new code is running on the instance.
      - [Post-deployment migrations](database/post_deployment_migrations.md) run _after_
        the new code is deployed, when the instance is configured to do that.
      - [Batched background migrations](database/batched_background_migrations.md) run in Sidekiq, and
        should be used for migrations that
        [exceed the post-deployment migration time limit](migration_style_guide.md#how-long-a-migration-should-take)
        GitLab.com scale.
1. **Sidekiq workers** [cannot change in a backwards-incompatible way](sidekiq/compatibility_across_updates.md):
   1. Sidekiq queues are not drained before a deploy happens, so there are
      workers in the queue from the previous version of GitLab.
   1. If you need to change a method signature, try to do so across two releases,
      and accept both the old and new arguments in the first of those.
   1. Similarly, if you need to remove a worker, stop it from being scheduled in
      one release, then remove it in the next. This allows existing jobs to
      execute.
   1. Don't forget, not every instance is upgraded to every intermediate version
      (some people may go from X.1.0 to X.10.0, or even try bigger upgrades!), so
      try to be liberal in accepting the old format if it is cheap to do so.
1. **Cached values** may persist across releases. If you are changing the type a
   cached value returns (say, from a string or nil to an array), change the
   cache key at the same time.
1. **Settings** should be added as a
   [last resort](https://handbook.gitlab.com/handbook/product/product-principles/#convention-over-configuration). See [Adding a new setting to GitLab Rails](architecture.md#adding-a-new-setting-in-gitlab-rails).
1. **File system access** is not possible in a [cloud-native architecture](architecture.md#adapting-existing-and-introducing-new-components).
   Ensure that we support object storage for any file storage we need to perform. For more
   information, see the [uploads documentation](uploads/_index.md).

### The responsibility of the merge request author

You are the [directly responsible individual](https://handbook.gitlab.com/handbook/people-group/directly-responsible-individuals/)
(DRI) for finding the best solution. Stay as the assignee throughout the review lifecycle.
If you cannot set yourself as an assignee, ask a
[reviewer](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#reviewer) to do it.

Do not submit a merge request that is too large, fixes multiple issues, has high
complexity, or implements more than one feature.

If the MR touches multiple CODEOWNERS sections, to minimize the approvals needed consider
splitting the MR by concerns to parallelize reviews.
Before requesting a maintainer review, confirm:

- The MR solves the intended problem in the most appropriate way.
- All requirements are satisfied.
- No remaining bugs, logic problems, uncovered edge cases, or known vulnerabilities exist.

Self-review your MR following the [Code Review](#reviewing-a-merge-request) guidelines.
Add inline comments on lines where you made decisions or trade-offs,
or where context helps the reviewer understand the code.

Involve [domain experts](#domain-experts), product managers, UX designers, and database specialists
as appropriate. If you are unsure whether your MR needs a domain expert review, it does.

For features spanning 10 or more MRs, work with your EM or Staff Engineer to identify
consistent maintainer who share the context.

If your MR touches multiple domains, request a review from an expert in each domain.

Before requesting review, add MR diff comments for:

- Added linting rules (RuboCop, JS, and so on).
- Added libraries (Ruby gems, JS libs, and so on).
- Links to parent classes or methods, where not obvious.
- Benchmarking results.
- Potentially insecure code.

Ensure reviewers have access to any projects, snippets, or assets needed to validate the solution.

When assigning reviewers, comment to specify which domain each reviewer should focus on.
This avoids ambiguity when a team member has expertise in multiple areas.
For examples, see [MR 75921](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75921#note_758161716)
and [MR 109500](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/109500#note_1253955051).

Only add `TODO` comments to source code if a reviewer requires it.
If you add a `TODO`, [include a link to the relevant issue](code_comments.md).

Write comments that [explain why, not only what](https://blog.codinghorror.com/code-tells-you-how-comments-tell-you-why/)
the code does.

Request maintainer reviews only when tests pass. If tests are failing, explain why in a comment.
Contact maintainers by email or Slack only for immediate requests.
In all other cases, adding them as a reviewer is sufficient.

### The responsibility of the reviewer

Reviewers are responsible for reviewing the specifics of the chosen solution.

If unavailable within the
[Review-response SLO](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#review-response-slo),
inform the author, find a replacement using the
[Review Workload Dashboard](https://gitlab-org.gitlab.io/gitlab-roulette/), and assign them.

When confident the MR meets all
[contribution acceptance criteria](contributing/merge_request_workflow.md#contribution-acceptance-criteria):

1. Select **Approve**.
1. `@` mention the author to notify them.
1. Request a review from a maintainer with [domain expertise](#domain-experts), or follow the
   [Reviewer roulette](#reviewer-roulette) suggestion.

### The responsibility of the maintainer

Maintainers are responsible for the overall health, quality, and consistency of
the GitLab codebase.
Their reviews focus on architecture, code organization, separation of concerns, tests,
DRYness, consistency, and readability.

Maintainers are the DRI for ensuring MRs reasonably meet
[acceptance criteria](contributing/merge_request_workflow.md#contribution-acceptance-criteria).

A maintainer makes sound judgements when evaluating the impact of an MR.
If a maintainer feels that an MR is not able to merged, it is their responsibility to say so.
The maintainer is also the expert adviser who knows when to pull in others for a
second opinion.

When a maintainer approves an MR, they are taking responsibility alongside the author.
This means that when there is a production incident, the maintainer may get
paged to help resolve issues.

Certain merge requests may target a stable branch. For an overview of how to handle these requests,
see the [patch release runbook](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/patch/engineers.md).

## Best practices

### Domain experts

Domain experts are team members who have substantial experience with a specific technology,
product feature, or area of the codebase. Team members are encouraged to self-identify as
domain experts and add it to their
[team profiles](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#how-to-self-identify-as-a-domain-expert).

When self-identifying as a domain expert, it is recommended to assign the MR changing the `.yml` file to be merged by an already established Domain Expert or a corresponding Engineering Manager.

We make the following assumption with regards to automatically being considered a domain expert:

- Team members working in a specific stage/group (for example, create: source code) are considered domain experts for that area of the app they work on.
- Team members working on a specific feature (for example, search) are considered domain experts for that feature.

We default to assigning reviews to team members with domain expertise for code reviews. UX reviews default to the recommended reviewer from the Review Roulette. Due to designer capacity limits, areas not supported by a Product Designer will no longer require a UX review unless it is a community contribution.
When a suitable [domain expert](#domain-experts) isn't available, you can choose any team member to review the MR, or follow the [Reviewer roulette](#reviewer-roulette) recommendation (see above for UX reviews). Double check if the person is OOO before assigning them.

To find a domain expert:

- In the Merge Request approvals widget, select [View eligible approvers](../user/project/merge_requests/approvals/rules.md#eligible-approvers).
  This widget shows recommended and required approvals per area of the codebase.
  These rules are defined in [Code Owners](../user/project/merge_requests/approvals/rules.md#code-owners-as-approvers).
- View the list of team members who work in the [stage or group](https://handbook.gitlab.com/handbook/product/categories/#devops-stages) related to the merge request.
- View team members' domain expertise on the [engineering projects](https://handbook.gitlab.com/handbook/engineering/projects/) page or on the [GitLab team page](https://about.gitlab.com/company/team/). Domains are self-identified, so use your judgment to map the changes on your merge request to a domain.
- Look for team members who have contributed to the files in the merge request. View the logs by running `git log <file>`.
- Look for team members who have reviewed the files. You can find the relevant merge request by:
  1. Getting the commit SHA by using `git log <file>`.
  1. Navigating to `https://gitlab.com/gitlab-org/gitlab/-/commit/<SHA>`.
  1. Selecting the related merge request shown for the commit.

### Reviewer roulette

> [!note]
> [Reviewer roulette](https://gitlab-org.gitlab.io/gitlab-roulette/) is an internal tool for
> GitLab.com, not available on customer installations.

The [Danger bot](dangerbot.md) picks a reviewer and maintainer for each codebase area your MR
touches. Override the suggestion if you know a better fit.

The roulette skips people whose status contains `OOO`, `PTO`, `Parental Leave`, `Friends and
Family`, or `Conference`, or who are at review capacity (set via a number status emoji: 2️⃣–5️⃣).

### Acceptance checklist

<!-- When editing, remember to announce the change to Engineering Division -->

This checklist encourages the authors, reviewers, and maintainers of merge requests (MRs) to confirm changes were analyzed for high-impact risks to quality, performance, reliability, security, observability, and maintainability.

Using checklists improves quality in software engineering. This checklist is a straightforward tool to support and bolster the skills of contributors to the GitLab codebase.

#### Quality

For further quality guidelines, see [testing](https://handbook.gitlab.com/handbook/engineering/testing/).

1. You have self-reviewed this MR per [code review guidelines](code_review.md).
1. The code follows the [software design guidelines](software_design.md).
1. Ensure [automated tests](testing_guide/_index.md) exist following the [testing pyramid](testing_guide/testing_levels.md). Add missing tests or create an issue documenting testing gaps.
1. You have considered the technical impacts on GitLab.com, Dedicated and self-managed.
1. You have considered the impact of this change on the frontend, backend, and database portions of the system where appropriate and applied the `~ux`, `~frontend`, `~backend`, and `~database` labels accordingly.
1. You have tested this MR in [all supported browsers](../install/requirements.md#supported-web-browsers), or determined that this testing is not needed.
1. You have confirmed that this change is [backwards compatible across updates](multi_version_compatibility.md), or you have decided that this does not apply.
1. You have properly separated [EE content](ee_features.md) (if any) from FOSS. Consider [running the CI pipelines in a FOSS context](ee_features.md#run-ci-pipelines-in-a-foss-context).
1. You have considered that existing data may be surprisingly varied. For example, if adding a new model validation, consider making it optional on existing data.
1. You have fixed flaky tests related to this MR, or have explained why they can be ignored. Flaky tests have error `Flaky test '<path/to/test>' was found in the list of files changed by this MR.` but can be in jobs that pass with warnings.

#### Performance, reliability, and availability

1. You are confident that this MR does not harm performance, or you have asked a reviewer to help assess the performance impact. ([Merge request performance guidelines](merge_request_concepts/performance.md))
1. You have added [information for database reviewers in the MR description](database_review.md#required), or you have decided that it is unnecessary.
   - [Does this MR have database-related changes?](database_review.md)
1. You have considered the availability and reliability risks of this change.
1. You have considered the scalability risk based on future predicted growth.
1. You have considered the performance, reliability, and availability impacts of this change on large customers who may have significantly more data than the average customer.
1. You have considered the performance, reliability, and availability impacts of this change on customers who may run GitLab on the [minimum system](../install/requirements.md).
1. You are confident that this change is compatible with the [Cells architecture](cells/_index.md). For more information, see
   [Cells development principles](cells/_index.md#cells-development-principles).

#### Observability instrumentation

1. You have included enough instrumentation to facilitate debugging and proactive performance improvements through observability.
   See [example](https://gitlab.com/gitlab-org/gitlab/-/issues/346124#expectations) of adding feature flags, logging, and instrumentation.

#### Documentation

1. You have included changelog trailers, or you have decided that they are not needed.
   - [Does this MR need a changelog?](changelog.md#what-warrants-a-changelog-entry)
1. You have added/updated documentation or decided that documentation changes are unnecessary for this MR.
   - [Is documentation required?](documentation/workflow.md#documentation-for-a-product-change)

#### Security

1. You have confirmed that if this MR contains changes to processing or storing of credentials or tokens, authorization, and authentication methods, or other items described in [the security review guidelines](https://handbook.gitlab.com/handbook/security/product-security/security-platforms-architecture/application-security/appsec-reviews/#what-should-be-reviewed), you have added the `~security` label and you have `@`-mentioned `@gitlab-com/gl-security/appsec`.
1. You have reviewed the documentation regarding [internal application security reviews](https://handbook.gitlab.com/handbook/security/product-security/security-platforms-architecture/application-security/appsec-reviews/#internal-application-security-reviews) for **when** and **how** to request a security review and requested a security review if this is warranted for this change.
1. If there are security scan results that are blocking the MR (due to the [merge request approval policies](https://gitlab.com/gitlab-com/gl-security/security-policies)):
   - For true positive findings, they should be corrected before the merge request is merged. This will remove the AppSec approval required by the merge request approval policy.
   - For false positive findings, something that should be discussed for risk acceptance, or anything questionable, ping `@gitlab-com/gl-security/appsec`.

#### Deployment

1. You have considered using a feature flag for this change because the change may be high risk.
1. If you are using a feature flag, you plan to test the change in staging before you test it in production, and you have considered rolling it out to a subset of production customers before rolling it out to all customers.
   - [When to use a feature flag](https://handbook.gitlab.com/handbook/product-development/how-we-work/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags)
1. You have informed the Infrastructure department of a default setting or new setting change per [definition of done](contributing/merge_request_workflow.md#definition-of-done), or decided that this is unnecessary.

#### Compliance

1. You have confirmed that the correct [MR type label](labels/_index.md) has been applied.

### Everyone

- Be kind.
- Accept that many programming decisions are opinions. Discuss trade-offs and resolve quickly.
- Ask questions. Make suggestions, not demands.
- Avoid selective ownership of code ("mine", "not mine").
- Be explicit. People don't always understand your intentions online.
- Be humble. Consider a one-on-one call for lengthy misunderstandings and post a follow-up summary.
- Mention the person directly when a comment is addressed specifically to them.

### For authors: getting changes merged faster

1. Follow best practices: write clear descriptions, add screenshots and validation steps, address
   `dangerbot` comments, and complete the [acceptance checklist](#acceptance-checklist).
1. Follow GitLab patterns. Long discussions delay merging. Consider following the documented
   approach, then open a separate MR to propose changes to best practices.
1. Keep MRs small. Around 200 lines is a good target.
   - Smaller MRs are reviewed faster and have fewer blocking discussions.
   - Use [stacked diffs](../user/project/merge_requests/stacked_diffs.md) for sequential MRs.
   - Split changes so only one maintainer is required per MR (for example, ship database changes
     before the feature).
   - UI with mocked data must be behind a [feature flag](feature_flags/_index.md).
1. Minimize the number of reviewers. A database reviewer can also review backend; a fullstack
   engineer can cover frontend and backend.
1. Know your maintainers and assign domain experts. Maintainers prioritize MRs in areas they know
   well.

### Having your merge request reviewed

- Read through the entire diff before your first push. Check for unrelated changes and debug code.
- Write a detailed description per the
  [merge request guidelines](contributing/merge_request_workflow.md#merge-request-guidelines-for-contributors).
- Don't take feedback personally. Rather, the review is of the code, and its impact on production systems.
- Explain why the code exists, not just what it does.
- Try to respond to every comment. Only resolve threads you have fully addressed. If a comment can be addressed in a follow-up issue, work with the maintainer on a path forward.
- Push feedback-based changes as isolated commits. Do not squash until ready to merge.
- Re-request review once you are ready for another round.

### Responding to GitLab Duo review comments

When GitLab Duo provides automated code review comments on your merge request,
address all comments before requesting a review from human reviewers.

Your response can take any form, as long as it clearly indicates that you have
considered the comment:

- If you made changes based on the suggestion, explain what you changed.
- If the issue is already addressed in another way, mention how it was resolved.
- If the comment is not relevant or incorrect, explain why you are not acting on it.
  A "thumbs down" can be adequate if the comment is clearly irrelevant, but
  an explanation is preferable if there might be any confusion.

Leave GitLab Duo discussion threads unresolved so that reviewers and
maintainers can easily see your responses and verify that all automated feedback
has been appropriately addressed.

### Merging a merge request

Before merging:

- Set the milestone.
- Confirm the correct [MR type label](labels/_index.md#type-labels) is applied.
- Resolve warnings and errors from Danger bot, code quality, and other reports. Post a comment if
  merging with any failed job.

At least one maintainer must approve before merging. Authors and people who add commits cannot
approve their own MR.

If the final approver did not set auto-merge, the MR author may merge their own MR if all required
approvals are in place and they have merge rights. This aligns with the GitLab
[bias for action](https://handbook.gitlab.com/handbook/values/#bias-for-action) value.

When ready to merge:

> [!warning]
> If the merge request is from a fork, also check the
> [guidelines for community contributions](#community-contributions).

- Use [Squash and merge](../user/project/merge_requests/squash_and_merge.md) only if the author
  set it or the commit history is messy.
- In the **Pipelines** tab, select **Run pipeline**, then enable **Auto-merge** on the
  **Overview** tab.
  - Do not merge when
    [the default branch is broken](https://handbook.gitlab.com/handbook/engineering/workflow/#broken-master),
    except in
    [specific cases](https://handbook.gitlab.com/handbook/engineering/workflow/#criteria-for-merging-during-broken-master).
  - Start a new pipeline if the latest one was created before approval and the MR has backend
    changes.
  - You may skip a new pipeline if the latest merged results pipeline was created less than 16
    hours ago (72 hours for stable branches).

### Community contributions

> [!warning]
> **Review all changes thoroughly for malicious code before starting a
> [merged results pipeline](../ci/pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project).**

When reviewing community MRs:

- Scrutinize new dependencies (e.g. `Gemfile.lock`, `yarn.lock`). They could introduce malicious packages.
- Review links and images, especially in documentation MRs.
- When in doubt, ask `@gitlab-com/gl-security/appsec` to review **before** starting any pipeline.
- Set the milestone only when the MR is likely to merge in the current milestone.

#### Taking over a community merge request

When an MR needs changes but the author is unresponsive or unable to finish:

1. Comment that you (the merge request coach) are taking over.
1. Add the `~"coach will finish"` label.
1. Create a feature branch from main and merge their branch into it.
1. Open a new MR, link the community MR, and add the `~"Community contribution"` label.
1. Notify the contributor and follow the regular review process.

### Finding the right balance

Finding the right balance in how deeply to review requires sound judgement. Keep in mind:

- Finding bugs is important, but good design reduces future complexity.
- Enforce [code style](contributing/style_guides.md) through
  [automation](https://handbook.gitlab.com/handbook/values/#cleanup-over-sign-off) rather than
  review comments.
- For non-blocking suggestions, consider approving the MR before passing it back. This reduces
  time-to-merge.
- Distinguish between doing things right and doing things right now. For example, avoid requiring major
  refactors in an urgent security fix.
- Doing things well today is usually better than doing something perfectly
  tomorrow.

### Customer critical merge requests

A merge request may benefit from being considered a customer critical priority because there is a significant benefit to the business in doing so.

Properties of customer critical merge requests:

- A senior director or higher in Development must approve that a merge request qualifies as customer-critical. Alternatively, if two of their direct reports approve, that can also serve as approval.
- The DRI applies the `customer-critical-merge-request` label to the merge request.
- It is required that the reviewers and maintainers involved with a customer critical merge request are engaged as soon as this decision is made.
- It is required to prioritize work for those involved on a customer critical merge request so that they have the time available necessary to focus on it.
- It is required to adhere to GitLab [values](https://handbook.gitlab.com/handbook/values/) and processes when working on customer critical merge requests, taking particular note of family and friends first/work second, definition of done, iteration, and release when it's ready.
- Customer critical merge requests are required to not reduce security, introduce data-loss risk, reduce availability, nor break existing functionality per the process for [prioritizing technical decisions](https://handbook.gitlab.com/handbook/engineering/development/principles/#prioritizing-technical-decisions).
- On customer critical requests, it is recommended that those involved consider coordinating synchronously (Zoom, Slack) in addition to asynchronously (merge requests comments) if they believe this may reduce the elapsed time to merge even though this may sacrifice [efficiency](https://handbook.gitlab.com/handbook/company/culture/all-remote/asynchronous/#evaluating-efficiency).
- After a customer critical merge request is merged, a retrospective must be completed with the intention of reducing the frequency of future customer critical merge requests.

## Troubleshooting failing pipelines

- **Unrelated test failures**: Check if the failure also happens on the default branch.
  If so, wait for the broken master fix, then re-run the pipeline for the MR.
- **`danger-review` job failed**: Check if your MR has more than 20 commits. If so, rebase and
  squash. Otherwise, re-run the job.

For help, comment `@gitlab-bot help` on the MR, or ask in the
[Community Discord](https://discord.gg/gitlab) `contribute` channel.

### Credits

Based on the [`thoughtbot` code review guide](https://github.com/thoughtbot/guides/tree/main/code-review).
