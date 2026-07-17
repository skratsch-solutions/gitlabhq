<script>
import {
  GlButton,
  GlCollapse,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlPopover,
  GlTooltipDirective,
  GlSprintf,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, n__, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WorkItemDetailPanel from '~/work_items/components/work_item_detail_panel.vue';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import mergeRequestRelatedWorkItemsQuery from '~/sidebar/queries/merge_request_related_work_items.query.graphql';
import createMergeRequestWorkItemRelationMutation from '~/sidebar/queries/create_merge_request_work_item_relation.mutation.graphql';
import { DETAIL_VIEW_QUERY_PARAM_NAME, VIEW_CONTEXT } from '~/work_items/constants';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';
import { MR_WORK_ITEM_RELATIONSHIP_TYPES } from '~/sidebar/constants';
import RelatedWorkItemsAddForm from './related_work_items_add_form.vue';

export default {
  name: 'MRRelatedWorkItems',
  components: {
    GlButton,
    GlCollapse,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlPopover,
    GlSprintf,
    WorkItemDetailPanel,
    RelatedWorkItemsAddForm,
  },
  viewContext: VIEW_CONTEXT.drawerMergeRequest,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['fullPath', 'id'],
  data() {
    return {
      activeItem: null,
      isCollapsed: true,
      params: null,
      mergeRequest: null,
      isAddModalVisible: false,
    };
  },
  apollo: {
    mergeRequest: {
      query: mergeRequestRelatedWorkItemsQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.id),
          explicitMrWorkItemRelations: Boolean(this.glFeatures.explicitMrWorkItemRelations),
        };
      },
      update(data) {
        return data?.mergeRequest || null;
      },
      result() {
        this.checkDetailPanelParams();
      },
      error() {
        createAlert({
          message: __('Something went wrong while fetching related work items.'),
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.mergeRequest.loading;
    },
    mergeRequestGid() {
      return convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.id);
    },
    allItems() {
      const relations = this.glFeatures.explicitMrWorkItemRelations
        ? this.mergeRequest?.workItemRelations?.nodes
        : this.mergeRequest?.linkedWorkItems;
      return (relations || []).filter((i) => i.workItem);
    },
    canAdminMergeRequest() {
      return this.mergeRequest?.userPermissions?.adminMergeRequest || false;
    },
    closingWorkItems() {
      return this.allItems
        .filter((i) => i.linkType === MR_WORK_ITEM_RELATIONSHIP_TYPES.closing)
        .map((i) => i.workItem);
    },
    relatedWorkItems() {
      return this.allItems
        .filter((i) => i.linkType === MR_WORK_ITEM_RELATIONSHIP_TYPES.related)
        .map((i) => i.workItem);
    },
    mentionedWorkItems() {
      return this.allItems
        .filter((i) => i.linkType === MR_WORK_ITEM_RELATIONSHIP_TYPES.mentioned)
        .map((i) => i.workItem);
    },
    showCollapsedState() {
      return this.allItems.length > 2;
    },
    collapsedSummary() {
      const parts = [];
      if (this.closingWorkItems.length > 0) {
        parts.push(`${__('Closing')} ${this.closingWorkItems.length}`);
      }
      if (this.relatedWorkItems.length > 0) {
        parts.push(`${__('Related')} ${this.relatedWorkItems.length}`);
      }
      if (this.mentionedWorkItems.length > 0) {
        parts.push(`${__('Mentioned')} ${this.mentionedWorkItems.length}`);
      }
      return parts.join(', ');
    },
  },
  watch: {
    params(newParams) {
      const item = this.allItems.find(
        (i) => getIdFromGraphQLId(i.workItem.id) === newParams.id,
      )?.workItem;
      if (item) {
        this.activeItem = item;
      } else {
        updateHistory({
          url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
        });
      }
    },
  },
  created() {
    window.addEventListener('popstate', this.checkDetailPanelParams);
  },
  beforeDestroy() {
    window.removeEventListener('popstate', this.checkDetailPanelParams);
  },
  methods: {
    async handleLink({ workItems = [], linkType } = {}) {
      if (!workItems.length) {
        this.isAddModalVisible = false;
        return;
      }

      try {
        const { data } = await this.$apollo.mutate({
          mutation: createMergeRequestWorkItemRelationMutation,
          variables: {
            projectPath: this.fullPath,
            iid: this.mergeRequest.iid,
            workItemIds: workItems.map((item) => item.id),
            linkType,
          },
          update: (cache, { data: result }) => this.updateLinkedWorkItemsCache(cache, result),
        });

        const errors = data?.mergeRequestCreateWorkItemRelations?.errors || [];
        if (errors.length) {
          createAlert({ message: errors.join(' ') });
          return;
        }

        /**
         * Close the modal only after a successful response so a failed link
         * keeps the modal open and the user can retry without reopening it.
         */
        this.isAddModalVisible = false;
        this.$toast.show(
          n__('WorkItem|Linked item added', 'WorkItem|Linked items added', workItems.length),
        );
      } catch (error) {
        createAlert({
          message: __('Something went wrong while linking the work item.'),
          error,
          captureError: true,
        });
      }
    },
    async handleCreated() {
      this.isAddModalVisible = false;

      /**
       * workItemCreate does not return the MergeRequestWorkItemRelation node
       * (id, fromMrDescription) that the query is keyed on, so refetch to pick
       * up the new relation.
       */
      await this.$apollo.queries.mergeRequest.refetch();

      /**
       * Show the toast only after the refetch has resolved, so a failed refetch
       * does not show a success message.
       */
      this.$toast.show(s__('WorkItem|Linked item added'));
    },
    updateLinkedWorkItemsCache(cache, result) {
      const created = result?.mergeRequestCreateWorkItemRelations?.workItemRelations || [];
      if (!created.length) {
        return;
      }

      const variables = {
        id: this.mergeRequestGid,
        explicitMrWorkItemRelations: Boolean(this.glFeatures.explicitMrWorkItemRelations),
      };

      const existing = cache.readQuery({ query: mergeRequestRelatedWorkItemsQuery, variables });
      if (!existing?.mergeRequest) {
        return;
      }

      if (this.glFeatures.explicitMrWorkItemRelations) {
        const existingNodes = existing.mergeRequest.workItemRelations?.nodes || [];
        const existingIds = new Set(existingNodes.map((node) => node.workItem?.id));
        const newNodes = created.filter(
          (relation) => relation.workItem && !existingIds.has(relation.workItem.id),
        );

        cache.writeQuery({
          query: mergeRequestRelatedWorkItemsQuery,
          variables,
          data: {
            mergeRequest: {
              ...existing.mergeRequest,
              workItemRelations: {
                __typename: 'MergeRequestWorkItemRelationConnection',
                nodes: [...existingNodes, ...newNodes],
              },
            },
          },
        });
        return;
      }

      const existingLinks = existing.mergeRequest.linkedWorkItems || [];
      const existingIds = new Set(existingLinks.map((link) => link.workItem?.id));
      const newLinks = created
        .filter((relation) => relation.workItem && !existingIds.has(relation.workItem.id))
        .map((relation) => ({
          __typename: 'LinkedWorkItem',
          linkType: relation.linkType,
          workItem: relation.workItem,
        }));

      cache.writeQuery({
        query: mergeRequestRelatedWorkItemsQuery,
        variables,
        data: {
          mergeRequest: {
            ...existing.mergeRequest,
            linkedWorkItems: [...existingLinks, ...newLinks],
          },
        },
      });
    },
    openDetailPanel(event, item) {
      if (event.metaKey || event.ctrlKey) {
        return;
      }
      event.preventDefault();
      this.activeItem = item;
    },
    checkDetailPanelParams() {
      const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);

      if (!queryParam) {
        this.activeItem = null;
        return;
      }

      this.parseDetailPanelParams(queryParam);
    },
    parseDetailPanelParams(queryParam) {
      try {
        this.params = JSON.parse(atob(queryParam));
      } catch {
        updateHistory({
          url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
        });
      }
    },
  },
};
</script>

