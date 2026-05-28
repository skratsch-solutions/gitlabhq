<script>
import { GlDashboardLayout, GlButton, GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import DashboardFilters from '../components/dashboard_filters.vue';
import DashboardLoader from '../components/dashboard_loader.vue';
import DashboardSettingsDrawer from '../components/dashboard_settings_drawer.vue';

export default {
  name: 'ExploreAnalyticsDashboard',
  components: {
    GlDashboardLayout,
    GlButton,
    GlEmptyState,
    DashboardFilters,
    DashboardLoader,
    DashboardSettingsDrawer,
  },
  props: {
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      filters: {},
      selectedGroup: null,
      selectedProject: null,
      isSettingsDrawerOpen: false,
    };
  },
  methods: {
    openSettingsDrawer() {
      this.isSettingsDrawerOpen = true;
    },
    closeSettingsDrawer() {
      this.isSettingsDrawerOpen = false;
    },
    setDateRangeFilter({ dateRangeOption, startDate, endDate }) {
      this.filters = {
        ...this.filters,
        dateRangeOption,
        startDate,
        endDate,
      };
    },
    setProjectsFilter(projects) {
      const [project = null] = projects ?? [];
      this.selectedProject = project;
      this.filters = {
        ...this.filters,
        projects: project ? [project.fullPath] : [],
      };
    },
    setGroupsFilter(groups) {
      const [group = null] = groups ?? [];
      this.selectedGroup = group;
      // Clearing a group also clears the project (which lives under it).
      if (!group) {
        this.selectedProject = null;
      }
      this.filters = {
        ...this.filters,
        groups: group ? [group.fullPath] : [],
        projects: [],
      };
    },
  },
  i18n: {
    addPanel: s__('AnalyticsDashboards|Add panel'),
  },
};
</script>
<template>
  <dashboard-loader>
    <template #dashboard="{ dashboardId, config, hasPanels, cellHeight, minCellHeight }">
      <gl-dashboard-layout
        :config="config"
        :cell-height="cellHeight"
        :min-cell-height="minCellHeight"
        :filters="filters"
      >
        <template #filters>
          <dashboard-filters
            :group-namespace="selectedGroup?.fullPath || ''"
            @set-date-range="setDateRangeFilter"
            @set-projects="setProjectsFilter"
            @set-groups="setGroupsFilter"
          />
        </template>

        <template #actions>
          <div v-if="isEditing" class="gl-flex gl-gap-2">
            <gl-button icon="plus" data-testid="dashboard-add-panel-button">{{
              $options.i18n.addPanel
            }}</gl-button>
            <gl-button
              icon="settings"
              :title="s__('AnalyticsDashboards|Settings')"
              data-testid="dashboard-settings-button"
              @click="openSettingsDrawer"
            />
          </div>
        </template>

        <template #empty-state>
          <div
            v-if="isEditing && !hasPanels"
            class="gl-border gl-w-full gl-rounded-base gl-border-dashed gl-py-13"
          >
            <gl-empty-state
              :title="s__('AnalyticsDashboards|Start building your dashboard')"
              :description="
                s__(
                  'AnalyticsDashboards|Add panels to this dashboard to visualize your analytics data.',
                )
              "
              illustration-name="empty-epic-md"
            >
              <template #actions>
                <gl-button variant="confirm" icon="plus">{{ $options.i18n.addPanel }}</gl-button>
              </template>
            </gl-empty-state>
          </div>
        </template>
      </gl-dashboard-layout>

      <dashboard-settings-drawer
        v-if="isEditing"
        :dashboard-id="dashboardId"
        :dashboard-config="config"
        :open="isSettingsDrawerOpen"
        @close="closeSettingsDrawer"
      />
    </template>
  </dashboard-loader>
</template>
