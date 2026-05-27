import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDashboardLayout, GlSkeletonLoader, GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import ExploreAnalyticsDashboard from '~/explore/analytics_dashboards/pages/details.vue';
import DashboardFilters from '~/explore/analytics_dashboards/components/dashboard_filters.vue';
import DashboardSettingsDrawer from '~/explore/analytics_dashboards/components/dashboard_settings_drawer.vue';
import getDashboardQuery from '~/explore/analytics_dashboards/graphql/get_dashboard.query.graphql';
import getSystemDashboardQuery from '~/explore/analytics_dashboards/graphql/get_system_dashboard.query.graphql';
import {
  mockDashboardResponse,
  mockDashboardCompactGridResponse,
  mockSystemDashboardResponse,
} from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('ExploreAnalyticsDashboard', () => {
  let wrapper;

  const defaultPropsData = {
    currentUserId: 1,
  };

  const mockBreadcrumbState = { name: '', updateName: jest.fn() };

  const mockResolvedQuery = (queryResponse = mockDashboardResponse) =>
    createMockApollo([[getDashboardQuery, jest.fn().mockResolvedValue({ data: queryResponse })]]);

  const mockRejectedQuery = () =>
    createMockApollo([
      [getDashboardQuery, jest.fn().mockRejectedValue(new Error('Network error'))],
    ]);

  const createComponent = ({
    requestHandlers,
    props = {},
    routeParams = { slug: '3' },
    routeMeta = { system: false },
    stubs = {},
  } = {}) => {
    wrapper = shallowMountExtended(ExploreAnalyticsDashboard, {
      propsData: { ...defaultPropsData, ...props },
      apolloProvider: requestHandlers || mockResolvedQuery(),
      provide: { breadcrumbState: mockBreadcrumbState },
      mocks: { $route: { params: routeParams, meta: routeMeta } },
      stubs,
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findDashboardLayout = () => wrapper.findComponent(GlDashboardLayout);
  const findDashboardFilters = () => wrapper.findComponent(DashboardFilters);
  const findAddPanelButton = () => wrapper.findByTestId('dashboard-add-panel-button');
  const findSettingsButton = () => wrapper.findByTestId('dashboard-settings-button');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findSettingsDrawer = () => wrapper.findComponent(DashboardSettingsDrawer);

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('while the query is loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render the dashboard layout', () => {
      expect(findDashboardLayout().exists()).toBe(false);
    });
  });

  describe('with data loaded', () => {
    const { config } = mockDashboardResponse.customDashboard;

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('does not render the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('renders the dashboard layout', () => {
      expect(findDashboardLayout().exists()).toBe(true);
    });

    it('passes the dashboard config to the layout', () => {
      expect(findDashboardLayout().props('config').title).toBe(config.title);
    });

    it('replaces original panel ids with unique ids', () => {
      const { panels } = findDashboardLayout().props('config');

      panels.forEach((panel, idx) => {
        expect(panel.id).toBe(`panel-${idx + 1}`);
        expect(panel.id).not.toBe(`panel-original-${idx + 1}`);
      });
    });

    it('does not set cellHeight for a non-compact grid', () => {
      expect(findDashboardLayout().props('cellHeight')).toBe(137);
    });

    it('does not set minCellHeight for a non-compact grid', () => {
      expect(findDashboardLayout().props('minCellHeight')).toBe(1);
    });

    it('updates the breadcrumb state with the dashboard title', () => {
      expect(mockBreadcrumbState.updateName).toHaveBeenCalledWith(config.title);
    });
  });

  describe('with a compact grid height', () => {
    beforeEach(async () => {
      createComponent({ requestHandlers: mockResolvedQuery(mockDashboardCompactGridResponse) });
      await waitForPromises();
    });

    it('sets cellHeight to 10', () => {
      expect(findDashboardLayout().props('cellHeight')).toBe(10);
    });

    it('sets minCellHeight to 10', () => {
      expect(findDashboardLayout().props('minCellHeight')).toBe(10);
    });
  });

  describe('dashboard filters', () => {
    const filtersSlotStub = {
      props: ['filters'],
      template: '<div><slot name="filters" /></div>',
    };

    beforeEach(async () => {
      createComponent({ stubs: { GlDashboardLayout: filtersSlotStub } });
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

  describe('with a query error', () => {
    beforeEach(async () => {
      createComponent({ requestHandlers: mockRejectedQuery() });
      await waitForPromises();
    });

    it('shows an error alert', () => {
      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Failed to load dashboard. Please try again.',
          captureError: true,
        }),
      );
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

  describe('when the route is a system dashboard', () => {
    let customQueryHandler;
    let systemQueryHandler;

    const createSystemComponent = ({ slug = 'merge_requests' } = {}) => {
      customQueryHandler = jest.fn().mockResolvedValue({ data: mockDashboardResponse });
      systemQueryHandler = jest.fn().mockResolvedValue({ data: mockSystemDashboardResponse });

      const apolloProvider = createMockApollo([
        [getDashboardQuery, customQueryHandler],
        [getSystemDashboardQuery, systemQueryHandler],
      ]);

      createComponent({
        requestHandlers: apolloProvider,
        routeParams: { slug },
      });
    };

    beforeEach(async () => {
      createSystemComponent();
      await waitForPromises();
    });

    it('uses the system dashboard query', () => {
      expect(systemQueryHandler).toHaveBeenCalledWith({ slug: 'merge_requests' });
    });

    it('does not call the custom dashboard query', () => {
      expect(customQueryHandler).not.toHaveBeenCalled();
    });

    it('does not convert the slug into a GraphQL ID', () => {
      expect(systemQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({ slug: 'merge_requests' }),
      );
      expect(systemQueryHandler).not.toHaveBeenCalledWith(
        expect.objectContaining({ slug: expect.stringContaining('gid://') }),
      );
    });

    it('renders the system dashboard config in the layout', () => {
      expect(wrapper.findComponent(GlDashboardLayout).props('config').title).toBe(
        mockSystemDashboardResponse.customSystemDashboard.config.title,
      );
    });
  });

  describe('when the system dashboard does not exist', () => {
    let systemQueryHandler;

    beforeEach(async () => {
      systemQueryHandler = jest.fn().mockResolvedValue({ data: { customSystemDashboard: null } });

      const apolloProvider = createMockApollo([[getSystemDashboardQuery, systemQueryHandler]]);

      createComponent({
        requestHandlers: apolloProvider,
        routeParams: { slug: 'does_not_exist' },
      });

      await waitForPromises();
    });

    it('queries the system dashboard endpoint with the slug', () => {
      expect(systemQueryHandler).toHaveBeenCalledWith({ slug: 'does_not_exist' });
    });

    it('does not show an error alert', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('renders the dashboard layout with an empty config', () => {
      expect(findDashboardLayout().exists()).toBe(true);
      expect(findDashboardLayout().props('config')).toEqual({});
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
        dashboardId: expect.any(String),
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
