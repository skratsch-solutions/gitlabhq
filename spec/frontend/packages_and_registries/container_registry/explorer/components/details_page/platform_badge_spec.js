import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PlatformBadge from '~/packages_and_registries/container_registry/explorer/components/details_page/platform_badge.vue';
import { WINDOWS_BUILD_LABELS } from '~/packages_and_registries/container_registry/explorer/constants';

describe('PlatformBadge', () => {
  let wrapper;

  const createWrapper = (platform) => {
    wrapper = shallowMount(PlatformBadge, {
      propsData: { platform },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);

  describe('platformText', () => {
    it('renders os/architecture for linux/amd64', () => {
      createWrapper({ os: 'linux', architecture: 'amd64', variant: null, osVersion: null });

      expect(findBadge().text()).toBe('linux/amd64');
    });

    it('renders os/architecture/variant for linux/arm64/v8', () => {
      createWrapper({ os: 'linux', architecture: 'arm64', variant: 'v8', osVersion: null });

      expect(findBadge().text()).toBe('linux/arm64/v8');
    });

    it('renders windows/amd64 with known build label', () => {
      createWrapper({
        os: 'windows',
        architecture: 'amd64',
        variant: null,
        osVersion: '10.0.20348.4529',
      });

      expect(findBadge().text()).toBe('windows/amd64 (ltsc2022)');
    });

    it('renders windows/amd64 without parenthetical for unknown build number', () => {
      createWrapper({
        os: 'windows',
        architecture: 'amd64',
        variant: null,
        osVersion: '10.0.99999.0',
      });

      expect(findBadge().text()).toBe('windows/amd64');
    });

    it('does not append build label for non-windows os with osVersion', () => {
      createWrapper({
        os: 'linux',
        architecture: 'amd64',
        variant: null,
        osVersion: '10.0.20348.4529',
      });

      expect(findBadge().text()).toBe('linux/amd64');
    });

    describe('all known Windows build labels', () => {
      it.each(Object.entries(WINDOWS_BUILD_LABELS))(
        'build %s renders label %s',
        (buildNumber, label) => {
          createWrapper({
            os: 'windows',
            architecture: 'amd64',
            variant: null,
            osVersion: `10.0.${buildNumber}.0`,
          });

          expect(findBadge().text()).toBe(`windows/amd64 (${label})`);
        },
      );
    });

    it('handles null variant gracefully', () => {
      createWrapper({ os: 'linux', architecture: 'amd64', variant: null, osVersion: null });

      expect(findBadge().text()).toBe('linux/amd64');
    });

    it('handles null osVersion gracefully', () => {
      createWrapper({ os: 'windows', architecture: 'amd64', variant: null, osVersion: null });

      expect(findBadge().text()).toBe('windows/amd64');
    });
  });
});
