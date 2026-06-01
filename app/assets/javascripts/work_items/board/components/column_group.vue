<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getBoardWorkItemsQuery from 'ee_else_ce/work_items/board/graphql/get_board_work_items.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';

import ColumnHeader from './column_header.vue';
import WorkItemCard from './work_item_card.vue';

export default {
  name: 'ColumnGroup',
  i18n: {
    emptyText: s__('WorkItemBoard|No items'),
  },
  components: {
    ColumnHeader,
    GlLoadingIcon,
    WorkItemCard,
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
  data() {
    return {
      workItems: [],
      error: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.workItems.loading;
    },
    queryVariables() {
      return {
        fullPath: this.rootPageFullPath,
        firstPageSize: 20,
        ...this.baseQueryVariables,
        ...this.columnFilter,
      };
    },
    columnFilter() {
      return {
        [this.groupProperty]: { name: this.value.name }, // must be last to override base
      };
    },
  },
  apollo: {
    workItems() {
      const query =
        this.glFeatures.workItemRestApiFrontendUsers && this.glFeatures.workItemRestApi
          ? getWorkItemsRestQuery
          : getBoardWorkItemsQuery;
      return {
        query,
        update(data) {
          return data?.namespace?.workItems?.nodes ?? [];
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
          this.error = s__(
            'WorkItemBoard|An error occurred while fetching work items for this column.',
          );
          Sentry.captureException(error);
        },
      };
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
      <gl-loading-icon v-if="isLoading" size="sm" class="gl-mt-4" />
      <p
        v-else-if="error"
        data-testid="error-state"
        class="gl-py-3 gl-text-center gl-text-sm gl-text-subtle"
      >
        {{ error }}
      </p>
      <p
        v-else-if="workItems.length === 0"
        data-testid="empty-state"
        class="gl-py-3 gl-text-center gl-text-sm gl-text-subtle"
      >
        {{ $options.i18n.emptyText }}
      </p>
      <ul v-else class="gl-m-0 gl-flex gl-list-none gl-flex-col gl-gap-3 gl-p-0">
        <work-item-card v-for="workItem in workItems" :key="workItem.id" :item="workItem" />
      </ul>
    </div>
  </div>
</template>
