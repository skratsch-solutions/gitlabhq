import {
  GlButton,
  GlCollapse,
  GlFormCheckboxGroup,
  GlFormCheckbox,
  GlPopover,
  GlAnimatedChevronRightDownIcon,
} from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PersonalAccessTokenResourcesList from '~/personal_access_tokens/components/create_granular_token/personal_access_token_resources_list.vue';
import { stubComponent } from 'helpers/stub_component';
import { mockGroupPermissions, mockGroupResources } from '../../mock_data';

describe('PersonalAccessTokenResourcesList', () => {
  let wrapper;

  const createComponent = ({ isFiltering = false } = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenResourcesList, {
      propsData: {
        scope: 'namespace',
        permissions: mockGroupPermissions,
        isFiltering,
      },
      stubs: {
        GlAnimatedChevronRightDownIcon: stubComponent(GlAnimatedChevronRightDownIcon, {
          props: ['isOn'],
        }),
      },
    });
  };

  const findCheckboxGroup = () => wrapper.findComponent(GlFormCheckboxGroup);
  const findCategoryButtons = () => wrapper.findAllComponents(GlButton);
  const findCategoryButton = (index) => wrapper.findAllComponents(GlButton).at(index);
  const findCollapses = () => wrapper.findAllComponents(GlCollapse);
  const findCollapse = (index) => findCollapses().at(index);
  const findChevron = () => wrapper.findComponent(GlAnimatedChevronRightDownIcon);
  const findCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findCheckbox = (index) => findCheckboxes().at(index);
  const findPopovers = () => wrapper.findAllComponents(GlPopover);
  const findPopover = (index) => findPopovers().at(index);

  const clickCategoryButton = (index) => {
    findCategoryButton(index).vm.$emit('click');
    return nextTick();
  };

  beforeEach(() => createComponent());

  describe('props validation', () => {
    it('validates `scope` prop correctly', () => {
      const { validator } = PersonalAccessTokenResourcesList.props.scope;

      expect(validator('namespace')).toBe(true);
      expect(validator('user')).toBe(true);
      expect(validator('invalid')).toBe(false);
      expect(validator('')).toBe(false);
    });
  });

  describe('rendering', () => {
    it('renders checkbox group', () => {
      expect(findCheckboxGroup().exists()).toBe(true);
    });

    it('renders category buttons', () => {
      expect(findCategoryButtons()).toHaveLength(2);

      expect(findCategoryButton(0).text()).toBe('Groups and projects');
      expect(findCategoryButton(1).text()).toBe('Merge request');
    });

    it('renders collapse components for each category', () => {
      expect(findCollapses()).toHaveLength(2);

      expect(findCollapse(0).props('visible')).toBe(false);
      expect(findCollapse(1).props('visible')).toBe(false);
    });
  });

  describe('category toggle', () => {
    describe('when category is toggled open', () => {
      beforeEach(() => clickCategoryButton(0));

      it('shows permissions list', () => {
        expect(findCollapse(0).props('visible')).toBe(true);
      });

      it('shows chevron as open', () => {
        expect(findChevron().props('isOn')).toBe(true);
      });
    });

    describe('when category is toggled closed', () => {
      beforeEach(() => {
        clickCategoryButton(0); // Toggle open.
        clickCategoryButton(0); // Toggle closed.
      });

      it('hides permissions list', () => {
        expect(findCollapse(0).props('visible')).toBe(false);
      });

      it('shows chevron as closed', () => {
        expect(findChevron().props('isOn')).toBe(false);
      });
    });

    describe('when filtering permissions', () => {
      beforeEach(() => {
        wrapper.setProps({ isFiltering: true });
      });

      it('disables category button', () => {
        expect(findCategoryButton(0).props('disabled')).toBe(true);
      });

      it('shows permissions list', () => {
        expect(findCollapse(0).props('visible')).toBe(true);
      });

      it('shows chevron as opened', () => {
        expect(findChevron().props('isOn')).toBe(true);
      });
    });
  });

  describe('resource checkboxes', () => {
    beforeEach(() => {
      clickCategoryButton(0);
      return clickCategoryButton(1);
    });

    it('renders checkboxes for each resource', () => {
      expect(findCheckboxes()).toHaveLength(3);

      expect(findCheckbox(0).text()).toBe('Project');
      expect(findCheckbox(0).attributes('value')).toBe('project');

      expect(findCheckbox(1).text()).toBe('Contributed project');
      expect(findCheckbox(1).attributes('value')).toBe('contributed_project');

      expect(findCheckbox(2).text()).toBe('Repository');
      expect(findCheckbox(2).attributes('value')).toBe('repository');
    });
  });

  describe('resource description', () => {
    it('renders popover with description for each resource', () => {
      expect(findPopovers()).toHaveLength(3);

      expect(findPopover(0).text()).toBe('Project resource description');
      expect(findPopover(0).attributes('target')).toBe('namespace-project');

      expect(findPopover(1).text()).toBe('Contributed project resource description');
      expect(findPopover(1).attributes('target')).toBe('namespace-contributed_project');

      expect(findPopover(2).text()).toBe('Repository resource description');
      expect(findPopover(2).attributes('target')).toBe('namespace-repository');
    });
  });

  describe('events', () => {
    it('emits `input` event when selection changes', async () => {
      await findCheckboxGroup().vm.$emit('input', mockGroupResources);

      expect(wrapper.emitted('input')).toEqual([[mockGroupResources]]);
    });
  });
});
