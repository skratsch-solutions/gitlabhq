<script>
import GITLAB_LOGO_SVG_URL from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?url';
import {
  GlTable,
  GlAvatarLabeled,
  GlAvatarLink,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime/timeago_utility';
import DashboardDeleteModal from './dashboard_delete_modal.vue';
import DashboardsListNameCell from './dashboards_list_name_cell.vue';

export default {
  name: 'DashboardsList',
  components: {
    GlTable,
    GlAvatarLabeled,
    GlAvatarLink,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    DashboardsListNameCell,
    DashboardDeleteModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    dashboards: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      deleteDashboardId: '',
    };
  },
  methods: {
    showDeleteModal(id) {
      this.deleteDashboardId = id;
      this.$refs.deleteModal.show();
    },
    formatUpdatedAt(updatedAt) {
      return getTimeago().format(updatedAt);
    },
  },
  actions: {
    items: [
      {
        text: __('Edit'),
        action: () => {},
      },
      {
        text: __('Make a copy'),
        action: () => {},
      },
      {
        text: __('Share'),
        action: () => {},
      },
    ],
  },
  avatarSize: 24,
  fields: [
    {
      key: 'name',
      label: __('Title'),
    },
    {
      key: 'createdBy',
      label: __('Created by'),
      tdClass: '!gl-align-bottom',
    },
    {
      key: 'updatedAt',
      label: __('Last edited'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'actions',
      tdClass: '!gl-text-right',
      label: __('Actions'),
    },
  ],
  createdByGitLab: {
    avatarUrl: GITLAB_LOGO_SVG_URL,
    label: __('GitLab'),
  },
};
</script>
<template>
  <div>
    <dashboard-delete-modal ref="deleteModal" :dashboard-id="deleteDashboardId" />

    <gl-table stacked="sm" :items="dashboards" :fields="$options.fields">
      <template #head(actions)="column"
        ><span class="gl-sr-only">{{ column.label }}</span></template
      >
      <template #cell(name)="{ item: { name, isStarred, description, dashboardUrl } }">
        <dashboards-list-name-cell
          :name="name"
          :description="description"
          :is-starred="isStarred"
          :dashboard-url="dashboardUrl"
        />
      </template>
      <template #cell(createdBy)="{ item: { createdBy, system } }">
        <gl-avatar-labeled
          v-if="system"
          :src="$options.createdByGitLab.avatarUrl"
          :size="$options.avatarSize"
          :label="$options.createdByGitLab.label"
          shape="circle"
          fallback-on-error
        />
        <gl-avatar-link v-else target="_blank" :href="createdBy.webPath">
          <gl-avatar-labeled
            :src="createdBy.avatarUrl"
            :size="$options.avatarSize"
            :label="createdBy.name"
            shape="circle"
            fallback-on-error
          />
        </gl-avatar-link>
      </template>
      <template #cell(updatedAt)="{ item: { system, updatedAt } }">
        <span v-if="!system" data-testid="dashboard-updated-at">{{
          formatUpdatedAt(updatedAt)
        }}</span>
      </template>
      <template #cell(actions)="{ field, item }">
        <gl-disclosure-dropdown
          v-gl-tooltip.hover
          icon="ellipsis_v"
          category="tertiary"
          :title="field.label"
          no-caret
          left
          data-testid="dashboard-actions"
          toggle-text="More actions"
          text-sr-only
        >
          <gl-disclosure-dropdown-group :group="$options.actions" />
          <gl-disclosure-dropdown-group v-if="!item.system" bordered>
            <gl-disclosure-dropdown-item
              variant="danger"
              data-testid="dashboard-delete-action"
              @action="showDeleteModal(item.id)"
            >
              <template #list-item>
                {{ __('Delete') }}
              </template>
            </gl-disclosure-dropdown-item>
          </gl-disclosure-dropdown-group>
        </gl-disclosure-dropdown>
      </template>
    </gl-table>
  </div>
</template>
