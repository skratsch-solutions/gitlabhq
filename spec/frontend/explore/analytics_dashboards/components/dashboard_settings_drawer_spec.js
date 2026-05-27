import { nextTick } from 'vue';
import { GlDrawer } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import DashboardSettingsDrawer from '~/explore/analytics_dashboards/components/dashboard_settings_drawer.vue';
import DashboardDeleteModal from '~/vue_shared/components/dashboards_list/dashboard_delete_modal.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

jest.mock('~/lib/utils/dom_utils', () => ({
  getContentWrapperHeight: () => '123',
}));

describe('DashboardSettingsDrawer', () => {
  let wrapper;

  const defaultPropsData = {
    open: false,
    dashboardConfig: {
      title: 'Test Dashboard',
      description: 'Test Description',
    },
    dashboardId: 'gid://gitlab/Analytics::CustomDashboard/1',
  };

  const createComponent = (props = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(DashboardSettingsDrawer, {
      propsData: {
        ...defaultPropsData,
        ...props,
      },
      provide: {
        exploreAnalyticsDashboardsPath: '/dashboards/',
      },
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findTitleInput = () => wrapper.findByTestId('dashboard-title-input');
  const findDescriptionTextarea = () => wrapper.findByTestId('dashboard-description-textarea');
  const findSaveButton = () => wrapper.findByTestId('settings-save-button');
  const findCancelButton = () => wrapper.findByTestId('settings-cancel-button');
  const findDeleteButton = () => wrapper.findByTestId('settings-delete-button');
  const findDeleteModal = () => wrapper.findComponent(DashboardDeleteModal);

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

    it('initializes the title field with the config title', () => {
      expect(findTitleInput().props('value')).toBe('Test Dashboard');
    });

    it('initializes the description field with the config description', () => {
      expect(findDescriptionTextarea().props('value')).toBe('Test Description');
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

  describe('delete functionality', () => {
    beforeEach(() => {
      createComponent({ open: true }, mountExtended);
    });

    it('shows the delete modal when Delete dashboard is pressed', async () => {
      const showSpy = jest.spyOn(findDeleteModal().vm, 'show');
      findDeleteButton().vm.$emit('click');
      await nextTick();

      expect(showSpy).toHaveBeenCalled();
    });

    it('redirects back to the list view when delete is successful', async () => {
      findDeleteModal().vm.$emit('delete');
      await nextTick();

      expect(visitUrl).toHaveBeenCalledWith('/dashboards/');
    });
  });
});
