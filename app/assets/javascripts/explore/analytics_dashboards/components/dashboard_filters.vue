<script>
import { GlFormGroup } from '@gitlab/ui';
import { s__ } from '~/locale';
import DateRangeFilter from './date_range_filter.vue';
import GroupsFilter from './groups_filter.vue';
import ProjectsFilter from './projects_filter.vue';
import { DATE_RANGE_OPTION_LAST_30_DAYS } from './constants';

export default {
  name: 'DashboardFilters',
  components: {
    GlFormGroup,
    DateRangeFilter,
    GroupsFilter,
    ProjectsFilter,
  },
  i18n: {
    region: s__('AnalyticsDashboards|Dashboard filters'),
    groupsLabel: s__('AnalyticsDashboards|Groups'),
    projectsLabel: s__('AnalyticsDashboards|Projects'),
    dateRangeLabel: s__('AnalyticsDashboards|Date range'),
  },
  props: {
    groupNamespace: {
      type: String,
      required: true,
    },
  },
  emits: ['set-date-range', 'set-projects', 'set-groups'],
  DATE_RANGE_OPTION_LAST_30_DAYS,
};
</script>
<template>
  <div
    data-testid="dashboard-filters"
    role="group"
    :aria-label="$options.i18n.region"
    class="gl-flex gl-flex-col gl-gap-3 md:gl-flex-row"
  >
    <gl-form-group :label="$options.i18n.groupsLabel">
      <groups-filter @group-selected="$emit('set-groups', $event)" />
    </gl-form-group>
    <gl-form-group class="gl-full-w" :label="$options.i18n.projectsLabel">
      <projects-filter
        :group-namespace="groupNamespace"
        :disabled="!groupNamespace"
        @project-selected="$emit('set-projects', $event)"
      />
    </gl-form-group>
    <gl-form-group :label="$options.i18n.dateRangeLabel">
      <date-range-filter
        :default-option="$options.DATE_RANGE_OPTION_LAST_30_DAYS"
        @change="$emit('set-date-range', $event)"
      />
    </gl-form-group>
  </div>
</template>
