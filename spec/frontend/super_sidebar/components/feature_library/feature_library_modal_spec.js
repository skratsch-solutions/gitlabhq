import { GlModal, GlSearchBoxByType, GlTab, GlEmptyState } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import FeatureLibraryModal from '~/super_sidebar/components/feature_library/feature_library_modal.vue';
import FeatureLibraryItem from '~/super_sidebar/components/feature_library/feature_library_item.vue';

// Mirrors the nav tree shape passed down from sidebar_menu.vue: sections (menu
// groups) holding leaf nav items enriched with feature-library metadata.
const sections = [
  {
    id: 'plan_menu',
    title: 'Plan',
    items: [
      {
        id: 'project_issue_list',
        title: 'Work items',
        description: 'Track tasks and issues',
        library_icon: 'issues',
      },
      {
        id: 'boards',
        title: 'Boards',
        description: 'Visualize work with boards',
        library_icon: 'list-numbered',
      },
      // No description: should be excluded from the catalog.
      { id: 'milestones', title: 'Milestones', library_icon: 'milestone' },
    ],
  },
  {
    id: 'code_menu',
    title: 'Code',
    items: [
      {
        id: 'repository',
        title: 'Repository',
        description: 'Browse and manage your code',
        library_icon: 'code',
        tier: 'free',
      },
    ],
  },
  // Section with no enriched items: should not produce a tab.
  {
    id: 'manage_menu',
    title: 'Manage',
    items: [{ id: 'members', title: 'Members', library_icon: 'users' }],
  },
];

describe('FeatureLibraryModal', () => {
  let wrapper;

  const createWrapper = ({ currentPinnedIds = [] } = {}) => {
    wrapper = mountExtended(FeatureLibraryModal, {
      propsData: { sections, currentPinnedIds },
      stubs: { GlModal: { template: '<div><slot /></div>' } },
    });
  };

  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findTabLabels = () => wrapper.findAllByRole('tab').wrappers.map((w) => w.text());
  const findItems = () => wrapper.findAllComponents(FeatureLibraryItem);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findScrollArea = () => wrapper.findByTestId('feature-library-scroll-area');
  const findGrid = () => wrapper.findByTestId('feature-library-grid');

  describe('rendering', () => {
    beforeEach(() => createWrapper());

    it('renders an "All" tab plus one tab per section that has enriched items', () => {
      // manage_menu has no enriched items, so it gets no tab.
      expect(findTabLabels()).toEqual(['All', 'Plan', 'Code']);
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
  });

  describe('modal layout', () => {
    // Mount with the real GlModal so we can read the props/attrs it receives.
    beforeEach(() => {
      wrapper = mountExtended(FeatureLibraryModal, {
        propsData: { sections, currentPinnedIds: [] },
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

  describe('catalog', () => {
    beforeEach(() => createWrapper());

    it('only lists items that carry feature-library metadata (a description)', () => {
      const ids = findItems().wrappers.map((w) => w.props('item').id);
      expect(ids.sort()).toEqual(['boards', 'project_issue_list', 'repository']);
    });

    it('maps library_icon onto the item icon', () => {
      const repository = findItems().wrappers.find((w) => w.props('item').id === 'repository');
      expect(repository.props('item').icon).toBe('code');
    });

    it('tags each item with the id of its parent section as its category', () => {
      const repository = findItems().wrappers.find((w) => w.props('item').id === 'repository');
      expect(repository.props('item').category).toBe('code_menu');
    });
  });

  describe('filtering', () => {
    beforeEach(() => createWrapper());

    it('filters by search query (substring on title or description)', async () => {
      await findSearch().vm.$emit('input', 'Repository');
      const titles = findItems().wrappers.map((w) => w.props('item').title);
      expect(titles).toEqual(['Repository']);
    });

    it('filters by active category (section)', async () => {
      // Tabs order: All (0), Plan (1), Code (2).
      await findAllTabs().at(1).vm.$emit('click');
      await nextTick();
      const categories = findItems().wrappers.map((w) => w.props('item').category);
      expect(categories.every((c) => c === 'plan_menu')).toBe(true);
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
  });

  describe('currentPinnedIds', () => {
    it('passes pinned=true to items whose id is in currentPinnedIds', () => {
      createWrapper({ currentPinnedIds: ['repository'] });
      const matchingItem = findItems().wrappers.find((w) => w.props('item').id === 'repository');
      expect(matchingItem.props('pinned')).toBe(true);
    });
  });
});