<template>
  <div class="gl-leading-20 gl-text-default">
    <div class="gl-flex gl-items-center gl-font-bold gl-leading-24 gl-text-default">
      <span data-testid="title" class="hide-collapsed">{{ __('Work items') }}</span>
      <gl-loading-icon v-if="isLoading" size="sm" inline class="hide-collapsed gl-ml-2" />
      <div class="gl-ml-auto gl-flex gl-items-center gl-gap-1">
        <gl-icon
          v-if="!isLoading && allItems.length === 0"
          id="related-work-items-info"
          name="information-o"
          class="gl-cursor-pointer gl-text-subtle"
        />
        <gl-button
          v-if="canAdminMergeRequest"
          v-gl-tooltip
          :title="__('Add a work item')"
          :aria-label="__('Add a work item')"
          category="tertiary"
          icon="plus"
          size="small"
          class="!gl-p-0"
          data-testid="add-work-item-button"
          @click="isAddModalVisible = true"
        />
      </div>
      <gl-button
        v-if="showCollapsedState"
        v-show="!isCollapsed"
        v-gl-tooltip
        :title="__('Collapse work items')"
        :aria-label="__('Collapse work items')"
        category="tertiary"
        icon="chevron-down"
        size="small"
        :class="['-gl-mr-2 !gl-p-0', { 'gl-ml-auto': !canAdminMergeRequest }]"
        @click="isCollapsed = true"
      />
    </div>
    <template v-if="!isLoading && allItems.length > 0">
      <div v-if="showCollapsedState" v-show="isCollapsed" class="hide-collapsed gl-mt-2">
        <gl-link class="gl-text-sm !gl-text-link" @click="isCollapsed = false">
          {{ collapsedSummary }}
        </gl-link>
      </div>
      <gl-collapse :visible="!showCollapsedState || !isCollapsed" class="hide-collapsed">
        <div v-if="closingWorkItems.length > 0" class="gl-mt-2">
          <span class="gl-text-sm gl-font-bold gl-text-subtle">{{ __('Closing') }}</span>
          <ul class="gl-m-0 gl-list-none gl-p-0">
            <li v-for="item in closingWorkItems" :key="item.id" class="gl-mt-1">
              <gl-link
                :href="item.webPath"
                class="has-popover gl-block gl-truncate"
                data-reference-type="work_item"
                data-placement="top"
                :data-iid="item.iid"
                :data-project-path="item.namespace.fullPath"
                @click="openDetailPanel($event, item)"
              >
                {{ item.title }}
              </gl-link>
            </li>
          </ul>
        </div>
        <div v-if="relatedWorkItems.length > 0" class="gl-mt-3">
          <span class="gl-text-sm gl-font-bold gl-text-subtle">{{ __('Related') }}</span>
          <ul class="gl-m-0 gl-list-none gl-p-0">
            <li v-for="item in relatedWorkItems" :key="item.id" class="gl-mt-1">
              <gl-link
                :href="item.webPath"
                class="has-popover gl-block gl-truncate"
                data-reference-type="work_item"
                data-placement="top"
                :data-iid="item.iid"
                :data-project-path="item.namespace.fullPath"
                @click="openDetailPanel($event, item)"
              >
                {{ item.title }}
              </gl-link>
            </li>
          </ul>
        </div>
        <div v-if="mentionedWorkItems.length > 0" class="gl-mt-3">
          <span class="gl-text-sm gl-font-bold gl-text-subtle">{{ __('Mentioned') }}</span>
          <ul class="gl-m-0 gl-list-none gl-p-0">
            <li v-for="item in mentionedWorkItems" :key="item.id" class="gl-mt-1">
              <gl-link
                :href="item.webPath"
                class="has-popover gl-block gl-truncate"
                data-reference-type="work_item"
                data-placement="top"
                :data-iid="item.iid"
                :data-project-path="item.namespace.fullPath"
                @click="openDetailPanel($event, item)"
              >
                {{ item.title }}
              </gl-link>
            </li>
          </ul>
        </div>
      </gl-collapse>
    </template>
    <template v-else-if="!isLoading">
      <span class="hide-collapsed gl-text-subtle">{{ __('None') }}</span>
      <gl-popover target="related-work-items-info" placement="top">
        <template #title>{{ __('Work item links') }}</template>
        <gl-sprintf
          :message="
            __(
              'To link work items, you can add %{linkStart}closing patterns%{linkEnd} to the description.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              href="https://docs.gitlab.com/user/project/issues/managing_issues/#closing-issues-automatically"
              target="_blank"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </gl-popover>
    </template>
    <work-item-detail-panel
      :active-item="activeItem"
      :view-context="$options.viewContext"
      :open="activeItem !== null"
      issuable-type="Issue"
      @close="activeItem = null"
    />
    <related-work-items-add-form
      v-if="canAdminMergeRequest"
      :full-path="fullPath"
      :merge-request-id="mergeRequestGid"
      :merge-request-title="mergeRequest.title"
      :merge-request-reference="mergeRequest.reference"
      :visible="isAddModalVisible"
      @hide="isAddModalVisible = false"
      @link="handleLink"
      @created="handleCreated"
    />
  </div>
</template>
