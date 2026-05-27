import { GlButton } from '@gitlab/ui';
import DashboardSettingsDrawer from './dashboard_settings_drawer.vue';

export default {
  component: DashboardSettingsDrawer,
  title: 'explore/analytics_dashboards/components/dashboard_settings_drawer',
};

const Template = (args, { argTypes }) => ({
  components: { DashboardSettingsDrawer, GlButton },
  props: Object.keys(argTypes),
  data() {
    return {
      isDrawerOpen: false,
    };
  },
  provide: {
    exploreAnalyticsDashboardsPath: '/explore/analytics_dashboards',
  },
  template: `
    <div>
      <gl-button @click="isDrawerOpen = true">Open Settings</gl-button>
      <dashboard-settings-drawer
        :open="isDrawerOpen"
        v-bind="$props"
        @close="isDrawerOpen = false"
      />
    </div>
  `,
});

const defaultArgs = {
  dashboardId: '1',
  dashboardConfig: {
    title: 'Sample Dashboard',
    description: 'This is a sample dashboard for testing',
  },
};

export const Default = Template.bind({});
Default.args = defaultArgs;
