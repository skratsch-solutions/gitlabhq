import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ExploreAnalyticsDashboardEdit from '~/explore/analytics_dashboards/pages/edit.vue';
import DashboardSettingsDrawer from '~/explore/analytics_dashboards/components/dashboard_settings_drawer.vue';
import DashboardLoader from '~/explore/analytics_dashboards/components/dashboard_loader.vue';
import getDashboardQuery from '~/explore/analytics_dashboards/graphql/get_dashboard.query.graphql';
import { mockDashboardResponse } from '../mock_data';

Vue.use(VueApollo);

describe('ExploreAnalyticsDashboardEdit', () => {
  let wrapper;

  const mockBreadcrumbState = { name: '', updateName: jest.fn() };

  const mockResolvedQuery = (queryResponse = mockDashboardResponse) =>
    createMockApollo([[getDashboardQuery, jest.fn().mockResolvedValue({ data: queryResponse })]]);

  const createComponent = ({ requestHandlers } = {}) => {
    wrapper = shallowMountExtended(ExploreAnalyticsDashboardEdit, {
      apolloProvider: requestHandlers || mockResolvedQuery(),
      provide: { breadcrumbState: mockBreadcrumbState },
      mocks: { $route: { params: { slug: '3' } } },
      stubs: { DashboardLoader },
    });
  };

  const findAddPanelButton = () => wrapper.findByTestId('dashboard-add-panel-button');
  const findSettingsButton = () => wrapper.findByTestId('dashboard-settings-button');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findSettingsDrawer = () => wrapper.findComponent(DashboardSettingsDrawer);

  describe('actions', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('shows the Add Panel button', () => {
      expect(findAddPanelButton().exists()).toBe(true);
      expect(findAddPanelButton().text()).toContain('Add panel');
    });

    it('shows the Settings cog button', () => {
      expect(findSettingsButton().exists()).toBe(true);
      expect(findSettingsButton().attributes('icon')).toBe('settings');
    });
  });

  describe('empty state', () => {
    it('does not show when there are panels', async () => {
      createComponent();
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(false);
    });

    it('shows when there are no panels', async () => {
      const emptyDashboardResponse = {
        customDashboard: {
          ...mockDashboardResponse.customDashboard,
          config: {
            ...mockDashboardResponse.customDashboard.config,
            panels: [],
          },
        },
      };

      createComponent({
        requestHandlers: mockResolvedQuery(emptyDashboardResponse),
      });
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props()).toMatchObject({
        title: 'Start building your dashboard',
        description: 'Add panels to this dashboard to visualize your analytics data.',
        illustrationName: 'empty-epic-md',
      });
    });
  });

  describe('settings drawer', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the settings drawer', () => {
      expect(findSettingsDrawer().exists()).toBe(true);
    });

    it('passes the correct props to the settings drawer', () => {
      expect(findSettingsDrawer().props()).toMatchObject({
        open: false,
        dashboardConfig: expect.any(Object),
        dashboardId: 'gid://gitlab/Analytics::CustomDashboards::Dashboard/3',
      });
    });

    describe('when the settings button is clicked', () => {
      beforeEach(async () => {
        findSettingsButton().vm.$emit('click');
        await nextTick();
      });

      it('opens the settings drawer', () => {
        expect(findSettingsDrawer().props('open')).toBe(true);
      });

      describe('when the settings drawer emits close', () => {
        beforeEach(async () => {
          findSettingsDrawer().vm.$emit('close');
          await nextTick();
        });

        it('closes the settings drawer', () => {
          expect(findSettingsDrawer().props('open')).toBe(false);
        });
      });
    });
  });
});
