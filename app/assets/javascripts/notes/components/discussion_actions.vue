<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import DiscussionReplyPlaceholder from './discussion_reply_placeholder.vue';
import ResolveDiscussionButton from './resolve_discussion_button.vue';
import ResolveWithIssueButton from './discussion_resolve_with_issue_button.vue';

export default {
  name: 'DiscussionActions',
  components: {
    DiscussionReplyPlaceholder,
    ResolveDiscussionButton,
    ResolveWithIssueButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    ResolveWithDuoDropdownItem: () =>
      import('ee_component/notes/components/resolve_with_duo_dropdown_item.vue'),
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    isResolving: {
      type: Boolean,
      required: true,
    },
    resolveButtonTitle: {
      type: String,
      required: true,
    },
    resolveWithIssuePath: {
      type: String,
      required: false,
      default: '',
    },
    // eslint-disable-next-line vue/no-unused-properties -- shouldShowJumpToNextDiscussion is part of the component's public API.
    shouldShowJumpToNextDiscussion: {
      type: Boolean,
      required: true,
    },
    sourceBranch: {
      type: String,
      required: false,
      default: '',
    },
    iid: {
      type: [String, Number],
      required: false,
      default: null,
    },
    canResolveDiscussionsWithAi: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['resolve', 'showReplyForm'],
  data() {
    return {
      isDuoLoading: false,
    };
  },
  computed: {
    resolvableNotes() {
      return this.discussion.notes.filter((x) => x.resolvable);
    },
    userCanResolveDiscussion() {
      return this.resolvableNotes.every((note) => note.current_user?.can_resolve_discussion);
    },
    showIssueButton() {
      return this.discussion.resolvable && !this.discussion.resolved && this.resolveWithIssuePath;
    },
    showSecondaryActionsDropdown() {
      return (
        this.discussion.resolvable && !this.discussion.resolved && this.canResolveDiscussionsWithAi
      );
    },
    resolveWithIssueItem() {
      return { text: __('Resolve with new issue'), href: this.resolveWithIssuePath };
    },
  },
};
</script>

<template>
  <div class="discussion-with-resolve-btn gl-clearfix">
    <discussion-reply-placeholder @focus="$emit('showReplyForm')" />

    <div v-if="userCanResolveDiscussion" class="btn-group discussion-actions" role="group">
      <div class="btn-group">
        <resolve-discussion-button
          v-if="discussion.resolvable"
          data-testid="resolve-discussion-button"
          :is-resolving="isResolving"
          :button-title="resolveButtonTitle"
          @on-click="$emit('resolve')"
        />
      </div>
      <gl-disclosure-dropdown
        v-if="showSecondaryActionsDropdown"
        :icon="isDuoLoading ? undefined : 'chevron-down'"
        category="secondary"
        :toggle-text="__('More resolve options')"
        :loading="isDuoLoading"
        text-sr-only
        no-caret
      >
        <gl-disclosure-dropdown-item v-if="resolveWithIssuePath" :item="resolveWithIssueItem" />
        <resolve-with-duo-dropdown-item
          :discussion="discussion"
          :source-branch="sourceBranch"
          :iid="iid"
          @triggering="isDuoLoading = true"
          @triggered="isDuoLoading = false"
        />
      </gl-disclosure-dropdown>
      <resolve-with-issue-button v-else-if="showIssueButton" :url="resolveWithIssuePath" />
    </div>
  </div>
</template>
