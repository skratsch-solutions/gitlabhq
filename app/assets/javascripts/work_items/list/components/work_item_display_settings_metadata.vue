<script>
import { GlDisclosureDropdownItem, GlIcon, GlToggle } from '@gitlab/ui';
import produce from 'immer';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { InternalEvents } from '~/tracking';
import updateWorkItemListUserPreference from '~/work_items/graphql/update_work_item_list_user_preferences.mutation.graphql';
import getUserWorkItemsPreferences from '~/work_items/graphql/get_user_preferences.query.graphql';
import {
  WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS,
  METADATA_KEYS,
  ROUTES,
} from '~/work_items/constants';

export default {
  name: 'WorkItemDisplaySettingsMetadata',
  components: {
    GlDisclosureDropdownItem,
    GlIcon,
    GlToggle,
  },
  mixins: [InternalEvents.mixin()],
  i18n: {
    fields: s__('WorkItems|Fields'),
  },
  props: {
    workItemTypeId: {
      type: String,
      required: true,
    },
    sortKey: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    namespacePreferences: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    isServiceDeskList: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['update-settings'],
  computed: {
    isSavedView() {
      return this.$route?.name === ROUTES.savedView;
    },
    hiddenMetadataKeys() {
      return this.namespacePreferences?.hiddenMetadataKeys || [];
    },
    applicableMetadataPreferences() {
      return WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.filter((item) => {
        if (item.key === METADATA_KEYS.STATUS) {
          return !this.isServiceDeskList;
        }
        return !this.isGroup || item.isPresentInGroup;
      });
    },
  },
  methods: {
    async toggleMetadataDisplaySettings(metadataKey) {
      const wasHidden = this.hiddenMetadataKeys.includes(metadataKey);
      const newHiddenKeys = wasHidden
        ? this.hiddenMetadataKeys.filter((key) => key !== metadataKey)
        : [...this.hiddenMetadataKeys, metadataKey];

      const input = {
        hiddenMetadataKeys: newHiddenKeys,
      };

      if (this.isSavedView) {
        this.$emit('update-settings', input);
        if (!wasHidden) {
          this.trackEvent('work_item_metadata_field_hidden', {
            property: metadataKey,
          });
        }
        return;
      }

      try {
        await this.$apollo.mutate({
          mutation: updateWorkItemListUserPreference,
          variables: {
            namespace: this.fullPath,
            displaySettings: input,
          },
          optimisticResponse: {
            workItemUserPreferenceUpdate: {
              errors: [],
              userPreferences: {
                displaySettings: {
                  hiddenMetadataKeys: newHiddenKeys,
                },
                sort: this.sortKey,
                __typename: 'WorkItemTypesUserPreference',
              },
              __typename: 'WorkItemUserPreferenceUpdatePayload',
            },
          },
          update: (
            cache,
            {
              data: {
                workItemUserPreferenceUpdate: { userPreferences },
              },
            },
          ) => {
            cache.updateQuery(
              {
                query: getUserWorkItemsPreferences,
                variables: {
                  namespace: this.fullPath,
                  workItemTypeId: this.workItemTypeId,
                  userPreferencesOnly: this.isSavedView,
                },
              },
              (existingData) =>
                produce(existingData, (draftData) => {
                  if (draftData?.currentUser) {
                    draftData.currentUser.workItemPreferences = {
                      ...(draftData?.currentUser?.workItemPreferences ?? {}),
                      displaySettings: userPreferences.displaySettings,
                    };
                  }
                }),
            );
          },
        });

        if (!wasHidden) {
          this.trackEvent('work_item_metadata_field_hidden', {
            property: metadataKey,
          });
        }
      } catch (error) {
        createAlert({
          message: __('Something went wrong while saving the preference.'),
          captureError: true,
          error,
        });
      }
    },
  },
};
</script>

<template>
  <div data-testid="display-settings-metadata">
    <span>{{ $options.i18n.fields }}</span>
    <ul class="gl-m-0 gl-mt-2 gl-list-none gl-p-0">
      <gl-disclosure-dropdown-item
        v-for="metadata in applicableMetadataPreferences"
        :key="metadata.key"
        class="work-item-dropdown-toggle"
        @action="toggleMetadataDisplaySettings(metadata.key)"
      >
        <template #list-item>
          <div class="gl-flex gl-items-center gl-gap-3">
            <gl-icon :name="metadata.icon" />
            <gl-toggle
              :value="!hiddenMetadataKeys.includes(metadata.key)"
              :label="metadata.label"
              class="gl-w-full gl-justify-between"
              label-position="left"
            />
          </div>
        </template>
      </gl-disclosure-dropdown-item>
    </ul>
  </div>
</template>
