<script>
import { GlDashboardLayout } from '@gitlab/ui';
import DashboardFilters from '../components/dashboard_filters.vue';
import DashboardLoader from '../components/dashboard_loader.vue';

export default {
  name: 'ExploreAnalyticsDashboard',
  components: {
    GlDashboardLayout,
    DashboardFilters,
    DashboardLoader,
  },
  data() {
    return {
      filters: {},
      selectedGroup: null,
      selectedProject: null,
    };
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
};
</script>
<template>
  <dashboard-loader>
    <template #dashboard="{ config, cellHeight, minCellHeight }">
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
      </gl-dashboard-layout>
    </template>
  </dashboard-loader>
</template>
