import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDrawer, GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DashboardSettingsDrawer from '~/explore/analytics_dashboards/components/dashboard_settings_drawer.vue';
import DashboardSettingsForm from '~/explore/analytics_dashboards/components/dashboard_settings_form.vue';
import updateCustomDashboardMutation from '~/explore/analytics_dashboards/graphql/update_custom_dashboard.mutation.graphql';

Vue.use(VueApollo);

jest.mock('~/lib/utils/dom_utils', () => ({
  getContentWrapperHeight: () => '123',
}));

describe('DashboardSettingsDrawer', () => {
  let wrapper;
  let mockApollo;

  const defaultPropsData = {
    open: false,
    dashboardConfig: {
      title: 'Test Dashboard',
      description: 'Test Description',
      panels: [],
    },
    dashboardId: 'gid://gitlab/Analytics::CustomDashboard/1',
  };

  const mockApolloProvider = (customResolver) =>
    createMockApollo([
      [
        updateCustomDashboardMutation,
        customResolver ||
          jest.fn().mockResolvedValue({
            data: {
              updateCustomDashboard: {
                dashboard: {
                  id: 'gid://gitlab/Analytics::CustomDashboard/1',
                  name: 'Test Dashboard',
                  description: 'Test Description',
                },
                errors: [],
              },
            },
          }),
      ],
    ]);

  const createComponent = (props = {}, mountFn = shallowMountExtended, response) => {
    mockApollo = mockApolloProvider(response);
    jest.spyOn(mockApollo.defaultClient, 'mutate');

    wrapper = mountFn(DashboardSettingsDrawer, {
      propsData: {
        ...defaultPropsData,
        ...props,
      },
      provide: {
        exploreAnalyticsDashboardsPath: '/dashboards/',
      },
      apolloProvider: mockApollo,
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findFormSettings = () => wrapper.findComponent(DashboardSettingsForm);
  const findSaveButton = () => wrapper.findByTestId('settings-save-button');
  const findCancelButton = () => wrapper.findByTestId('settings-cancel-button');
  const findDeleteButton = () => wrapper.findByTestId('settings-delete-button');
  const findErrorAlert = () => wrapper.findComponent(GlAlert);

  it('emits close when GlDrawer emits close', async () => {
    createComponent();

    findDrawer().vm.$emit('close');
    await nextTick();

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  describe('form initialization', () => {
    beforeEach(async () => {
      createComponent({ open: true });
      await nextTick();
    });

    it('renders the DashboardSettingsForm component', () => {
      expect(findFormSettings().exists()).toBe(true);
    });

    it('initializes the form with the config title and description', () => {
      expect(findFormSettings().props('value')).toEqual({
        title: 'Test Dashboard',
        description: 'Test Description',
      });
    });

    it('passes isLoading as false to the form', () => {
      expect(findFormSettings().props('isLoading')).toBe(false);
    });
  });

  describe('form actions', () => {
    beforeEach(() => {
      createComponent({ open: true });
    });

    it('renders the save button', () => {
      expect(findSaveButton().exists()).toBe(true);
      expect(findSaveButton().text()).toBe('Save');
    });

    it('emits close when the cancel button is pressed', async () => {
      findCancelButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('close')).toHaveLength(1);
    });
  });

  describe('save functionality', () => {
    describe('blank title validation', () => {
      beforeEach(() => {
        createComponent({ open: true });
        findFormSettings().vm.$emit('input', { title: '', description: 'Test' });
        findSaveButton().vm.$emit('click');
      });

      it('does not send a mutation request', () => {
        expect(mockApollo.defaultClient.mutate).not.toHaveBeenCalled();
      });

      it('shows the title required error alert', () => {
        expect(findErrorAlert().exists()).toBe(true);
        expect(findErrorAlert().text()).toContain('Dashboard title is required');
      });

      it('keeps the drawer open', () => {
        expect(findDrawer().props('open')).toBe(true);
      });
    });

    describe('loading state during request', () => {
      beforeEach(() => {
        createComponent({ open: true });
        findFormSettings().vm.$emit('input', {
          title: 'Updated Title',
          description: 'Updated Description',
        });
        findSaveButton().vm.$emit('click');
      });

      it('passes isLoading as true to the form', () => {
        expect(findFormSettings().props('isLoading')).toBe(true);
      });

      it('disables the save button', () => {
        expect(findSaveButton().props('loading')).toBe(true);
      });

      it('disables the cancel button', () => {
        expect(findCancelButton().props('disabled')).toBe(true);
      });

      it('disables the delete button', () => {
        expect(findDeleteButton().props('disabled')).toBe(true);
      });
    });

    describe('successful save', () => {
      beforeEach(async () => {
        createComponent({ open: true });
        findFormSettings().vm.$emit('input', {
          title: 'Updated Title',
          description: 'Updated Description',
        });
        findSaveButton().vm.$emit('click');
        await waitForPromises();
      });

      it('sends the update mutation with correct payload', () => {
        expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: updateCustomDashboardMutation,
            variables: {
              input: {
                id: 'gid://gitlab/Analytics::CustomDashboard/1',
                name: 'Updated Title',
                description: 'Updated Description',
                config: {
                  title: 'Updated Title',
                  description: 'Updated Description',
                  panels: [],
                },
              },
            },
          }),
        );
      });

      it('evicts the dashboard from the cache', () => {
        const mutateCall = mockApollo.defaultClient.mutate.mock.calls[0][0];
        expect(mutateCall.update).toBeDefined();
      });

      it('emits close event', () => {
        expect(wrapper.emitted('close')).toHaveLength(1);
      });

      it('stops the loading state', () => {
        expect(findFormSettings().props('isLoading')).toBe(false);
      });
    });

    describe('request error', () => {
      const error = 'Dashboard name already exists';

      beforeEach(async () => {
        createComponent(
          { open: true },
          shallowMountExtended,
          jest.fn().mockResolvedValue({
            data: {
              updateCustomDashboard: {
                dashboard: null,
                errors: [error],
              },
            },
          }),
        );
        findFormSettings().vm.$emit('input', {
          title: 'Updated Title',
          description: 'Updated Description',
        });
        findSaveButton().vm.$emit('click');
        await waitForPromises();
      });

      it('shows the error in the alert', () => {
        expect(findErrorAlert().exists()).toBe(true);
        expect(findErrorAlert().text()).toContain(error);
      });

      it('keeps the drawer open', () => {
        expect(findDrawer().props('open')).toBe(true);
      });

      it('stops the loading state', () => {
        expect(findFormSettings().props('isLoading')).toBe(false);
      });
    });

    describe('server error', () => {
      beforeEach(async () => {
        createComponent(
          { open: true },
          shallowMountExtended,
          jest.fn().mockRejectedValue(new Error('Network error')),
        );
        findFormSettings().vm.$emit('input', {
          title: 'Updated Title',
          description: 'Updated Description',
        });
        findSaveButton().vm.$emit('click');
        await waitForPromises();
      });

      it('shows the generic error message in the alert', () => {
        expect(findErrorAlert().exists()).toBe(true);
        expect(findErrorAlert().text()).toContain('Failed to update dashboard. Please try again.');
      });

      it('keeps the drawer open', () => {
        expect(findDrawer().props('open')).toBe(true);
      });

      it('stops the loading state', () => {
        expect(findFormSettings().props('isLoading')).toBe(false);
      });
    });
  });

  it('trims title and description when sending the mutation', async () => {
    createComponent({ open: true });
    findFormSettings().vm.$emit('input', {
      title: '  Updated Title with spaces  ',
      description: '  Updated Description with spaces  ',
    });
    findSaveButton().vm.$emit('click');
    await waitForPromises();

    expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith(
      expect.objectContaining({
        mutation: updateCustomDashboardMutation,
        variables: {
          input: {
            id: 'gid://gitlab/Analytics::CustomDashboard/1',
            name: 'Updated Title with spaces',
            description: 'Updated Description with spaces',
            config: {
              title: 'Updated Title with spaces',
              description: 'Updated Description with spaces',
              panels: [],
            },
          },
        },
      }),
    );
  });
});
