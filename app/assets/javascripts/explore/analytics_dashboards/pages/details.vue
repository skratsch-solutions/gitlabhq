<script>
import { GlDashboardLayout, GlSkeletonLoader, GlButton, GlEmptyState } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { isNumeric } from '~/lib/utils/number_utils';
import { s__ } from '~/locale';
import {
  GRID_HEIGHT_COMPACT,
  GRID_HEIGHT_COMPACT_CELL_HEIGHT,
  GRID_HEIGHT_COMPACT_MIN_CELL_HEIGHT,
} from '../constants';
import { getUniquePanelId, convertToDashboardGraphQLId } from '../utils';
import getDashboardQuery from '../graphql/get_dashboard.query.graphql';
import DashboardFilters from '../components/dashboard_filters.vue';
import getSystemDashboardQuery from '../graphql/get_system_dashboard.query.graphql';

export default {
  name: 'ExploreAnalyticsDashboard',
  components: { GlDashboardLayout, GlSkeletonLoader, GlButton, GlEmptyState, DashboardFilters },
  inject: ['breadcrumbState'],
  props: {
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      dashboard: null,
      filters: {},
      selectedGroup: null,
      selectedProject: null,
    };
  },
  computed: {
    slug() {
      return this.$route?.params.slug;
    },
    isSystemDashboard() {
      // Custom dashboards are routed by their numeric ID; system dashboards by their slug.
      return !isNumeric(this.slug);
    },
    dashboardId() {
      return this.isSystemDashboard ? this.slug : convertToDashboardGraphQLId(this.slug);
    },
    dashboardConfig() {
      if (!this.dashboard?.config) return {};
      // Each panel needs a uniqueId or the prop validator for GlDashboardLayout will fail
      const { panels, ...rest } = this.dashboard.config;
      return {
        ...rest,
        panels: panels.map(({ id, ...panel }) => ({
          ...panel,
          id: getUniquePanelId(),
        })),
      };
    },
    isLoading() {
      return Boolean(this.$apollo.queries.dashboard?.loading);
    },
    cellHeight() {
      return this.dashboardConfig?.gridHeight === GRID_HEIGHT_COMPACT
        ? GRID_HEIGHT_COMPACT_CELL_HEIGHT
        : undefined;
    },
    minCellHeight() {
      return this.dashboardConfig?.gridHeight === GRID_HEIGHT_COMPACT
        ? GRID_HEIGHT_COMPACT_MIN_CELL_HEIGHT
        : undefined;
    },
    hasPanels() {
      return this.dashboardConfig.panels.length > 0;
    },
  },
  watch: {
    dashboard() {
      this.breadcrumbState.updateName(this.dashboardConfig?.title);
    },
  },
  methods: {
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
  apollo: {
    dashboard: {
      query() {
        return this.isSystemDashboard ? getSystemDashboardQuery : getDashboardQuery;
      },
      variables() {
        if (this.isSystemDashboard) {
          return { slug: this.dashboardId };
        }
        return { id: this.dashboardId };
      },
      update({ customDashboard = {}, customSystemDashboard = {} }) {
        return this.isSystemDashboard ? customSystemDashboard : customDashboard;
      },
      error(err) {
        createAlert({
          message: s__('AnalyticsDashboards|Failed to load dashboard. Please try again.'),
          captureError: true,
          error: err,
        });
      },
    },
  },
  i18n: {
    addPanel: s__('AnalyticsDashboards|Add panel'),
  },
};
</script>
<template>
  <gl-skeleton-loader v-if="isLoading" />
  <div v-else>
    <gl-dashboard-layout
      :config="dashboardConfig"
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
  </div>
</template>
