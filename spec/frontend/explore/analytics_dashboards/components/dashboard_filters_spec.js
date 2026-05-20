import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DashboardFilters from '~/explore/analytics_dashboards/components/dashboard_filters.vue';

describe('DashboardFilters', () => {
  let wrapper;

  const GroupsFilterStub = { name: 'GroupsFilter', template: '<div />' };
  const ProjectsFilterStub = {
    name: 'ProjectsFilter',
    props: ['groupNamespace', 'disabled'],
    template: '<div />',
  };
  const DateRangeFilterStub = {
    name: 'DateRangeFilter',
    props: ['defaultOption'],
    template: '<div />',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(DashboardFilters, {
      propsData: { groupNamespace: 'gitlab-org', ...props },
      stubs: {
        GroupsFilter: GroupsFilterStub,
        ProjectsFilter: ProjectsFilterStub,
        DateRangeFilter: DateRangeFilterStub,
      },
    });
  };

  const findGroupsFilter = () => wrapper.findComponent(GroupsFilterStub);
  const findProjectsFilter = () => wrapper.findComponent(ProjectsFilterStub);
  const findDateRangeFilter = () => wrapper.findComponent(DateRangeFilterStub);

  describe('rendering', () => {
    beforeEach(() => createComponent());

    it('renders the filter region wrapper', () => {
      const region = wrapper.findByTestId('dashboard-filters');

      expect(region.exists()).toBe(true);
      expect(region.attributes('role')).toBe('group');
      expect(region.attributes('aria-label')).toBe('Dashboard filters');
    });

    it('passes the groupNamespace prop to the projects filter', () => {
      expect(findProjectsFilter().exists()).toBe(true);
      expect(findProjectsFilter().props('groupNamespace')).toBe('gitlab-org');
    });

    it('enables the projects filter when a group is selected', () => {
      expect(findProjectsFilter().exists()).toBe(true);
      expect(findProjectsFilter().props('disabled')).toBe(false);
    });

    it('defaults the date range filter to the last 30 days', () => {
      expect(findDateRangeFilter().exists()).toBe(true);
      expect(findDateRangeFilter().props('defaultOption')).toBe('30d');
    });
  });

  describe('when no group is selected', () => {
    beforeEach(() => createComponent({ props: { groupNamespace: '' } }));

    it('disables the projects filter', () => {
      expect(findProjectsFilter().props('disabled')).toBe(true);
    });
  });

  describe('event re-emission', () => {
    beforeEach(() => createComponent());

    it('re-emits group-selected as set-groups', () => {
      const payload = [{ id: 1, fullPath: 'gitlab-org' }];

      findGroupsFilter().vm.$emit('group-selected', payload);

      expect(wrapper.emitted('set-groups')).toEqual([[payload]]);
    });

    it('re-emits project-selected as set-projects', () => {
      const payload = [{ id: 9, fullPath: 'gitlab-org/gitlab-test' }];

      findProjectsFilter().vm.$emit('project-selected', payload);

      expect(wrapper.emitted('set-projects')).toEqual([[payload]]);
    });

    it('re-emits date-range filter change as set-date-range', () => {
      const payload = {
        dateRangeOption: '30d',
        startDate: new Date('2026-04-11'),
        endDate: new Date('2026-05-11'),
      };

      findDateRangeFilter().vm.$emit('change', payload);

      expect(wrapper.emitted('set-date-range')).toEqual([[payload]]);
    });
  });
});
