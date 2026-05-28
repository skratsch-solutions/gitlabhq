import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import toggleWhatsNewDrawer from '~/whats_new';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { FORUM_URL, PROMO_URL, CONTRIBUTE_URL } from '~/constants';
import { mockTracking } from 'helpers/tracking_helper';
import HelpCenterUpgradeSubscription from 'ee_component/super_sidebar/components/help_center_upgrade_subscription.vue';
import { sidebarData } from '../mock_data';

jest.mock('~/whats_new');

describe('HelpCenter component', () => {
  let wrapper;
  let trackingSpy;

  const GlEmoji = { template: '<img/>' };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownGroup = (i = 0) => {
    return wrapper.findAllComponents(GlDisclosureDropdownGroup).at(i);
  };
  const withinComponent = () => within(wrapper.element);
  const findButton = (name) => withinComponent().getByRole('button', { name });
  const findUpgradeButton = () => wrapper.findComponent(HelpCenterUpgradeSubscription);

  const createWrapper = (sidebarDataOverride = sidebarData, provide = {}) => {
    wrapper = mountExtended(HelpCenter, {
      propsData: { sidebarData: sidebarDataOverride },
      stubs: { GlEmoji, HelpCenterUpgradeSubscription: true },
      provide: {
        isSaas: false,
        isIconOnly: false,
        ...provide,
      },
    });
    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  const trackingAttrs = (label) => {
    return {
      'data-track-action': 'click_link',
      'data-track-property': 'nav_help_menu',
      'data-track-label': label,
    };
  };

  const PRIVACY_HELP_ITEM = {
    text: HelpCenter.i18n.privacy,
    href: `${PROMO_URL}/privacy`,
    extraAttrs: trackingAttrs('privacy'),
  };

  const getDefaultHelpItems = (customSidebarData = sidebarData) => [
    { text: HelpCenter.i18n.help, href: helpPagePath(), extraAttrs: trackingAttrs('help') },
    {
      text: HelpCenter.i18n.support,
      href: customSidebarData.support_path,
      extraAttrs: trackingAttrs('support'),
    },
    {
      text: HelpCenter.i18n.docs,
      href: customSidebarData.docs_path,
      extraAttrs: trackingAttrs('gitlab_documentation'),
    },
    {
      text: HelpCenter.i18n.university,
      href: customSidebarData.university_path,
      extraAttrs: trackingAttrs('gitlab_university'),
    },
    {
      text: HelpCenter.i18n.plans,
      href: customSidebarData.compare_plans_url,
      extraAttrs: trackingAttrs('compare_gitlab_plans'),
    },
    {
      text: HelpCenter.i18n.forum,
      href: FORUM_URL,
      extraAttrs: trackingAttrs('community_forum'),
    },
    {
      text: HelpCenter.i18n.contribute,
      href: CONTRIBUTE_URL,
      extraAttrs: trackingAttrs('contribute_to_gitlab'),
    },
    {
      text: HelpCenter.i18n.feedback,
      href: `${PROMO_URL}/submit-feedback`,
      extraAttrs: trackingAttrs('submit_feedback'),
    },
  ];

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders menu items', () => {
      expect(findDropdownGroup(0).props('group').items).toEqual(getDefaultHelpItems());

      expect(findDropdownGroup(1).props('group').items).toEqual([
        expect.objectContaining({ text: HelpCenter.i18n.shortcuts }),
        expect.objectContaining({ text: HelpCenter.i18n.whatsnew }),
      ]);
    });

    it('does not render privacy item if not in SaaS mode', () => {
      createWrapper(sidebarData, { isSaas: false });

      expect(findDropdownGroup(0).props('group').items).toEqual(getDefaultHelpItems());
    });

    it('renders privacy item if in SaaS mode', () => {
      createWrapper(sidebarData, { isSaas: true });

      expect(findDropdownGroup(0).props('group').items).toEqual([
        ...getDefaultHelpItems(),
        PRIVACY_HELP_ITEM,
      ]);
    });

    describe('compare plans URL', () => {
      it('uses the compare_plans_url provided in sidebarData', () => {
        const customSidebarData = {
          ...sidebarData,
          compare_plans_url: '/custom/billing/path',
        };

        createWrapper(customSidebarData);

        const helpItems = findDropdownGroup(0).props('group').items;
        const plansItem = helpItems.find((item) => item.text === HelpCenter.i18n.plans);

        expect(plansItem.href).toBe('/custom/billing/path');
      });

      it('uses the compare_plans_url from sidebarData', () => {
        createWrapper();

        const helpItems = findDropdownGroup(0).props('group').items;
        const plansItem = helpItems.find((item) => item.text === HelpCenter.i18n.plans);

        expect(plansItem.href).toBe(sidebarData.compare_plans_url);
      });
    });

    describe('with GitLab version check feature enabled', () => {
      beforeEach(() => {
        createWrapper({
          ...sidebarData,
          show_version_check: true,
        });
      });

      it('shows version information as first item', () => {
        expect(findDropdownGroup(0).props('group').items).toEqual([
          {
            text: HelpCenter.i18n.version,
            href: helpPagePath('update/_index.md'),
            version: '16.0',
            extraAttrs: trackingAttrs('version_help_dropdown'),
          },
        ]);
      });
    });

    describe('when Terms of Service and Data Privacy is set', () => {
      it('shows link to Terms of Service and Data Privacy', () => {
        const customSidebarData = {
          ...sidebarData,
          terms: '/-/users/terms',
        };

        createWrapper(customSidebarData);

        expect(findDropdownGroup(0).props('group').items).toEqual([
          ...getDefaultHelpItems(customSidebarData),
          expect.objectContaining({
            text: HelpCenter.i18n.terms,
            href: '/-/users/terms',
            extraAttrs: {
              ...trackingAttrs('terms'),
            },
          }),
        ]);
      });

      it('does not show link to Terms of Service and Data Privacy on SaaS even if it is set', () => {
        const customSidebarData = {
          ...sidebarData,
          terms: '/-/users/terms',
        };

        createWrapper(customSidebarData, { isSaas: true });

        expect(findDropdownGroup(0).props('group').items).toEqual([
          ...getDefaultHelpItems(customSidebarData),
          PRIVACY_HELP_ITEM,
        ]);
      });
    });

    describe('when Terms of Service and Data Privacy is undefined', () => {
      beforeEach(() => {
        createWrapper({
          ...sidebarData,
          terms: undefined,
        });
      });

      it('does not show link to Terms of Service and Data Privacy', () => {
        const menuItems = findDropdownGroup(0)
          .props('group')
          .items.map(({ text }) => text);
        expect(menuItems).not.toContain('Terms and privacy');
      });
    });

    describe('keyboard shortcuts', () => {
      let button;

      beforeEach(() => {
        button = findButton('Keyboard shortcuts');
      });

      it('shows the keyboard shortcuts modal', () => {
        expect(button.classList.contains('js-shortcuts-modal-trigger')).toBe(true);
      });

      it('has Snowplow tracking attributes', () => {
        expect(findButton('Keyboard shortcuts').dataset).toEqual(
          expect.objectContaining({
            trackAction: 'click_button',
            trackLabel: 'keyboard_shortcuts_help',
            trackProperty: 'nav_help_menu',
          }),
        );
      });
    });

    describe("What's new", () => {
      const findWhatsNewItem = () =>
        wrapper
          .findAllComponents(GlDisclosureDropdownGroup)
          .wrappers.flatMap((g) => g.props('group').items)
          .find((item) => item?.text === HelpCenter.i18n.whatsnew);

      beforeEach(() => {
        createWrapper({
          ...sidebarData,
          show_version_check: true,
        });
      });

      it("shows the What's new slideout when clicked", async () => {
        await findWhatsNewItem().action();
        expect(toggleWhatsNewDrawer).toHaveBeenCalledWith(
          {
            versionDigest: sidebarData.whats_new_version_digest,
            initialReadArticles: sidebarData.whats_new_read_articles,
            markAsReadPath: sidebarData.whats_new_mark_as_read_path,
            mostRecentReleaseItemsCount: sidebarData.whats_new_most_recent_release_items_count,
          },
          expect.any(Function),
        );
      });

      it('reuses the cached drawer instance on subsequent clicks', async () => {
        await findWhatsNewItem().action();
        await findWhatsNewItem().action();
        expect(toggleWhatsNewDrawer).toHaveBeenCalledTimes(2);
        expect(toggleWhatsNewDrawer).toHaveBeenLastCalledWith();
      });

      it('has Snowplow tracking attributes on the menu item', () => {
        expect(findWhatsNewItem().extraAttrs).toEqual({
          'data-track-action': 'click_button',
          'data-track-label': 'whats_new',
          'data-track-property': 'nav_help_menu',
        });
      });
    });

    describe("What's new visibility", () => {
      it('hides the menu item when display_whats_new is disabled', () => {
        createWrapper({ ...sidebarData, display_whats_new: false });

        expect(findDropdownGroup(1).props('group').items).toEqual([
          expect.objectContaining({ text: HelpCenter.i18n.shortcuts }),
        ]);
      });

      it('renders the menu item even when all articles are read', () => {
        createWrapper({ ...sidebarData, whats_new_read_articles: [1, 2] });

        expect(findDropdownGroup(1).props('group').items).toEqual([
          expect.objectContaining({ text: HelpCenter.i18n.shortcuts }),
          expect.objectContaining({ text: HelpCenter.i18n.whatsnew }),
        ]);
      });
    });

    describe('dropdown toggle', () => {
      it('tracks Snowplow event when dropdown is shown', () => {
        findDropdown().vm.$emit('shown');
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_toggle', {
          label: 'show_help_dropdown',
          property: 'nav_help_menu',
        });
      });

      it('tracks Snowplow event when dropdown is hidden', () => {
        findDropdown().vm.$emit('hidden');
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_toggle', {
          label: 'hide_help_dropdown',
          property: 'nav_help_menu',
        });
      });
    });
  });

  describe('when free_group_upgrade_link is provided', () => {
    beforeEach(() => {
      createWrapper({ ...sidebarData, free_group_upgrade_link: '/groups/my-group/-/billings' });
    });

    it('renders upgrade subscription button', () => {
      expect(findUpgradeButton().exists()).toBe(true);
    });
  });

  describe('when free_group_upgrade_link is not provided', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not render upgrade subscription button', () => {
      expect(findUpgradeButton().exists()).toBe(false);
    });
  });
});
