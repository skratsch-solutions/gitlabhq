import { GlModal, GlSearchBoxByType, GlTab, GlEmptyState } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import FeatureLibraryModal from '~/super_sidebar/components/feature_library/feature_library_modal.vue';
import FeatureLibraryItem from '~/super_sidebar/components/feature_library/feature_library_item.vue';
import FeatureLibraryRecommended from '~/super_sidebar/components/feature_library/feature_library_recommended.vue';
import { CATEGORIES } from '~/super_sidebar/components/feature_library/constants';
import { MOCK_CATALOG } from '~/super_sidebar/components/feature_library/mock_catalog';

describe('FeatureLibraryModal', () => {
  let wrapper;

  const createWrapper = ({ panelType = 'project', currentPinnedIds = [] } = {}) => {
    wrapper = mountExtended(FeatureLibraryModal, {
      propsData: { panelType, currentPinnedIds },
      stubs: { GlModal: { template: '<div><slot /></div>' } },
    });
  };

  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findRecommended = () => wrapper.findComponent(FeatureLibraryRecommended);
  const findItems = () => wrapper.findAllComponents(FeatureLibraryItem);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findScrollArea = () => wrapper.findByTestId('feature-library-scroll-area');
  const findGrid = () => wrapper.findByTestId('feature-library-grid');

  describe('rendering', () => {
    beforeEach(() => createWrapper());

    it('renders a tab per category', () => {
      expect(findAllTabs()).toHaveLength(CATEGORIES.length);
    });

    it('wraps content in a flexible scroll area that fills available height and scrolls overflow', () => {
      const scrollArea = findScrollArea();
      expect(scrollArea.exists()).toBe(true);
      expect(scrollArea.classes()).toEqual(
        expect.arrayContaining(['gl-grow', 'gl-min-h-0', 'gl-overflow-y-auto']),
      );
    });

    it('renders a search input', () => {
      expect(findSearch().exists()).toBe(true);
    });

    it('lays the feature grid out responsively (one column on small viewports, scaling up)', () => {
      expect(findGrid().classes()).toEqual(
        expect.arrayContaining(['gl-grid-cols-1', 'sm:gl-grid-cols-2', 'md:gl-grid-cols-3']),
      );
    });

    it('adds a top margin above the search input', () => {
      expect(findSearch().classes()).toContain('gl-mt-3');
    });

    it('shows the Recommended row by default', () => {
      expect(findRecommended().exists()).toBe(true);
    });

    it('hides the Recommended row when the panel has no recommended items', () => {
      createWrapper({ panelType: 'group' });
      expect(findRecommended().exists()).toBe(false);
    });
  });

  describe('modal layout', () => {
    // Mount with the real GlModal so we can read the props/attrs it receives.
    beforeEach(() => {
      wrapper = mountExtended(FeatureLibraryModal, {
        propsData: { panelType: 'project', currentPinnedIds: [] },
      });
    });

    it('blurs the page behind the modal', () => {
      const modalClass = wrapper.findComponent(GlModal).props('modalClass');
      expect(typeof modalClass).toBe('string');
      expect(modalClass).toContain('gl-backdrop-blur-sm');
    });

    it('centers the dialog and caps its height so tall content scrolls internally', () => {
      const { $attrs } = wrapper.findComponent(GlModal).vm;
      expect($attrs).toHaveProperty('centered');
      expect($attrs).toHaveProperty('scrollable');
    });

    it('reserves a dismissable gutter around the dialog at every breakpoint', () => {
      const modalClass = wrapper.findComponent(GlModal).props('modalClass');
      expect(modalClass).toContain('gl-p-5');
    });
  });

  describe('filtering', () => {
    beforeEach(() => createWrapper({ panelType: 'project' }));

    it('only renders items whose panels include panelType', () => {
      const rendered = findItems().wrappers.map((w) => w.props('item').item_id);
      const expected = MOCK_CATALOG.filter((i) => i.panels.includes('project')).map(
        (i) => i.item_id,
      );
      expect(rendered.sort()).toEqual(expected.sort());
    });

    it('filters by search query (substring on title or description)', async () => {
      await findSearch().vm.$emit('input', 'Repository');
      const titles = findItems().wrappers.map((w) => w.props('item').title);
      expect(titles).toEqual(['Repository']);
    });

    it('hides Recommended when search is non-empty', async () => {
      await findSearch().vm.$emit('input', 'Repository');
      expect(findRecommended().exists()).toBe(false);
    });

    it('filters by active category', async () => {
      // Categories: 'plan' contains project_issue_list and activity.
      const planIndex = CATEGORIES.findIndex((c) => c.id === 'plan');
      await findAllTabs().at(planIndex).vm.$emit('click');
      await nextTick();
      const categories = findItems().wrappers.map((w) => w.props('item').category);
      expect(categories.every((c) => c === 'plan')).toBe(true);
    });

    it('hides Recommended when active category is not "all"', async () => {
      const planIndex = CATEGORIES.findIndex((c) => c.id === 'plan');
      await findAllTabs().at(planIndex).vm.$emit('click');
      await nextTick();
      expect(findRecommended().exists()).toBe(false);
    });

    it('renders empty state when no items match', async () => {
      await findSearch().vm.$emit('input', '__no_such_feature__');
      expect(findItems()).toHaveLength(0);
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('pin toggle', () => {
    it('re-emits pin-toggle (with title) from grid items', () => {
      createWrapper();
      findItems().at(0).vm.$emit('pin-toggle', 'some_id', true, 'Some title');
      expect(wrapper.emitted('pin-toggle')).toEqual([['some_id', true, 'Some title']]);
    });

    it('re-emits pin-toggle (with title) from the Recommended row', () => {
      createWrapper();
      findRecommended().vm.$emit('pin-toggle', 'some_id', false, 'Some title');
      expect(wrapper.emitted('pin-toggle')).toEqual([['some_id', false, 'Some title']]);
    });
  });

  describe('currentPinnedIds', () => {
    it('passes pinned=true to items whose id is in currentPinnedIds', () => {
      const firstProjectItem = MOCK_CATALOG.find((i) => i.panels.includes('project'));
      createWrapper({ currentPinnedIds: [firstProjectItem.item_id] });
      const matchingItem = findItems().wrappers.find(
        (w) => w.props('item').item_id === firstProjectItem.item_id,
      );
      expect(matchingItem.props('pinned')).toBe(true);
    });
  });
});
