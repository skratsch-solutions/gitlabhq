---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects>.
title: Release notes
---

GitLab release notes are stored in the `gitlab` repository.

Release notes are organized into one directory for each release with an `index.md` file and individual
files for each feature. For example, the structure is similar to:

```plaintext
doc/
└─ releases/
   └─ 19/
     └─ gitlab-19-0-released/
     │  ├── index.md
     │  └── featureA-Beta.md
     └─ gitlab-19-1-released/
        ├── index.md
        ├── featureB.md
        └── featureA-GA.md
```

For each release, the product manager is responsible for creating the MR and files for the feature release note.
The Technical writing team is responsible for creating all other directories and files.

## How to add a feature release note

To update the release notes for 19.0:

1. Open the [`gitlab-19-0-released.md`](../../releases/19/gitlab-19-0-released.md) file
   in the `gitlab-org/gitlab` project.
1. Copy the commented-out text at the top of the page. It's an `H3` heading, comment for the category, details, and a block of text.
1. Paste the text into the section that makes the most sense: the primary feature, or one of the
   secondary groups. For more information, see [release post organization](#organization).
1. Add a `>` to the end of the category comment so it's properly formatted HTML: (`<!-- categories: <name value from categories.yml> -->`).
   Add values that match the [categories.yml](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/categories.yml) file.
   The value is case-sensitive.
   Use comma separation for multiple values.
1. Edit the text to reflect your feature announcement.
   - Use 125 words or fewer, and no images or videos.
   - Documentation links are allowed and must be relative.
   - Ensure work item links are not confidential.
   - Links to other resources are also allowed.
1. Open a merge request:
   - Use the Release Notes Item template to populate the description and to track progress.
   - Assign the merge request to an Engineering Manager and Technical Writer for review.

> [!note]
> All release notes should be merged by 00:00 (midnight) UTC on the Friday before the release day to be included in the appropriate release.

If your item is primary, review the instructions for What's new.

## How the notable contributor is added

Developer Relations creates the merge request that adds a few sentences about the release's notable contributor.

The format should be similar to:

```markdown
We'd also like to announce this month's [Notable Contributor](https://contributors.gitlab.com/notable-contributors):
<name>!

We are excited to recognize [Name](https://gitlab.com/<username>), a ....
```

This merge request can be merged at any point before the release, though
you can check with the author to confirm.

## Technical Writer review

To review a release note merge request:

1. Review the tiers, offerings, documentation link, issue link, and content.
   Ensure the links have been changed from the examples, and that the work item isn't confidential.
1. Start an automatic rebase with `/rebase` in an empty comment, then set it to auto-merge when the pipeline completes.

While it is preferable for the writer to merge, any Maintainer can merge.
The priority is for the item to be merged before the release.

## Technical Writer release day process

On release day, the writer assigned to the upcoming release creates three merge requests:

- One for the `gitlab` repo. This MR updates the introductory language and the description text.
  It also introduces a page for the next release and adds a redirect.
- One for `docs-gitlab-com`. This MR adds the next release version to the navigation.
- One that backports the final release notes to the most recent "stable branch."
  For example, if you are releasing 19.1, the stable branch is `19-1-stable-ee`.

You can create the first two merge requests a few days before the release.
The third one must be done on release day.

> [!warning]
> Do not merge the changes until the release manager confirms that the packages are publicly
> available, usually around 14:00 UTC. Release managers will put a note in the
> `#release-post` channel when it's time to publish.

### Update content to reflect today's release

Open the file for the release, for example `doc/releases/19/gitlab-19-0-released.md`, and update the following content.

1. In the metadata, after the `group`, add the release date. For example:

   ```markdown
   date: 2026-05-21
   ```

   This addition will make the pipeline fail until the date of release.
   This is expected.

1. Change the `description` metadata from:

   ```markdown
   Summary of features included in <version>
   ```

   To:

   ```markdown
   GitLab <version> released with <top feature title>
   ```

1. Change the `title` from:

   ```markdown
   title: GitLab <version> - not yet released
   ```

   To:

   ```markdown
   title: GitLab <version>
   ```

1. Change the intro text from:

   ```markdown
   The following features are being delivered for GitLab <version>.
   These features are now available on GitLab.com.
   ```

   To:

   ```markdown
   On <release date>, GitLab <version> was released with the following features.
   ```

   Replace the date and version with the version that's being released.

### Create content for next release

Now create a file for the next version.

1. In the `/doc/releases/` folder, create a Markdown file for the next release. For example, `19/gitlab-19-1-released.md`.
1. Populate the file with the [template](#templates).
1. Add a `>` to the end of the category comment so it's properly formatted HTML: `<!-- categories: <name value from categories.yml> -->`
1. In the metadata and intro text, change the version number to the next version number.

### Update the index file

Now update the index file to point to the new file.

1. Open `/doc/releases/19/_index.md`.
1. Add the upcoming version, for example, if 19.0 is shipping, add 19.1:

   ```markdown
   {{</* cards */>}}

   - [GitLab 19.0](gitlab-19-0-released.md)
   - [GitLab 19.1](gitlab-19-1-released.md)

   {{</* /cards */>}}
   ```

### Update the redirect file

1. Open `doc/releases/upcoming.md`.
1. Update the text and metadata to reflect the next release.

You can now push your commit. This merge request is complete.

### Update the left navigation

Now go to the `docs-gitlab-com` repository and update `navigation.yaml` to
add the next version's page to the left navigation.

For example, add 19.1:

```yaml
        - title: GitLab 19
          url: 'releases/19/'
          submenu:
            - title: GitLab 19.0
              url: 'releases/19/gitlab-19-0-released/'
            - title: GitLab 19.1
              url: 'releases/19/gitlab-19-1-released/'
```

You can now push your commit. This merge request is complete.

### Backport the final notes

After the release notes are published, you must backport them. Do this work on release day and not before.

The final cutoff for the `gitlab` repository happens the Friday before the release.
If a user selects the version from the upper-right corner of the docs site, they won't get the final notes.
Backporting makes the notes visible and up-to-date when users select the newly released version.

1. Check out the "stable branch." For example, if you are releasing 19.1, check out `19-1-stable-ee`.
1. Open the latest release notes from the `gitlab` repository and copy the file contents.
1. Paste the contents over the local version of the release notes.
1. Open a merge request and select the **Stable branch** template to populate the description.
   Change the target branch to the stable branch (`19-1-stable-ee`).
1. Have a maintainer review and merge. (It can be another tech writer.)
   If the branch is still locked, ask for assistance in the `#release-post` channel,
   or wait a few hours until the branch is available to merge.
1. After merge, [create a new docs pipeline](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/pipelines/new).
   For **Run for branch name or tag**, select the version to deploy. In this example, choose `19.1`,
   then select **New pipeline**.

## Update a release note after the release deadline

To update or add a release note after the release, complete the following steps.

Update the `gitlab` repository:

1. Open a merge request to update the Markdown file in the `gitlab` repository.
1. Make your changes and have a technical writer review and merge.

Backport the change:

1. Check out the "stable branch." For example, if you are updating 19.0, check out `19-0-stable-ee`.
1. Make your change in this branch.
1. Open a merge request and set the target branch to the stable branch (`19-0-stable-ee`).
1. Have a maintainer review and merge. (It can be another tech writer.)
1. After merge, [create a new docs pipeline](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/pipelines/new).
   For **Run for branch name or tag**, select the version to deploy. In this example, choose `19.0`,
   then select **New pipeline**.

1. On <https://docs.gitlab.com>, select the version in the upper-right corner and ensure the notes
   were updated successfully.

## Organization

In the release post, each feature release note is grouped into a section based on the `stage`
metadata defined in the feature release note. Each [stage](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/data/release_post_groupings.yaml)
maps to one of the following sections:

| Section                     | Stages |
| --------------------------- | ------ |
| Primary features            | -      |
| Agentic Core                | `ai-powered`, `modelops` |
| Unified DevOps and Security | `analytics`, `application_security_testing`, `create`, `deploy`, `knowledge_graph`, `package`, `plan`, `security_risk_management`, `software_supply_chain_security`, `verify` |
| Scale and Deployments       | `data_access`, `database_excellence`, `developer_experience`, `foundations`, `fulfillment`, `gitlab_dedicated`, `gitlab_delivery`, `growth`, `production_engineering`, `tenant_scale`, `unlisted/unknown` |

Sections appear in the order listed in the table, with `Primary features` first. Any stage that
isn't mapped appears in the `Scale and Deployments` section. To add features to the `Primary features` section,
use the [`level`](#feature-release-note-metadata) metadata.

In each section, feature release notes are listed alphabetically by title. To override this order, define a value
for the `weight` metadata, where lower numbers go first.

Generally, use multiples of 10 (such as `10`, `20`, `30`) to leave room for future insertions, and avoid single-digit
values unless a note must absolutely appear first.

## Metadata

### Minor release index metadata

| Metadata      | Format                                                                                                                         | Description |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| `title`       | Pre-release: `GitLab <version> - not yet released`<br>Post-release: `GitLab <version>`                                         | Page title. Uses the first format before release, and the second on release day. |
| `description` | Pre-release: `Summary of features included in <version>`<br>Post-release: `GitLab <version> released with <top feature title>` | Short summary displayed on cards for the index page. |
| `group`       | `Monthly Release`, `Patch Release`                                                                                             | Used for analytics and feedback. Always uses `Monthly Release`; patch releases are created through a different process. |
| `stage`       | `Release Notes`                                                                                                                | Used for analytics and feedback. Always uses `Release Notes`. |

### Feature release note metadata

| Metadata             | Format                                                                                                 | Description |
| -------------------- | ------------------------------------------------------------------------------------------------------ | ----------- |
| `title`              | string                                                                                                 | Feature title. Displayed as a section heading. Ideally seven words or fewer. |
| `tier`               | array, formatted like `[ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government]` | Feature tier. Formatting matters. Requires at least one. Always follow this order. |
| `offering`           | array, formatted like `[ Free, Premium, Ultimate ]`                                                    | Feature offerings. Requires at least one. Always follow this order. |
| `documentation_link` | relative URL                                                                                           | Link to the feature documentation. Don't use `https://`-style links. |
| `work_item`          | absolute URL                                                                                           | Link to the related work item. Must not be confidential. |
| `categories`         | array                                                                                                  | An array with the `Name` value of one or more [categories](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/categories.yml). Values are case-sensitive, separate multiple values with commas. If a related category doesn't exist, make another merge request to add it. |
| `stage`              | string                                                                                                 | Name of the stage that created the feature. Used to [organize](#organization) the section the release note appears in. |
| `level`              | One of: `primary` or `secondary`                                                                       | Optional. Controls placement in the `Primary features` section. If undefined, defaults to `secondary`. |
| `weight`             | number                                                                                                 | Optional. Controls ordering in each [section](#organization). Lower numbers go first. To force a feature release note first in a section, use a lower number such as 10. To avoid sorting issues with other feature release notes, avoid using single-digit numbers unless the note must absolutely appear first. |

## Templates

### Minor release index

```markdown
---
title: "GitLab <version> - not yet released"
description: "Summary of features included in <version>"
group: Monthly Release
stage: Release Notes
---

The following features are being delivered for GitLab <version>.
These features are now available on GitLab.com.

## Notable contributor
```

### Feature release note

```markdown
---
title:
tier: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
offering: [ Free, Premium, Ultimate ]
stage:
documentation_link: "../../../_index.md#popular-topics"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/<work-item-number>
categories: [ System Access, Permissions ]
level: primary or secondary
weight: 50
---

The text of the feature release note.

Explain the value of this improvement with 125 words or fewer.
Use phrases that start with, "In previous versions of GitLab, you couldn't... Now you can..."
```
