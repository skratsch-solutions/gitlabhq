<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import getBoardNamespaceStatusesQuery from 'ee_else_ce/work_items/board/graphql/get_namespace_statuses.query.graphql';
import updateBoardWorkItemMutation from './graphql/update_board_work_item.mutation.graphql';
import { boardColumnQuery, boardColumnQueryVariables } from './utils';
import {
  addWorkItemToColumn,
  readWorkItemFromColumn,
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
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.groupByValues.loading;
    },
    columnQuery() {
      return boardColumnQuery(this.glFeatures);
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
    async onCardMove({ from, to, item, newIndex }) {
      const fromStatusId = from?.dataset?.statusId;
      const toStatusId = to?.dataset?.statusId;
      const workItemId = item?.dataset?.workItemId;

      if (!fromStatusId || !toStatusId || !workItemId || fromStatusId === toStatusId) {
        return;
      }

      const fromValue = this.statusById(fromStatusId);
      const toValue = this.statusById(toStatusId);
      if (!fromValue || !toValue) {
        return;
      }

      const { cache } = this.$apollo.getClient();
      const query = this.columnQuery;
      const fromVariables = this.columnVariables(fromValue);
      const toVariables = this.columnVariables(toValue);

      // Snapshot the moved card so the cache update can reinsert it into the target
      // column (with the new status) on both the optimistic and the confirmed pass.
      const node = readWorkItemFromColumn({ cache, query, variables: fromVariables, workItemId });
      if (!node) {
        return;
      }

      try {
        // Apollo runs `update` optimistically, then again on the server result; a
        // failure discards the optimistic layer and snaps the card back. We reinsert
        // the cached `node` (it has the display fields) rather than the id-only payload.
        const { data } = await this.$apollo.mutate({
          mutation: updateBoardWorkItemMutation,
          variables: { input: { id: workItemId, statusWidget: { status: toStatusId } } },
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
              status: toValue,
            });
          },
        });

        if (data?.workItemUpdate?.errors?.length) {
          throw new Error(data.workItemUpdate.errors.join(', '));
        }
      } catch (error) {
        this.$toast.show(I18N_MOVE_ERROR);
        Sentry.captureException(error);
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
      @card-move="onCardMove"
    />
  </div>
</template>
