import { GlButton, GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import FeatureLibraryItem from '~/super_sidebar/components/feature_library/feature_library_item.vue';
import { TIERS, BADGES } from '~/super_sidebar/components/feature_library/constants';

const baseItem = {
  item_id: 'repository',
  title: 'Repository',
  description: 'Browse and manage your code',
  icon: 'code',
  category: 'code',
  tier: TIERS.FREE,
  enhanced_tiers: [],
  badges: [],
  panels: ['project'],
  recommended: false,
};

describe('FeatureLibraryItem', () => {
  let wrapper;

  const createWrapper = ({ item = baseItem, pinned = false, solidBackground = false } = {}) => {
    wrapper = mountExtended(FeatureLibraryItem, {
      propsData: { item, pinned, solidBackground },
    });
  };

  const findTitle = () => wrapper.findByTestId('feature-library-item-title');
  const findDescription = () => wrapper.findByTestId('feature-library-item-description');
  const findTierLabel = () => wrapper.findByTestId('feature-library-item-tier');
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findBetaBadge = () => wrapper.findByTestId('feature-library-item-beta');
  const findPinButton = () => wrapper.findComponent(GlButton);

  describe('rendering', () => {
    beforeEach(() => createWrapper());

    it('renders the icon', () => {
      expect(findIcon().props('name')).toBe('code');
    });

    it('renders the title', () => {
      expect(findTitle().text()).toBe('Repository');
    });

    it('renders the description', () => {
      expect(findDescription().text()).toBe('Browse and manage your code');
    });
  });

  describe('tier label', () => {
    it.each([
      [{ tier: TIERS.FREE, enhanced_tiers: [] }, 'Free'],
      [{ tier: TIERS.FREE, enhanced_tiers: [TIERS.PREMIUM] }, 'Free · Enhanced with Premium'],
      [{ tier: TIERS.FREE, enhanced_tiers: [TIERS.ULTIMATE] }, 'Free · Enhanced with Ultimate'],
      [{ tier: TIERS.PREMIUM, enhanced_tiers: [] }, 'Premium'],
      [{ tier: TIERS.ULTIMATE, enhanced_tiers: [] }, 'Ultimate'],
      [{ tier: TIERS.ADD_ON, enhanced_tiers: [] }, 'Add-on'],
    ])('renders %j as "%s"', (tierProps, expected) => {
      createWrapper({ item: { ...baseItem, ...tierProps } });
      expect(findTierLabel().text()).toBe(expected);
    });
  });

  describe('BETA badge', () => {
    it('does not render when badges is empty', () => {
      createWrapper();
      expect(findBetaBadge().exists()).toBe(false);
    });

    it('renders when badges includes "beta"', () => {
      createWrapper({ item: { ...baseItem, badges: [BADGES.BETA] } });
      expect(findBetaBadge().text()).toBe('BETA');
    });
  });

  describe('layout', () => {
    it('top-aligns the icon tile with the heading', () => {
      createWrapper();
      expect(wrapper.classes()).toContain('gl-items-start');
      expect(wrapper.classes()).not.toContain('gl-items-center');
    });
  });

  describe('solidBackground prop', () => {
    it('uses a transparent background with a fill hover by default', () => {
      createWrapper();
      expect(wrapper.classes()).toContain('gl-bg-transparent');
      expect(wrapper.classes()).toContain('hover:gl-bg-strong');
    });

    it('uses a solid background with a shadow hover when solidBackground is true', () => {
      createWrapper({ solidBackground: true });
      expect(wrapper.classes()).toContain('gl-bg-default');
      expect(wrapper.classes()).not.toContain('gl-bg-transparent');
      // On a strong-fill backdrop, a fill hover would blend into it, so the
      // chip elevates with a shadow instead.
      expect(wrapper.classes()).toContain('hover:gl-shadow-md');
      expect(wrapper.classes()).not.toContain('hover:gl-bg-strong');
    });
  });

  describe('pin button', () => {
    it('emits pin-toggle with nextState=true and the title when not pinned', async () => {
      createWrapper({ pinned: false });
      await findPinButton().trigger('click');
      expect(wrapper.emitted('pin-toggle')).toEqual([['repository', true, 'Repository']]);
    });

    it('emits pin-toggle with nextState=false and the title when pinned', async () => {
      createWrapper({ pinned: true });
      await findPinButton().trigger('click');
      expect(wrapper.emitted('pin-toggle')).toEqual([['repository', false, 'Repository']]);
    });

    it('uses "Pin" aria-label when not pinned', () => {
      createWrapper({ pinned: false });
      expect(findPinButton().attributes('aria-label')).toBe('Pin Repository');
    });

    it('uses "Unpin" aria-label when pinned', () => {
      createWrapper({ pinned: true });
      expect(findPinButton().attributes('aria-label')).toBe('Unpin Repository');
    });
  });
});
