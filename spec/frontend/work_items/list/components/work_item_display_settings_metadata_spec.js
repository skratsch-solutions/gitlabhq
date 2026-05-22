import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdownItem, GlToggle } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemDisplaySettingsMetadata from '~/work_items/list/components/work_item_display_settings_metadata.vue';
import updateWorkItemListUserPreference from '~/work_items/graphql/update_work_item_list_user_preferences.mutation.graphql';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS,
  METADATA_KEYS,
  ROUTES,
} from '~/work_items/constants';

Vue.use(VueApollo);

jest.mock('~/alert');

const firstMetadataKey = METADATA_KEYS[Object.keys(METADATA_KEYS)[0]];

describe('WorkItemDisplaySettingsMetadata', () => {
  let wrapper;
  let mockApolloProvider;
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const namespacePreferencesHandler = jest.fn().mockResolvedValue({
    data: {
      workItemUserPreferenceUpdate: {
        __typename: 'WorkItemUserPreferenceUpdatePayload',
        errors: [],
        userPreferences: {
          __typename: 'UserPreferences',
          displaySettings: { hiddenMetadataKeys: [firstMetadataKey] },
          sort: 'UPDATED_DESC',
        },
      },
    },
  });

  const createComponent = ({
    mountFn = shallowMount,
    props = {},
    namespaceHandler = namespacePreferencesHandler,
    routeName = ROUTES.index,
  } = {}) => {
    mockApolloProvider = createMockApollo([[updateWorkItemListUserPreference, namespaceHandler]]);

    wrapper = mountFn(WorkItemDisplaySettingsMetadata, {
      apolloProvider: mockApolloProvider,
      mocks: {
        $route: { name: routeName },
      },
      propsData: {
        namespacePreferences: { hiddenMetadataKeys: [] },
        fullPath: 'gitlab-org/gitlab',
        isGroup: false,
        isServiceDeskList: false,
        workItemTypeId: 'gid://gitlab/WorkItems::Type/8',
        sortKey: 'UPDATED_DESC',
        ...props,
      },
    });
  };

  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findToggles = () => wrapper.findAllComponents(GlToggle);
  const findFirstDropdownItem = () => findDropdownItems().at(0);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders a toggle for every setting field', () => {
    createComponent();

    expect(findToggles()).toHaveLength(WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.length);
  });

  it('marks toggles as on when the key is not in hiddenMetadataKeys', () => {
    createComponent({
      mountFn: mount,
      props: { namespacePreferences: { hiddenMetadataKeys: [firstMetadataKey] } },
    });

    const toggleForHiddenKey = findToggles().at(0);
    expect(toggleForHiddenKey.props('value')).toBe(false);
  });

  it('renders only group-applicable metadata fields in group context', () => {
    createComponent({ props: { isGroup: true } });

    const groupApplicableFields = WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.filter(
      (field) => field.isPresentInGroup,
    );
    expect(findToggles()).toHaveLength(groupApplicableFields.length);
  });

  describe('when not on a saved view', () => {
    beforeEach(() => {
      createComponent({ routeName: ROUTES.index });
    });

    it('toggles metadata field visibility via the mutation', async () => {
      findFirstDropdownItem().vm.$emit('action');
      await waitForPromises();

      expect(namespacePreferencesHandler).toHaveBeenCalledWith({
        namespace: 'gitlab-org/gitlab',
        displaySettings: {
          hiddenMetadataKeys: [firstMetadataKey],
        },
      });
    });

    it('shows an alert when the mutation fails', async () => {
      const error = new Error('Network error');
      const errorHandler = jest.fn().mockRejectedValue(error);
      createComponent({ namespaceHandler: errorHandler });

      findFirstDropdownItem().vm.$emit('action');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while saving the preference.',
        captureError: true,
        error,
      });
    });

    it('tracks work_item_metadata_field_hidden when a field is hidden', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findFirstDropdownItem().vm.$emit('action');
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'work_item_metadata_field_hidden',
        { property: firstMetadataKey },
        undefined,
      );
    });
  });

  describe('when on a saved view', () => {
    beforeEach(() => {
      createComponent({ routeName: ROUTES.savedView });
    });

    it('updates settings without calling the mutation', async () => {
      findFirstDropdownItem().vm.$emit('action');
      await waitForPromises();

      expect(namespacePreferencesHandler).not.toHaveBeenCalled();
      expect(wrapper.emitted('update-settings')).toEqual([
        [{ hiddenMetadataKeys: [firstMetadataKey] }],
      ]);
    });

    it('tracks work_item_metadata_field_hidden when a field is hidden', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findFirstDropdownItem().vm.$emit('action');
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'work_item_metadata_field_hidden',
        { property: firstMetadataKey },
        undefined,
      );
    });
  });
});
