<script>
import { GlDrawer, GlFormGroup, GlFormInput, GlFormTextarea, GlButton } from '@gitlab/ui';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import DashboardDeleteModal from '../../../vue_shared/components/dashboards_list/dashboard_delete_modal.vue';

export default {
  name: 'DashboardSettingsDrawer',
  components: {
    GlDrawer,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlButton,
    DashboardDeleteModal,
  },
  inject: ['exploreAnalyticsDashboardsPath'],
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
      title: '',
      description: '',
    };
  },
  computed: {
    drawerHeaderHeight() {
      return getContentWrapperHeight();
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
      this.title = this.dashboardConfig?.title || '';
      this.description = this.dashboardConfig?.description || '';
    },
    showDeleteModal() {
      this.$refs.deleteModal.show();
    },
    handleDeleteSuccess() {
      visitUrl(this.exploreAnalyticsDashboardsPath);
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
        <div>
          <gl-form-group
            :label="s__('AnalyticsDashboards|Dashboard title')"
            label-for="dashboard-title"
          >
            <gl-form-input
              id="dashboard-title"
              v-model="title"
              :placeholder="s__('AnalyticsDashboards|Enter a title')"
              data-testid="dashboard-title-input"
            />
          </gl-form-group>
          <gl-form-group
            :label="s__('AnalyticsDashboards|Dashboard description')"
            label-for="dashboard-description"
          >
            <gl-form-textarea
              id="dashboard-description"
              v-model="description"
              :placeholder="s__('AnalyticsDashboards|Enter a description (optional)')"
              data-testid="dashboard-description-textarea"
            />
          </gl-form-group>
        </div>
      </template>

      <template #footer>
        <div class="gl-flex gl-w-full gl-items-center gl-gap-3">
          <gl-button variant="confirm" data-testid="settings-save-button">{{
            s__('AnalyticsDashboards|Save')
          }}</gl-button>
          <gl-button data-testid="settings-cancel-button" @click="$emit('close')">{{
            s__('AnalyticsDashboards|Cancel')
          }}</gl-button>
          <gl-button
            class="gl-ml-auto"
            variant="danger"
            category="secondary"
            data-testid="settings-delete-button"
            @click="showDeleteModal"
          >
            {{ s__('AnalyticsDashboards|Delete dashboard') }}
          </gl-button>
        </div>
      </template>
    </gl-drawer>

    <dashboard-delete-modal
      ref="deleteModal"
      :dashboard-id="dashboardId"
      data-testid="settings-delete-modal"
      @delete="handleDeleteSuccess"
    />
  </div>
</template>
