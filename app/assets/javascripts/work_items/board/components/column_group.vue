<script>
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DraggableCompat from '~/lib/utils/vue3compat/draggable_compat.vue';
import { defaultSortableOptions, DRAG_DELAY } from '~/sortable/constants';
import WorkItemChildrenLoadMore from '~/work_items/components/shared/work_item_children_load_more.vue';
import { DEFAULT_PAGE_SIZE_BOARD_COLUMN_SUBSEQUENT } from '~/work_items/constants';

import { boardColumnQuery, boardColumnQueryVariables } from '../utils';
import { BOARD_DND_GROUP, BOARD_CARD_CLASS } from '../constants';
import ColumnHeader from './column_header.vue';
import WorkItemCard from './work_item_card.vue';
import WorkItemCardSkeleton from './work_item_card_skeleton.vue';

export default {
  name: 'ColumnGroup',
  // Number of ghost cards shown while loading the initial page or paginating.
  skeletonCount: 3,
  // `draggable` is scoped to the card class so the load-more row stays fixed.
  sortableOptions: {
    ...defaultSortableOptions,
    group: BOARD_DND_GROUP,
    draggable: `.${BOARD_CARD_CLASS}`,
    delay: DRAG_DELAY,
    delayOnTouchOnly: true,
  },
  i18n: {
    emptyText: s__('WorkItemBoard|No items'),
    fetchError: s__('WorkItemBoard|An error occurred while fetching work items for this column.'),
    loadMoreError: s__('WorkItemBoard|An error occurred while fetching more work items.'),
  },
  components: {
    ColumnHeader,
    DraggableCompat,
    WorkItemCard,
    WorkItemCardSkeleton,
    WorkItemChildrenLoadMore,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    value: {
      type: Object,
      required: true,
    },
    groupProperty: {
      type: String,
      required: true,
    },
    rootPageFullPath: {
      type: String,
      required: true,
    },
    baseQueryVariables: {
      type: Object,
      required: true,
    },
  },
  emits: ['card-move'],
  data() {
    return {
      workItemsConnection: { nodes: [], pageInfo: {} },
      error: null,
      loadMoreError: false,
      fetchNextPageInProgress: false,
    };
  },
  computed: {
    isLoading() {
      // Initial load only; once items exist the load-more component owns the
      // in-progress indicator, so the column spinner never replaces the list.
      return this.$apollo.queries.workItemsConnection.loading && this.workItems.length === 0;
    },
    workItems() {
      return this.workItemsConnection?.nodes ?? [];
    },
    pageInfo() {
      return this.workItemsConnection?.pageInfo ?? {};
    },
    hasNextPage() {
      return Boolean(this.pageInfo.hasNextPage);
    },
    showEmptyState() {
      return !this.isLoading && !this.fetchNextPageInProgress && this.workItems.length === 0;
    },
    queryVariables() {
      return boardColumnQueryVariables({
        rootPageFullPath: this.rootPageFullPath,
        baseQueryVariables: this.baseQueryVariables,
        groupProperty: this.groupProperty,
        value: this.value,
      });
    },
  },
  apollo: {
    workItemsConnection() {
      const query = boardColumnQuery(this.glFeatures);
      return {
        query,
        update(data) {
          return data?.namespace?.workItems ?? { nodes: [], pageInfo: {} };
        },
        result(result) {
          if (!result.error) {
            this.error = null;
          }
        },
        variables() {
          return this.queryVariables;
        },
        error(error) {
          // Pagination failures are surfaced inline by fetchNextPage so that
          // already-loaded items stay visible; only the initial load replaces the column.
          if (this.fetchNextPageInProgress) {
            return;
          }
          this.error = this.$options.i18n.fetchError;
          Sentry.captureException(error);
        },
      };
    },
  },
  methods: {
    fetchNextPage() {
      if (!this.hasNextPage || this.fetchNextPageInProgress) {
        return;
      }

      this.fetchNextPageInProgress = true;
      this.loadMoreError = false;

      this.$apollo.queries.workItemsConnection
        .fetchMore({
          variables: {
            ...this.queryVariables,
            firstPageSize: DEFAULT_PAGE_SIZE_BOARD_COLUMN_SUBSEQUENT,
            afterCursor: this.pageInfo.endCursor,
          },
          updateQuery(previousResult, { fetchMoreResult }) {
            const previousConnection = previousResult?.namespace?.workItems;
            const newConnection = fetchMoreResult?.namespace?.workItems;

            if (!newConnection) {
              return previousResult;
            }

            return {
              ...fetchMoreResult,
              namespace: {
                ...fetchMoreResult.namespace,
                workItems: {
                  ...newConnection,
                  nodes: [...(previousConnection?.nodes ?? []), ...newConnection.nodes],
                },
              },
            };
          },
        })
        .catch((error) => {
          this.loadMoreError = true;
          Sentry.captureException(error);
        })
        .finally(() => {
          this.fetchNextPageInProgress = false;
        });
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-h-full gl-w-48 gl-shrink-0 gl-flex-col gl-rounded-lg gl-bg-strong dark:gl-bg-subtle"
  >
    <column-header :value="value" :group-property="groupProperty" :count="workItems.length" />
    <div class="gl-flex gl-min-h-0 gl-flex-1 gl-flex-col gl-overflow-y-auto gl-px-3 gl-pb-3">
      <p
        v-if="error"
        data-testid="error-state"
        class="gl-py-3 gl-text-center gl-text-sm gl-text-subtle"
      >
        {{ error }}
      </p>
      <!-- Always rendered (outside the error state) so an empty column stays a drop target. -->
      <draggable-compat
        v-else
        :value="workItems"
        item-key="id"
        tag="ul"
        :data-status-id="value.id"
        v-bind="$options.sortableOptions"
        class="gl-m-0 gl-flex gl-flex-1 gl-list-none gl-flex-col gl-gap-3 gl-p-0"
        @end="$emit('card-move', $event)"
      >
        <work-item-card v-for="workItem in workItems" :key="workItem.id" :item="workItem" />
        <work-item-card-skeleton
          v-for="n in isLoading || fetchNextPageInProgress ? $options.skeletonCount : 0"
          :key="`skeleton-${n}`"
        />
        <li
          v-if="showEmptyState"
          data-testid="empty-state"
          class="gl-list-none gl-py-3 gl-text-center gl-text-sm gl-text-subtle"
        >
          {{ $options.i18n.emptyText }}
        </li>
        <li v-if="hasNextPage && !fetchNextPageInProgress" class="gl-list-none">
          <work-item-children-load-more
            class="gl-justify-center"
            :fetch-next-page-in-progress="fetchNextPageInProgress"
            @fetch-next-page="fetchNextPage"
          />
        </li>
        <li
          v-if="loadMoreError"
          data-testid="load-more-error"
          class="gl-list-none gl-py-2 gl-text-center gl-text-sm gl-text-subtle"
        >
          {{ $options.i18n.loadMoreError }}
        </li>
      </draggable-compat>
    </div>
  </div>
</template>
