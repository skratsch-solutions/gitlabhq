import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDashboardLayout, GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ExploreAnalyticsDashboard from '~/explore/analytics_dashboards/pages/details.vue';
import DashboardFilters from '~/explore/analytics_dashboards/components/dashboard_filters.vue';
import DashboardSettingsDrawer from '~/explore/analytics_dashboards/components/dashboard_settings_drawer.vue';
import DashboardLoader from '~/explore/analytics_dashboards/components/dashboard_loader.vue';
import getDashboardQuery from '~/explore/analytics_dashboards/graphql/get_dashboard.query.graphql';
import { mockDashboardResponse } from '../mock_data';

Vue.use(VueApollo);

describe('ExploreAnalyticsDashboard', () => {
  let wrapper;

  const mockBreadcrumbState = { name: '', updateName: jest.fn() };

  const mockResolvedQuery = (queryResponse = mockDashboardResponse) =>
    createMockApollo([[getDashboardQuery, jest.fn().mockResolvedValue({ data: queryResponse })]]);

  const createComponent = ({
    requestHandlers,
    props = {},
    routeParams = { slug: '3' },
    stubs = {},
  } = {}) => {
    wrapper = shallowMountExtended(ExploreAnalyticsDashboard, {
      propsData: props,
      apolloProvider: requestHandlers || mockResolvedQuery(),
      provide: { breadcrumbState: mockBreadcrumbState },
      mocks: { $route: { params: routeParams } },
      stubs: { DashboardLoader, ...stubs },
    });
  };

  const findDashboardLayout = () => wrapper.findComponent(GlDashboardLayout);
  const findDashboardFilters = () => wrapper.findComponent(DashboardFilters);
  const findAddPanelButton = () => wrapper.findByTestId('dashboard-add-panel-button');
  const findSettingsButton = () => wrapper.findByTestId('dashboard-settings-button');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findSettingsDrawer = () => wrapper.findComponent(DashboardSettingsDrawer);

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('dashboard filters', () => {
    const dashboardLoaderSlotStub = {
      template: `
        <div>
          <slot name="dashboard" :config="{ panels: [] }" :cell-height="undefined" :min-cell-height="undefined" :has-panels="false" />
        </div>
      `,
    };

    const filtersSlotStub = {
      props: ['filters'],
      template: '<div><slot name="filters" /></div>',
    };

    beforeEach(async () => {
      createComponent({
        stubs: { DashboardLoader: dashboardLoaderSlotStub, GlDashboardLayout: filtersSlotStub },
      });
      await waitForPromises();
    });

    it('passes an empty groupNamespace to dashboard-filters by default', () => {
      expect(findDashboardFilters().props('groupNamespace')).toBe('');
    });

    it('passes an empty filters object to the dashboard layout by default', () => {
      expect(findDashboardLayout().props('filters')).toEqual({});
    });

    describe('when dashboard-filters emits set-groups with a group', () => {
      const group = { id: 1, fullPath: 'gitlab-org' };

      beforeEach(async () => {
        findDashboardFilters().vm.$emit('set-groups', [group]);
        await waitForPromises();
      });

      it('updates the groupNamespace prop passed back to dashboard-filters', () => {
        expect(findDashboardFilters().props('groupNamespace')).toBe(group.fullPath);
      });

      it('passes the selected group full path to the dashboard layout filters', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject({
          groups: [group.fullPath],
          projects: [],
        });
      });
    });

    describe('when dashboard-filters emits set-projects with a project', () => {
      const project = { id: 2, fullPath: 'gitlab-org/gitlab' };

      beforeEach(async () => {
        findDashboardFilters().vm.$emit('set-projects', [project]);
        await waitForPromises();
      });

      it('passes the selected project full path to the dashboard layout filters', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject({
          projects: [project.fullPath],
        });
      });
    });

    describe('when dashboard-filters emits set-projects with an empty list', () => {
      beforeEach(async () => {
        findDashboardFilters().vm.$emit('set-projects', []);
        await waitForPromises();
      });

      it('clears the projects on the dashboard layout filters', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject({ projects: [] });
      });
    });

    describe('when dashboard-filters emits set-date-range', () => {
      const dateRange = {
        dateRangeOption: 'custom',
        startDate: new Date('2026-01-01'),
        endDate: new Date('2026-01-31'),
      };

      beforeEach(async () => {
        findDashboardFilters().vm.$emit('set-date-range', dateRange);
        await waitForPromises();
      });

      it('passes the date range to the dashboard layout filters', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject(dateRange);
      });
    });
  });

  describe('when editing', () => {
    beforeEach(async () => {
      createComponent({ props: { isEditing: true } });
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

  describe('when not editing', () => {
    beforeEach(async () => {
      createComponent({ props: { isEditing: false } });
      await waitForPromises();
    });

    it('does not show the Add Panel button', () => {
      expect(findAddPanelButton().exists()).toBe(false);
    });

    it('does not show the Settings cog button', () => {
      expect(findSettingsButton().exists()).toBe(false);
    });

    it('does not render the settings drawer', () => {
      expect(findSettingsDrawer().exists()).toBe(false);
    });
  });

  describe('empty state', () => {
    it('does not show when there are panels', async () => {
      createComponent({ props: { isEditing: true } });
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
        props: { isEditing: true },
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
      createComponent({ props: { isEditing: true } });
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
