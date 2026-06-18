<script>
import { GlAlert, GlFormCheckbox } from '@gitlab/ui';
import { DEFAULT_PER_PAGE } from '~/api';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import SelectGroupsTab from '~/import/offline_transfer/components/select_groups_tab.vue';
import offlineTransferSourceOwnedGroupsQuery from '~/import/offline_transfer/graphql/queries/offline_transfer_source_owned_groups.query.graphql';
import { OFFLINE_EXPORT_TAB_HEADINGS, OFFLINE_EXPORT_TAB_FIELDS } from '../constants';

export default {
  name: 'OfflineTransferExportApp',
  components: {
    FormStepper,
    SelectGroupsTab,
    GlAlert,
    GlFormCheckbox,
  },
  data() {
    const tabFields = OFFLINE_EXPORT_TAB_FIELDS.map((field) => [field, false]);

    return {
      offlineTransferSourceOwnedGroups: null,
      showValidationError: false,
      isFormComplete: false,

      isStepComplete: Object.fromEntries(tabFields),
      showFetchError: false,
      showSelectError: false,
      search: null,
      startCursor: null,
      endCursor: null,
      selectedGroups: [],
    };
  },

  apollo: {
    offlineTransferSourceOwnedGroups: {
      query: offlineTransferSourceOwnedGroupsQuery,
      update(data) {
        return data.groups;
      },
      variables() {
        return {
          search: this.search,
          ...this.pagination,
        };
      },
      error() {
        this.showFetchError = true;
      },
    },
  },

  computed: {
    pageGroups() {
      return this.offlineTransferSourceOwnedGroups?.nodes ?? [];
    },
    pageInfo() {
      return this.offlineTransferSourceOwnedGroups?.pageInfo;
    },
    pagination() {
      if (!this.startCursor && !this.endCursor) {
        return { first: DEFAULT_PER_PAGE, after: null, last: null, before: null };
      }

      return {
        first: this.endCursor && DEFAULT_PER_PAGE,
        after: this.endCursor,
        last: this.startCursor && DEFAULT_PER_PAGE,
        before: this.startCursor,
      };
    },
    selectedGroupIds() {
      return this.selectedGroups.map((group) => group.id);
    },
    isLoading() {
      return this.$apollo.queries.offlineTransferSourceOwnedGroups.loading;
    },
    selectedGroupsCount() {
      return this.selectedGroups.length;
    },
  },
  watch: {
    // TODO: When adding searchbox, also watch search, reset cursors
    selectedGroupsCount() {
      this.showSelectError = false;
    },
  },

  methods: {
    onComplete() {
      this.isFormComplete = true;
    },
    isGroupSelected(group) {
      return this.selectedGroups.some((selected) => selected.id === group.id);
    },
    addGroup(group) {
      this.selectedGroups = [...this.selectedGroups, group];
    },
    removeGroup(group) {
      this.selectedGroups = this.selectedGroups.filter((selected) => selected.id !== group.id);
    },
    onToggleGroup(group) {
      if (this.isGroupSelected(group)) {
        this.removeGroup(group);
      } else {
        this.addGroup(group);
      }
    },
    onSteppedForward() {
      this.showValidationError = false;
      this.showSelectError = false;
    },

    onSelectAllCurrentPage() {
      const newSelections = this.pageGroups.filter((group) => !this.isGroupSelected(group));
      this.selectedGroups = [...this.selectedGroups, ...newSelections];
    },
    onDeselectAll() {
      this.selectedGroups = [];
    },
    onNext(endCursor) {
      this.startCursor = null;
      this.endCursor = endCursor;
    },
    onPrev(startCursor) {
      this.startCursor = startCursor;
      this.endCursor = null;
    },
    onValidationFailed(stepIndex) {
      if (stepIndex === 0) {
        this.showSelectError = true;
      } else {
        this.showValidationError = true;
      }
    },
    validateStep(stepIndex) {
      // each tab/step has a unique validation logic
      // passed down to formstepper that if false prevents
      // continuing to the next tab
      switch (stepIndex) {
        case 0:
          return this.selectedGroupsCount > 0;
        case 1:
          return this.isStepComplete.configure;
        case 2:
          return this.isStepComplete.review;
        case 3:
          return this.isStepComplete.export;
        default:
          return false;
      }
    },
    onSteppedBack({ previousTabIndex }) {
      // stepping back resets the `valid` state of previously completed tab
      this.isStepComplete[OFFLINE_EXPORT_TAB_FIELDS[previousTabIndex]] = false;
    },
  },
  STEPS: OFFLINE_EXPORT_TAB_HEADINGS,
};
</script>

