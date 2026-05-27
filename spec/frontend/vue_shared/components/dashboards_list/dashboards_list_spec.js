import { nextTick } from 'vue';
import { GlTable, GlAvatarLabeled } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import DashboardsList from '~/vue_shared/components/dashboards_list/dashboards_list.vue';
import DashboardDeleteModal from '~/vue_shared/components/dashboards_list/dashboard_delete_modal.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const mockDashboards = [
  {
    id: 'gid://gitlab/Analytics::CustomDashboard/1',
    name: 'First custom dashboard',
    description: 'Default dashboard description',
    slug: 'first-custom-dashboard',
    createdBy: {
      id: 133737,
      name: 'Fake User',
      username: 'fakeuser',
      avatarUrl: '/fake/user/avatar.jpg',
      webUrl: '/fakeuser',
      webPath: '/fakeuser',
    },
    isCustom: true,
    isStarred: false,
    isEditable: true,
    shareLink: '/fake/link/to/share',
    updatedAt: '2020-07-01',
    dashboardUrl: '/fake/url/1',
  },
  {
    id: 'gid://gitlab/Analytics::CustomDashboard/2',
    name: 'Cool dashboard',
    description:
      'Cool custom dashboard that has a description that is very long and will most definitely overflow',
    slug: 'cool-custom-dashboard',
    createdBy: {
      id: 133737,
      name: 'Fake User',
      username: 'fakeuser',
      avatarUrl: '/fake/user/avatar.jpg',
      webUrl: '/fakeuser',
      webPath: '/fakeuser',
    },
    isCustom: true,
    isStarred: false,
    isEditable: true,
    shareLink: '/fake/link/to/share',
    updatedAt: '2020-06-01',
    dashboardUrl: '/fake/url/2',
  },
];

