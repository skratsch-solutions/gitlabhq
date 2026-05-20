import { GlDrawer } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemDisplaySettingsDrawer from '~/work_items/list/components/work_item_display_settings_drawer.vue';
import WorkItemDisplaySettingsSort from '~/work_items/list/components/work_item_display_settings_sort.vue';

const SORT_OPTIONS = [
  {
    id: 1,
    title: 'Created date',
    sortDirection: { ascending: 'CREATED_ASC', descending: 'CREATED_DESC' },
  },
];

describe('WorkItemDisplaySettingsDrawer', () => {
  let wrapper;

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findSort = () => wrapper.findComponent(WorkItemDisplaySettingsSort);

  const createComponent = ({ props = {}, slots = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemDisplaySettingsDrawer, {
      propsData: {
        open: false,
        ...props,
      },
      slots,
    });
  };

  it('passes the open prop through to GlDrawer', () => {
    createComponent({ props: { open: true } });

    expect(findDrawer().props('open')).toBe(true);
  });

  it('emits close when GlDrawer emits close', () => {
    createComponent({ props: { open: true } });

    findDrawer().vm.$emit('close');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('renders slot content in place of the placeholder', () => {
    createComponent({
      slots: { default: '<div data-testid="custom-body">custom</div>' },
    });

    expect(wrapper.findByTestId('custom-body').exists()).toBe(true);
  });

  describe('sort section', () => {
    it('does not render when sortOptions is empty', () => {
      createComponent();

      expect(findSort().exists()).toBe(false);
    });

    it('passes sortOptions and sortKey to the sort component', () => {
      createComponent({
        props: { sortOptions: SORT_OPTIONS, sortKey: 'CREATED_DESC' },
      });

      expect(findSort().props()).toMatchObject({
        sortOptions: SORT_OPTIONS,
        sortKey: 'CREATED_DESC',
      });
    });

    it('re-emits sort when the sort component emits it', () => {
      createComponent({
        props: { sortOptions: SORT_OPTIONS, sortKey: 'CREATED_DESC' },
      });

      findSort().vm.$emit('sort', 'CREATED_ASC');

      expect(wrapper.emitted('sort')).toEqual([['CREATED_ASC']]);
    });
  });
});
