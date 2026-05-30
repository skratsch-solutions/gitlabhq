<script>
import { GlAvatar, GlIcon, GlLink, GlPopover, GlSkeletonLoader, GlTruncate } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { newDate } from '~/lib/utils/datetime/date_calculation_utility';
import defaultAvatarUrl from 'images/no_avatar.png';
import query from '../queries/commit.query.graphql';

export default {
  name: 'CommitPopover',

  components: {
    GlAvatar,
    GlIcon,
    GlLink,
    GlPopover,
    GlSkeletonLoader,
    GlTruncate,
  },

  props: {
    target: {
      type: HTMLAnchorElement,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    commitSha: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      commit: null,
      isLoading: true,
    };
  },

  apollo: {
    commit: {
      query,
      variables() {
        return {
          projectPath: this.projectPath,
          sha: this.commitSha,
        };
      },
      update: (data) => data.project?.repository?.commit ?? null,
      result() {
        this.isLoading = false;
      },
      error() {
        this.isLoading = false;
      },
    },
  },

  computed: {
    authorName() {
      return this.commit?.author?.name ?? this.commit?.authorName ?? '';
    },
    avatarUrl() {
      return this.commit?.author?.avatarUrl ?? defaultAvatarUrl;
    },
    authoredText() {
      if (!this.commit?.authoredDate) return '';
      const timeago = getTimeago().format(newDate(this.commit.authoredDate));
      return sprintf(__('Authored %{timeago}'), { timeago });
    },
  },
};
</script>

<template>
  <gl-popover
    :target="target"
    boundary="viewport"
    placement="top"
    css-classes="gl-min-w-30"
    :show="isLoading || Boolean(commit)"
  >
    <gl-skeleton-loader v-if="isLoading" :height="15">
      <rect width="100%" height="15" rx="4" />
    </gl-skeleton-loader>

    <template v-else-if="commit">
      <div class="gl-flex gl-flex-col gl-gap-3">
        <div class="gl-text-subtle" data-testid="commit-authored-text">
          {{ authoredText }}
        </div>

        <gl-link
          :href="commit.webPath"
          class="gl-text-default hover:gl-text-default"
          data-testid="commit-title-link"
        >
          <gl-truncate :text="commit.title" :lines="2" class="gl-heading-5 !gl-my-0" />
        </gl-link>

        <div class="gl-flex gl-items-center gl-gap-2 gl-text-subtle">
          <gl-avatar :src="avatarUrl" :size="16" :alt="authorName" />
          <span data-testid="commit-author-name">{{ authorName }}</span>
        </div>

        <div class="gl-flex gl-items-center gl-gap-2">
          <gl-icon name="commit" :size="14" class="gl-text-subtle" />
          <gl-link
            :href="commit.webPath"
            class="gl-font-monospace gl-text-subtle hover:gl-text-default"
            data-testid="commit-sha-link"
          >
            {{ commit.shortId }}
          </gl-link>
        </div>
      </div>
    </template>
  </gl-popover>
</template>
