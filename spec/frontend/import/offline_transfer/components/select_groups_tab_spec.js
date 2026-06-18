import { GlLoadingIcon, GlEmptyState, GlKeysetPagination } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SelectGroupsTab from '~/import/offline_transfer/components/select_groups_tab.vue';
import SelectGroupRow from '~/import/offline_transfer/components/select_group_row.vue';
import { mockGroups } from '../mock_data';

describe('SelectGroupsTab', () => {
  let wrapper;

  const defaultProps = {
    pageGroups: mockGroups,
    showSelectError: false,
  };

  const createComponent = (propsData = {}) => {
    wrapper = shallowMountExtended(SelectGroupsTab, {
      propsData: { ...defaultProps, ...propsData },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findList = () => wrapper.find('ul');
  const findAllRows = () => wrapper.findAllComponents(SelectGroupRow);
  const findCount = () => wrapper.findByTestId('selected-count');
  const findSelectCurrentPage = () => wrapper.findByTestId('select-current-page');
  const findDeselectAll = () => wrapper.findByTestId('deselect-all');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findNoGroupsSelectedError = () => wrapper.findByTestId('selected-error');
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  describe('group list', () => {
    it('shows the empty message when not loading and there are no groups', () => {
      createComponent({ pageGroups: [] });

      expect(findEmptyState().exists()).toBe(true);
    });

    it('renders one SelectGroupRow per group', () => {
      createComponent();

      expect(findAllRows()).toHaveLength(mockGroups.length);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('passes name, description and avatarUrl through to each row', () => {
      createComponent();
      const firstRow = findAllRows().at(0);

      expect(firstRow.props()).toMatchObject({
        name: 'Flight',
        description: 'Flight',
        avatarUrl: null,
      });
    });

    it('marks a row checked when its id is in selectedIds', () => {
      createComponent({ selectedIds: ['gid://glab/Group/1'] });

      expect(findAllRows().at(0).props('checked')).toBe(true);
      expect(findAllRows().at(1).props('checked')).toBe(false);
    });
  });

  describe('loading state', () => {
    it('shows the loading icon while loading', () => {
      createComponent({ loading: true });

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findList().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('does not show the loading icon once loaded', () => {
      createComponent({ loading: false });

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('selection', () => {
    it('count matches the total groups selected', () => {
      createComponent({ selectedIds: ['gid://glab/Group/1'] });

      expect(findCount().text()).toBe('1 group selected');
    });

    it('emits toggle with the group when a row is selected', () => {
      createComponent();
      findAllRows().at(1).vm.$emit('toggle');

      expect(wrapper.emitted('toggle')).toEqual([[mockGroups[1]]]);
    });

    it('emits select-current-page when Select all is clicked', () => {
      createComponent();
      findSelectCurrentPage().vm.$emit('click');

      expect(wrapper.emitted('select-current-page')).toHaveLength(1);
    });

    it('emits deselect-all when Deselect all is clicked', () => {
      createComponent({ selectedIds: ['gid://glab/Group/1'] });
      findDeselectAll().vm.$emit('click');

      expect(wrapper.emitted('deselect-all')).toHaveLength(1);
    });

    it('disables Select all when every group is already selected', () => {
      createComponent({ selectedIds: mockGroups.map((group) => group.id) });

      expect(findSelectCurrentPage().props('disabled')).toBe(true);
    });

    it('disables Deselect all when nothing is selected', () => {
      createComponent();

      expect(findDeselectAll().props('disabled')).toBe(true);
      expect(findNoGroupsSelectedError().exists()).toBe(false);
    });

    it('error is shown when nothing is selected and showSelectError is passed as true', () => {
      createComponent({ selectedIds: [], showSelectError: true });

      expect(findNoGroupsSelectedError().text()).toBe('Select at least one group to continue');
    });

    it('hides error when a group becomes selected even if showSelectError is true', () => {
      createComponent({ selectedIds: ['gid://glab/Group/1'], showSelectError: true });

      expect(findNoGroupsSelectedError().exists()).toBe(false);
      expect(findCount().exists()).toBe(true);
    });
  });

  describe('pagination', () => {
    it('is not rendered when there is just one page', () => {
      createComponent({ pageInfo: { hasNextPage: false, hasPreviousPage: false } });

      expect(findPagination().exists()).toBe(false);
    });

    it('renders when there is a next page', () => {
      createComponent({ pageInfo: { hasNextPage: true, hasPreviousPage: false } });

      expect(findPagination().exists()).toBe(true);
    });

    it('renders when there is a previous page', () => {
      createComponent({ pageInfo: { hasNextPage: false, hasPreviousPage: true } });

      expect(findPagination().exists()).toBe(true);
    });

    it('correctly emits `next` with the cursor', () => {
      createComponent({ pageInfo: { hasNextPage: true, hasPreviousPage: false } });

      findPagination().vm.$emit('next', 'cursor123');

      expect(wrapper.emitted('next')).toEqual([['cursor123']]);
    });

    it('correctly emits `prev` with the cursor', () => {
      createComponent({ pageInfo: { hasNextPage: false, hasPreviousPage: true } });

      findPagination().vm.$emit('prev', 'cursor456');

      expect(wrapper.emitted('prev')).toEqual([['cursor456']]);
    });
  });
});
