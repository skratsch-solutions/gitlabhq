<script>
import { GlDrawer, GlButton, GlAlert } from '@gitlab/ui';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { s__ } from '~/locale';
import updateCustomDashboardMutation from '../graphql/update_custom_dashboard.mutation.graphql';
import DashboardSettingsForm from './dashboard_settings_form.vue';

export default {
  name: 'DashboardSettingsDrawer',
  components: {
    GlDrawer,
    GlButton,
    GlAlert,
    DashboardSettingsForm,
  },
  props: {
    open: {
      type: Boolean,
      required: true,
    },
    dashboardConfig: {
      type: Object,
      required: true,
    },
    dashboardId: {
      type: String,
      required: true,
    },
  },
  emits: ['close'],
  data() {
    return {
      formData: {
        title: '',
        description: '',
      },
      errorMessage: '',
      isLoading: false,
    };
  },
  computed: {
    drawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    panels() {
      return this.dashboardConfig.panels;
    },
  },
  watch: {
    open(newVal) {
      if (newVal) {
        this.syncConfig();
      }
    },
  },
  mounted() {
    this.syncConfig();
  },
  methods: {
    syncConfig() {
      this.formData = {
        title: this.dashboardConfig?.title || '',
        description: this.dashboardConfig?.description || '',
      };
      this.clearError();
    },
    clearError() {
      this.errorMessage = '';
    },
    async handleSave() {
      this.clearError();

      const title = this.formData.title.trim();
      const description = this.formData.description.trim();
      if (!title) {
        this.errorMessage = s__('AnalyticsDashboards|Dashboard title is required.');
        return;
      }

      this.isLoading = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateCustomDashboardMutation,
          variables: {
            input: {
              id: this.dashboardId,
              name: title,
              description,
              config: {
                title,
                description,
                panels: this.panels,
              },
            },
          },
          update: (cache) => {
            const cacheId = cache.identify({
              id: this.dashboardId,
              __typename: 'CustomDashboard',
            });
            cache.evict({ id: cacheId });
          },
        });

        const { errors } = data?.updateCustomDashboard || {};
        if (errors?.length) {
          [this.errorMessage] = errors;
        } else {
          this.$emit('close');
        }
      } catch (error) {
        this.errorMessage = s__(
          'AnalyticsDashboards|Failed to update dashboard. Please try again.',
        );
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-drawer
      :open="open"
      :header-height="drawerHeaderHeight"
      variant="sidebar"
      class="!gl-w-full !gl-max-w-xl"
      data-testid="dashboard-settings-drawer"
      @close="$emit('close')"
    >
      <template #title>
        <h4 class="gl-m-0">{{ s__('AnalyticsDashboards|Dashboard settings') }}</h4>
      </template>

      <template #default>
        <gl-alert v-if="errorMessage" variant="danger" class="gl-mb-4" @dismiss="clearError">
          {{ errorMessage }}
        </gl-alert>
        <dashboard-settings-form v-model="formData" :is-loading="isLoading" />
      </template>

      <template #footer>
        <div class="gl-flex gl-w-full gl-items-center gl-gap-3">
          <gl-button
            variant="confirm"
            :loading="isLoading"
            data-testid="settings-save-button"
            @click="handleSave"
          >
            {{ s__('AnalyticsDashboards|Save') }}
          </gl-button>
          <gl-button
            :disabled="isLoading"
            data-testid="settings-cancel-button"
            @click="$emit('close')"
            >{{ s__('AnalyticsDashboards|Cancel') }}</gl-button
          >
          <gl-button
            class="gl-ml-auto"
            variant="danger"
            category="secondary"
            :disabled="isLoading"
            data-testid="settings-delete-button"
          >
            {{ s__('AnalyticsDashboards|Delete dashboard') }}
          </gl-button>
        </div>
      </template>
    </gl-drawer>
  </div>
</template>
