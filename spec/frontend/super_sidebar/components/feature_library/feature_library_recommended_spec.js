import { mountExtended } from 'helpers/vue_test_utils_helper';
import FeatureLibraryRecommended from '~/super_sidebar/components/feature_library/feature_library_recommended.vue';
import FeatureLibraryItem from '~/super_sidebar/components/feature_library/feature_library_item.vue';
import { TIERS } from '~/super_sidebar/components/feature_library/constants';

const makeItem = (id, overrides = {}) => ({
  item_id: id,
  title: id,
  description: `${id} description`,
  icon: 'code',
  category: 'code',
  tier: TIERS.FREE,
  enhanced_tiers: [],
  badges: [],
  panels: ['project'],
  recommended: true,
  ...overrides,
});

describe('FeatureLibraryRecommended', () => {
  let wrapper;

  const createWrapper = ({ items = [], pinnedIds = [] } = {}) => {
    wrapper = mountExtended(FeatureLibraryRecommended, {
      propsData: { items, pinnedIds },
    });
  };

  const findAllItems = () => wrapper.findAllComponents(FeatureLibraryItem);
  const findHeading = () => wrapper.findByTestId('feature-library-recommended-heading');
  const findGrid = () => wrapper.findByTestId('feature-library-recommended-grid');

  it('renders the "Recommended" heading', () => {
    createWrapper();
    expect(findHeading().text()).toBe('Recommended');
  });

  it('renders one FeatureLibraryItem per item', () => {
    createWrapper({ items: [makeItem('a'), makeItem('b'), makeItem('c')] });
    expect(findAllItems()).toHaveLength(3);
  });

  it('passes pinned=true to items whose id is in pinnedIds', () => {
    createWrapper({
      items: [makeItem('a'), makeItem('b')],
      pinnedIds: ['b'],
    });
    expect(findAllItems().at(0).props('pinned')).toBe(false);
    expect(findAllItems().at(1).props('pinned')).toBe(true);
  });

  it('lays recommended items out responsively (one column on small viewports, scaling up)', () => {
    createWrapper({ items: [makeItem('a')] });
    expect(findGrid().classes()).toEqual(
      expect.arrayContaining(['gl-grid-cols-1', 'sm:gl-grid-cols-2', 'md:gl-grid-cols-3']),
    );
  });

  it('renders recommended items on a solid background', () => {
    createWrapper({ items: [makeItem('a')] });
    expect(findAllItems().at(0).props('solidBackground')).toBe(true);
  });

  it('re-emits pin-toggle from child items', () => {
    createWrapper({ items: [makeItem('a')] });
    findAllItems().at(0).vm.$emit('pin-toggle', 'a', true);
    expect(wrapper.emitted('pin-toggle')).toEqual([['a', true]]);
  });
});