<template>
  <div>
    <header class="gl-my-5">
      <h1 class="gl-heading-display">
        {{ s__('OfflineTransferExport|Export for offline transfer') }}
      </h1>
      <p class="gl-max-w-2xl">
        {{
          s__(
            'OfflineTransferExport|Export your groups to an AWS S3 storage service you control. You can import them to any GitLab instance, even without a network connection between this instance and the destination instance.',
          )
        }}
      </p>
      <!-- // temporary alerts, to be replaced-->
      <gl-alert
        v-if="showFetchError"
        :title="__('Error')"
        :dismiss-label="__('Dismiss')"
        dismissible
        variant="danger"
        data-testid="fetch-error-alert"
        @dismiss="showFetchError = false"
      >
        {{ s__('OfflineTransferExport|Could not load groups. Please try again.') }}
      </gl-alert>

      <gl-alert
        v-if="isFormComplete"
        :title="__('Complete')"
        :dismiss-label="__('Dismiss')"
        dismissible
        variant="info"
        data-testid="completion-alert"
        @dismiss="isFormComplete = false"
      />
      <!-- TODO: When the configure/review/export steps get real
        validation, move their errors inline at the top of each step's content (as
        step 0 does) and remove this alert. -->
      <gl-alert
        v-if="showValidationError"
        :title="__('Error')"
        :dismiss-label="__('Dismiss')"
        dismissible
        variant="danger"
        data-testid="validation-alert"
        @dismiss="showValidationError = false"
      />
    </header>

    <form-stepper
      :steps="$options.STEPS"
      :validate-step="validateStep"
      :completion-button-text="s__('OfflineTransferExport|Start export')"
      @stepped-back="onSteppedBack"
      @stepped-forward="onSteppedForward"
      @validation-failed="onValidationFailed"
      @complete="onComplete"
    >
      <template #step-0>
        <h2 class="gl-heading-3">
          {{ s__('OfflineTransferExport|Select groups to export') }}
        </h2>
        <p>
          {{
            s__(
              'OfflineTransferExport|Each group is exported with all of its subgroups and projects.',
            )
          }}
        </p>
        <select-groups-tab
          :page-groups="pageGroups"
          :selected-ids="selectedGroupIds"
          :loading="isLoading"
          :page-info="pageInfo"
          :show-select-error="showSelectError"
          @toggle="onToggleGroup"
          @select-current-page="onSelectAllCurrentPage"
          @deselect-all="onDeselectAll"
          @next="onNext"
          @prev="onPrev"
        />
      </template>

      <template #step-1>
        <h2 class="gl-heading-3">{{ s__('OfflineTransferExport|Export configuration') }}</h2>
        <gl-form-checkbox v-model="isStepComplete.configure" />
      </template>

      <template #step-2>
        <h2 class="gl-heading-3">{{ s__('OfflineTransferExport|Review export') }}</h2>
        <gl-form-checkbox v-model="isStepComplete.review" />
      </template>

      <template #step-3>
        <h2 class="gl-heading-3">{{ s__('OfflineTransferExport|Export') }}</h2>
        <gl-form-checkbox v-model="isStepComplete.export" />
      </template>
    </form-stepper>
  </div>
</template>
