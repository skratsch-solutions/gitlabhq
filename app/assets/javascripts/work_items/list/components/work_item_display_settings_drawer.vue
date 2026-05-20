<script>
import { GlDrawer } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import WorkItemDisplaySettingsSort from './work_item_display_settings_sort.vue';

export default {
  name: 'WorkItemDisplaySettingsDrawer',
  components: {
    GlDrawer,
    WorkItemDisplaySettingsSort,
  },
  i18n: {
    title: s__('WorkItems|Display'),
  },
  props: {
    open: {
      type: Boolean,
      required: true,
    },
    sortOptions: {
      type: Array,
      required: false,
      default: () => [],
    },
    sortKey: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['close', 'sort'],
  computed: {
    hasSortOptions() {
      return this.sortOptions.length > 0;
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onSort(newSortKey) {
      this.$emit('sort', newSortKey);
    },
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :open="open"
    :z-index="$options.DRAWER_Z_INDEX"
    class="work-item-display-settings-drawer"
    data-testid="display-settings-drawer"
    @close="onClose"
  >
    <template #title>
      <h2 class="gl-my-0 gl-text-size-h2 gl-leading-24">{{ $options.i18n.title }}</h2>
    </template>
    <template #default>
      <work-item-display-settings-sort
        v-if="hasSortOptions"
        :sort-options="sortOptions"
        :sort-key="sortKey"
        class="gl-pb-4"
        @sort="onSort"
      />
      <div :class="{ 'gl-border-t gl-pt-4': hasSortOptions }">
        <slot></slot>
      </div>
    </template>
  </gl-drawer>
</template>
