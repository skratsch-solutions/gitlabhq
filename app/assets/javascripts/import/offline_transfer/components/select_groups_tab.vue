<script>
import { GlLoadingIcon, GlButton, GlEmptyState, GlKeysetPagination } from '@gitlab/ui';
import EMPTY_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-catalog-md.svg';
import { s__, n__ } from '~/locale';
import SelectGroupRow from '~/import/offline_transfer/components/select_group_row.vue';

export default {
  name: 'SelectGroupsTab',
  components: { GlLoadingIcon, GlButton, SelectGroupRow, GlEmptyState, GlKeysetPagination },
  props: {
    pageGroups: {
      type: Array,
      required: true,
    },
    selectedIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    pageInfo: {
      type: Object,
      required: false,
      default: () => ({
        hasNextPage: false,
        hasPreviousPage: false,
        startCursor: null,
        endCursor: null,
      }),
    },
    showSelectError: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['toggle', 'select-current-page', 'deselect-all', 'next', 'prev'],
  computed: {
    currentPageSelected() {
      return (
        this.pageGroups.length > 0 &&
        this.pageGroups.every((group) => this.selectedIds.includes(group.id))
      );
    },
    noneSelected() {
      return this.selectedIds.length === 0;
    },
    countText() {
      return n__('%d group selected', '%d groups selected', this.selectedIds.length);
    },
  },
  methods: {
    isChecked(id) {
      return this.selectedIds.includes(id);
    },
  },

  i18n: {
    SELECT_PAGE: s__('OfflineTransferExport|Select page'),
    DESELECT_ALL: s__('OfflineTransferExport|Deselect all'),
    EMPTY_TITLE: s__('OfflineTransferExport|You have no groups available to export'),
  },
  EMPTY_SVG_URL,
};
</script>

<template>
  <gl-loading-icon v-if="loading" size="lg" class="gl-mt-5" />
  <gl-empty-state
    v-else-if="pageGroups.length === 0"
    :svg-path="$options.EMPTY_SVG_URL"
    :svg-height="150"
    :title="$options.i18n.EMPTY_TITLE"
  />
  <div v-else>
    <div class="gl-flex gl-items-center gl-justify-between gl-py-3">
      <span
        v-if="noneSelected && showSelectError"
        role="alert"
        class="gl-font-semibold gl-text-danger"
        data-testid="selected-error"
        >{{ s__('OfflineTransferExport|Select at least one group to continue') }}</span
      >
      <span v-else class="gl-font-semibold" data-testid="selected-count">{{ countText }}</span>
      <div class="gl-flex gl-gap-3">
        <gl-button
          variant="link"
          data-testid="select-current-page"
          :disabled="currentPageSelected"
          @click="$emit('select-current-page')"
        >
          {{ $options.i18n.SELECT_PAGE }}
        </gl-button>
        <gl-button
          variant="link"
          data-testid="deselect-all"
          :disabled="noneSelected"
          @click="$emit('deselect-all')"
        >
          {{ $options.i18n.DESELECT_ALL }}
        </gl-button>
      </div>
    </div>
    <ul class="gl-m-0 gl-list-none gl-p-0">
      <select-group-row
        v-for="group in pageGroups"
        :key="group.id"
        :name="group.fullName"
        :description="group.description"
        :avatar-url="group.avatarUrl"
        :checked="isChecked(group.id)"
        @toggle="$emit('toggle', group)"
      />
    </ul>
    <div
      v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage"
      class="gl-mt-4 gl-flex gl-justify-center"
    >
      <gl-keyset-pagination
        :has-next-page="pageInfo.hasNextPage"
        :has-previous-page="pageInfo.hasPreviousPage"
        :start-cursor="pageInfo.startCursor"
        :end-cursor="pageInfo.endCursor"
        @prev="$emit('prev', $event)"
        @next="$emit('next', $event)"
      />
    </div>
  </div>
</template>
