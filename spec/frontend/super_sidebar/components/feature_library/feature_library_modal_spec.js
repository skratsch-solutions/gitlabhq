import { GlModal, GlSearchBoxByType, GlTab, GlEmptyState, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import FeatureLibraryModal from '~/super_sidebar/components/feature_library/feature_library_modal.vue';
import FeatureLibraryItem from '~/super_sidebar/components/feature_library/feature_library_item.vue';
import {
  EVENT_OPEN_FEATURE_LIBRARY_MODAL,
  EVENT_SEARCH_FEATURES_IN_FEATURE_LIBRARY_MODAL,
  EVENT_CLICK_CATEGORY_TAB_IN_FEATURE_LIBRARY_MODAL,
  EVENT_PIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
  EVENT_UNPIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
  EVENT_NAVIGATE_TO_FEATURE_FROM_FEATURE_LIBRARY_MODAL,
} from '~/super_sidebar/tracking_constants';

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

  const createWrapper = ({ currentPinnedIds = [], showFeedbackLink = false } = {}) => {
    wrapper = shallowMountExtended(FeatureLibraryModal, {
      propsData: { sections, currentPinnedIds, showFeedbackLink },
      // Stub GlModal (declared props stay props, everything else surfaces as
      // attrs) and render all its slots so footer/body content is inspectable.
      stubs: { GlModal: stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE }) },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findTabLabels = () => findAllTabs().wrappers.map((w) => w.attributes('title'));
  const findItems = () => wrapper.findAllComponents(FeatureLibraryItem);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findScrollArea = () => wrapper.findByTestId('feature-library-scroll-area');
  const findGrid = () => wrapper.findByTestId('feature-library-grid');
  const findFeedbackLink = () => wrapper.findComponent(GlLink);

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
        expect.arrayContaining([
          'feature-library-scroll-area',
          'gl-grow',
          'gl-min-h-0',
          'gl-overflow-y-auto',
        ]),
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
    describe('with default props', () => {
      beforeEach(() => createWrapper());

      it('blurs the page behind the modal', () => {
        expect(findModal().props('modalClass')).toContain('gl-backdrop-blur-sm');
      });

      it('does not use centered so the top edge stays anchored during search', () => {
        expect(findModal().attributes('centered')).toBeUndefined();
      });

      it('caps its height so tall content scrolls internally', () => {
        expect(findModal().attributes('scrollable')).toBeDefined();
      });

      it('applies the feature-library-modal class for top-anchored positioning', () => {
        expect(findModal().props('modalClass')).toContain('feature-library-modal');
      });

      it('reserves a dismissable gutter around the dialog', () => {
        const modalClass = findModal().props('modalClass');
        expect(modalClass).toContain('gl-px-2');
        expect(modalClass).toContain('sm:gl-px-5');
      });

      describe('footer visibility', () => {
        describe('when the feedback link is enabled', () => {
          beforeEach(() => createWrapper({ showFeedbackLink: true }));

          it('shows the footer', () => {
            expect(findModal().attributes('hide-footer')).toBeUndefined();
          });
        });

        describe('when there is no feedback link to show', () => {
          beforeEach(() => createWrapper({ showFeedbackLink: false }));

          it('hides the footer', () => {
            expect(findModal().attributes('hide-footer')).toBe('true');
          });
        });
      });
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
      const items = findItems().wrappers.map((w) => w.props('item'));
      expect(items.filter((i) => i.category === 'plan_menu').map((i) => i.id)).toEqual([
        'project_issue_list',
        'boards',
      ]);
      expect(items.filter((i) => i.category === 'code_menu').map((i) => i.id)).toEqual([
        'repository',
      ]);
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
    beforeEach(() => createWrapper());

    it('re-emits pin-toggle (with title) from grid items', () => {
      findItems().at(0).vm.$emit('pin-toggle', 'some_id', true, 'Some title');
      expect(wrapper.emitted('pin-toggle')).toEqual([['some_id', true, 'Some title']]);
    });
  });

  describe('currentPinnedIds', () => {
    beforeEach(() => createWrapper({ currentPinnedIds: ['repository'] }));

    it('passes pinned=true to items whose id is in currentPinnedIds', () => {
      const matchingItem = findItems().wrappers.find((w) => w.props('item').id === 'repository');
      expect(matchingItem.props('pinned')).toBe(true);
    });
  });

  describe('internal events tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    // The mixin forwards a third `category` arg (undefined) to InternalEvents.trackEvent.
    const CATEGORY = undefined;

    beforeEach(() => {
      createWrapper();
    });

    it('tracks opening the modal when it is shown', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findModal().vm.$emit('shown');
      expect(trackEventSpy).toHaveBeenCalledWith(EVENT_OPEN_FEATURE_LIBRARY_MODAL, {}, CATEGORY);
    });

    it('tracks clicking a category tab, labelled with the category id', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      // Tabs order: All (0), Plan (1), Code (2).
      await findAllTabs().at(1).vm.$emit('click');
      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_CLICK_CATEGORY_TAB_IN_FEATURE_LIBRARY_MODAL,
        { label: 'plan_menu' },
        CATEGORY,
      );
    });

    it('tracks pinning an item, labelled with the item id', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findItems().at(0).vm.$emit('pin-toggle', 'repository', true, 'Repository');
      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_PIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
        { label: 'repository' },
        CATEGORY,
      );
    });

    it('tracks unpinning an item, labelled with the item id', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findItems().at(0).vm.$emit('pin-toggle', 'repository', false, 'Repository');
      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_UNPIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
        { label: 'repository' },
        CATEGORY,
      );
    });

    it('tracks navigating to a feature, labelled with the item id', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findItems().at(0).vm.$emit('navigate', 'repository');
      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_NAVIGATE_TO_FEATURE_FROM_FEATURE_LIBRARY_MODAL,
        { label: 'repository' },
        CATEGORY,
      );
    });

    // debounce is synchronous under the test mock (spec/frontend/__mocks__/lodash-es/debounce.js).
    it('tracks a search event when the user types a query', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findSearch().vm.$emit('input', 'repo');
      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_SEARCH_FEATURES_IN_FEATURE_LIBRARY_MODAL,
        {},
        CATEGORY,
      );
    });

    it('does not track a search event when the query is blank', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findSearch().vm.$emit('input', '   ');
      expect(trackEventSpy).not.toHaveBeenCalled();
    });

    // Guards against a pending debounced search event firing after the modal
    // closes. (The matching beforeUnmount cancel is exercised under Vue 3.)
    it('cancels the pending debounced search tracker when the modal is hidden', () => {
      const cancelSpy = wrapper.vm.debouncedTrackSearch.cancel;
      findModal().vm.$emit('hidden');
      expect(cancelSpy).toHaveBeenCalled();
    });
  });

  describe('feedback link', () => {
    describe('when showFeedbackLink is true', () => {
      beforeEach(() => createWrapper({ showFeedbackLink: true }));

      it('renders the feedback link', () => {
        expect(findFeedbackLink().exists()).toBe(true);
      });

      it('points the feedback link at the feedback issue', () => {
        expect(findFeedbackLink().attributes('href')).toBe(
          'https://gitlab.com/gitlab-org/gitlab/-/work_items/604008',
        );
      });
    });

    describe('when showFeedbackLink is false', () => {
      beforeEach(() => createWrapper({ showFeedbackLink: false }));

      it('does not render the feedback link', () => {
        expect(findFeedbackLink().exists()).toBe(false);
      });
    });

    describe('by default', () => {
      beforeEach(() => createWrapper());

      it('does not render the feedback link', () => {
        expect(findFeedbackLink().exists()).toBe(false);
      });
    });
  });
});
