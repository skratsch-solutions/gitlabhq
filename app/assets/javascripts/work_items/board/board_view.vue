<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { RELATIVE_POSITION_ASC } from '~/work_items/list/constants';

import getBoardNamespaceStatusesQuery from 'ee_else_ce/work_items/board/graphql/get_namespace_statuses.query.graphql';
import getWorkItemsCountOnlyQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_count_only.query.graphql';
import updateBoardWorkItemMutation from './graphql/update_board_work_item.mutation.graphql';
import {
  boardColumnQuery,
  boardColumnQueryVariables,
  getMovePositionIds,
  boardColumnCountVariables,
} from './utils';
import {
  addWorkItemToColumn,
  adjustWorkItemCountInColumn,
  readWorkItemFromColumn,
  readWorkItemsFromColumn,
  removeWorkItemFromColumn,
} from './graphql/cache_updates';
import { I18N_MOVE_ERROR } from './constants';
import ColumnGroup from './components/column_group.vue';

export default {
  name: 'BoardView',
  components: {
    GlLoadingIcon,
    ColumnGroup,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    rootPageFullPath: {
      type: String,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
  },
  emits: ['set-error'],
  data() {
    return {
      groupBy: { property: 'status' },
      groupByValues: [],
      // Locks dragging while a move mutation is in flight so a second drop can't
      // compute before/after ids against a stale, not-yet-persisted order.
      moveInProgress: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.groupByValues.loading;
    },
    columnQuery() {
      return boardColumnQuery(this.glFeatures);
    },
    // Relative position is only meaningful under Manual sort; any other sort would
    // immediately override a reorder, so we don't persist position then.
    isManualSort() {
      return this.queryVariables.sort === RELATIVE_POSITION_ASC;
    },
  },
  apollo: {
    groupByValues: {
      query: getBoardNamespaceStatusesQuery,
      variables() {
        return { fullPath: this.rootPageFullPath };
      },
      update(data) {
        return data?.namespace?.rootNamespace?.statuses?.nodes ?? [];
      },
      error(error) {
        this.$emit(
          'set-error',
          s__(
            'WorkItemBoard|Something went wrong when fetching the board columns. Please try again.',
          ),
        );
        Sentry.captureException(error);
      },
    },
  },
  methods: {
    statusById(statusId) {
      return this.groupByValues.find(({ id }) => id === statusId) ?? null;
    },
    columnVariables(value) {
      return boardColumnQueryVariables({
        rootPageFullPath: this.rootPageFullPath,
        baseQueryVariables: this.queryVariables,
        groupProperty: this.groupBy.property,
        value,
      });
    },
    columnCountVariables(value) {
      return boardColumnCountVariables({
        rootPageFullPath: this.rootPageFullPath,
        baseQueryVariables: this.queryVariables,
        groupProperty: this.groupBy.property,
        value,
      });
    },
    async onCardMove({ from, to, item, oldIndex, newIndex }) {
      const fromStatusId = from?.dataset?.statusId;
      const toStatusId = to?.dataset?.statusId;
      const workItemId = item?.dataset?.workItemId;

      if (!fromStatusId || !toStatusId || !workItemId) {
        return;
      }

      const fromValue = this.statusById(fromStatusId);
      const toValue = this.statusById(toStatusId);
      if (!fromValue || !toValue) {
        return;
      }

      // Columns are statuses, so an unchanged status means a same-column reorder.
      const statusChanged = fromStatusId !== toStatusId;

      const { cache } = this.$apollo.getClient();
      const query = this.columnQuery;
      const fromVariables = this.columnVariables(fromValue);
      const toVariables = this.columnVariables(toValue);

      // Relative position comes from the target column's pre-move order so the
      // before/after ids match where the card lands. Only computed under Manual sort.
      const { moveBeforeId, moveAfterId } = this.isManualSort
        ? getMovePositionIds({
            nodes: readWorkItemsFromColumn({ cache, query, variables: toVariables }),
            sameColumn: !statusChanged,
            oldIndex,
            newIndex,
          })
        : {};

      // Nothing to persist: dropped back in place with no status or position change.
      if (!statusChanged && !moveBeforeId && !moveAfterId) {
        return;
      }

      // Snapshot the moved card so the cache update can reinsert it into the target
      // column (with the new status) on both the optimistic and the confirmed pass.
      const node = readWorkItemFromColumn({ cache, query, variables: fromVariables, workItemId });
      if (!node) {
        return;
      }

      const input = { id: workItemId };
      if (statusChanged) {
        input.statusWidget = { status: toStatusId };
      }
      if (moveBeforeId) {
        input.moveBeforeId = moveBeforeId;
      }
      if (moveAfterId) {
        input.moveAfterId = moveAfterId;
      }

      this.moveInProgress = true;
      try {
        // Apollo runs `update` optimistically, then again on the server result; a
        // failure discards the optimistic layer and snaps the card back. We reinsert
        // the cached `node` (it has the display fields) rather than the id-only payload.
        const { data } = await this.$apollo.mutate({
          mutation: updateBoardWorkItemMutation,
          variables: { input },
          optimisticResponse: {
            workItemUpdate: {
              __typename: 'WorkItemUpdatePayload',
              workItem: { __typename: 'WorkItem', id: workItemId },
              errors: [],
            },
          },
          update: (store, { data: { workItemUpdate } }) => {
            if (!workItemUpdate?.workItem) {
              return;
            }

            removeWorkItemFromColumn({ cache: store, query, variables: fromVariables, workItemId });
            addWorkItemToColumn({
              cache: store,
              query,
              variables: toVariables,
              workItem: node,
              index: newIndex,
              // Only patch the status badge on a cross-column move; a reorder keeps it.
              status: statusChanged ? toValue : null,
            });

            // The header counts live in their own count-only query cache, so keep them
            // in step with the connection updates above (rolled back on a failed move).
            adjustWorkItemCountInColumn({
              cache: store,
              query: getWorkItemsCountOnlyQuery,
              variables: this.columnCountVariables(fromValue),
              delta: -1,
            });
            adjustWorkItemCountInColumn({
              cache: store,
              query: getWorkItemsCountOnlyQuery,
              variables: this.columnCountVariables(toValue),
              delta: 1,
            });
          },
        });

        if (data?.workItemUpdate?.errors?.length) {
          throw new Error(data.workItemUpdate.errors.join(', '));
        }
      } catch (error) {
        this.$toast.show(I18N_MOVE_ERROR);
        Sentry.captureException(error);
      } finally {
        this.moveInProgress = false;
      }
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-w-full gl-gap-3 gl-overflow-x-auto gl-py-5"
    style="height: calc(100dvh - 220px - 2rem)"
  >
    <gl-loading-icon v-if="isLoading && groupByValues.length === 0" size="lg" class="gl-m-auto" />
    <column-group
      v-for="value in groupByValues"
      :key="value.id"
      :value="value"
      :group-property="groupBy.property"
      :root-page-full-path="rootPageFullPath"
      :base-query-variables="queryVariables"
      :drag-disabled="moveInProgress"
      @card-move="onCardMove"
    />
  </div>
</template>
