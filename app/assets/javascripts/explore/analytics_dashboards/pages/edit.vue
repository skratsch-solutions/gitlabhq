<script>
import { GlDashboardLayout, GlButton, GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import DashboardLoader from '../components/dashboard_loader.vue';
import DashboardSettingsDrawer from '../components/dashboard_settings_drawer.vue';

export default {
  name: 'ExploreAnalyticsDashboardEdit',
  components: {
    GlDashboardLayout,
    GlButton,
    GlEmptyState,
    DashboardLoader,
    DashboardSettingsDrawer,
  },
  data() {
    return {
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
      >
        <template #actions>
          <div class="gl-flex gl-gap-2">
            <gl-button icon="plus" data-testid="dashboard-add-panel-button">{{
              $options.i18n.addPanel
            }}</gl-button>
            <gl-button
              icon="settings"
              :aria-label="s__('AnalyticsDashboards|Settings')"
              data-testid="dashboard-settings-button"
              @click="openSettingsDrawer"
            />
          </div>
        </template>

        <template #empty-state>
          <div
            v-if="!hasPanels"
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
        :dashboard-id="dashboardId"
        :dashboard-config="config"
        :open="isSettingsDrawerOpen"
        @close="closeSettingsDrawer"
      />
    </template>
  </dashboard-loader>
</template>