describe('DashboardsList', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);
  const findTableRows = () => wrapper.findAll('tbody tr');
  const findStarIcons = () => wrapper.findAllByTestId('dashboard-star-icon');
  const findDashboardLinks = () => wrapper.findAllByTestId('dashboard-redirect-link');
  const findUserAvatars = () => wrapper.findAllComponents(GlAvatarLabeled);
  const findActionDropdowns = () => wrapper.findAllByTestId('dashboard-actions');
  const findDeleteActions = () => wrapper.findAllByTestId('dashboard-delete-action');
  const findDeleteModal = () => wrapper.findComponent(DashboardDeleteModal);
  const findEditActions = () => wrapper.findAllByTestId('dashboard-edit-action');

  const createWrapper = (props = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(DashboardsList, {
      propsData: {
        dashboards: mockDashboards,
        ...props,
      },
    });
  };

  describe('with valid dashboard data', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the table component', () => {
      expect(findTable().exists()).toBe(true);
      expect(findTable().attributes('stacked')).toBe('sm');
    });
  });

  describe('with data', () => {
    describe('with custom dashboards', () => {
      beforeEach(() => {
        createWrapper({}, mountExtended);
      });

      it('renders the correct number of table rows', () => {
        expect(findTableRows()).toHaveLength(mockDashboards.length);
      });

      it('renders user avatars with correct props', () => {
        const avatars = findUserAvatars();

        avatars.wrappers.forEach((avatar, index) => {
          const dashboard = mockDashboards[index];
          expect(avatar.props()).toMatchObject({
            src: dashboard.createdBy.avatarUrl,
            size: 24,
            shape: 'circle',
            fallbackOnError: true,
            label: dashboard.createdBy.name,
          });
        });
      });

      it('renders user', () => {
        mockDashboards.forEach((dashboard, index) => {
          const row = findTableRows().at(index);
          expect(row.text()).toContain(dashboard.createdBy.name);

          expect(row.html()).toContain(dashboard.createdBy.webPath);
        });
      });

      it('renders last edited dates as relative time', () => {
        mockDashboards.forEach((dashboard, index) => {
          const row = findTableRows().at(index);
          const updatedAt = row.find('[data-testid="dashboard-updated-at"]');
          expect(updatedAt.exists()).toBe(true);
        });

        expect(findTableRows().at(0).text()).toContain('5 days ago');
        expect(findTableRows().at(1).text()).toContain('1 month ago');
      });

      it('renders action dropdowns for each dashboard', () => {
        const actionDropdowns = findActionDropdowns();

        expect(actionDropdowns).toHaveLength(mockDashboards.length);

        actionDropdowns.wrappers.forEach((dropdown) => {
          expect(dropdown.props()).toMatchObject({
            icon: 'ellipsis_v',
            category: 'tertiary',
            textSrOnly: true,
            noCaret: true,
          });
        });
      });

      it('renders the valid fields', () => {
        const expectedFields = ['Title', 'Created by', 'Last edited', 'Actions'];
        const fields = findTable()
          .props('fields')
          .map(({ label }) => label);

        expect(fields).toEqual(expectedFields);
      });
    });

    describe('with system dashboards', () => {
      const mockSystemDashboards = [
        {
          name: 'System dashboard',
          system: true,
          description:
            'Cool custom dashboard that has a description that is very long and will most definitely overflow',
          slug: 'cool-custom-dashboard',
          shareLink: '/fake/link/to/share',
          updatedAt: '2025-10-28',
          dashboardUrl: '/fake/url/2',
        },
      ];

      beforeEach(() => {
        createWrapper({ dashboards: mockSystemDashboards }, mountExtended);
      });

      it('renders the correct number of table rows', () => {
        expect(findTableRows()).toHaveLength(mockSystemDashboards.length);
      });

      it('renders GitLab in the created by field', () => {
        const avatars = findUserAvatars();

        avatars.wrappers.forEach((avatar) => {
          expect(avatar.props()).toMatchObject({
            src: 'file-mock',
            size: 24,
            shape: 'circle',
            fallbackOnError: true,
            label: 'GitLab',
          });
        });
      });

      it('renders the valid fields', () => {
        const expectedFields = ['Title', 'Created by', 'Last edited', 'Actions'];
        const fields = findTable()
          .props('fields')
          .map(({ label }) => label);

        expect(fields).toEqual(expectedFields);
      });

      it('does not render the last edited time for system dashboards', () => {
        const updatedAt = findTableRows().at(0).find('[data-testid="dashboard-updated-at"]');
        expect(updatedAt.exists()).toBe(false);
      });
    });

    describe('dashboard actions', () => {
      describe('for custom dashboards', () => {
        beforeEach(() => {
          createWrapper({}, mountExtended);
        });

        it('renders delete action for custom dashboards', () => {
          expect(findDeleteActions()).toHaveLength(mockDashboards.length);
          findDeleteActions().wrappers.forEach((action) => {
            expect(action.props('variant')).toBe('danger');
            expect(action.text()).toContain('Delete');
          });
        });
      });

      describe('for system dashboards', () => {
        const mockSystemDashboards = [
          {
            name: 'System dashboard',
            system: true,
            description: 'System dashboard description',
            slug: 'system-dashboard',
            shareLink: '/fake/link/to/share',
            updatedAt: '2025-10-28',
            dashboardUrl: '/fake/url/2',
          },
        ];

        beforeEach(() => {
          createWrapper({ dashboards: mockSystemDashboards }, mountExtended);
        });

        it('does not render edit action for system dashboards', () => {
          expect(findEditActions()).toHaveLength(0);
        });

        it('does not render delete action for system dashboards', () => {
          expect(findDeleteActions()).toHaveLength(0);
        });
      });

      describe('delete modal', () => {
        beforeEach(() => {
          createWrapper({}, mountExtended);
          findDeleteActions().at(0).vm.$emit('action');
        });

        it('sets correct dashboardId when delete action is clicked', () => {
          expect(findDeleteModal().props('dashboardId')).toBe(mockDashboards[0].id);
        });

        it('hides the modal when the delete is completed', async () => {
          const hideModalSpy = jest.spyOn(findDeleteModal().vm, 'hide');
          findDeleteModal().vm.$emit('delete');
          await nextTick();
          expect(hideModalSpy).toHaveBeenCalled();
        });
      });

      describe('edit action', () => {
        beforeEach(() => {
          createWrapper({}, mountExtended);
        });

        it('redirects to the dashboard edit URL when edit action is clicked', () => {
          findEditActions().at(0).vm.$emit('action');
          expect(visitUrl).toHaveBeenCalledWith('/fake/url/1/edit');
        });
      });
    });
  });

  describe('with empty dashboard data', () => {
    beforeEach(() => {
      createWrapper({ dashboards: [] });
    });

    it('renders the table component', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('renders no table rows', () => {
      expect(findTableRows()).toHaveLength(0);
    });

    it('renders no dashboard links', () => {
      expect(findDashboardLinks()).toHaveLength(0);
    });

    it('renders no star icons', () => {
      expect(findStarIcons()).toHaveLength(0);
    });

    it('renders no user avatars', () => {
      expect(findUserAvatars()).toHaveLength(0);
    });
  });
});
