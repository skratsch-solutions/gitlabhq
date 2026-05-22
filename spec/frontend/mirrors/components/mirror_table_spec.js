import { GlTable, GlAlert, GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import MirrorTable from '~/mirrors/components/mirror_table.vue';
import MirrorActions from '~/mirrors/components/mirror_actions.vue';
import { PROJECT_ID, createMirror } from './mock_data';

describe('MirrorTable', () => {
  let wrapper;

  const createComponent = ({
    mirrors = [
      createMirror({ id: 1 }),
      createMirror({ id: 2, url: 'https://example.com/mirror2.git' }),
    ],
    settingsEnabled = true,
    repositoryMirrorsAvailable = false,
  } = {}) => {
    wrapper = mountExtended(MirrorTable, {
      propsData: {
        initialMirrors: mirrors,
      },
      provide: {
        projectId: PROJECT_ID,
        settingsEnabled,
        repositoryMirrorsAvailable,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findByTestId('mirror-table-empty-state');
  const findMirrorActions = () => wrapper.findAllComponents(MirrorActions);
  const findTableRows = () => findTable().findAll('tbody tr');
  const findBranchSettingBadge = () => wrapper.findByTestId('mirror-branches-badge');

  describe('rendering', () => {
    it('renders GlTable with correct items', () => {
      createComponent();

      expect(findTable().exists()).toBe(true);
      expect(findTableRows()).toHaveLength(2);
    });

    it('shows empty state when no mirrors', () => {
      createComponent({ mirrors: [] });

      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().text()).toBe('There are currently no mirrored repositories.');
    });

    it('does not show empty state when mirrors exist', () => {
      createComponent();

      expect(findEmptyState().exists()).toBe(false);
    });

    it('does not show alert by default', () => {
      createComponent();

      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('mirror URL and direction', () => {
    it('renders mirror URL and "Push" direction for push mirrors', () => {
      createComponent({ mirrors: [createMirror()] });

      expect(wrapper.text()).toContain('https://example.com/mirror.git');
      expect(wrapper.text()).toContain('Push');
    });
  });

  describe('disabled badge', () => {
    it('shows disabled badge in the status column when mirror.enabled is false', () => {
      createComponent({ mirrors: [createMirror({ enabled: false })] });

      const statusCell = findTableRows().at(0).findAll('td').at(4);
      const badge = statusCell
        .findAllComponents(GlBadge)
        .wrappers.find((w) => w.props('variant') === 'warning');
      expect(badge).toBeDefined();
      expect(badge.text()).toBe('Disabled');
    });

    it('does not show disabled badge in the URL column', () => {
      createComponent({ mirrors: [createMirror({ enabled: false })] });

      const urlCell = findTableRows().at(0).findAll('td').at(0);
      const badge = urlCell
        .findAllComponents(GlBadge)
        .wrappers.find((w) => w.props('variant') === 'warning');
      expect(badge).toBeUndefined();
    });

    it('does not show disabled badge when mirror.enabled is true', () => {
      createComponent({ mirrors: [createMirror()] });

      const badge = wrapper
        .findAllComponents(GlBadge)
        .wrappers.find((w) => w.props('variant') === 'warning');
      expect(badge).toBeUndefined();
    });
  });

  describe('error badge', () => {
    it('shows error badge with tooltip when mirror.lastError is present', () => {
      createComponent({ mirrors: [createMirror({ lastError: 'Connection refused' })] });

      const badge = wrapper
        .findAllComponents(GlBadge)
        .wrappers.find((w) => w.props('variant') === 'danger');
      expect(badge).toBeDefined();
      expect(badge.text()).toBe('Error');
      expect(badge.attributes('title')).toBe('Connection refused');
    });

    it('does not show error badge when no error', () => {
      createComponent({ mirrors: [createMirror()] });

      const badge = wrapper
        .findAllComponents(GlBadge)
        .wrappers.find((w) => w.props('variant') === 'danger');
      expect(badge).toBeUndefined();
    });
  });

  describe('mirror branches setting badge', () => {
    it('shows "All branches" badge when mirrorBranchesSetting is "all"', () => {
      createComponent({
        mirrors: [createMirror({ mirrorBranchesSetting: 'all' })],
        repositoryMirrorsAvailable: true,
      });

      const badge = findBranchSettingBadge();
      expect(badge.exists()).toBe(true);
      expect(badge.text()).toBe('All branches');
    });

    it('shows "All protected branches" badge when mirrorBranchesSetting is "protected"', () => {
      createComponent({
        mirrors: [createMirror({ mirrorBranchesSetting: 'protected' })],
        repositoryMirrorsAvailable: true,
      });

      const badge = findBranchSettingBadge();
      expect(badge.exists()).toBe(true);
      expect(badge.text()).toBe('All protected branches');
    });

    it('shows "Specific branches" badge with regex tooltip when mirrorBranchesSetting is "regex"', () => {
      createComponent({
        mirrors: [
          createMirror({ mirrorBranchesSetting: 'regex', mirrorBranchRegex: 'main|release.*' }),
        ],
        repositoryMirrorsAvailable: true,
      });

      const badge = findBranchSettingBadge();
      expect(badge.exists()).toBe(true);
      expect(badge.text()).toBe('Specific branches');
      expect(badge.attributes('title')).toBe('main|release.*');
    });

    it('does not show badge when repositoryMirrorsAvailable is false', () => {
      createComponent({
        mirrors: [createMirror({ mirrorBranchesSetting: 'all' })],
        repositoryMirrorsAvailable: false,
      });

      expect(findBranchSettingBadge().exists()).toBe(false);
    });

    it('does not show badge when mirrorBranchesSetting is not present', () => {
      createComponent({
        mirrors: [createMirror()],
        repositoryMirrorsAvailable: true,
      });

      expect(findBranchSettingBadge().exists()).toBe(false);
    });
  });

  describe('timestamps', () => {
    it('shows time-ago-tooltip for last update started at and last update at', () => {
      createComponent({ mirrors: [createMirror()] });

      const tooltips = wrapper.findAllComponents(TimeAgoTooltip);
      expect(tooltips).toHaveLength(2);
      expect(tooltips.at(0).props('time')).toBe('2024-01-01T00:00:00Z');
      expect(tooltips.at(1).props('time')).toBe('2024-01-01T00:00:00Z');
    });

    it('shows "Never" when lastUpdateAt and lastUpdateStartedAt are null', () => {
      createComponent({
        mirrors: [createMirror({ lastUpdateAt: null, lastUpdateStartedAt: null })],
      });

      expect(wrapper.findAllComponents(TimeAgoTooltip)).toHaveLength(0);
      expect(wrapper.text()).toContain('Never');
    });
  });

  describe('action buttons when settingsEnabled is true', () => {
    it('renders MirrorActions for each mirror row', () => {
      createComponent();

      const actions = findMirrorActions();
      expect(actions).toHaveLength(2);
    });

    it('passes the correct mirror prop to each MirrorActions component', () => {
      const mirrors = [
        createMirror({ id: 1 }),
        createMirror({ id: 2, url: 'https://example.com/mirror2.git' }),
      ];
      createComponent({ mirrors });

      const actions = findMirrorActions();
      expect(actions.at(0).props('mirror')).toMatchObject({ id: 1 });
      expect(actions.at(1).props('mirror')).toMatchObject({ id: 2 });
    });
  });

  describe('action buttons when settingsEnabled is false', () => {
    it('does not render MirrorActions', () => {
      createComponent({ settingsEnabled: false });

      expect(findMirrorActions()).toHaveLength(0);
    });
  });
});
