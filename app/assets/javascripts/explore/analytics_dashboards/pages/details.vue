<script>
import { GlDashboardLayout, GlSkeletonLoader } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import {
  GRID_HEIGHT_COMPACT,
  GRID_HEIGHT_COMPACT_CELL_HEIGHT,
  GRID_HEIGHT_COMPACT_MIN_CELL_HEIGHT,
} from '../constants';
import { getUniquePanelId, convertToDashboardGraphQLId } from '../utils';
import getDashboardQuery from '../graphql/get_dashboard.query.graphql';
import DashboardFilters from '../components/dashboard_filters.vue';

export default {
  name: 'ExploreAnalyticsDashboard',
  components: { GlDashboardLayout, GlSkeletonLoader, DashboardFilters },
  inject: ['breadcrumbState'],
  data() {
    return {
      dashboard: null,
      filters: {},
      selectedGroup: null,
      selectedProject: null,
    };
  },
  computed: {
    dashboardId() {
      return convertToDashboardGraphQLId(this.$route?.params.slug);
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
      query: getDashboardQuery,
      variables() {
        return { id: this.dashboardId };
      },
      update({ customDashboard = {} }) {
        return customDashboard;
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
    </gl-dashboard-layout>
  </div>
</template>
