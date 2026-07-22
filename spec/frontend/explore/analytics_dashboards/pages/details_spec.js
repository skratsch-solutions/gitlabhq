import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlDashboardLayout, GlTabs, GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ExploreAnalyticsDashboard from '~/explore/analytics_dashboards/pages/details.vue';
import DashboardFilters from '~/explore/analytics_dashboards/components/dashboard_filters.vue';
import DashboardLoader from '~/explore/analytics_dashboards/components/dashboard_loader.vue';
import getDashboardQuery from '~/explore/analytics_dashboards/graphql/get_dashboard.query.graphql';
import { mockDashboardResponse } from '../mock_data';

Vue.use(VueApollo);

describe('ExploreAnalyticsDashboardDetails', () => {
  let wrapper;

  const mockBreadcrumbState = { name: '', slug: '', update: jest.fn() };

  const mockResolvedQuery = (queryResponse = mockDashboardResponse) =>
    createMockApollo([[getDashboardQuery, jest.fn().mockResolvedValue({ data: queryResponse })]]);

  const createComponent = ({ requestHandlers, routeParams = { slug: '3' }, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(ExploreAnalyticsDashboard, {
      apolloProvider: requestHandlers || mockResolvedQuery(),
      provide: { breadcrumbState: mockBreadcrumbState },
      mocks: { $route: { params: routeParams } },
      stubs: { DashboardLoader, ...stubs },
    });
  };

  const findDashboardLayout = () => wrapper.findComponent(GlDashboardLayout);
  const findDashboardFilters = () => wrapper.findComponent(DashboardFilters);
  const findViewsTabs = () => wrapper.findComponent(GlTabs);
  const findViewTabs = () => wrapper.findAllComponents(GlTab);

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

  describe('dashboard views', () => {
    const overviewPanels = [{ id: 'panel-1', title: 'Overview panel' }];
    const detailsPanels = [
      { id: 'panel-2', title: 'Details panel one' },
      { id: 'panel-3', title: 'Details panel two' },
    ];
    const configWithViews = {
      panels: [],
      views: [
        { title: 'Overview', panels: overviewPanels },
        { title: 'Details', panels: detailsPanels },
      ],
    };

    const dashboardLoaderSlotStub = (config) => ({
      data() {
        return { slotConfig: config };
      },
      template: `
        <div>
          <slot name="dashboard" :config="slotConfig" :cell-height="undefined" :min-cell-height="undefined" />
        </div>
      `,
    });

    const filtersSlotStub = {
      props: ['config'],
      template: '<div><slot name="filters" /></div>',
    };

    const createWithConfig = async (config) => {
      createComponent({
        stubs: {
          DashboardLoader: dashboardLoaderSlotStub(config),
          GlDashboardLayout: filtersSlotStub,
        },
      });
      await waitForPromises();
    };

    describe('when the dashboard defines views', () => {
      beforeEach(() => createWithConfig(configWithViews));

      it('renders a tab for each view', () => {
        expect(findViewsTabs().exists()).toBe(true);
        expect(findViewTabs().wrappers.map((tab) => tab.attributes('title'))).toEqual([
          'Overview',
          'Details',
        ]);
      });

      it('feeds the first view panels to the layout by default', () => {
        expect(findDashboardLayout().props('config').panels).toEqual(overviewPanels);
      });

      it('feeds the selected view panels to the layout when switching views', async () => {
        findViewsTabs().vm.$emit('input', 1);
        await waitForPromises();

        expect(findDashboardLayout().props('config').panels).toEqual(detailsPanels);
      });
    });

    describe('when the dashboard has no views', () => {
      beforeEach(() => createWithConfig({ panels: overviewPanels }));

      it('does not render the views tabs', () => {
        expect(findViewsTabs().exists()).toBe(false);
      });

      it('passes the dashboard config through to the layout unchanged', () => {
        expect(findDashboardLayout().props('config').panels).toEqual(overviewPanels);
      });
    });
  });
});
